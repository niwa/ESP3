function [layers,id_rem] = open_em_file_standalone(Filename_cell,varargin)
id_rem = [];
layers = layer_cl.empty();

p = inputParser;

if ~iscell(Filename_cell)
    Filename_cell = {Filename_cell};
end

if isempty(Filename_cell)
    return;
end

def_path_m = fullfile(tempdir,'data_echo');

if ischar(Filename_cell)
    def_gps_only_val = 0;
else
    def_gps_only_val = zeros(1,numel(Filename_cell));
end

addRequired(p,'Filename_cell',@(x) ischar(x)||iscell(x));
addParameter(p,'PathToMemmap',def_path_m,@ischar);
addParameter(p,'Calibration',[]);
addParameter(p,'Frequencies',[]);
addParameter(p,'Channels',{});
addParameter(p,'GPSOnly',def_gps_only_val);
addParameter(p,'load_bar_comp',[]);
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));

parse(p,Filename_cell,varargin{:});

[path_f,file_f,~] = cellfun(@fileparts,Filename_cell,'un',0);

[file_f,ia] = unique(file_f);
path_f = path_f(ia);

Filename_cell = fullfile(path_f,file_f);

nb_files = numel(Filename_cell);
load_bar_comp = p.Results.load_bar_comp;

if ~isempty(load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_files,'Value',0);
end

layers = [];
id_rem = [];

ext = {'.wcd' '.all' };

%HEADER_SIZE  =20;

dg_to_read = {'ATTITUDE (41H)' ...
    'DEPTH DATAGRAM (44H)' ...
    'SURFACE SOUND SPEED (47H)' ...
    'INSTALLATION PARAMETERS START (49H)' ...
    'RAW RANGE AND ANGLE 78 (4EH)' ...
    'POSITION (50H)' ...
    'RUNTIME PARAMETERS (52H)' ...
    'SOUND SPEED PROFILE (55H)' ...
    'INSTALLATION PARAMETERS STOP (69H)' ...
    'WATER COLUMN DATAGRAM (6BH)' ...
    'AMPLITUDE AND PHASE WC DATAGRAM (72H)' ...
    };

wc_dg_names = {'WATER COLUMN DATAGRAM (6BH)' 'AMPLITUDE AND PHASE WC DATAGRAM (72H)'};

block_len = get_block_len(50,'cpu',p.Results.block_len);

for uu = 1:nb_files
    try
        dg_to_read_bool = true(1,numel(dg_to_read));

        if ~isempty(load_bar_comp)
            set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_files,'Value',uu);
        end

        file_read_bool = false;
        has_been_read  =false;
        EM_data_struct = init_EM_data_struct(dg_to_read);
        [path_f,fileN,~] = fileparts(Filename_cell{uu});
        echo_folder = get_esp3_file_folder(path_f,true);

        fileStruct = fullfile(echo_folder,[fileN '_emstruct.mat']);

        force_read = isdebugging;

        if isfile(fileStruct) && ~force_read
            s_out = load(fileStruct);
            EM_data_struct = s_out.EM_data_struct;
            if strcmpi(EM_data_struct.EM_struct_version,get_curr_EM_struct_version())
                has_been_read = true;
                file_read_bool = true;
            else
                EM_data_struct = init_EM_data_struct(dg_to_read);
            end
        end

        [~,ff,ee] = fileparts(EM_data_struct.Filename);
        EM_data_struct.Filename = fullfile(path_f,[ff ee]);

        fields = fieldnames(EM_data_struct);

        for uif = 1:numel(fields)
            if isfield(EM_data_struct.(fields{uif}),'fname')
                [~,ff,ee] = fileparts(EM_data_struct.(fields{uif}).fname);
                EM_data_struct.(fields{uif}).fname = fullfile(path_f,[ff ee]);
            end
        end

        if ~has_been_read

            for iext = 1:numel(ext)

                if ~isfile([Filename_cell{uu} ext{iext}])
                    continue;
                end
                Filename = [Filename_cell{uu} ext{iext}];
                EM_data_struct.Filename = Filename;
                [path_f,fileN,~] = fileparts(Filename);
                echo_folder = get_esp3_file_folder(path_f,true);
                str = '';

                s=dir(Filename);
                filesize=s.bytes;

                ftype = get_ftype(Filename);

                if ~ismember(ftype,{'EM'})
                    continue;
                end

                fileIdx = fullfile(echo_folder,[fileN '_' ext{iext}(2:end) '_echoidx.mat']);

                try
                    fidx = load(fileIdx);
                    idx_raw_obj = fidx.idx_raw_obj;
                catch
                    idx_raw_obj = raw_idx_cl(Filename,p.Results.load_bar_comp);
                    save(fileIdx,'idx_raw_obj');
                end

                if ~isempty(load_bar_comp)
                    str_disp=sprintf('Opening File %d/%d : %s',uu,nb_files,Filename);
                    load_bar_comp.progress_bar.setText(str_disp);
                else
                    fprintf('\nOpening File %s:\n',Filename);
                end

                dg_str_cell = cellfun(@dg_num_to_str,idx_raw_obj.type_dg,'un',0);
                dg_str_cell_u = unique(dg_str_cell);
                dg_str_cell_u_val = cellfun(@matlab.lang.makeValidName,dg_str_cell_u,'un',0);
                dg_str_cell_val = dg_str_cell;

                for uic = 1:numel(dg_str_cell_u_val)
                    dg_str_cell_val(strcmpi(dg_str_cell,dg_str_cell_u{uic})) = dg_str_cell_u_val(uic);
                end


                if ismember('AMPLITUDE AND PHASE WC DATAGRAM (72H)',dg_str_cell)
                    dg_to_read_bool(strcmpi(dg_to_read,'WATER COLUMN DATAGRAM (6BH)')) = false;
                end

                idg_to_read = find(ismember(dg_str_cell,dg_to_read(dg_to_read_bool)));

                if isempty(idg_to_read)
                    continue;
                end

                [fid,~] = fopen(Filename, 'r');
                [~,~,~,enc] = fopen(fid);
                fclose(fid);

                [fid,~] = fopen(Filename, 'r',idx_raw_obj.b_ordering,enc);

                if ~isempty(load_bar_comp)
                    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',idg_to_read(end),'Value',0);
                end

                for idg = idg_to_read
                    %curpos = ftell(fid);
                    datpos = idx_raw_obj.pos_dg(idg);
                    if ~isempty(load_bar_comp)&&(rem(idg,50)==0||idg ==idg_to_read(end))
                        set(load_bar_comp.progress_bar,'Value',idg);
                    elseif isempty(load_bar_comp)
                        nstr = numel(str);
                        str = sprintf('%2.0f%%',floor(datpos/filesize*100));
                        fprintf([repmat('\b',1,nstr) '%s'],str);
                    end

                    try
                        datpos = idx_raw_obj.pos_dg(idg);
                        fseek(fid, datpos,'bof');

                        header_struct = read_em_header(fid);

                        if isempty(header_struct.dgSize)||header_struct.dgSize==0||header_struct.stx~=2
                            continue;
                        end
                        fields = fieldnames(EM_data_struct);

                        idx_struct = find(ismember(fields,dg_str_cell_val{idg}),1);

                        if isempty(idx_struct)||isempty(EM_data_struct.(fields{idx_struct}))
                            struct_in = header_struct;
                            idn = 1;
                        else
                            struct_in = EM_data_struct.(fields{idx_struct});
                            idn = numel(EM_data_struct.(fields{idx_struct}).stx)+1;
                        end


                        fh = fieldnames(header_struct);

                        for ifi = 1:numel(fh)
                            struct_in.(fh{ifi})(idn) = header_struct.(fh{ifi});
                        end

                        switch dg_str_cell{idg}
                            case 'ATTITUDE (41H)'
                                struct_out = read_ATTITUDE_41H(fid,struct_in);
                            case 'DEPTH DATAGRAM (44H)'
                                struct_out = read_DEPTH_DATAGRAM_44H(fid,struct_in);
                            case 'SURFACE SOUND SPEED (47H)'
                                struct_out = read_SURFACE_SOUND_SPEED_47H(fid,struct_in);
                            case {'INSTALLATION PARAMETERS START (49H)' 'INSTALLATION PARAMETERS STOP (69H)'}
                                struct_out = read_INSTALLATION_PARAMETERS(fid,struct_in);
                            case 'RAW RANGE AND ANGLE 78 (4EH)'
                                struct_out = read_RAW_RANGE_AND_ANGLE_78_4EH(fid,struct_in);
                            case 'POSITION (50H)'
                                struct_out = read_POSITION_50H(fid,struct_in);
                            case 'RUNTIME PARAMETERS (52H)'
                                struct_out = read_RUNTIME_PARAMETERS_52H(fid,struct_in);
                            case 'SOUND SPEED PROFILE (55H)'
                                struct_out = read_SOUND_SPEED_PROFILE_55H(fid,struct_in);
                            case 'WATER COLUMN DATAGRAM (6BH)'
                                struct_out = read_WC_dg(fid,struct_in,'WC');
                                struct_out.fname = Filename;
                                struct_out.b_ordering = idx_raw_obj.b_ordering;

                            case 'AMPLITUDE AND PHASE WC DATAGRAM (72H)'
                                struct_out = read_WC_dg(fid,struct_in,'AP');
                                struct_out.fname = Filename;
                                struct_out.b_ordering = idx_raw_obj.b_ordering;

                            otherwise
                                continue;
                        end


                    catch err
                        print_errors_and_warnings([],'warning',sprintf('Could not read datagram %s\n',dg_str_cell{idg}));
                        print_errors_and_warnings([],'warning',err);
                    end

                    valid =  struct_out.ETX(idn)==3&&struct_out.stx(idn)==2;

                    if ~valid
                        continue;
                    end

                    dg_to_read_bool(strcmpi(dg_to_read,dg_str_cell{idg})) = false;
                    EM_data_struct.(dg_str_cell_val{idg}) = struct_out;

                end

                file_read_bool = true;

            end
            save(fileStruct,'EM_data_struct');
        end


        if ~file_read_bool
            dlg_perso([],'Unable to open file',sprintf('Could not open file %s',Filename_cell{uu}));
            continue;
        end

        fields = fieldnames(EM_data_struct);

        idx_wc = find(ismember(fields,matlab.lang.makeValidName(wc_dg_names)) & ~structfun(@isempty,EM_data_struct));

        if isempty(idx_wc)
            dlg_perso([],'No WC datagrams',sprintf('%s does not contains WC datagrams and will not be opened by ESP3 at this time... \nThis is sad.',Filename_cell{uu}));
            continue
        end

        if numel(idx_wc)>1
            idx_wc = idx_wc(2);
        end

        if isfield(EM_data_struct,'SURFACESOUNDSPEED_47H_')&&~isempty(EM_data_struct.SURFACESOUNDSPEED_47H_)
            ss  = mean(cell2mat(EM_data_struct.SURFACESOUNDSPEED_47H_.SoundSpeed'))/10;
            env_data_obj = env_data_cl('SoundSpeed',ss);
        else
            env_data_obj  = env_data_cl();
        end

        if isfield(EM_data_struct,'SOUNDSPEEDPROFILE_55H_')&&~isempty(EM_data_struct.SOUNDSPEEDPROFILE_55H_)
            env_data_obj.SVP.depth = EM_data_struct.SOUNDSPEEDPROFILE_55H_.Depth{1};
            env_data_obj.SVP.soundspeed = EM_data_struct.SOUNDSPEEDPROFILE_55H_.SoundSpeed{1}*0.1;
            env_data_obj.SVP.ori = 'constant';
        end


        dt  = EM_data_struct.(fields{idx_wc}).SamplingFrequency;
        gg = findgroups(dt);

        idx_change = EM_data_struct.(fields{idx_wc}).PingCounter(abs(diff(gg))>0)-EM_data_struct.(fields{idx_wc}).PingCounter(1)+1;


        idg_start = [1 idx_change+1];
        idg_end = [idx_change numel(unique(EM_data_struct.(fields{idx_wc}).PingCounter))];
        t_change = EM_data_struct.(fields{idx_wc}).time(idg_start);

        dt = diff(t_change)*24*60*60;
        if any(dt>60)
            idg_start(dt<60) = [];
            idg_end(dt<60) = [];
        end

        str_disp=sprintf('Extracting WC data for file : %s',Filename_cell{uu});

        if ~isempty(load_bar_comp)
            load_bar_comp.progress_bar.setText(str_disp);
        else
            fprintf('\n%s\n',str_disp);
        end

        switch fields{idx_wc}
            case matlab.lang.makeValidName('AMPLITUDE AND PHASE WC DATAGRAM (72H)')
                dg_type  ='AP';
            case matlab.lang.makeValidName('WATER COLUMN DATAGRAM (6BH)')
                dg_type = 'WC';
        end

        [wc_struct_out,ac_data_obj,sample_offset] = read_WC_or_AP_data(EM_data_struct.(fields{idx_wc}),idg_start,idg_end,p.Results.PathToMemmap,load_bar_comp,dg_type);


        for idg = 1:numel(wc_struct_out)

            st = wc_struct_out{idg}.WC_1P_time(1);
            et = wc_struct_out{idg}.WC_1P_time(end);

            [nb_beams,nb_pings]  = size(wc_struct_out{idg}.WC_BP_BeamPointingAngle);

            if isfield(EM_data_struct,'POSITION_50H_')&&~isempty(EM_data_struct.POSITION_50H_)
                ipings  = find(EM_data_struct.POSITION_50H_.time>=st & EM_data_struct.POSITION_50H_.time<=et);
                if isempty(ipings)
                    gps_data_obj = gps_data_cl;
                else
                    mssg = cellfun(@(x) x(1:5),EM_data_struct.POSITION_50H_.PositionInputDatagramAsReceived(ipings),'un',0);
                    [id,G] = findgroups(mssg);
                    idd = mode(id);

                    gps_data_obj = gps_data_cl(...
                        'Lat',EM_data_struct.POSITION_50H_.Latitude(ipings(id==idd))/20000000,...
                        'Long',EM_data_struct.POSITION_50H_.Longitude(ipings(id==idd))/10000000,...
                        'Time',EM_data_struct.POSITION_50H_.time(ipings(id==idd)),...
                        'Speed',EM_data_struct.POSITION_50H_.SpeedOfVesselOverGround(ipings(id==idd))/100,...
                        'NMEA',G{idd});
                end

            else
                gps_data_obj = gps_data_cl;
            end

            if isfield(EM_data_struct,'ATTITUDE_41H_')&&~isempty(EM_data_struct.ATTITUDE_41H_)

                ipings  = find(EM_data_struct.ATTITUDE_41H_.time>=st & EM_data_struct.ATTITUDE_41H_.time<=et);
                if isempty(ipings)
                    att_nav_obj = attitude_nav_cl();
                else
                    id = EM_data_struct.ATTITUDE_41H_.SensorSystemDescriptor(ipings);
                    idd = mode(id);
                    att_nav_obj =attitude_nav_cl(...
                        'Time',cell2mat(EM_data_struct.ATTITUDE_41H_.time_cell(ipings(id==idd))'),...
                        'Roll',cell2mat(EM_data_struct.ATTITUDE_41H_.Roll(ipings(id==idd))')/100,...
                        'Pitch',cell2mat(EM_data_struct.ATTITUDE_41H_.Pitch(ipings(id==idd))')/100,...
                        'Heave',cell2mat(EM_data_struct.ATTITUDE_41H_.Heave(ipings(id==idd))')/100,...
                        'Heading',cell2mat(EM_data_struct.ATTITUDE_41H_.Heading(ipings(id==idd))')/100 ...
                        );
                end
            else
                if ~isempty(gps_data_obj.Lat)
                    if ~isempty(gps_data_obj)
                        att_nav_obj=att_heading_from_gps(gps_data_obj,2);
                    end
                else
                    att_nav_obj = attitude_nav_cl();
                end
            end


            if isstruct(EM_data_struct.RAWRANGEANDANGLE78_4EH_)
                [~,~,ipings] = intersect(wc_struct_out{idg}.WC_1P_PingCounter,EM_data_struct.RAWRANGEANDANGLE78_4EH_.PingCounter);
                sec_number  = EM_data_struct.RAWRANGEANDANGLE78_4EH_.TransmitSectorNumberTxArrayIndex(ipings);
                alpha = grow_mat(EM_data_struct.RAWRANGEANDANGLE78_4EH_.MeanAbsorptionCoeff(ipings),sec_number,wc_struct_out{idg}.WC_BP_TransmitSectorNumber);
                alpha = alpha/1e5;
                pulse_length = grow_mat(EM_data_struct.RAWRANGEANDANGLE78_4EH_.SignalLength(ipings),sec_number,wc_struct_out{idg}.WC_BP_TransmitSectorNumber);
                freq = grow_mat(EM_data_struct.RAWRANGEANDANGLE78_4EH_.CentreFrequency(ipings),sec_number,wc_struct_out{idg}.WC_BP_TransmitSectorNumber);
            else
                [nb_sec,nb_pings] = size(wc_struct_out{idg}.WC_TP_CenterFrequency);
                freq = grow_mat(mat2cell(wc_struct_out{idg}.WC_TP_CenterFrequency,nb_sec,ones(1,nb_pings)),...
                    mat2cell(wc_struct_out{idg}.WC_TP_TransmitSectorNumber,nb_sec,ones(1,nb_pings)),...
                    wc_struct_out{idg}.WC_BP_TransmitSectorNumber);
                pulse_length= repmat(EM_data_struct.RUNTIMEPARAMETERS_52H_.TransmitPulseLength(1)/1e3,size(freq,1),size(freq,2));%TOFIX
                alpha= repmat(EM_data_struct.RUNTIMEPARAMETERS_52H_.AbsorptionCoefficient(1)/1e5,size(freq,1),size(freq,2));%TOFIX
            end

            config_obj = config_cl();
            config_obj.BeamType = 'single-beam';%single beam (in each of the beams)

            params_obj = params_cl(nb_pings,nb_beams);
            params_obj.BeamAngleAlongship = zeros(size(wc_struct_out{idg}.WC_BP_BeamPointingAngle));
            params_obj.BeamAngleAthwartship = wc_struct_out{idg}.WC_BP_BeamPointingAngle;


            params_obj.SampleInterval=repmat(1./(wc_struct_out{idg}.WC_1P_SamplingFrequencyHz),nb_beams,1);
            params_obj.PulseLength=pulse_length;
            params_obj.TransmitPower=1e3*ones(nb_beams,nb_pings);
            params_obj.Frequency = freq;
            params_obj.FrequencyStart = freq;
            params_obj.FrequencyEnd = freq;

            config_obj.SerialNumber = sprintf('EM%d_%d',EM_data_struct.INSTALLATIONPARAMETERSSTART_49H_.emNumber(1),EM_data_struct.INSTALLATIONPARAMETERSSTART_49H_.systemSerialNumber(1));
            config_obj.ChannelID = sprintf('EM%d_%d_%.0fkHz',EM_data_struct.INSTALLATIONPARAMETERSSTART_49H_.emNumber(1),EM_data_struct.INSTALLATIONPARAMETERSSTART_49H_.systemSerialNumber(1),mean(freq(:)/1e3));
            config_obj.TransceiverName = sprintf('EM%d_%d',EM_data_struct.INSTALLATIONPARAMETERSSTART_49H_.emNumber(1),EM_data_struct.INSTALLATIONPARAMETERSSTART_49H_.systemSerialNumber(1));
            config_obj.TransducerName = sprintf('EM%d_%d',EM_data_struct.INSTALLATIONPARAMETERSSTART_49H_.emNumber(1),EM_data_struct.INSTALLATIONPARAMETERSSTART_49H_.systemSerialNumber(1));
            config_obj.TransceiverType = sprintf('EM%d_%d',EM_data_struct.INSTALLATIONPARAMETERSSTART_49H_.emNumber(1),EM_data_struct.INSTALLATIONPARAMETERSSTART_49H_.systemSerialNumber(1));
            config_obj.ChannelNumber = 1;
            config_obj.TransducerOffsetX = EM_data_struct.INSTALLATIONPARAMETERSSTART_49H_.S1X(1);
            config_obj.TransducerOffsetY = EM_data_struct.INSTALLATIONPARAMETERSSTART_49H_.S1Y(1);
            config_obj.TransducerOffsetZ = EM_data_struct.INSTALLATIONPARAMETERSSTART_49H_.S1Z(1);
            config_obj.TransducerAlphaX = EM_data_struct.INSTALLATIONPARAMETERSSTART_49H_.S1R(1);
            config_obj.TransducerAlphaY = EM_data_struct.INSTALLATIONPARAMETERSSTART_49H_.S1P(1);
            config_obj.TransducerAlphaZ = EM_data_struct.INSTALLATIONPARAMETERSSTART_49H_.S1H(1);

            config_obj.Frequency = mean(freq,2)';
            config_obj.FrequencyMinimum = min(freq,[],2)';
            config_obj.FrequencyMaximum = max(freq,[],2)';
            config_obj.BeamWidthAlongship = mean(EM_data_struct.RUNTIMEPARAMETERS_52H_.TransmitBeamwidth)/10*ones(size(config_obj.Frequency));
            config_obj.BeamWidthAthwartship = mean(EM_data_struct.RUNTIMEPARAMETERS_52H_.ReceiveBeamwidth)/10*ones(size(config_obj.Frequency));
            config_obj.EquivalentBeamAngle = estimate_eba(config_obj.BeamWidthAthwartship,config_obj.BeamWidthAlongship);
            config_obj.Gain = zeros(size(config_obj.Frequency));
            config_obj.SaCorrection = zeros(size(config_obj.Frequency));
            config_obj.PulseLength = mean(pulse_length,2)';

            trans_obj=transceiver_cl('Data',ac_data_obj{idg},...
                'Ping_offset',wc_struct_out{idg}.WC_1P_PingCounter(1),...
                'Sample_offset',sample_offset(idg),...
                'Time',wc_struct_out{idg}.WC_1P_time,...
                'Config',config_obj,...
                'Mode','CW',...
                'Params',params_obj);

            trans_obj.Config.MotionCompBool = [true true true false];

            wc_struct_out{idg}.WC_BP_DetectedRangeInSamples(wc_struct_out{idg}.WC_BP_DetectedRangeInSamples ==1) = nan;
            trans_obj.Bottom = bottom_cl('Origin','Kongsberg Detection','Sample_idx',wc_struct_out{idg}.WC_BP_DetectedRangeInSamples);

            [~,range_t]=trans_obj.compute_soundspeed_and_range(env_data_obj);
            trans_obj.set_transceiver_range(range_t);


            nb_samples = max(trans_obj.Data.Nb_samples);
            bsize=ceil(block_len/nb_samples/nb_beams)*4;
            u=0;

            if ~isempty(p.Results.load_bar_comp)
                p.Results.load_bar_comp.progress_bar.setText('Computing Sv');
                p.Results.load_bar_comp.progress_bar.set('Minimum',0,'Maximum',ceil(nb_pings/bsize),'Value',0);
            end

            %trans_obj.Params=trans_obj.Params.reduce_params();
            trans_obj.set_absorption(repmat(alpha(:,1)',max(ac_data_obj{idg}.Nb_samples),1));
            trans_obj.Config.SounderType = 'Multi-beam';

            while u<ceil(nb_pings/bsize)
                iP=(u*bsize+1):min(((u+1)*bsize),nb_pings);
                u=u+1;
                wc_data = trans_obj.Data.get_subdatamat('idx_ping',iP,'field','wc_data');
                K = (wc_struct_out{idg}.WC_1P_TVGFunctionApplied(iP)-20).*log10(range_t)...
                    +10*log10(wc_struct_out{idg}.WC_1P_SoundSpeed(iP).*shiftdim(pulse_length(:,iP)',-1)/2)...
                    +wc_struct_out{idg}.WC_1P_TVGOffset(iP);
                %           trans_obj.Data.replace_sub_data_v2([],'sp');
                trans_obj.Data.replace_sub_data_v2(wc_data-K,'sv','idx_ping',iP);

                if ~isempty(p.Results.load_bar_comp)
                    p.Results.load_bar_comp.progress_bar.set('Value',u);
                end
            end


            layer_obj=layer_cl('Filename',{EM_data_struct.Filename},...
                'Filetype','EM',...
                'GPSData',gps_data_obj,...
                'AttitudeNav',att_nav_obj,...
                'Transceivers',trans_obj,...
                'EnvData',env_data_obj);
            layers =[layers layer_obj];
        end
   
    catch err
        id_rem=union(id_rem,uu);
        dlg_perso([],'',sprintf('Could not open files %s\n',Filename_cell{uu}));
        print_errors_and_warnings(1,'error',err);

    end
end
end


function struct_out = init_EM_data_struct(dgnames)
struct_out = [];
for uit = 1:numel(dgnames)
    struct_out.(matlab.lang.makeValidName(dgnames{uit}))=[];
end
struct_out.Filename='';
struct_out.EM_struct_version = get_curr_EM_struct_version();
end

function [wc_struct,ac_data_obj,sample_offset] = read_WC_or_AP_data(em_data_struct,idx_ping_start,idx_ping_end,path_f,load_bar_comp,dgtype)
ac_data_obj=cell(1,numel(idx_ping_start));
wc_struct=cell(1,numel(idx_ping_start));
enc = 'US-ASCII';

fid  = fopen(em_data_struct.fname,'r',em_data_struct.b_ordering,enc);
% get the number of heads
headNumber = unique(em_data_struct.systemSerialNumber,'stable');

%[~,curr_filename,~]=fileparts(tempname)

fname = em_data_struct.fname;
[~,curr_filename,~] = fileparts(fname);

curr_data_name_t=fullfile(path_f,curr_filename,'ac_data');

%
% fields = {'sv','wc_data'};
% curr_data_name = cell(1,numel,fields;
%
% fexists = true;
% for ifif=1:numel(fields)
%     curr_data_name{ifif} = sprintf('%s_%s',curr_data_name_t{itr},fields{ifif});
%     fexists = isfile(curr_data_name{ifif})&&fexists;
% end

% get the list of pings and the index of first datagram for
% each ping
if isscalar(headNumber)
    % if only one head...
    [pingCounters, iFirstDatagram] = unique(em_data_struct.PingCounter,'stable');
else
    % in case there's more than one head, we're going to only
    % keep pings for which we have data for all heads

    % pings for first head

    pingCounters = unique(em_data_struct.PingCounter(em_data_struct.systemSerialNumber==headNumber(1)),'stable');

    % for each other head, get ping numbers and only keep
    % intersection
    for iH = 2:length(headNumber)
        pingCountersOtherHead = unique(em_data_struct.PingCounter(em_data_struct.systemSerialNumber==headNumber(iH)),'stable');
        pingCounters = intersect(pingCounters, pingCountersOtherHead,'stable');
    end

    iFirstDatagram  = nan(numel(pingCounters),2);
    % get the index of first datagram for each ping and each
    % head
    for iH = 1:length(headNumber)
        iFirstDatagram(:,iH) = arrayfun(@(x) find(em_data_struct.systemSerialNumber==headNumber(iH) & em_data_struct.PingCounter==x, 1),pingCounters);
    end
end

% test for inconsistencies between heads and raise a warning if
% one is detected
if length(headNumber) > 1
    fields = {'SoundSpeed','SamplingFrequency','TXTimeHeave','TVGFunctionApplied','TVGOffset','ScanningInfo'};
    for iFi = 1:length(fields)
        if any(any(em_data_struct.(fields{iFi})(iFirstDatagram(:,1))'.*ones(1,length(headNumber))~=em_data_struct.(fields{iFi})(iFirstDatagram)))
            warning('System has more than one head and "%s" data are inconsistent between heads for at least one ping. Using information from first head anyway.',fields{iFi});
        end
    end
end

sample_offset  = nan(1,numel(idx_ping_start));

for uip =1:numel(idx_ping_start)

    idx_pings_g  = idx_ping_start(uip):idx_ping_end(uip);
    idx_pings_g(idx_pings_g>numel(pingCounters)) = [];

    % save ping numbers
    wc_struct{uip}.WC_1P_PingCounter = pingCounters(idx_pings_g);

    % for the following fields, take value from first datagram in
    % first head
    wc_struct{uip}.WC_1P_time                            = em_data_struct.time(iFirstDatagram(idx_pings_g,1));
    wc_struct{uip}.WC_1P_SoundSpeed                      = em_data_struct.SoundSpeed(iFirstDatagram(idx_pings_g,1))*0.1;
    wc_struct{uip}.WC_1P_SamplingFrequencyHz             = em_data_struct.SamplingFrequency(iFirstDatagram(idx_pings_g,1)).*0.01; % in Hz
    wc_struct{uip}.WC_1P_TXTimeHeave                     = em_data_struct.TXTimeHeave(iFirstDatagram(idx_pings_g,1));
    wc_struct{uip}.WC_1P_TVGFunctionApplied              = em_data_struct.TVGFunctionApplied(iFirstDatagram(idx_pings_g,1));
    wc_struct{uip}.WC_1P_TVGOffset                       = em_data_struct.TVGOffset(iFirstDatagram(idx_pings_g,1));
    wc_struct{uip}.WC_1P_ScanningInfo                    = em_data_struct.ScanningInfo(iFirstDatagram(idx_pings_g,1));

    % for the other fields, sum the numbers from heads
    if length(headNumber) > 1
        wc_struct{uip}.WC_1P_NumberOfDatagrams         = sum(em_data_struct.NumberOfDatagrams(iFirstDatagram(idx_pings_g,:)),2)';
        wc_struct{uip}.WC_1P_NumberOfTransmitSectors   = sum(em_data_struct.NumberOfTransmitSectors(iFirstDatagram(idx_pings_g,:)),2)';
        wc_struct{uip}.WC_1P_NumberOfBeams       = sum(em_data_struct.TotalNumberOfReceiveBeams(iFirstDatagram(idx_pings_g,:)),2)'; % each head is decimated in beam individually
    else
        wc_struct{uip}.WC_1P_NumberOfDatagrams         = em_data_struct.NumberOfDatagrams(iFirstDatagram(idx_pings_g));
        wc_struct{uip}.WC_1P_NumberOfTransmitSectors   = em_data_struct.NumberOfTransmitSectors(iFirstDatagram(idx_pings_g));
        wc_struct{uip}.WC_1P_NumberOfBeams       = ceil(em_data_struct.TotalNumberOfReceiveBeams(iFirstDatagram(idx_pings_g)));
    end

    % get original data dimensions
    nPings = length(pingCounters(idx_pings_g)); % total number of pings in file
    maxNTransmitSectors = max(wc_struct{uip}.WC_1P_NumberOfTransmitSectors); % maximum number of transmit sectors in a ping

    % get dimensions of data to red after decimation
    nb_beams = max(wc_struct{uip}.WC_1P_NumberOfBeams); % maximum number of receive beams TO READ

    idgp = find(ismember(em_data_struct.PingCounter,pingCounters(idx_pings_g)));
    [~,~,subs]  = unique(em_data_struct.PingCounter(idgp));

    nb_samples_per_pings  = accumarray(subs,cellfun(@(x,y) max(x+y,[],2,'omitnan'),em_data_struct.NumberOfSamples(idgp),em_data_struct.StartRangeSampleNumber(idgp)),[],@max);
    start_sample_min_per_pings  = accumarray(subs,cellfun(@(x) min(x,[],2,'omitnan'),em_data_struct.StartRangeSampleNumber(idgp)),[],@max);

    sample_offset(uip) = min(start_sample_min_per_pings,[],1);
    nb_samples_per_pings = nb_samples_per_pings' - sample_offset(uip)+1;


    [nb_samples_group,~,id_end,block_id]=group_pings_per_samples(nb_samples_per_pings,idx_pings_g);



    ac_data_obj{uip} = ac_data_cl('SubData',[],...
        'Nb_samples', nb_samples_group,...
        'Nb_pings',   nPings,...
        'Nb_beams',nb_beams*ones(size(nb_samples_group)),...
        'BlockId' , block_id,...
        'MemapName',  sprintf('%s_%d',curr_data_name_t,idx_pings_g(1)));


    % initialize data per transmit sector and ping
    wc_struct{uip}.WC_TP_TiltAngle            = nan(maxNTransmitSectors,nPings);
    wc_struct{uip}.WC_TP_CenterFrequency      = nan(maxNTransmitSectors,nPings);
    wc_struct{uip}.WC_TP_TransmitSectorNumber = nan(maxNTransmitSectors,nPings);
    wc_struct{uip}.WC_TP_systemSerialNumber   = nan(maxNTransmitSectors,nPings);


    % initialize data per decimated beam and ping
    wc_struct{uip}.WC_BP_BeamPointingAngle      = nan(nb_beams,nPings);
    wc_struct{uip}.WC_BP_StartRangeSampleNumber = nan(nb_beams,nPings);
    wc_struct{uip}.WC_BP_NumberOfSamples        = nan(nb_beams,nPings);
    wc_struct{uip}.WC_BP_DetectedRangeInSamples = zeros(nb_beams,nPings);
    wc_struct{uip}.WC_BP_TransmitSectorNumber   = nan(nb_beams,nPings);
    wc_struct{uip}.WC_BP_BeamNumber             = nan(nb_beams,nPings);
    wc_struct{uip}.WC_BP_systemSerialNumber     = nan(nb_beams,nPings);


    switch dgtype
        case 'AP'
            prec  ='int16';
            fmt = 'single';sc = 'db';cf = 1;
        case 'WC'
            prec  ='int8';
            fmt = 'int8';sc = 'db';cf = 1/2;
    end

    % initialize ping group counter
    iG = 1;
    if ~isempty(load_bar_comp)
        set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nPings,'Value',0);
    end
    % now get data for each ping
    subIP = 0;

    for iP = idx_pings_g

        subIP  =subIP+1;
        if ~isempty(load_bar_comp)
            set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nPings,'Value',subIP);
        end

        pingCounter = wc_struct{uip}.WC_1P_PingCounter(1,subIP);

        if subIP > id_end(iG)
            iG = iG+1;
        end

        switch dgtype
            case 'AP'
                Ph_temp = zeros(nb_samples_group(iG),nb_beams,'int16');
        end

        SB_temp = intmin(prec)*ones(nb_samples_group(iG),nb_beams,prec);

        % initialize number of sectors and beams recorded so far for
        % that ping (needed for multiple heads)
        nTxSectTot = 0;
        nBeamTot = 0;
        
        for iH = 1:length(headNumber)

            headSSN = headNumber(iH);

            iDatagrams  = find( em_data_struct.PingCounter == pingCounter & ...
                em_data_struct.systemSerialNumber == headSSN);

            % actual number of datagrams available (ex: 4)
            nDatagrams  = length(iDatagrams);

            % some datagrams may be missing. Need to detect and adjust.
            datagramOrder     = em_data_struct.DatagramNumbers(iDatagrams); % order of the datagrams (ex: 4-3-6-2, the missing one is 1st, 5th and 7th)
            [~,IX]            = sort(datagramOrder);
            iDatagrams        = iDatagrams(IX); % index of the datagrams making up this ping in em_data_struct, but in the right order (ex: 64-59-58-61, missing datagrams are still missing)
            nBeamsPerDatagram = em_data_struct.NumberOfBeamsInThisDatagram(iDatagrams); % number of beams in each datagram making up this ping (ex: 56-61-53-28)

            % number of transmit sectors to record
            nTxSect = em_data_struct.NumberOfTransmitSectors(iDatagrams(1));

            % indices of those sectors in output structure
            iTxSectDest = nTxSectTot + (1:nTxSect);

            % recording data per transmit sector
            wc_struct{uip}.WC_TP_TiltAngle(iTxSectDest,subIP)            = em_data_struct.TiltAngle{iDatagrams(1)};
            wc_struct{uip}.WC_TP_CenterFrequency(iTxSectDest,subIP)      = em_data_struct.CenterFrequency{iDatagrams(1)};
            wc_struct{uip}.WC_TP_TransmitSectorNumber(iTxSectDest,subIP) = em_data_struct.TransmitSectorNumber{iDatagrams(1)};
            wc_struct{uip}.WC_TP_systemSerialNumber(iTxSectDest,subIP)   = headSSN;

            % updating total number of sectors recorded so far
            nTxSectTot = nTxSectTot + nTxSect;

            % and then read the data in each datagram
            for iD = 1:nDatagrams

                % indices of desired beams in this head/datagram
                if iD == 1
                    % if first datagram, start with first beam
                    iBeamStart = 1;
                else
                    % if not first datagram, continue the
                    % decimation where we left it
                    nBeamsLastDatag = nBeamsPerDatagram(iD-1);
                    lastRecBeam  = iBeamSource(end);
                    iBeamStart = 1 - (nBeamsLastDatag-lastRecBeam);
                end

                % select beams with decimation
                iBeamSource = iBeamStart:nBeamsPerDatagram(iD);

                % number of beams to record
                nBeam = length(iBeamSource);

                % indices of those beams in output structure
                iBeamDest = nBeamTot + (1:nBeam);

                % record those beams data, applying decimation in
                % range to the data that are samples numbers.
                wc_struct{uip}.WC_BP_BeamPointingAngle(iBeamDest,subIP)      = em_data_struct.BeamPointingAngle{iDatagrams(iD)}(iBeamSource)/100;
                wc_struct{uip}.WC_BP_StartRangeSampleNumber(iBeamDest,subIP) = em_data_struct.StartRangeSampleNumber{iDatagrams(iD)}(iBeamSource);
                wc_struct{uip}.WC_BP_NumberOfSamples(iBeamDest,subIP)        = em_data_struct.NumberOfSamples{iDatagrams(iD)}(iBeamSource);
                wc_struct{uip}.WC_BP_DetectedRangeInSamples(iBeamDest,subIP) = em_data_struct.DetectedRangeInSamples{iDatagrams(iD)}(iBeamSource)-em_data_struct.StartRangeSampleNumber{iDatagrams(iD)}(iBeamSource)+1;
                wc_struct{uip}.WC_BP_TransmitSectorNumber(iBeamDest,subIP)   = em_data_struct.TransmitSectorNumber2{iDatagrams(iD)}(iBeamSource);
                wc_struct{uip}.WC_BP_BeamNumber(iBeamDest,subIP)             = em_data_struct.BeamNumber{iDatagrams(iD)}(iBeamSource);
                wc_struct{uip}.WC_BP_systemSerialNumber(iBeamDest,subIP)     = headSSN;

                % and then, in each beam...
                for iB = 1:nBeam
                    nSamp = em_data_struct.NumberOfSamples{iDatagrams(iD)}(iBeamSource(iB));
                    samp_start = 1;


                    switch dgtype
                        case 'AP'
                            pos = em_data_struct.SampleWCPosition{iDatagrams(iD)}(iBeamSource(iB));
                            fseek(fid,pos,'bof');

                            % read amplitude data
                            tmp = fread(fid,nSamp,'uint16',2);
                            %nSamp  =min(nSamp,numel(tmp));

                            % transform amplitude data
                            SB_temp(samp_start+(0:(nSamp-1)),iBeamDest(iB)) = 20*log10(single(tmp)*0.0001);

                            % get to the start of phase data
                            pos = pos+2;

                            fseek(fid,pos,'bof');

                            % read phase data
                            tmp = fread(fid,nSamp,'int16',2);
                            %nSamp  =min(nSamp,numel(tmp));
                            % transform phase data
                            Ph_temp((1:nSamp),iBeamDest(iB)) = (-0.0001*single(tmp)/pi*180);

                        case 'WC'
                            % get to the start of the data in original file
                            pos = em_data_struct.SampleWCPosition{iDatagrams(iD)}(iBeamSource(iB));

                            fseek(fid,pos,'bof');

                            % read raw data, with decimation in range
                            SB_temp(samp_start+(0:(nSamp-1)),iBeamDest(iB)) = fread(fid, nSamp, 'int8')/2;

                    end

                end

                % updating total number of beams recorded so far
                nBeamTot = nBeamTot + nBeam;

            end

        end

        ac_data_obj{uip}.replace_sub_data_v2(permute(SB_temp,[1 3 2]),'wc_data','idx_ping',subIP,...
            'Fmt',fmt,...
            'ConvFactor',cf,...
            'Scale',sc,...
            'idx_r',1:size(SB_temp,1),...
            'idx_beam',1:size(SB_temp,2));

        switch dgtype
            case 'AP'
                ac_data_obj{uip}.replace_sub_data_v2(permute(Ph_temp,[1 3 2]),'acrossphi','idx_ping',subIP,...
                    'idx_r',1:size(Ph_temp,1),...
                    'idx_beam',1:size(Ph_temp,2));
        end

    end
end

fclose(fid);

end


function struct_out = read_ATTITUDE_41H(fid,struct_in)
idn = numel(struct_in.stx); struct_out = struct_in;
struct_out.AttitudeCounter(idn) = struct_in.number(idn);
struct_out.NumberOfEntries(idn)                      = fread(fid,1,'uint16');
N = struct_out.NumberOfEntries(idn);
temp = ftell(fid);
T = fread(fid,N,'uint16',12-2);
struct_out.time_cell{idn} =  T/(24*60*60*1e3)+struct_out.time(idn);
fseek(fid,temp+2,'bof');
struct_out.SensorStatus{idn}                       = fread(fid,N,'uint16',12-2);
fseek(fid,temp+4,'bof');
struct_out.Roll{idn}                               = fread(fid,N,'int16',12-2);
fseek(fid,temp+6,'bof');
struct_out.Pitch{idn}                              = fread(fid,N,'int16',12-2);
fseek(fid,temp+8,'bof');
struct_out.Heave{idn}                              = fread(fid,N,'int16',12-2);
fseek(fid,temp+10,'bof');
struct_out.Heading{idn}                            = fread(fid,N,'uint16',12-2);
fseek(fid,2-12,'cof');

struct_out.SensorSystemDescriptor(idn)                 = fread(fid,1,'uint8');
struct_out.ETX(idn)                                    = fread(fid,1,'uint8');
struct_out.CheckSum(idn)                              = fread(fid,1,'uint16');
end

function struct_out = read_DEPTH_DATAGRAM_44H(fid,struct_in)
idn = numel(struct_in.stx);struct_out = struct_in;
struct_out.PingCounter(idn) = struct_in.number(idn);

struct_out.HeadingOfVessel(idn)                  = fread(fid,1,'uint16');
struct_out.SoundSpeedAtTransducer(idn)           = fread(fid,1,'uint16');
struct_out.TransmitTransducerDepth(idn)          = fread(fid,1,'uint16');
struct_out.MaximumNumberOfBeamsPossible(idn)     = fread(fid,1,'uint8');
struct_out.NumberOfValidBeams(idn)               = fread(fid,1,'uint8'); %N
struct_out.ZResolution(idn)                      = fread(fid,1,'uint8');
struct_out.XAndYResolution(idn)                  = fread(fid,1,'uint8');
struct_out.SamplingRate(idn)                     = fread(fid,1,'uint16'); % OR: struct_out.DepthDifferenceBetweenSonarHeadsInTheEM3000D= fread(fid,1,'int16');

% repeat cycle: N entries of 16 bits
temp = ftell(fid);
N = struct_out.NumberOfValidBeams(idn);
struct_out.DepthZ{idn}                        = fread(fid,N,'int16',16-2); % OR 'uint16' for EM120 and EM300
fseek(fid,temp+2,'bof');
struct_out.AcrosstrackDistanceY{idn}          = fread(fid,N,'int16',16-2);
fseek(fid,temp+4,'bof');
struct_out.AlongtrackDistanceX{idn}           = fread(fid,N,'int16',16-2);
fseek(fid,temp+6,'bof');
struct_out.BeamDepressionAngle{idn}           = fread(fid,N,'int16',16-2);
fseek(fid,temp+8,'bof');
struct_out.BeamAzimuthAngle{idn}              = fread(fid,N,'uint16',16-2);
fseek(fid,temp+10,'bof');
struct_out.Range{idn}                         = fread(fid,N,'uint16',16-2);
fseek(fid,temp+12,'bof');
struct_out.QualityFactor{idn}                 = fread(fid,N,'uint8',16-1);
fseek(fid,temp+13,'bof');
struct_out.LengthOfDetectionWindow{idn}       = fread(fid,N,'uint8',16-1);
fseek(fid,temp+14,'bof');
struct_out.ReflectivityBS{idn}                = fread(fid,N,'int8',16-1);
fseek(fid,temp+15,'bof');
struct_out.BeamNumber{idn}                    = fread(fid,N,'uint8',16-1);
fseek(fid,1-16,'cof'); % we need to come back after last jump

struct_out.TransducerDepthOffsetMultiplier(idn)= fread(fid,1,'int8');
struct_out.ETX(idn)                            = fread(fid,1,'uint8');
struct_out.CheckSum(idn)                       = fread(fid,1,'uint16');
end


function struct_out = read_SURFACE_SOUND_SPEED_47H(fid,struct_in)
idn = numel(struct_in.stx);struct_out = struct_in;
struct_out.SoundSpeedCounter(idn) = struct_in.number(idn);
struct_out.NumberOfEntries(idn)                   = fread(fid,1,'uint16'); %N

% repeat cycle: N entries of 4 bits
temp = ftell(fid);
N =  struct_out.NumberOfEntries(idn);
struct_out.TimeInSecondsSinceRecordStart{idn} = fread(fid,N,'uint16',4-2);
fseek(fid,temp+2,'bof');
struct_out.SoundSpeed{idn}                    = fread(fid,N,'uint16',4-2);
fseek(fid,2-4,'cof'); % we need to come back after last jump

struct_out.Spare(idn)                             = fread(fid,1,'uint8');
struct_out.ETX(idn)                               = fread(fid,1,'uint8');
struct_out.CheckSum(idn)                          = fread(fid,1,'uint16');

end

function struct_out = read_INSTALLATION_PARAMETERS(fid,struct_in)
idn = numel(struct_in.stx);
struct_out = struct_in;
struct_out.SurveyLineNumber(idn) = struct_in.number(idn);
struct_out.SerialNumberOfSecondSonarHead(idn)   = fread(fid,1,'uint16');


str_tmp                                         = fscanf(fid, '%c', struct_in.dgSize(idn)-21);
str_tmp_cell = strsplit(str_tmp,',');
for uip = 1:numel(str_tmp_cell)
    str_info = strsplit(str_tmp_cell{uip},'=');
    if numel(str_info)==2
        val = str2double(str_info{2});
        if~isnan(val)
            struct_out.(str_info{1})(idn) = val;
        else
            struct_out.(str_info{1}){idn} = str_info{2};
        end
    end
end

struct_out.ETX(idn)                             = fread(fid,1,'uint8');
struct_out.CheckSum(idn)                        = fread(fid,1,'uint16');



end

function struct_out = read_RAW_RANGE_AND_ANGLE_78_4EH(fid,struct_in)
idn = numel(struct_in.stx);struct_out = struct_in;
struct_out.PingCounter(idn) = struct_in.number(idn);

struct_out.SoundSpeedAtTransducer(idn)           = fread(fid,1,'uint16');
struct_out.NumberOfTransmitSectors(idn)          = fread(fid,1,'uint16'); %Ntx
struct_out.NumberOfReceiverBeamsInDatagram(idn)  = fread(fid,1,'uint16'); %Nrx
struct_out.NumberOfValidDetections(idn)          = fread(fid,1,'uint16');
struct_out.SamplingFrequencyInHz(idn)            = fread(fid,1,'float32');
struct_out.Dscale(idn)                           = fread(fid,1,'uint32');

% repeat cycle #1: Ntx entries of 24 bits
temp = ftell(fid);
C = 24;
Ntx = struct_out.NumberOfTransmitSectors(idn);
struct_out.TiltAngle{idn}                    = fread(fid,Ntx,'int16',C-2);
fseek(fid,temp+2,'bof');
struct_out.FocusRange{idn}                   = fread(fid,Ntx,'uint16',C-2);
fseek(fid,temp+4,'bof');
struct_out.SignalLength{idn}                 = fread(fid,Ntx,'float32',C-4);
fseek(fid,temp+8,'bof');
struct_out.SectorTransmitDelay{idn}          = fread(fid,Ntx,'float32',C-4);
fseek(fid,temp+12,'bof');
struct_out.CentreFrequency{idn}              = fread(fid,Ntx,'float32',C-4);
fseek(fid,temp+16,'bof');
struct_out.MeanAbsorptionCoeff{idn}          = fread(fid,Ntx,'uint16',C-2);
fseek(fid,temp+18,'bof');
struct_out.SignalWaveformIdentifier{idn}     = fread(fid,Ntx,'uint8',C-1);
fseek(fid,temp+19,'bof');
struct_out.TransmitSectorNumberTxArrayIndex{idn}= fread(fid,Ntx,'uint8',C-1);
fseek(fid,temp+20,'bof');
struct_out.SignalBandwidth{idn}              = fread(fid,Ntx,'float32',C-4);
fseek(fid,4-C,'cof');

% repeat cycle #2: Nrx entries of 16 bits
temp = ftell(fid);
C = 16;
Nrx = struct_out.NumberOfReceiverBeamsInDatagram(idn);
struct_out.BeamPointingAngle{idn}            = fread(fid,Nrx,'int16',C-2);
fseek(fid,temp+2,'bof');
struct_out.TransmitSectorNumber{idn}         = fread(fid,Nrx,'uint8',C-1);
fseek(fid,temp+3,'bof');
struct_out.DetectionInfo{idn}                = fread(fid,Nrx,'uint8',C-1);
fseek(fid,temp+4,'bof');
struct_out.DetectionWindowLength{idn}        = fread(fid,Nrx,'uint16',C-2);
fseek(fid,temp+6,'bof');
struct_out.QualityFactor{idn}                = fread(fid,Nrx,'uint8',C-1);
fseek(fid,temp+7,'bof');
struct_out.Dcorr{idn}                       = fread(fid,Nrx,'int8',C-1);
fseek(fid,temp+8,'bof');
struct_out.TwoWayTravelTime{idn}             = fread(fid,Nrx,'float32',C-4);
fseek(fid,temp+12,'bof');
struct_out.ReflectivityBS{idn}               = fread(fid,Nrx,'int16',C-2);
fseek(fid,temp+14,'bof');
struct_out.RealTimeCleaningInfo{idn}         = fread(fid,Nrx,'int8',C-1);
fseek(fid,temp+15,'bof');
struct_out.Spare{idn}                        = fread(fid,Nrx,'uint8',C-1);
fseek(fid,1-C,'cof');

struct_out.Spare2(idn)                           = fread(fid,1,'uint8');
struct_out.ETX(idn)                              = fread(fid,1,'uint8');
struct_out.CheckSum(idn)                         = fread(fid,1,'uint16');

end

function struct_out = read_POSITION_50H(fid,struct_in)
idn = numel(struct_in.stx);struct_out = struct_in;
struct_out.PositionCounter(idn) = struct_in.number(idn);
struct_out.Latitude(idn)                        = fread(fid,1,'int32');
struct_out.Longitude(idn)                       = fread(fid,1,'int32');
struct_out.MeasureOfPositionFixQuality(idn)     = fread(fid,1,'uint16');
struct_out.SpeedOfVesselOverGround(idn)         = fread(fid,1,'uint16');
struct_out.CourseOfVesselOverGround(idn)        = fread(fid,1,'uint16');
struct_out.HeadingOfVessel(idn)                 = fread(fid,1,'uint16');
struct_out.PositionSystemDescriptor(idn)        = fread(fid,1,'uint8');
struct_out.NumberOfBytesInInputDatagram(idn)    = fread(fid,1,'uint8');
struct_out.PositionInputDatagramAsReceived{idn} = fscanf(fid, '%c', struct_in.dgSize(idn) -37);

struct_out.ETX(idn)                             = fread(fid,1,'uint8');
struct_out.CheckSum(idn)                        = fread(fid,1,'uint16');
end

function struct_out = read_RUNTIME_PARAMETERS_52H(fid,struct_in)
idn = numel(struct_in.stx);struct_out = struct_in;
struct_out.PingCounter(idn) = struct_in.number(idn);
struct_out.OperatorStationStatus(idn)                   = fread(fid,1,'uint8');
struct_out.ProcessingUnitStatus(idn)                    = fread(fid,1,'uint8');
struct_out.BSPStatus(idn)                               = fread(fid,1,'uint8');
struct_out.SonarHeadStatus(idn)                         = fread(fid,1,'uint8');
struct_out.Mode(idn)                                    = fread(fid,1,'uint8');
struct_out.FilterIdentifier(idn)                        = fread(fid,1,'uint8');
struct_out.MinimumDepth(idn)                            = fread(fid,1,'uint16');
struct_out.MaximumDepth (idn)                           = fread(fid,1,'uint16');
struct_out.AbsorptionCoefficient(idn)                   = fread(fid,1,'uint16');
struct_out.TransmitPulseLength(idn)                     = fread(fid,1,'uint16');
struct_out.TransmitBeamwidth(idn)                       = fread(fid,1,'uint16');
struct_out.TransmitPowerReMaximum(idn)                 = fread(fid,1,'int8');
struct_out.ReceiveBeamwidth(idn)                        = fread(fid,1,'uint8');
struct_out.ReceiveBandwidth(idn)                        = fread(fid,1,'uint8');
struct_out.ReceiverFixedGainSetting(idn)                = fread(fid,1,'uint8'); % OR mode 2
struct_out.TVGLawCrossoverAngle(idn)                    = fread(fid,1,'uint8');
struct_out.SourceOfSoundSpeedAtTransducer(idn)          = fread(fid,1,'uint8');
struct_out.MaximumPortSwathWidth(idn)                   = fread(fid,1,'uint16');
struct_out.BeamSpacing(idn)                             = fread(fid,1,'uint8');
struct_out.MaximumPortCoverage(idn)                     = fread(fid,1,'uint8');
struct_out.YawAndPitchStabilizationMode(idn)            = fread(fid,1,'uint8');
struct_out.MaximumStarboardCoverage(idn)                = fread(fid,1,'uint8');
struct_out.MaximumStarboardSwathWidth(idn)              = fread(fid,1,'uint16');
struct_out.DurotongSpeed(idn)                           = fread(fid,1,'uint16'); % OR: struct_out.TransmitAlongTilt = fread(fid,1,'int16');
struct_out.HiLoFrequencyAbsorptionCoefficientRatio(idn) = fread(fid,1,'uint8'); % OR filter identifier 2
struct_out.ETX(idn)                                     = fread(fid,1,'uint8');
struct_out.CheckSum(idn)                                = fread(fid,1,'uint16');

end

function struct_out = read_SOUND_SPEED_PROFILE_55H(fid,struct_in)
idn = numel(struct_in.stx);struct_out = struct_in;
struct_out.ProfileCounter(idn) = struct_in.number(idn);

struct_out.DateWhenProfileWasMade(idn)                           = fread(fid,1,'uint32');
struct_out.TimeSinceMidnightInMillisecondsWhenProfileWasMade(idn)= fread(fid,1,'uint32');
struct_out.NumberOfEntries(idn)                                  = fread(fid,1,'uint16'); %N
struct_out.DepthResolution(idn)                                  = fread(fid,1,'uint16');

temp = ftell(fid);
N = struct_out.NumberOfEntries(idn);
struct_out.Depth{idn}                                        = fread(fid,N,'uint32',8-4);
fseek(fid,temp+4,'bof');
struct_out.SoundSpeed{idn}                                   = fread(fid,N,'uint32',8-4);
fseek(fid,4-8,'cof');

struct_out.SpareByte(idn)                                        = fread(fid,1,'uint8');
struct_out.ETX(idn)                                              = fread(fid,1,'uint8');
struct_out.CheckSum(idn)                                         = fread(fid,1,'uint16');

end

function struct_out = read_XYZ_88_58H(fid,struct_in)
idn = numel(struct_in.stx);struct_out = struct_in;
struct_out.PingCounter(idn) = struct_in.number(idn);
struct_out.NumberOfBytesInDatagram(idn)           = struct_in.dgSize(idn) ;

struct_out.HeadingOfVessel(idn)                   = fread(fid,1,'uint16');
struct_out.SoundSpeedAtTransducer(idn)            = fread(fid,1,'uint16');
struct_out.TransmitTransducerDepth(idn)           = fread(fid,1,'float32');
struct_out.NumberOfBeamsInDatagram(idn)           = fread(fid,1,'uint16');
struct_out.NumberOfValidDetections(idn)           = fread(fid,1,'uint16');
struct_out.SamplingFrequencyInHz(idn)             = fread(fid,1,'float32');
struct_out.ScanningInfo(idn)                      = fread(fid,1,'uint8');
struct_out.Spare1(idn)                            = fread(fid,1,'uint8');
struct_out.Spare2(idn)                            = fread(fid,1,'uint8');
struct_out.Spare3(idn)                            = fread(fid,1,'uint8');

% repeat cycle: N entries of 20 bits
temp = ftell(fid);
C = 20;
N = struct_out.NumberOfBeamsInDatagram{idn};
struct_out.DepthZ{idn}                       = fread(fid,N,'float32',C-4);
fseek(fid,temp+4,'bof');
struct_out.AcrosstrackDistanceY{idn}         = fread(fid,N,'float32',C-4);
fseek(fid,temp+8,'bof');
struct_out.AlongtrackDistanceX{idn}          = fread(fid,N,'float32',C-4);
fseek(fid,temp+12,'bof');
struct_out.DetectionWindowLength{idn}        = fread(fid,N,'uint16',C-2);
fseek(fid,temp+14,'bof');
struct_out.QualityFactor{idn}                = fread(fid,N,'uint8',C-1);
fseek(fid,temp+15,'bof');
struct_out.BeamIncidenceAngleAdjustment{idn} = fread(fid,N,'int8',C-1);
fseek(fid,temp+16,'bof');
struct_out.DetectionInformation{idn}         = fread(fid,N,'uint8',C-1);
fseek(fid,temp+17,'bof');
struct_out.RealTimeCleaningInformation{idn}  = fread(fid,N,'int8',C-1);
fseek(fid,temp+18,'bof');
struct_out.ReflectivityBS{idn}               = fread(fid,N,'int16',C-2);
fseek(fid,2-C,'cof'); % we need to come back after last jump

struct_out.Spare4(idn)                            = fread(fid,1,'uint8');
struct_out.ETX(idn)                               = fread(fid,1,'uint8');
struct_out.CheckSum(idn)                          = fread(fid,1,'uint16');
end



function struct_out = read_WC_dg(fid,struct_in,dgtype)
idn = numel(struct_in.stx);struct_out = struct_in;
struct_out.PingCounter(idn) = struct_in.number(idn);

struct_out.NumberOfBytesInDatagram(idn) = struct_in.dgSize(idn);
% position at start of datagram
pos_1 = ftell(fid);

struct_out.NumberOfDatagrams(idn)                 = fread(fid,1,'uint16');
struct_out.DatagramNumbers(idn)                   = fread(fid,1,'uint16');
struct_out.NumberOfTransmitSectors(idn)           = fread(fid,1,'uint16'); %Ntx
struct_out.TotalNumberOfReceiveBeams(idn)         = fread(fid,1,'uint16');
struct_out.NumberOfBeamsInThisDatagram(idn)       = fread(fid,1,'uint16'); %Nrx
struct_out.SoundSpeed(idn)                        = fread(fid,1,'uint16'); %SS
struct_out.SamplingFrequency(idn)                 = fread(fid,1,'uint32'); %SF

struct_out.TXTimeHeave(idn)                       = fread(fid,1,'int16');
struct_out.TVGFunctionApplied(idn)                = fread(fid,1,'uint8'); %X
struct_out.TVGOffset(idn)                         = fread(fid,1,'uint8'); %C
struct_out.ScanningInfo(idn)                      = fread(fid,1,'uint8');
struct_out.Spare1(idn)                            = fread(fid,1,'uint8');
struct_out.Spare2(idn)                            = fread(fid,1,'uint8');
struct_out.Spare3(idn)                            = fread(fid,1,'uint8');

C = 6;
Ntx = struct_out.NumberOfTransmitSectors(idn);
tmp_data = fread(fid,C*Ntx,'int8=>int8');
tt = [tmp_data(1:6:end) tmp_data(2:6:end)]';
struct_out.TiltAngle{idn}                   = typecast(tt(:) ,'int16');
tt = [tmp_data(3:6:end) tmp_data(4:6:end)]';
struct_out.CenterFrequency{idn}             = typecast(tt(:),'uint16');
struct_out.TransmitSectorNumber{idn}        = tmp_data(5:6:end);
struct_out.Spare{idn}                       = tmp_data(6:6:end);

% repeat cycle #2: Nrx entries of a possibly variable number of
% bits. Reading everything first and using a for loop to parse
% the data in it
Nrx = struct_out.NumberOfBeamsInThisDatagram(idn);

pos_init = ftell(fid); % position at start of data
id = 0; % offset for start of each Nrx block
wc_parsing_error = 0; % initialize flag

% initialize outputs
struct_out.BeamPointingAngle{idn}          = nan(1,Nrx);
struct_out.StartRangeSampleNumber{idn}      = nan(1,Nrx);
struct_out.NumberOfSamples{idn}             = nan(1,Nrx);
struct_out.DetectedRangeInSamples{idn}      = nan(1,Nrx);
struct_out.TransmitSectorNumber2{idn}       = nan(1,Nrx);
struct_out.BeamNumber{idn}                  = nan(1,Nrx);
struct_out.SampleWCPosition{idn} = nan(1,Nrx);
Ns = zeros(1,Nrx);

switch dgtype
    case 'AP'
        mult = 4;
    case 'WC'
        mult = 1;
end

for jj = 1:Nrx

    try
        struct_out.BeamPointingAngle{idn}(jj)       = fread(fid,1,'int16');
        ttt = fread(fid,3,'uint16');
        struct_out.StartRangeSampleNumber{idn}(jj)  = ttt(1);
        struct_out.NumberOfSamples{idn}(jj)         = ttt(2);
        struct_out.DetectedRangeInSamples{idn}(jj)  = ttt(3);
        struct_out.TransmitSectorNumber2{idn}(jj)   = fread(fid,1,'uint8');
        struct_out.BeamNumber{idn}(jj)          	 = fread(fid,1,'uint8');
        struct_out.SampleWCPosition{idn}(jj) = pos_init + id + 10;

        if struct_out.NumberOfSamples{idn}(jj) < 2^16/2
            Ns(jj) = struct_out.NumberOfSamples{idn}(jj);
        else
            struct_out.NumberOfSamples{idn}(jj) = 0;
            Ns(jj) = 0;
        end

        % offset to next jj block
        id = 10*jj + mult*sum(Ns);
        fseek(fid,mult*Ns(jj),'cof');


    catch

        % issue in the recording, flag and exit the loop
        struct_out.NumberOfSamples{idn}(jj) = 0;
        Ns(jj) = 0;
        wc_parsing_error = 1;
        struct_out.ETX(idn) = 1;
        struct_out.CheckSum(idn) = 0;
        continue;

    end

end
pos_end = ftell(fid);

tmp_end = fread(fid,struct_in.dgSize(idn) -(pos_end-pos_1+1)-15,'int8=>int8');

if numel(tmp_end)<=3
    struct_out.ETX(idn)  = 0;
    struct_out.CheckSum(idn) = 0;
    wc_parsing_error = 1;
end

if wc_parsing_error == 0
    % HERE if data parsing all went well
    us = 0;
    % "spare byte if required to get even length (always 0 if used)"
    if floor((Nrx*10+mult*sum(Ns))/2) == (Nrx*10+mult*sum(Ns))/2
        % even so far, since ETX is 1 byte, add a spare here
        struct_out.Spare4(idn) = double(typecast(tmp_end(1),'uint8'));
        us = us+1;
    else
        % odd so far, since ETX is 1 bytes, no spare
        struct_out.Spare4(idn) = NaN;
    end

    % end of datagram
    struct_out.ETX(idn)      = typecast(tmp_end(us+1),'uint8');
    struct_out.CheckSum(idn) = typecast(tmp_end(2+us:3+us),'uint16');

end



end

function dg_str = dg_num_to_str(dg_num)
switch dg_num
    case 49
        dg_str = 'PU STATUS OUTPUT (31H)';
    case 65
        dg_str = 'ATTITUDE (41H)';
    case 67
        dg_str = 'CLOCK (43H)';
    case 68
        dg_str = 'DEPTH DATAGRAM (44H)';
    case 71
        dg_str = 'SURFACE SOUND SPEED (47H)';
    case 72
        dg_str = 'HEADING (48H)';
    case 73
        dg_str = 'INSTALLATION PARAMETERS START (49H)';
    case 78
        dg_str = 'RAW RANGE AND ANGLE 78 (4EH)';
    case 79
        dg_str = 'QUALITY FACTOR DATAGRAM 79 (4FH)';
    case 80
        dg_str = 'POSITION (50H)';
    case 82
        dg_str = 'RUNTIME PARAMETERS (52H)';
    case 83
        dg_str = 'SEABED IMAGE DATAGRAM (53H)';
    case 85
        dg_str = 'SOUND SPEED PROFILE (55H)';
    case 88
        dg_str = 'XYZ 88 (58H)';
    case 89
        dg_str = 'SEABED IMAGE DATA 89 (59H)';
    case 102
        dg_str = 'RAW RANGE AND BEAM ANGLE (f) (66H)';
    case 104
        dg_str = 'DEPTH (PRESSURE) OR HEIGHT DATAGRAM (68H)';
    case 105
        dg_str = 'INSTALLATION PARAMETERS STOP (69H)';
    case 107
        dg_str = 'WATER COLUMN DATAGRAM (6BH)';
    case 110
        dg_str = 'NETWORK ATTITUDE VELOCITY DATAGRAM (6EH)';
    case 114
        dg_str = 'AMPLITUDE AND PHASE WC DATAGRAM (72H)';
    otherwise
        dg_str = sprintf('UNKNOWN DATAGRAM (%sH)',dec2hex(dg_num));
end

end