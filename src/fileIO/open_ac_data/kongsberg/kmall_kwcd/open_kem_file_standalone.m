function [layers,id_rem] = open_kem_file_standalone(Filename_cell,varargin)
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

ext = {'.kmwcd' '.kmall'};

if numel(p.Results.GPSOnly) ~= numel(Filename_cell)
    GPSOnly = ones(1,numel(Filename_cell))*p.Results.GPSOnly;
else
    GPSOnly = p.Results.GPSOnly;
end


%HEADER_SIZE  =20;

all_dg = {'#IIP' ...% '#IIP - Installation parameters and sensor setup'
    '#IOP' ...% '#IOP - Runtime parameters as chosen by operator'
    '#IBE'... % '#IBE - Built in test (BIST) error report'
    '#IBR'... % '#IBR - Built in test (BIST) reply'
    '#IBS'... % '#IBS - Built in test (BIST) short reply'
    '#MRZ'... % '#MRZ - Multibeam (M) raw range (R) and depth(Z) datagram'
    '#MWC'... % '#MWC - Multibeam (M) water (W) column (C) datagram'
    '#SPO'... % '#SPO - Sensor (S) data for position (PO)'
    '#SKM'... % '#SKM - Sensor (S) KM binary sensor format'
    '#SVP'... % '#SVP - Sensor (S) data from sound velocity (V) profile (P) or CTD'
    '#SVT'... % '#SVT - Sensor (S) data for sound velocity (V) at transducer (T)'
    '#SCL'... % '#SCL - Sensor (S) data from clock (CL)'
    '#SDE'... % '#SDE - Sensor (S) data from depth (DE) sensor'
    '#SHI'... % '#SHI - Sensor (S) data for height (HI)'
    '#CPO'... % '#CPO - Compatibility (C) data for position (PO)'
    '#CHE'... % '#CHE - Compatibility (C) data for heave (HE)'
    '#FCF'... % '#FCF - Backscatter calibration (C) file (F) datagram'
    };

dg_to_read = {'#IIP' ...% '#IIP - Installation parameters and sensor setup'
    '#IOP' ...% '#IOP - Runtime parameters as chosen by operator'
    '#MRZ'... % '#MRZ - Multibeam (M) raw range (R) and depth(Z) datagram'
    '#MWC'... % '#MWC - Multibeam (M) water (W) column (C) datagram'
    '#SPO'... % '#SPO - Sensor (S) data for position (PO)'
    '#SKM'... % '#SKM - Sensor (S) KM binary sensor format'
    '#SVP'... % '#SVP - Sensor (S) data from sound velocity (V) profile (P) or CTD'
    '#SVT'... % '#SVT - Sensor (S) data for sound velocity (V) at transducer (T)'
    '#SDE'... % '#SDE - Sensor (S) data from depth (DE) sensor'
    };

wc_dg_names = {'#MWC'};

block_len = get_block_len(50,'cpu',p.Results.block_len);

for uu = 1:nb_files
    try
        dg_to_read_bool = true(1,numel(dg_to_read));

        if ~isempty(load_bar_comp)
            set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_files,'Value',uu);
        end

        file_read_bool = false;
        has_been_read  =false;
        KEM_data_struct = init_KEM_data_struct(dg_to_read);
        [path_f,fileN,~] = fileparts(Filename_cell{uu});
        echo_folder = get_esp3_file_folder(path_f,true);

        fileStruct = fullfile(echo_folder,[fileN '_kemstruct.mat']);

        force_read = isdebugging;

        if isfile(fileStruct)&&~force_read
            s_out = load(fileStruct);
            KEM_data_struct = s_out.KEM_data_struct;
            if strcmpi(KEM_data_struct.KEM_struct_version,get_curr_KEM_struct_version())
                has_been_read = true;
                file_read_bool = true;
            else
                KEM_data_struct = init_KEM_data_struct(dg_to_read);
            end
        end

        [~,ff,ee] = fileparts(KEM_data_struct.Filename);
        KEM_data_struct.Filename = fullfile(path_f,[ff ee]);

        fields = fieldnames(KEM_data_struct);

        for uif = 1:numel(fields)
            if isfield(KEM_data_struct.(fields{uif}),'fname')
                [~,ff,ee] = fileparts(KEM_data_struct.(fields{uif}).fname);
                KEM_data_struct.(fields{uif}).fname = fullfile(path_f,[ff ee]);
            end
        end

        if ~has_been_read || isdebugging

            for iext = 1:numel(ext)

                if ~isfile([Filename_cell{uu} ext{iext}])
                    continue;
                end

                Filename = [Filename_cell{uu} ext{iext}];
                KEM_data_struct.Filename = Filename;
                [path_f,fileN,~] = fileparts(Filename);
                echo_folder = get_esp3_file_folder(path_f,true);
                str = '';

                s=dir(Filename);
                filesize=s.bytes;

                ftype = get_ftype(Filename);

                if ~ismember(ftype,{'KEM'})
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

                dg_str_cell = idx_raw_obj.type_dg;
                dg_str_cell_u = unique(dg_str_cell);
                dg_str_cell_u_val = cellfun(@matlab.lang.makeValidName,dg_str_cell_u,'un',0);
                dg_str_cell_val = dg_str_cell;

                for uic = 1:numel(dg_str_cell_u_val)
                    dg_str_cell_val(strcmpi(dg_str_cell,dg_str_cell_u{uic})) = dg_str_cell_u_val(uic);
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

                        [struct_in,header_struct]  = init_new_dg(fid,[]);

                        if ~checkKEMheader(header_struct)
                            continue;
                        end


                        fields = fieldnames(KEM_data_struct);

                        idx_struct = find(ismember(fields,dg_str_cell_val{idg}),1);

                        if isempty(idx_struct)||isempty(KEM_data_struct.(fields{idx_struct}))
                            idn = 1;
                            struct_in.fname = Filename;
                        else
                            struct_in = KEM_data_struct.(fields{idx_struct});
                            idn = numel(KEM_data_struct.(fields{idx_struct}).dgSize)+1;
                        end

                        fh = fieldnames(header_struct);

                        for ifi = 1:numel(fh)
                            if isnumeric(header_struct.(fh{ifi}))
                                struct_in.(fh{ifi})(idn) = header_struct.(fh{ifi});
                            else
                                struct_in.(fh{ifi}){idn} = header_struct.(fh{ifi});
                            end
                        end

                        switch dg_str_cell{idg}
                            case '#IIP'
                                struct_out = read_IIP_IOP(fid,struct_in,dg_str_cell{idg});
                            case '#IOP'
                                struct_out = read_IIP_IOP(fid,struct_in,dg_str_cell{idg});
                            case '#MRZ'
                                struct_out = read_MRZ(fid,struct_in);
                            case '#MWC'
                                struct_out = read_MWC(fid,struct_in);
                            case'#SPO'
                                struct_out = read_SPO(fid,struct_in);
                            case'#SKM'
                                struct_out = read_SKM(fid,struct_in);
                            case '#SVP'
                                struct_out = read_SVP(fid,struct_in);
                            case '#SDE'
                                continue;
                            otherwise
                                continue;
                        end

                    catch err
                        print_errors_and_warnings([],'warning',sprintf('Could not read datagram %s\n',dg_str_cell{idg}));
                        print_errors_and_warnings([],'warning',err);
                        continue;
                    end

                    valid =  ~(isempty(struct_out.dgSize(end)) || struct_out.dgSize(end) == 0);

                    if ~valid
                        continue;
                    end

                    dg_to_read_bool(strcmpi(dg_to_read,dg_str_cell{idg})) = false;

                    KEM_data_struct.(dg_str_cell_val{idg}) = struct_out;

                end

                file_read_bool = true;

            end
            save(fileStruct,'KEM_data_struct');
        end


        if ~file_read_bool
            dlg_perso([],'Unable to open file',sprintf('Could not open file %s',Filename_cell{uu}));
            continue;
        end

        fields = fieldnames(KEM_data_struct);

        idx_wc = find(ismember(fields,matlab.lang.makeValidName(wc_dg_names)) & ~structfun(@isempty,KEM_data_struct), 1);

        if ~any(idx_wc)
            dlg_perso([],'No WC datagrams',sprintf('%s does not contains WC datagrams and will not be opened by ESP3 at this time... \nThis is sad.',Filename_cell{uu}));
            continue
        end


        if isfield(KEM_data_struct,'x_MRZ')&&~isempty(KEM_data_struct.x_MRZ)
            ss  = mean(KEM_data_struct.x_MRZ.soundSpeedAtTxDepth_mPerSec);
            env_data_obj = env_data_cl('SoundSpeed',ss);
        else
            env_data_obj  = env_data_cl();
        end

        if isfield(KEM_data_struct,'x_SVP')&&~isempty(KEM_data_struct.x_SVP) && numel(KEM_data_struct.x_SVP.depth_m)>1
            env_data_obj.SVP.depth = KEM_data_struct.x_SVP.depth_m;
            env_data_obj.SVP.soundspeed = KEM_data_struct.x_SVP.soundVelocity_mPerSec;
            env_data_obj.SVP.ori = 'constant';
        end


        dt  = KEM_data_struct.x_MWC.sampleFreq_Hz;
        gg = findgroups(dt);

        idx_change = KEM_data_struct.x_MWC.pingCnt(abs(diff(gg))>0)-KEM_data_struct.x_MWC.pingCnt(1)+1;


        idg_start = [1 idx_change+1];
        idg_end = [idx_change numel(unique(KEM_data_struct.x_MWC.pingCnt))];
        t_change = KEM_data_struct.x_MWC.time(idg_start);

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

        [wc_struct_out,ac_data_obj,sample_offset] = read_WC_data(KEM_data_struct.x_MWC,idg_start,idg_end,p.Results.PathToMemmap,load_bar_comp,GPSOnly(uu));


        for idg = 1:numel(wc_struct_out)

            if numel(wc_struct_out{idg}.WC_1P_pingCnt)<3
                continue;
            end

            st = wc_struct_out{idg}.WC_1P_time(1);
            et = wc_struct_out{idg}.WC_1P_time(end);

            [nb_beams,nb_pings]  = size(wc_struct_out{idg}.WC_BP_BeamPointingAngle);

            if isfield(KEM_data_struct,'x_SPO')&&~isempty(KEM_data_struct.x_SPO)
                ipings  = find(KEM_data_struct.x_SPO.time>=st & KEM_data_struct.x_SPO.time<=et);
                if isempty(ipings)
                    gps_data_obj = gps_data_cl;
                else
                    mssg = cellfun(@(x) x(1:6),KEM_data_struct.x_SPO.posDataFromSensor,'un',0);
                    [id,G] = findgroups(mssg);
                    idd = mode(id);

                    gps_data_obj = gps_data_cl(...
                        'Lat',KEM_data_struct.x_SPO.correctedLat_deg(ipings),...
                        'Long',KEM_data_struct.x_SPO.correctedLong_deg(ipings),...
                        'Time',KEM_data_struct.x_SPO.time(ipings),...
                        'Speed',KEM_data_struct.x_SPO.speedOverGround_mPerSec(ipings),...
                        'NMEA',G{idd});
                end

            else
                gps_data_obj = gps_data_cl;
            end

            if isfield(KEM_data_struct,'x_SKM')&&~isempty(KEM_data_struct.x_SKM)
                ipings  = find(KEM_data_struct.x_SKM.time>=st & KEM_data_struct.x_SKM.time<=et);
                if isempty(ipings)
                    att_nav_obj = attitude_nav_cl();
                else
                    id = KEM_data_struct.x_SKM.sensorSystem(ipings);
                    idd = mode(id);
                    cc = cell2mat(KEM_data_struct.x_SKM.sample(ipings(id==idd)));
                    att_nav_obj =attitude_nav_cl(...
                        'Time',[cc(:).time],...
                        'Roll',[cc(:).roll_deg],...
                        'Pitch',[cc(:).pitch_deg],...
                        'Heave',[cc(:).heave_m],...
                        'Heading',[cc(:).heading_deg] ...
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

            freq = nan(nb_beams,nb_pings);
            for ip  = 1:nb_pings
                id_sec = unique(wc_struct_out{idg}.WC_BP_TransmitSectorNumber(:,ip))';
                for uis = 1:numel(id_sec)
                    iBeam = wc_struct_out{idg}.WC_BP_TransmitSectorNumber == id_sec(uis);
                    freq(iBeam(:,ip),ip) = wc_struct_out{idg}.WC_TP_CenterFrequency(uis,ip);
                end
            end

            alpha  = arrayfun(@(x) seawater_absorption(x, env_data_obj.Salinity, env_data_obj.Temperature, env_data_obj.Depth,'fandg'),freq/1e3)/1e3;

            pulse_length = nan(nb_beams,nb_pings);
            pulse_length_eff = nan(nb_pings,nb_beams);

            if isfield(KEM_data_struct,'x_MRZ') && ~isempty(KEM_data_struct.x_MRZ)
                for ip  = 1:nb_pings
                    id_sec = unique(wc_struct_out{idg}.WC_BP_TransmitSectorNumber(:,ip))';
                    for uis = 1:numel(id_sec)
                        iBeam = wc_struct_out{idg}.WC_BP_TransmitSectorNumber == id_sec(uis);
                        [~,id_ping] = min(abs(wc_struct_out{idg}.WC_1P_pingCnt(ip)-KEM_data_struct.x_MRZ.pingCnt));
                        secinfo = KEM_data_struct.x_MRZ.sectorInfo{id_ping}(uis);
                        pulse_length(iBeam(:,ip),ip) = secinfo.totalSignalLength_sec;
                        pulse_length_eff(iBeam(:,ip),ip) = secinfo.effectiveSignalLength_sec;
                    end
                end
            else
                pulse_length(:) = 0.0001;
                pulse_length_eff(:) = 0.00007;
            end

            config_obj = config_cl();
            config_obj.BeamType = 'single-beam';%single beam (in each of the beams)
            config_obj.TransducerAlphaX = KEM_data_struct.x_IIP.TRAI_RX1_R;
            config_obj.TransducerAlphaY = KEM_data_struct.x_IIP.TRAI_RX1_P;
            config_obj.TransducerAlphaZ = KEM_data_struct.x_IIP.TRAI_RX1_H;
            config_obj.TransducerOffsetX = KEM_data_struct.x_IIP.TRAI_RX1_X;
            config_obj.TransducerOffsetY = KEM_data_struct.x_IIP.TRAI_RX1_Y;
            config_obj.TransducerOffsetZ = KEM_data_struct.x_IIP.TRAI_RX1_Z;

            params_obj = params_cl(nb_pings,nb_beams);
            params_obj.BeamAngleAlongship = zeros(size(wc_struct_out{idg}.WC_BP_BeamPointingAngle));
            params_obj.BeamAngleAthwartship= wc_struct_out{idg}.WC_BP_BeamPointingAngle;

            params_obj.SampleInterval=repmat(1./(wc_struct_out{idg}.WC_1P_SamplingFrequencyHz),nb_beams,1);
            params_obj.PulseLength=pulse_length;
            params_obj.TransmitPower=1e3*ones(nb_beams,nb_pings);
            params_obj.Frequency = freq;
            params_obj.FrequencyStart = freq;
            params_obj.FrequencyEnd = freq;

            config_obj.SerialNumber = sprintf('EM%d_%d',KEM_data_struct.x_IIP.echoSounderID,KEM_data_struct.x_IIP.systemID);
            config_obj.ChannelID = sprintf('EM%d_%d',KEM_data_struct.x_IIP.echoSounderID,KEM_data_struct.x_IIP.systemID);
            config_obj.TransceiverName = sprintf('EM%d_%d',KEM_data_struct.x_IIP.echoSounderID,KEM_data_struct.x_IIP.systemID);
            if isfield(KEM_data_struct.x_IIP,'SERIALno_RX') && isnumeric(KEM_data_struct.x_IIP.SERIALno_RX)
                snrx = KEM_data_struct.x_IIP.SERIALno_RX;
            else
                snrx = 0;
            end

            config_obj.TransducerName = sprintf('EM%d_%d_SN_%d',KEM_data_struct.x_IIP.echoSounderID,KEM_data_struct.x_IIP.systemID,snrx);
            config_obj.TransceiverType = sprintf('EM%d_%d',KEM_data_struct.x_IIP.echoSounderID,KEM_data_struct.x_IIP.systemID);
            config_obj.TransducerSerialNumber = sprintf('SN_%d',snrx);
            config_obj.ChannelNumber = 1;

            config_obj.Frequency = mean(freq,2)';

            if isfield(KEM_data_struct,'x_MRZ')&&~isempty(KEM_data_struct.x_MRZ)
                config_obj.FrequencyMinimum = min(KEM_data_struct.x_MRZ.freqRangeLowLim_Hz,[],'all')*ones(size(config_obj.Frequency));
                config_obj.FrequencyMaximum = max(KEM_data_struct.x_MRZ.freqRangeHighLim_Hz,[],'all')*ones(size(config_obj.Frequency));
                config_obj.BeamWidthAlongship = mean(KEM_data_struct.x_MRZ.transmitArraySizeUsed_deg)*ones(size(config_obj.Frequency));
                config_obj.BeamWidthAthwartship = mean(KEM_data_struct.x_MRZ.receiveArraySizeUsed_deg)*ones(size(config_obj.Frequency));
            else
                config_obj.FrequencyMinimum = min(freq,[],2)';
                config_obj.FrequencyMaximum = max(freq,[],2)';
                config_obj.BeamWidthAlongship = ones(size(config_obj.Frequency));
                config_obj.BeamWidthAthwartship = ones(size(config_obj.Frequency));
            end


            config_obj.EquivalentBeamAngle = estimate_eba(config_obj.BeamWidthAthwartship,config_obj.BeamWidthAlongship);
            config_obj.Gain = zeros(size(config_obj.Frequency));
            config_obj.SaCorrection = zeros(size(config_obj.Frequency));
            config_obj.PulseLength = mean(pulse_length,2)';

            trans_obj=transceiver_cl('Data',ac_data_obj{idg},...
                'Ping_offset',wc_struct_out{idg}.WC_1P_pingCnt(1),...
                'Sample_offset',sample_offset(idg),...
                'Time',wc_struct_out{idg}.WC_1P_time,...
                'Config',config_obj,...
                'Mode','CW',...
                'Params',params_obj);

            if isfield(KEM_data_struct,'x_MRZ')&&~isempty(KEM_data_struct.x_MRZ) 
                trans_obj.TransceiverDepth = resample_data_v2(-KEM_data_struct.x_MRZ.z_waterLevelReRefPoint_m,KEM_data_struct.x_MRZ.time,trans_obj.Time);
            end

            trans_obj.Config.MotionCompBool = [true true true true];

            wc_struct_out{idg}.WC_BP_DetectedRangeInSamples(wc_struct_out{idg}.WC_BP_DetectedRangeInSamples ==0) = nan;
            trans_obj.Bottom = bottom_cl('Origin','Kongsberg Detection','Sample_idx',ceil(wc_struct_out{idg}.WC_BP_DetectedRangeInSamples));

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

            compute_sv = true;

            if compute_sv && GPSOnly(uu) == 0
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
            end

            layer_obj=layer_cl('Filename',{KEM_data_struct.Filename},...
                'Filetype','EM',...
                'GPSData',gps_data_obj,...
                'AttitudeNav',att_nav_obj,...
                'Transceivers',trans_obj,...
                'EnvData',env_data_obj);
            % line_tmp = line_cl('Name',sprintf('MRUDepth from %s','z_waterLevelReRefPoint_m'),'Range',trans_obj.TransceiverDepth,'Time',trans_obj.Time,'Tag','offset');
            % layer_obj.add_lines(line_tmp);

            layers =[layers layer_obj];
        end
    catch err
        id_rem=union(id_rem,uu);
        dlg_perso([],'',sprintf('Could not open files %s\n',Filename_cell{uu}));
        print_errors_and_warnings(1,'error',err);

    end
end
end


function struct_out = init_KEM_data_struct(dgnames)
struct_out = [];
for uit = 1:numel(dgnames)
    struct_out.(matlab.lang.makeValidName(dgnames{uit}))=[];
end
struct_out.Filename='';
struct_out.KEM_struct_version = get_curr_KEM_struct_version();
end

function [wc_struct,ac_data_obj,sample_offset] = read_WC_data(KEM_WC_data_struct,idx_ping_start,idx_ping_end,path_f,load_bar_comp,gps_only_bool)

ac_data_obj=cell(1,numel(idx_ping_start));
wc_struct=cell(1,numel(idx_ping_start));
enc = 'US-ASCII';

fid  = fopen(KEM_WC_data_struct.fname,'r','l',enc);
% get the number of heads
headNumber = unique(KEM_WC_data_struct.systemID,'stable');
swath_number = unique(KEM_WC_data_struct.rxFanIndex,'stable');

%[~,curr_filename,~]=fileparts(tempname)

fname = KEM_WC_data_struct.fname;
[~,curr_filename,~] = fileparts(fname);

curr_data_name_t=fullfile(path_f,curr_filename,'ac_data');

% get the list of pings and the index of first datagram for
% each ping
if isscalar(headNumber)
    % if only one head...
    [pingCnts, iFirstDatagram] = unique(KEM_WC_data_struct.pingCnt,'stable');
else

    pingCnts = unique(KEM_WC_data_struct.pingCnt(KEM_WC_data_struct.systemID==headNumber(1)),'stable');

    % for each other head, get ping numbers and only keep
    % intersection
    for iH = 2:length(headNumber)
        pingCntsOtherHead = unique(KEM_WC_data_struct.pingCnt(KEM_WC_data_struct.systemID==headNumber(iH)),'stable');
        pingCnts = intersect(pingCnts, pingCntsOtherHead,'stable');
    end

    iFirstDatagram  = nan(numel(pingCnts),2);
    % get the index of first datagram for each ping and each
    % head
    for iH = 1:length(headNumber)
        iFirstDatagram(:,iH) = arrayfun(@(x) find(KEM_WC_data_struct.systemID==headNumber(iH) & KEM_WC_data_struct.pingCnt==x, 1),pingCnts);
    end
end

% test for inconsistencies between heads and raise a warning if
% one is detected
if length(headNumber) > 1
    fields = {'soundVelocity_mPerSec','sampleFreq_Hz','heave_m','TVGfunctionApplied','TVGoffset_dB'};
    for iFi = 1:length(fields)
        if any(any(KEM_WC_data_struct.(fields{iFi})(iFirstDatagram(:,1))'.*ones(1,length(headNumber))~=KEM_WC_data_struct.(fields{iFi})(iFirstDatagram)))
            warning('System has more than one head and "%s" data are inconsistent between heads for at least one ping. Using information from first head anyway.',fields{iFi});
        end
    end
end

sample_offset  = nan(1,numel(idx_ping_start));

for uip =1:numel(idx_ping_start)

    idx_pings_g  = idx_ping_start(uip):idx_ping_end(uip);
    idx_pings_g(idx_pings_g>numel(pingCnts)) = [];

    % save ping numbers
    wc_struct{uip}.WC_1P_pingCnt = pingCnts(idx_pings_g);

    % for the following fields, take value from first datagram in
    % first head
    wc_struct{uip}.WC_1P_time                            = KEM_WC_data_struct.time(iFirstDatagram(idx_pings_g,1));
    wc_struct{uip}.WC_1P_SoundSpeed                      = KEM_WC_data_struct.soundVelocity_mPerSec(iFirstDatagram(idx_pings_g,1));
    wc_struct{uip}.WC_1P_SamplingFrequencyHz             = KEM_WC_data_struct.sampleFreq_Hz(iFirstDatagram(idx_pings_g,1)); % in Hz
    wc_struct{uip}.WC_1P_TXTimeHeave                     = KEM_WC_data_struct.heave_m(iFirstDatagram(idx_pings_g,1));
    wc_struct{uip}.WC_1P_TVGFunctionApplied              = KEM_WC_data_struct.TVGfunctionApplied(iFirstDatagram(idx_pings_g,1));
    wc_struct{uip}.WC_1P_TVGOffset                       = KEM_WC_data_struct.TVGoffset_dB(iFirstDatagram(idx_pings_g,1));
    wc_struct{uip}.WC_1P_PhaseFlag                       = KEM_WC_data_struct.phaseFlag(iFirstDatagram(idx_pings_g,1));

    % for the other fields, sum the numbers from heads
    if length(headNumber) > 1
        wc_struct{uip}.WC_1P_NumberOfDatagrams         = sum(KEM_WC_data_struct.numOfDgms(iFirstDatagram(idx_pings_g,:)),2)';
        wc_struct{uip}.WC_1P_NumberOfTransmitSectors   = sum(KEM_WC_data_struct.numTxSectors(iFirstDatagram(idx_pings_g,:)),2)';
        wc_struct{uip}.WC_1P_NumberOfBeams       = sum(KEM_WC_data_struct.numBeams(iFirstDatagram(idx_pings_g,:)),2)'; % each head is decimated in beam individually
    else
        wc_struct{uip}.WC_1P_NumberOfDatagrams         = KEM_WC_data_struct.numOfDgms(iFirstDatagram(idx_pings_g));
        wc_struct{uip}.WC_1P_NumberOfTransmitSectors   = KEM_WC_data_struct.numTxSectors(iFirstDatagram(idx_pings_g));
        wc_struct{uip}.WC_1P_NumberOfBeams       = ceil(KEM_WC_data_struct.numBeams(iFirstDatagram(idx_pings_g)));
    end

    % get original data dimensions
    nPings = length(pingCnts(idx_pings_g)); % total number of pings in file
    maxNTransmitSectors = max(wc_struct{uip}.WC_1P_NumberOfTransmitSectors); % maximum number of transmit sectors in a ping
    maxNSwath = max(wc_struct{uip}.WC_1P_NumberOfTransmitSectors); % maximum number of transmit sectors in a ping

    % get dimensions of data to red after decimation
    nb_beams = max(wc_struct{uip}.WC_1P_NumberOfBeams); % maximum number of receive beams TO READ

    idgp = find(ismember(KEM_WC_data_struct.pingCnt,pingCnts(idx_pings_g)));
    [~,~,subs]  = unique(KEM_WC_data_struct.pingCnt(idgp));


    nb_samples_per_pings  = accumarray(subs,cellfun(@(x,y) max(x+y,[],2,'omitnan'),KEM_WC_data_struct.numSampleData(idgp),KEM_WC_data_struct.startRangeSampleNum(idgp)),[],@max);
    start_sample_min_per_pings  = accumarray(subs,cellfun(@(x) min(x,[],2,'omitnan'),KEM_WC_data_struct.startRangeSampleNum(idgp)),[],@max);

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
    wc_struct{uip}.WC_TP_systemID   = nan(maxNTransmitSectors,nPings);


    % initialize data per decimated beam and ping
    wc_struct{uip}.WC_BP_BeamPointingAngle      = nan(nb_beams,nPings);
    wc_struct{uip}.WC_BP_StartRangeSampleNumber = nan(nb_beams,nPings);
    wc_struct{uip}.WC_BP_NumberOfSamples        = nan(nb_beams,nPings);
    wc_struct{uip}.WC_BP_DetectedRangeInSamples = zeros(nb_beams,nPings);
    wc_struct{uip}.WC_BP_TransmitSectorNumber   = nan(nb_beams,nPings);
    wc_struct{uip}.WC_BP_systemID     = nan(nb_beams,nPings);

    prec  ='int8';
    fmt = 'int8';sc = 'db';cf = 1/2;

    % initialize ping group counter
    iG = 1;
    if ~isempty(load_bar_comp)
        set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nPings,'Value',0);
    end
    % now get data for each ping
    subIP = 0;
    str = '';
    
    for iP = idx_pings_g
        if gps_only_bool == 0
            SB_temp = single(intmin(prec))*ones(nb_samples_group(iG),nb_beams,'single');

            switch KEM_WC_data_struct.phaseFlag(iP)
                case 0
                    ph_temp= [];
                case 1
                    ph_temp = zeros(nb_samples_group(iG),nb_beams,'single');
                otherwise
                    ph_temp = zeros(nb_samples_group(iG),nb_beams,'single');
            end
        else
            ph_temp = [];
            SB_temp = [];
        end

        subIP  =subIP+1;

        if ~isempty(load_bar_comp)
            set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nPings,'Value',subIP);
        else
            nstr = numel(str);
            str = sprintf('%2.0f%%',floor(subIP/nPings*100));
            fprintf([repmat('\b',1,nstr) '%s'],str);
        end

        pingCnt = wc_struct{uip}.WC_1P_pingCnt(1,subIP);

        if subIP > id_end(iG)
            iG = iG+1;
        end

        % initialize number of sectors and beams recorded so far for
        % that ping (needed for multiple heads)
        nTxSectTot = 0;
        nBeamTot = 0;

        for iH = 1:length(headNumber)

            headSSN = headNumber(iH);
            
           
            iDatagrams  = find( KEM_WC_data_struct.pingCnt == pingCnt & ...
                KEM_WC_data_struct.systemID == headSSN & ...
                KEM_WC_data_struct.rxFanIndex == KEM_WC_data_struct.rxFanIndex(1)); %TOFIX only reading one swath

            if isempty(iDatagrams)
                subIP  =subIP-1;
                continue;
            end
            % actual number of datagrams available (ex: 4)
            nDatagrams  = length(iDatagrams);

            % some datagrams may be missing. Need to detect and adjust.
            datagramOrder     = KEM_WC_data_struct.dgmNum(iDatagrams); % order of the datagrams (ex: 4-3-6-2, the missing one is 1st, 5th and 7th)
            [~,IX]            = sort(datagramOrder);
            iDatagrams        = iDatagrams(IX); % index of the datagrams making up this ping in em_data_struct, but in the right order (ex: 64-59-58-61, missing datagrams are still missing)
            nBeamsPerDatagram = KEM_WC_data_struct.numBeams(iDatagrams); % number of beams in each datagram making up this ping (ex: 56-61-53-28)

            % number of transmit sectors to record
            nTxSect = KEM_WC_data_struct.numTxSectors(iDatagrams(1));

            % indices of those sectors in output structure
            iTxSectDest = nTxSectTot + (1:nTxSect);

            % recording data per transmit sector
            wc_struct{uip}.WC_TP_TiltAngle(iTxSectDest,subIP)            = [KEM_WC_data_struct.sectorData{iDatagrams(1)}(iTxSectDest).tiltAngleReTx_deg];
            wc_struct{uip}.WC_TP_CenterFrequency(iTxSectDest,subIP)      = [KEM_WC_data_struct.sectorData{iDatagrams(1)}(iTxSectDest).centreFreq_Hz];
            wc_struct{uip}.WC_TP_TransmitSectorNumber(iTxSectDest,subIP) = [KEM_WC_data_struct.sectorData{iDatagrams(1)}(iTxSectDest).txSectorNum];
            wc_struct{uip}.WC_TP_systemID(iTxSectDest,subIP)   = headSSN;

            % updating total number of sectors recorded so far
            nTxSectTot = nTxSectTot + nTxSect;
            nBeamMax = size(wc_struct{uip}.WC_BP_BeamPointingAngle,1);
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
                wc_struct{uip}.WC_BP_BeamPointingAngle(iBeamDest,subIP)      = KEM_WC_data_struct.beamPointAngReVertical_deg{iDatagrams(iD)}(iBeamSource);
                wc_struct{uip}.WC_BP_StartRangeSampleNumber(iBeamDest,subIP) = KEM_WC_data_struct.startRangeSampleNum{iDatagrams(iD)}(iBeamSource);
                wc_struct{uip}.WC_BP_NumberOfSamples(iBeamDest,subIP)        = KEM_WC_data_struct.numSampleData{iDatagrams(iD)}(iBeamSource);
                wc_struct{uip}.WC_BP_DetectedRangeInSamples(iBeamDest,subIP) = KEM_WC_data_struct.detectedRangeInSamples{iDatagrams(iD)}(iBeamSource)-KEM_WC_data_struct.startRangeSampleNum{iDatagrams(iD)}(iBeamSource)+1;
                wc_struct{uip}.WC_BP_TransmitSectorNumber(iBeamDest,subIP)   = KEM_WC_data_struct.beamTxSectorNum{iDatagrams(iD)}(iBeamSource);
                wc_struct{uip}.WC_BP_systemID(iBeamDest,subIP)     = headSSN;
                
                % and then, in each beam...
                if gps_only_bool == 0
                    for iB = 1:nBeam
                        nSamp = KEM_WC_data_struct.numSampleData{iDatagrams(iD)}(iBeamSource(iB));
                        samp_start = 1;


                        pos = KEM_WC_data_struct.sampleDataPositionInFile{iDatagrams(iD)}(iBeamSource(iB));
                        fseek(fid,pos,'bof');
                        switch wc_struct{uip}.WC_1P_PhaseFlag(subIP)
                            case 0
                                % get to the start of the data in original file
                                SB_temp(samp_start+(0:(nSamp-1)),iBeamDest(iB)) = fread(fid, nSamp, 'int8')*cf;
                            case 1
                                prec_phase  ='int8';
                                fmt_phase = 'int8';sc_phase = 'angle';
                                cf_phase = 180/double(intmax(prec_phase));
                                SB_temp(samp_start+(0:(nSamp-1)),iBeamDest(iB)) = fread(fid, nSamp, 'int8')*cf;
                                ph_temp(samp_start+(0:(nSamp-1)),iBeamDest(iB)) = fread(fid, nSamp, 'int8')*cf_phase;
                            otherwise
                                prec_phase  ='int16';
                                fmt_phase = 'int16';sc_phase = 'angle';
                                cf_phase = 180/double(intmax(prec_phase));
                                SB_temp(samp_start+(0:(nSamp-1)),iBeamDest(iB)) = fread(fid, nSamp, 'int8')*cf;
                                fseek(fid,pos+2,'bof');
                                ph_temp(samp_start+(0:(nSamp-1)),iBeamDest(iB),iBeamDest(iB)) = fread(fid,nSamp,'int16')*cf_phase;

                        end

                    end
                end
                % updating total number of beams recorded so far
                 nBeamTot = nBeamTot + nBeam;
                if nBeamTot>=nBeamMax%TOFIX
                    nBeamTot = 0;
                end
            end
        
        end

        if gps_only_bool == 0
            ac_data_obj{uip}.replace_sub_data_v2(permute(SB_temp,[1 3 2]),'wc_data','idx_ping',subIP,...
                'Fmt',fmt,...
                'ConvFactor',cf,...
                'Scale',sc,...
                'idx_r',1:size(SB_temp,1),...
                'idx_beam',1:size(SB_temp,2));

            if wc_struct{uip}.WC_1P_PhaseFlag(subIP)>0

                ac_data_obj{uip}.replace_sub_data_v2(permute(ph_temp,[1 3 2]),'acrossphi','idx_ping',subIP,...
                    'Fmt',fmt_phase,...
                    'ConvFactor',cf_phase,...
                    'Scale',sc_phase,...
                    'idx_r',1:size(ph_temp,1),...
                    'idx_beam',1:size(ph_temp,2));
            end
        end

    end
end

fclose(fid);

end

function [struct_out,header] = init_new_dg(fid,struct_in)
if ~isempty(struct_in)
    idn = numel(struct_in.dgSize)+1;
else
    idn = 1;
end

struct_out = struct_in;
header = read_kem_header(fid);

struct_out.dgmType{idn} = header.dgmType;
struct_out.dgmVersion(idn) = header.dgmVersion;
struct_out.systemID(idn) = header.systemID;
struct_out.echoSounderID(idn) = header.echoSounderID;
struct_out.time(idn) = header.time;
end

function struct_out = read_IIP_IOP(fid,struct_in,dgType)

struct_out  = struct_in;
idn = numel(struct_out.dgSize);

struct_out.numBytesCmnPart(idn) = fread(fid,1,'uint16');
struct_out.info(idn) = fread(fid,1,'uint16');
struct_out.status(idn) = fread(fid,1,'uint16');
struct_out.install_txt{idn} = fscanf(fid, '%c',struct_out.numBytesCmnPart-6);
install_txt = struct_out.install_txt{idn};

switch dgType
    case '#IIP'
        struct_out = decode_IIP(install_txt,struct_in);
    case '#IOP'
        struct_out = decode_IOP(install_txt,struct_in);
end

end

function struct_out = decode_IIP(install_txt,struct_in)
struct_out = struct_in;
idn = numel(struct_out.dgSize);

lines = strsplit(install_txt,newline);

ff_start = '';
for iL = 1:length(lines)
    line = lines{iL};
    line = strtrim(line);
    if isempty(line)
        continue;
    else
        l_split = strsplit(line,{','});
        for ill = 1:numel(l_split)
            if isempty(l_split{ill})
                continue;
            end
            try
            if contains(l_split{ill},'=') && ~contains(l_split{ill},';')
                lsplit_final = strsplit(l_split{ill},'=');
            else
                lsplit_final = strsplit(l_split{ill},':');
            end

            if isscalar(lsplit_final)
                ff_start = lsplit_final{1};
            end

            if strcmpi(lsplit_final{1},'VERSIONS') || strcmpi(lsplit_final{1},'SERIALno')
                ff_start = lsplit_final{1};
                continue;
            end

            if strcmpi(lsplit_final{1},'VERSIONS-END') || strcmpi(lsplit_final{1},'SERIALno-END')
                ff_start = '';
                continue;
            end

            if isscalar(lsplit_final)
                continue
            end

            if isempty(ff_start)
                ff  = matlab.lang.makeValidName(lsplit_final{1});
            else
                ff = sprintf('%s_%s',ff_start,matlab.lang.makeValidName(lsplit_final{1}));
            end

            if contains(lsplit_final{2},';') && contains(lsplit_final{2},'=')
                lsplit_final_f = strsplit(lsplit_final{2},';');
                fff = cell(1,numel(lsplit_final_f));
                vals = cell(1,numel(lsplit_final_f));
                for uif = 1:numel(lsplit_final_f)
                    lsplit_final_ff = strsplit(lsplit_final_f{uif},'=');
                    fff{uif} = sprintf('%s_%s',ff,lsplit_final_ff{1});
                    vals{uif} = lsplit_final_ff{2};
                end
            else
                fff = {ff};
                vals = lsplit_final(2);
            end
            for uif = 1:numel(vals)
                val = vals{uif};
                if ~isempty(val) && ~isnan(str2double(val))
                    val = str2double(val);
                    struct_out.(fff{uif})(idn) = val;
                else
                    struct_out.(fff{uif}){idn} = val;
                end
            end
            catch
                fprintf('Could not parse line %s in IIP datagram\n',l_split{ill});
            end

        end
    end

end
end

function struct_out = decode_IOP(iop_txt,struct_in)

struct_out = struct_in;
idn = numel(struct_out.dgSize);

% initialize section name to empty
newSectionName = '';

% read runtime_txt, line by line
lines = strsplit(iop_txt,newline);
for iL = 1:length(lines)
    line = lines{iL};
    try
        if isempty(line)
            newSectionName = '';
        else
            isNewSection = ~contains(line,':') || strcmp(line, 'Water Column: On');
            if isNewSection
                newSectionName = regexprep(matlab.lang.makeValidName(line,'ReplacementStyle','delete'),'_','');
            else
                if strcmp(line,'Water Column: Off')
                    continue
                end
                idxSeparator = strfind(line,':');
                key = regexprep(matlab.lang.makeValidName(line(1:idxSeparator-1),'ReplacementStyle','delete'),'_','');
                val = strtrim(line(idxSeparator+2:end));
                if isempty(newSectionName)
                    fullKey = key;
                else
                    fullKey = [newSectionName '_' key];
                end
                iK = 1;
                while isfield(struct_out, fullKey) && ...
                        numel(struct_out.(fullKey)) >= idn && ...
                        ~isundefined(struct_out.(fullKey)(idn))
                    iK = iK+1;
                    fullKey = [newSectionName '_' key '_' num2str(iK)];
                end

                % store parameter in fData, with value as a categorical
                struct_out.(fullKey)(idn) = categorical({val});

            end
        end
    catch
        fprintf('Could not parse line %s in IOP datagram\n',line);
    end
end


end


function struct_out = read_MRZ(fid,struct_in)

struct_out  = struct_in;
idn = numel(struct_out.dgSize);

dg_ver = struct_out.dgmVersion(idn);
struct_out.numOfDgms(idn) = fread(fid,1,'uint16');
struct_out.dgmNum(idn) = fread(fid,1,'uint16');
struct_out.numBytesCmnPart(idn) = fread(fid,1,'uint16');
struct_out.pingCnt(idn) = fread(fid,1,'uint16');
struct_out.rxFansPerPing(idn) = fread(fid,1,'uint8');
struct_out.rxFanIndex(idn) = fread(fid,1,'uint8');
struct_out.swathsPerPing(idn) = fread(fid,1,'uint8');
struct_out.swathAlongPosition(idn) = fread(fid,1,'uint8');
struct_out.txTransducerInd(idn) = fread(fid,1,'uint8');
struct_out.rxTransducerInd(idn) = fread(fid,1,'uint8');
struct_out.numRxTransducers(idn) = fread(fid,1,'uint8');
struct_out.algorithmType(idn) = fread(fid,1,'uint8');
struct_out.numBytesInfoData(idn) = fread(fid,1,'uint16');
struct_out.padding0(idn) = fread(fid,1,'uint16');
struct_out.pingRate_Hz(idn) = fread(fid,1,'float');
struct_out.beamSpacing(idn) = fread(fid,1,'uint8');
struct_out.depthMode(idn) = fread(fid,1,'uint8');
struct_out.subDepthMode(idn) = fread(fid,1,'uint8');
struct_out.distanceBtwSwath(idn) = fread(fid,1,'uint8');
struct_out.detectionMode(idn) = fread(fid,1,'uint8');
struct_out.pulseForm(idn) = fread(fid,1,'uint8');
struct_out.padding1(idn) = fread(fid,1,'uint16');
struct_out.frequencyMode_Hz(idn) = fread(fid,1,'float');
struct_out.freqRangeLowLim_Hz(idn) = fread(fid,1,'float');
struct_out.freqRangeHighLim_Hz(idn) = fread(fid,1,'float');
struct_out.maxTotalTxPulseLength_sec(idn) = fread(fid,1,'float');
struct_out.maxEffTxPulseLength_sec(idn) = fread(fid,1,'float');
struct_out.maxEffTxBandWidth_Hz(idn) = fread(fid,1,'float');
struct_out.absCoeff_dBPerkm(idn) = fread(fid,1,'float');
struct_out.portSectorEdge_deg(idn) = fread(fid,1,'float');
struct_out.starbSectorEdge_deg(idn) = fread(fid,1,'float');
struct_out.portMeanCov_deg(idn) = fread(fid,1,'float');
struct_out.starbMeanCov_deg(idn) = fread(fid,1,'float');
struct_out.portMeanCov_m(idn) = fread(fid,1,'int16');
struct_out.starbMeanCov_m(idn) = fread(fid,1,'int16');
struct_out.modeAndStabilisation(idn) = fread(fid,1,'uint8');
struct_out.runtimeFilter1(idn) = fread(fid,1,'uint8');
struct_out.runtimeFilter2(idn) = fread(fid,1,'uint16');
struct_out.pipeTrackingStatus(idn) = fread(fid,1,'uint32');
struct_out.transmitArraySizeUsed_deg(idn) = fread(fid,1,'float');
struct_out.receiveArraySizeUsed_deg(idn) = fread(fid,1,'float');
struct_out.transmitPower_dB(idn) = fread(fid,1,'float');
struct_out.SLrampUpTimeRemaining(idn) = fread(fid,1,'uint16');
struct_out.padding2(idn) = fread(fid,1,'uint16');
struct_out.yawAngle_deg(idn) = fread(fid,1,'float');
struct_out.numTxSectors(idn) = fread(fid,1,'uint16');
struct_out.numBytesPerTxSector(idn) = fread(fid,1,'uint16');
struct_out.headingVessel_deg(idn) = fread(fid,1,'float');
struct_out.soundSpeedAtTxDepth_mPerSec(idn) = fread(fid,1,'float');
struct_out.txTransducerDepth_m(idn) = fread(fid,1,'float');
struct_out.z_waterLevelReRefPoint_m(idn) = fread(fid,1,'float');
struct_out.x_kmallToall_m(idn) = fread(fid,1,'float');
struct_out.y_kmallToall_m(idn) = fread(fid,1,'float');
struct_out.latLongInfo(idn) = fread(fid,1,'uint8');
struct_out.posSensorStatus(idn) = fread(fid,1,'uint8');
struct_out.attitudeSensorStatus(idn) = fread(fid,1,'uint8');

struct_out.padding3(idn) = fread(fid,1,'uint8');

struct_out.latitude_deg(idn) = fread(fid,1,'double');
struct_out.longitude_deg(idn) = fread(fid,1,'double');
struct_out.ellipsoidHeightReRefPoint_m(idn) = fread(fid,1,'float');

if dg_ver > 0
    struct_out.bsCorrectionOffset_dB(idn) = fread(fid,1,'float');
    struct_out.lambertsLawApplied(idn) = fread(fid,1,'uint8');
    struct_out.iceWindow(idn) = fread(fid,1,'uint8');

    if dg_ver == 1
        struct_out.padding4(idn) = fread(fid,1,'uint16');
    else
        struct_out.activeModes(idn) = fread(fid,1,'uint16');
    end

end

Ntx = struct_out.numTxSectors(idn);

for iTx = 1:Ntx
    struct_out.sectorInfo{idn}(iTx) = read_kem_MRZ_txSectorInfo(fid,dg_ver);
end

struct_out = read_kem_dg_MRZ_rxInfo(fid,struct_out);

Ndc = struct_out.numExtraDetectionClasses(idn);

for iD = 1:Ndc
    struct_out.extraDetClassInfo{idn}(iD) = read_kem_MRZ_extraDetClassInfo(fid);
end

Nrx = struct_out.numSoundingsMaxMain(idn);
Nd  = struct_out.numExtraDetections(idn);
struct_out.sounding{idn} = read_kem_dg_MRZ_sounding(fid, Nrx+Nd);

Ns = [struct_out.sounding{idn}.SInumSamples];
for iRx = 1:(Nrx+Nd)
    struct_out.SIsample_desidB{idn}{iRx} = fread(fid,Ns(iRx),'int16');
end

end

function struct_out = read_kem_MRZ_txSectorInfo(fid, dg_ver)
struct_out.txSectorNumb = fread(fid,1,'uint8');
struct_out.txArrNumber = fread(fid,1,'uint8');
struct_out.txSubArray = fread(fid,1,'uint8');
struct_out.padding0 = fread(fid,1,'uint8');
struct_out.sectorTransmitDelay_sec = fread(fid,1,'float');
struct_out.tiltAngleReTx_deg = fread(fid,1,'float');
struct_out.txNominalSourceLevel_dB = fread(fid,1,'float');
struct_out.txFocusRange_m = fread(fid,1,'float');
struct_out.centreFreq_Hz = fread(fid,1,'float');
struct_out.signalBandWidth_Hz = fread(fid,1,'float');
struct_out.totalSignalLength_sec = fread(fid,1,'float');

struct_out.pulseShading = fread(fid,1,'uint8');
struct_out.signalWaveForm = fread(fid,1,'uint8');
struct_out.padding1 = fread(fid,1,'uint16');

if dg_ver > 0
    struct_out.highVoltageLevel_dB = fread(fid,1,'float');
    struct_out.sectorTrackingCorr_dB = fread(fid,1,'float');
    struct_out.effectiveSignalLength_sec = fread(fid,1,'float');
end

end


function struct_out = read_kem_MRZ_extraDetClassInfo(fid)
struct_out.numExtraDetInClass = fread(fid,1,'uint16');
struct_out.padding = fread(fid,1,'int8');
struct_out.alarmFlag = fread(fid,1,'uint8');
end

function struct_out = read_kem_dg_MRZ_sounding(fid, N)
structSize = 120;
data = fread(fid,N.*structSize,'uint8=>uint8');
data = reshape(data, [structSize,N]);
struct_out.soundingIndex = typecast(reshape(data(1:2,:),1,[]),'uint16');
struct_out.txSectorNumb = data(3,:);
struct_out.detectionType = data(4,:);
struct_out.detectionMethod = data(5,:);
struct_out.detectionClass = data(9,:);
struct_out.detectionConfidenceLevel = data(10,:);
struct_out.rangeFactor = typecast(reshape(data(13:16,:),1,[]),'single');
struct_out.qualityFactor = typecast(reshape(data(17:20,:),1,[]),'single');
struct_out.detectionUncertaintyVer_m = typecast(reshape(data(21:24,:),1,[]),'single');
struct_out.detectionUncertaintyHor_m = typecast(reshape(data(25:28,:),1,[]),'single');
struct_out.detectionWindowLength_sec = typecast(reshape(data(29:32,:),1,[]),'single');
struct_out.echoLength_sec = typecast(reshape(data(33:36,:),1,[]),'single');
struct_out.WCBeamNumb = typecast(reshape(data(37:38,:),1,[]),'uint16');
struct_out.WCrange_samples = typecast(reshape(data(39:40,:),1,[]),'uint16');
struct_out.WCNomBeamAngleAcross_deg = typecast(reshape(data(41:44,:),1,[]),'single');
struct_out.meanAbsCoeff_dBPerkm = typecast(reshape(data(45:48,:),1,[]),'single');
struct_out.reflectivity1_dB = typecast(reshape(data(49:52,:),1,[]),'single');
struct_out.reflectivity2_dB = typecast(reshape(data(53:56,:),1,[]),'single');
struct_out.receiverSensitivityApplied_dB = typecast(reshape(data(57:60,:),1,[]),'single');
struct_out.sourceLevelApplied_dB = typecast(reshape(data(61:64,:),1,[]),'single');
struct_out.BScalibration_dB = typecast(reshape(data(65:68,:),1,[]),'single');
struct_out.TVG_dB = typecast(reshape(data(69:72,:),1,[]),'single');
struct_out.beamAngleReRx_deg = typecast(reshape(data(73:76,:),1,[]),'single');
struct_out.beamAngleCorrection_deg = typecast(reshape(data(77:80,:),1,[]),'single');
struct_out.twoWayTravelTime_sec = typecast(reshape(data(81:84,:),1,[]),'single');
struct_out.twoWayTravelTimeCorrection_sec = typecast(reshape(data(85:88,:),1,[]),'single');
struct_out.deltaLatitude_deg = typecast(reshape(data(89:92,:),1,[]),'single');
struct_out.deltaLongitude_deg = typecast(reshape(data(93:96,:),1,[]),'single');
struct_out.z_reRefPoint_m = typecast(reshape(data(97:100,:),1,[]),'single');
struct_out.y_reRefPoint_m = typecast(reshape(data(101:104,:),1,[]),'single');
struct_out.x_reRefPoint_m = typecast(reshape(data(105:108,:),1,[]),'single');
struct_out.beamIncAngleAdj_deg = typecast(reshape(data(109:112,:),1,[]),'single');
struct_out.realTimeCleanInfo = typecast(reshape(data(113:114,:),1,[]),'uint16');
struct_out.SIstartRange_samples = typecast(reshape(data(115:116,:),1,[]),'uint16');
struct_out.SIcentreSample = typecast(reshape(data(117:118,:),1,[]),'uint16');
struct_out.SInumSamples = typecast(reshape(data(119:120,:),1,[]),'uint16');
end

function struct_out = read_MWC(fid, struct_in)
struct_out  = struct_in;
idn = numel(struct_out.dgSize);

pifStartOfDatagram = ftell(fid);
pifEndOfDatagram = pifStartOfDatagram + struct_out.dgSize(idn) + 4;

dg_ver = struct_out.dgmVersion(idn);
struct_out.numOfDgms(idn) = fread(fid,1,'uint16');
struct_out.dgmNum(idn) = fread(fid,1,'uint16');
struct_out.numBytesCmnPart(idn) = fread(fid,1,'uint16');
struct_out.pingCnt(idn) = fread(fid,1,'uint16');
struct_out.rxFansPerPing(idn) = fread(fid,1,'uint8');
struct_out.rxFanIndex(idn) = fread(fid,1,'uint8');
struct_out.swathsPerPing(idn) = fread(fid,1,'uint8');
struct_out.swathAlongPosition(idn) = fread(fid,1,'uint8');
struct_out.txTransducerInd(idn) = fread(fid,1,'uint8');
struct_out.rxTransducerInd(idn) = fread(fid,1,'uint8');
struct_out.numRxTransducers(idn) = fread(fid,1,'uint8');
struct_out.algorithmType(idn) = fread(fid,1,'uint8');

struct_out    = read_kem_dg_MWCtxInfo(fid,struct_out);

Ntx = struct_out.numTxSectors(idn);
for iTx = 1:Ntx
    struct_out.sectorData{idn}(iTx) = read_kem_dg_MWCtxSectorData(fid);
end

struct_out = read_kem_dg_MWCrxInfo(fid,struct_out);

% Pointer to beam related information. Struct defines information about
% data for a beam. Beam information is followed by sample amplitudes in
% 0.5 dB resolution . Amplitude array is followed by phase information
% if phaseFlag >0. These data defined by struct
% EMdgmMWCrxBeamPhase1_def (read_int8_t) or struct EMdgmMWCrxBeamPhase2_def
% (int16_t) if indicated in the field phaseFlag in struct
% EMdgmMWCrxInfo_def.
% Lenght of data block for each beam depends on the operators choise of
% phase information (see table).
% phaseFlag 	Beam block size
% 0             numBytesPerBeamEntry + numSampleData* size(sampleAmplitude05dB_p)
% 1             numBytesPerBeamEntry + numSampleData* size(sampleAmplitude05dB_p) + numSampleData* size(EMdgmMWCrxBeamPhase1_def)
% 2             numBytesPerBeamEntry + numSampleData* size(sampleAmplitude05dB_p) + numSampleData* size(EMdgmMWCrxBeamPhase2_def)
phaseFlag = struct_out.phaseFlag(idn);
Nrx = struct_out.numBeams(idn);
struct_out = read_kem_dg_MWCrxBeamData(fid, struct_out,phaseFlag, Nrx, dg_ver, pifEndOfDatagram);
end


function struct_out = read_kem_dg_MWCtxInfo(fid,struct_in)
struct_out  = struct_in;
idn = numel(struct_out.dgSize);

struct_out.numBytesTxInfo(idn) = fread(fid,1,'uint16');
struct_out.numTxSectors(idn) = fread(fid,1,'uint16');
struct_out.numBytesPerTxSector(idn) = fread(fid,1,'uint16');
struct_out.padding(idn) = fread(fid,1,'int16');
struct_out.heave_m(idn) = fread(fid,1,'float');

end


function struct_out = read_kem_dg_MWCtxSectorData(fid)
struct_out.tiltAngleReTx_deg = fread(fid,1,'float');
struct_out.centreFreq_Hz = fread(fid,1,'float');
struct_out.txBeamWidthAlong_deg = fread(fid,1,'float');
struct_out.txSectorNum = fread(fid,1,'uint16');
struct_out.padding = fread(fid,1,'int16');
end


function struct_out = read_kem_dg_MWCrxInfo(fid,struct_in)
struct_out  = struct_in;
idn = numel(struct_out.dgSize);

struct_out.numBytesRxInfo(idn) = fread(fid,1,'uint16');
struct_out.numBeams(idn) = fread(fid,1,'uint16');
struct_out.numBytesPerBeamEntry(idn) = fread(fid,1,'uint8');
struct_out.phaseFlag(idn) = fread(fid,1,'uint8');
struct_out.TVGfunctionApplied(idn) = fread(fid,1,'uint8');
struct_out.TVGoffset_dB(idn) = fread(fid,1,'int8');
struct_out.sampleFreq_Hz(idn) = fread(fid,1,'float');
struct_out.soundVelocity_mPerSec(idn) = fread(fid,1,'float');
end

function struct_out = read_kem_dg_MRZ_rxInfo(fid,struct_in)
struct_out  = struct_in;
idn = numel(struct_out.dgSize);

struct_out.numBytesRxInfo(idn) = fread(fid,1,'uint16');
struct_out.numSoundingsMaxMain(idn) = fread(fid,1,'uint16');
struct_out.numSoundingsValidMain(idn) = fread(fid,1,'uint16');
struct_out.numBytesPerSounding(idn) = fread(fid,1,'uint16');
struct_out.WCSampleRate(idn) = fread(fid,1,'float');
struct_out.seabedImageSampleRate(idn) = fread(fid,1,'float');
struct_out.BSnormal_dB(idn) = fread(fid,1,'float');
struct_out.BSoblique_dB(idn) = fread(fid,1,'float');
struct_out.extraDetectionAlarmFlag(idn) = fread(fid,1,'uint16');
struct_out.numExtraDetections(idn) = fread(fid,1,'uint16');
struct_out.numExtraDetectionClasses(idn) = fread(fid,1,'uint16');
struct_out.numBytesPerClass(idn) = fread(fid,1,'uint16');
end


function struct_out = read_kem_dg_MWCrxBeamData(fid,struct_in, phaseFlag, Nrx, dg_ver, pifEndOfDatagram)
struct_out  = struct_in;
idn = numel(struct_out.dgSize);


struct_tmp = struct(...
    'beamPointAngReVertical_deg',nan(1,Nrx),...
    'startRangeSampleNum',nan(1,Nrx),...
    'detectedRangeInSamples',nan(1,Nrx),...
    'beamTxSectorNum',nan(1,Nrx),...
    'numSampleData',nan(1,Nrx),...
    'detectedRangeInSamplesHighResolution',nan(1,Nrx),...
    'sampleDataPositionInFile',nan(1,Nrx));

for iRx = 1:Nrx

    struct_tmp.beamPointAngReVertical_deg(iRx) = fread(fid,1,'float');

    struct_tmp.startRangeSampleNum(iRx) = fread(fid,1,'uint16');
    struct_tmp.detectedRangeInSamples(iRx) = fread(fid,1,'uint16');

    struct_tmp.beamTxSectorNum(iRx) = fread(fid,1,'uint16');
    struct_tmp.numSampleData(iRx) = fread(fid,1,'uint16');

    if dg_ver >= 1
        struct_tmp.detectedRangeInSamplesHighResolution(iRx) = fread(fid,1,'float');
    end

    pif = ftell(fid);
    struct_tmp.sampleDataPositionInFile(iRx) = pif;

    Ns = struct_tmp.numSampleData(iRx);

    dataBlockSizeInBytes = Ns.*(1+phaseFlag);

    if pifEndOfDatagram-(pif+dataBlockSizeInBytes) >= 0
        fseek(fid,dataBlockSizeInBytes,0);
    else
        break
    end
end

ff = fieldnames(struct_tmp);

for uif = 1:numel(ff)
    struct_out.(ff{uif}){idn} = struct_tmp.(ff{uif});
end

end

function struct_out = read_SPO(fid, struct_in)

struct_out  = struct_in;
idn = numel(struct_out.dgSize);

struct_out.numBytesCmnPart(idn) = fread(fid,1,'uint16');
struct_out.SensorSystemNumber(idn) = fread(fid,1,'uint16');

tmp = fread(fid,1,'uint16');
dataBin = dec2bin(reshape(tmp,[],1), 16);
struct_out.activeSensor(idn) = bin2dec(dataBin(:,end));
struct_out.dataQuality(idn) = categorical(bin2dec(dataBin(:,end-2)),[0,1],{'Data OK','Reduced Performance'});
struct_out.dataValidity(idn) = categorical(bin2dec(dataBin(:,end-4)),[0,1],{'Data OK','Invalid data'});
struct_out.velocitySource(idn) = categorical(bin2dec(dataBin(:,end-6)),[0,1],{'Velocity from sensor','Velocity calculated by PU'});
struct_out.timeSource(idn) = categorical(bin2dec(dataBin(:,end-9)),[0,1],{'Time from PU used (system)','Time from datagram used'});
struct_out.motionCorrection(idn) = categorical(bin2dec(dataBin(:,end-10)),[0,1],{'No motion correction','With motion correction'});
struct_out.qualityCheck(idn) = categorical(bin2dec(dataBin(:,end-11)),[0,1],{'Normal quality check','Operator quality check. Data always valid'});

struct_out.padding(idn) = fread(fid,1,'uint16');

SPO_data_numBytes = (struct_out.dgSize(idn) - 4) ...
    - 20 ...
    - struct_out.numBytesCmnPart(idn) ...
    - 40;


t_sec = fread(fid,1,'uint32');
t_nanosec = fread(fid,1,'uint32');
struct_out.timeFromSensor(idn) = datenum(datetime(t_sec + t_nanosec.*10^-9,'ConvertFrom','posixtime'));
struct_out.posFixQuality_m(idn) = fread(fid,1,'float');
struct_out.correctedLat_deg(idn) = fread(fid,1,'double');
struct_out.correctedLong_deg(idn) = fread(fid,1,'double');
struct_out.speedOverGround_mPerSec(idn) = fread(fid,1,'float');
struct_out.courseOverGround_deg(idn) = fread(fid,1,'float');
struct_out.ellipsoidHeightReRefPoint_m(idn) = fread(fid,1,'float');
struct_out.posDataFromSensor{idn} = fscanf(fid, '%c', SPO_data_numBytes);
end

function out_struct = read_EMdgmSVP(fid, dgmVersion_warning_flag)
%read_EMDGMSVP  Read kmall structure #SVP
%
%   #SVP - Sound Velocity Profile. Data from sound velocity profile or from
%   CTD profile. Sound velocity is measured directly or estimated,
%   respectively.
%
%   Verified correct for kmall format revisions F-I
%
%   See also read_KMALL_FROM_FILEINFO.

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

out_struct.header = read_EMdgmHeader(fid);

SVP_VERSION = out_struct.header.dgmVersion;
if SVP_VERSION~=1 && dgmVersion_warning_flag
    % definitions in this function and subfunctions valid for SVP_VERSION:
    % 1 (kmall format revisions F-I)
    warning('#SVP datagram version (%i) unsupported. Continue reading but there may be issues.',SVP_VERSION);
end

% Size in bytes of body part struct. Used for denoting size of rest of
% the datagram.
out_struct.numBytesCmnPart = fread(fid,1,'uint16');

% Number of sound velocity samples.
out_struct.numSamples = fread(fid,1,'uint16');

% Sound velocity profile format:
% 'S00' = sound velocity profile
% 'S01' = CTD profile
out_struct.sensorFormat = fscanf(fid,'%c',4);

% Time extracted from the Sound Velocity Profile. Parameter is set to
% zero if not found.
out_struct.time_sec = fread(fid,1,'uint32');

% Latitude in degrees. Negative if southern hemisphere. Position
% extracted from the Sound Velocity Profile. Parameter is set to define
% UNAVAILABLE_LATITUDE if not available.
out_struct.latitude_deg = fread(fid,1,'double');

% Longitude in degrees. Negative if western hemisphere. Position
% extracted from the Sound Velocity Profile. Parameter is set to define
% UNAVAILABLE_LONGITUDE if not available.
out_struct.longitude_deg = fread(fid,1,'double');

% SVP point samples, repeated numSamples times.
for iS = 1:out_struct.numSamples
    out_struct.sensorData(iS) = read_EMdgmSVPpoint(fid);
end

end


function struct_out = read_SVP(fid,struct_in)

struct_out =struct_in;
idn = numel(struct_in.dgSize);

struct_out.depth_m(idn) = fread(fid,1,'float');

struct_out.soundVelocity_mPerSec(idn) = fread(fid,1,'float');

struct_out.padding(idn) = fread(fid,1,'uint32');
struct_out.temp_C(idn) = fread(fid,1,'float');
struct_out.salinity(idn) = fread(fid,1,'float');

end



function struct_out = read_SKM(fid, struct_in)
struct_out =struct_in;
idn = numel(struct_in.dgSize);
struct_out.numBytesInfoPart(idn) = fread(fid,1,'uint16');
struct_out.sensorSystem(idn) = fread(fid,1,'uint8');
struct_out.sensorStatus(idn) = fread(fid,1,'uint8');
struct_out.sensorInputFormat(idn) = fread(fid,1,'uint16');
struct_out.numSamplesArray(idn) = fread(fid,1,'uint16');
struct_out.numBytesPerSample(idn) = fread(fid,1,'uint16');
struct_out.sensorDataContents(idn) = fread(fid,1,'uint16');

Nsamp = struct_out.numSamplesArray(idn);

for iS = 1:Nsamp
    struct_out.sample{idn}(iS) = read_EMdgmSKMsample_def(fid);
end

end



function out_struct = read_EMdgmSKMsample_def(fid)
out_struct.dgmType = fscanf(fid,'%c',4);
out_struct.numBytesDgm = fread(fid,1,'uint16');
out_struct.dgmVersion = fread(fid,1,'uint16');
t_sec = fread(fid,1,'uint32');
t_nanosec = fread(fid,1,'uint32');
out_struct.time = datenum(datetime(t_sec + t_nanosec.*10^-9,'ConvertFrom','posixtime'));
out_struct.status = fread(fid,1,'uint32');
out_struct.latitude_deg = fread(fid,1,'double');
out_struct.longitude_deg = fread(fid,1,'double');
out_struct.ellipsoidHeight_m = fread(fid,1,'float');
out_struct.roll_deg = fread(fid,1,'float');
out_struct.pitch_deg = fread(fid,1,'float');
out_struct.heading_deg = fread(fid,1,'float');
out_struct.heave_m = fread(fid,1,'float');
out_struct.rollRate = fread(fid,1,'float');
out_struct.pitchRate = fread(fid,1,'float');
out_struct.yawRate = fread(fid,1,'float');
out_struct.velNorth = fread(fid,1,'float');
out_struct.velEast = fread(fid,1,'float');
out_struct.velDown = fread(fid,1,'float');
out_struct.latitudeError_m = fread(fid,1,'float');
out_struct.longitudeError_m = fread(fid,1,'float');
out_struct.ellipsoidHeightError_m = fread(fid,1,'float');
out_struct.rollError_deg = fread(fid,1,'float');
out_struct.pitchError_deg = fread(fid,1,'float');
out_struct.headingError_deg = fread(fid,1,'float');
out_struct.heaveError_m = fread(fid,1,'float');
out_struct.northAcceleration = fread(fid,1,'float');
out_struct.eastAcceleration = fread(fid,1,'float');
out_struct.downAcceleration = fread(fid,1,'float');
out_struct.time_sec = fread(fid,1,'uint32');
out_struct.time_nanosec = fread(fid,1,'uint32');
out_struct.delayedHeave_m = fread(fid,1,'float');

end








