function [layers,id_rem] = open_sl_file_stdalone(Filename_cell,varargin)
id_rem = [];
layers = layer_cl.empty();

p = inputParser;

if ~iscell(Filename_cell)
    Filename_cell = {Filename_cell};
end

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
addParameter(p,'Frequencies',[]);
addParameter(p,'Channels',{});
addParameter(p,'GPSOnly',def_gps_only_val);
addParameter(p,'load_bar_comp',[]);

parse(p,Filename_cell,varargin{:});

nb_files = numel(Filename_cell);
load_bar_comp = p.Results.load_bar_comp;

if ~isempty(load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_files,'Value',0);
end

layers = [];
id_rem = [];

% KNOTS_KMH = 1.85200;
% EARTH_RADIUS = 6356752.3142;
% FEET_CONVERSION = 0.3048;
%
% ilay  = 0;

force_read = false;

for uif = 1:nb_files
    
    if ~isempty(load_bar_comp)
        str_disp=sprintf('Opening File %d/%d : %s',uif,nb_files,Filename_cell{uif});
        load_bar_comp.progress_bar.setText(str_disp);
    end
    
    Filename = Filename_cell{uif};
    if ~isfile(Filename)
        id_rem = union(id_rem,uif);
        continue;
    end
    
    s=dir(Filename);
    f_size_bytes=s.bytes;
    
    fid=fopen(Filename,'r','l');
    
    header_struct = read_sl_header(fid);
    fprintf(1,'Format: sl%d\nVersion: %d\nFramesize: %d\n',header_struct.format,header_struct.version,header_struct.framesize);
    
    iframe = 1;
    
    [path_f,fileN] = fileparts(Filename);
    echo_folder = get_esp3_file_folder(path_f,true);

    fileStruct = fullfile(echo_folder,[fileN '_sl_struct.mat']);
    
    force_read = force_read && ~isdeployed();
    
    has_been_read = false;
    SL_data_struct = [];
    
    if isfile(fileStruct)&&~force_read
        s_out = load(fileStruct);
        SL_data_struct = s_out.SL_data_struct;
        if strcmpi(SL_data_struct.SL_struct_version,get_curr_SL_struct_version())
            has_been_read = true;
        else
            SL_data_struct = [];
        end
    end
    
    if ~has_been_read || force_read
        if ~isempty(load_bar_comp)
            str_disp=sprintf('Indexing File %s', Filename);
            load_bar_comp.progress_bar.setText(str_disp);
        end
        while  ~feof(fid)
            fpos = ftell(fid);
            if ~isempty(load_bar_comp)
                set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',f_size_bytes,'Value',fpos);
            end
            
            try
                
                switch header_struct.format
                    case 1
                        close(fid);
                        return;
                        %read_sl1_frame_header(fid,header_struct.version,header_struct.framesize);
                    case {2,3}
                        %header_length = 168;
                        [SL_data_struct,fsize] = read_slg_frame_header(fid,SL_data_struct,header_struct.format,header_struct.version,header_struct.framesize);
                        
                end
                fseek(fid,fpos+fsize,'bof');
                
                if fsize <= 0
                    break;
                end
                
                if isempty(SL_data_struct)||numel(SL_data_struct.header_length)==iframe-1
                    continue;
                end
                
                SL_data_struct.frame_data_pos(iframe) = fpos+SL_data_struct.header_length(iframe);
                
                iframe = numel(SL_data_struct.header_length)+1;
            catch err
                if ~feof(fid)
                    disp('Error reading SL frame');
                    print_errors_and_warnings([],'error',err);
                end
            end
        end
        SL_data_struct.chan_type = cellfun(@get_channel_type,num2cell(SL_data_struct.chan_type_id),'UniformOutput',0);
        [SL_data_struct.freq_min,SL_data_struct.freq_max] = arrayfun(@get_freq_range,SL_data_struct.freq_id);
        
        SL_data_struct.SL_struct_version = get_curr_SL_struct_version;
        save(fileStruct,'SL_data_struct');
    end
    
    fclose(fid);
    
    soundspeed = 1500;
    
    dr =(SL_data_struct.range_max-SL_data_struct.range_min)./SL_data_struct.packetsize;
    dt = 2*dr/soundspeed;
    
    SL_data_struct.sampling_frequency = 1./dt;
    
    [channels_types,~] = unique(string(SL_data_struct.chan_type),'stable');
    non_valid_channels = ["Secondary (Traditional Sonar)" "invalid" "Debug Digital" "Debug Noise" "3D" "Composite (Sidescan)" "Right (Sidescan)" "Left (Sidescan)"];
    channels_types(ismember(channels_types,non_valid_channels)) = [];
    idx_valid = find(ismember(string(SL_data_struct.chan_type),channels_types));
    idx_valid(idx_valid>numel(SL_data_struct.frame_data_pos)) = [];
    data_tot = [];
    nb_pings = zeros(1,numel(channels_types));
    nb_samples = zeros(1,numel(channels_types));
    r_min = zeros(1,numel(channels_types));
    fs_max = zeros(1,numel(channels_types));
    dr_min = zeros(1,numel(channels_types));
    r_chan = cell(1,numel(channels_types));
    
    trans_obj=transceiver_cl.empty();
    
    env_data_obj = env_data_cl('Temperature',mean(SL_data_struct.temperature(idx_valid)),'SoundSpeed',soundspeed);
    gps_data = gps_data_cl.empty();

    if SL_data_struct.posixTime(1) == -1
        dlg_perso([],'warning',sprintf('No time reference for file %s',fileN));
        SL_data_struct.posixTime(:) = 0;
    end
    SL_data_struct.timeOffset(SL_data_struct.timeOffset>1e8) = nan;
    chan_names = cellfun(@matlab.lang.makeValidName,channels_types,'un',0);
    idx_chan = cell(1,numel(channels_types));
    for uic = 1:numel(channels_types)
        idx_chan{uic} = find(string(SL_data_struct.chan_type) == channels_types(uic)&~isnan(dr)&~isinf(dr));
        nb_pings(uic) = numel(idx_chan{uic});
    end

    id_1 = nb_pings ==1;
    channels_types(id_1) = [];
    nb_pings(id_1) = [];
    idx_chan(id_1) = [];

    if isempty(nb_pings)
        id_rem = union(id_rem,uif);
        continue;
    end
    idx_chan_tot = idx_chan;
    for uic = 1:numel(channels_types)
        
        idx_chan = idx_chan_tot{uic};
        nb_pings(uic) = numel(idx_chan);

        data_tot.(chan_names{uic}) = [];
        fs_max(uic) = max(SL_data_struct.sampling_frequency(idx_chan));
        dr_min(uic) = min(dr(idx_chan));
        r_min(uic) = min(SL_data_struct.range_min(idx_chan));
        nb_samples(uic) = ceil((max(SL_data_struct.range_max(idx_chan))-min(SL_data_struct.range_min(idx_chan)))/dr_min(uic));
        data_tot.(chan_names{uic}) = zeros(nb_samples(uic),nb_pings(uic),'uint8');
        r_chan{uic} = (r_min(uic)+(0:nb_samples(uic)-1)*dr_min(uic))';
        [~,curr_filename,~]=fileparts(tempname);
        curr_data_name_t=fullfile(p.Results.PathToMemmap,curr_filename,'ac_data');
        
        ac_data_chan = ac_data_cl('SubData',[],...
            'Nb_samples', nb_samples(uic),...
            'Nb_pings',   nb_pings(uic),...
            'Nb_beams',   1,...
            'MemapName',  curr_data_name_t);
        
        
        params_obj = params_cl(nb_pings(uic),1);
        params_obj.BeamAngleAlongship=zeros(1,nb_pings(uic));
        params_obj.BeamAngleAthwartship=zeros(1,nb_pings(uic));
        
        params_obj.SampleInterval=ones(1,nb_pings(uic))*1/fs_max(uic);
        params_obj.PulseLength=ones(1,nb_pings(uic))*mean(params_obj.SampleInterval,'all','omitnan')*10;
        params_obj.TransmitPower=10*ones(1,nb_pings(uic));
        params_obj.Frequency = 1/2*(SL_data_struct.freq_min(idx_chan)+SL_data_struct.freq_max(idx_chan));
        params_obj.FrequencyStart = SL_data_struct.freq_min(idx_chan);
        params_obj.FrequencyEnd = SL_data_struct.freq_max(idx_chan);
        
        config_obj = config_cl();
        config_obj.Frequency = mean(params_obj.Frequency,'omitnan');
        config_obj.FrequencyMinimum = mean(params_obj.FrequencyStart,'omitnan');
        config_obj.FrequencyMaximum = mean(params_obj.FrequencyEnd,'omitnan');
        config_obj.SerialNumber = sprintf('SL_%s_%.0fkHz_%.0f',channels_types(uic),config_obj.Frequency/1e3,uic);
        config_obj.ChannelID = sprintf('SL_%s_%.0fkHz',channels_types(uic),config_obj.Frequency/1e3);
        config_obj.TransceiverName = sprintf('SL_%s_%.0fkHz',channels_types(uic),config_obj.Frequency/1e3);
        config_obj.TransducerName = sprintf('SL_%s_%.0fkHz',channels_types(uic),config_obj.Frequency/1e3);
        config_obj.TransceiverType = 'SL??';
        config_obj.ChannelNumber = uic;
        
        config_obj.BeamWidthAlongship = 20;%????Not likely but placeholder
        config_obj.BeamWidthAthwartship = 20;%????Not likely but placeholder
        [~,config_obj.BeamType] = get_channel_type(SL_data_struct.chan_type_id(idx_chan(1)));
        
        ac_data_chan.init_sub_data('img_intensity','DefaultValue',0);
        
        t_off = SL_data_struct.timeOffset(idx_chan);
        if isnan(t_off(1))
            t_off(1) = 0;
        end
        
        t0 = SL_data_struct.posixTime(idx_chan(1));

        if t0 == 0
            t0 = SL_data_struct.posixTime(1);
        end

        tmp_time =  datenum(datetime(t0, 'ConvertFrom', 'posixtime'))+t_off/1e3/(24*60*60);
        idx_fine = [true diff(tmp_time)>0];

        tmp_time(~idx_fine) = nan;

        tmp_time = fillmissing(tmp_time,'linear');

        dt = diff(tmp_time);

        if ~all(dt>0)
            print_errors_and_warnings([],'warning',sprintf('Issue reading time for channel %s in file %s',channels_types(uic),fileN));
            tmp_time = datenum(datetime(t0, 'ConvertFrom', 'posixtime'))+(0:(nb_pings(uic)-1))/(24*60*60);%TEMP FIX issue with timestamps
        end
        
        gps_data(uic) = gps_data_cl('Time',tmp_time,'Lat',SL_data_struct.lat(idx_chan),'Long',SL_data_struct.long(idx_chan),'Speed',SL_data_struct.gps_speed_knots(idx_chan));
        trans_obj(uic)=transceiver_cl('Data',ac_data_chan,...
            'Ping_offset',0,...
            'Sample_offset',max(floor(r_min(uic)/dr_min(uic)),0),...
            'Time',tmp_time,...
            'Config',config_obj,...
            'Params',params_obj);

        bot_idx = floor(SL_data_struct.depth(idx_chan)./dr_min(uic));
        bot_idx(bot_idx<=1) = nan;

         trans_obj(uic).Bottom = bottom_cl('Origin','Sounder',...
            'Sample_idx',bot_idx);
        
        trans_obj(uic).Config.SounderType = sprintf('Recreational Echo-Sounder: %s',channels_types(uic));
        [~,range_t]=trans_obj(uic).compute_soundspeed_and_range(env_data_obj);
        trans_obj(uic).set_transceiver_range(range_t);
        trans_obj(uic).set_absorption(env_data_obj);
    end
    
    fid=fopen(Filename,'r','l');
    if ~isempty(load_bar_comp)
        str_disp=sprintf('Opening File %s', Filename);
        load_bar_comp.progress_bar.setText(str_disp);
    end
   
    
    [chan_type_unique,~,ic] = unique(SL_data_struct.chan_type);

    chan_type_name = cell(1,numel(SL_data_struct.chan_type));

    for uic = 1:numel(chan_type_unique)
        chan_type_name(uic == ic) = {matlab.lang.makeValidName(chan_type_unique{uic})};
    end

    idx_ping = zeros(1,numel(channels_types));
    idx_ping_tmp = zeros(1,numel(channels_types));
    r_ref = cell(1,numel(chan_type_unique));
    b_size = 1e9;
    for iframe = idx_valid
        if ~isempty(load_bar_comp)
            set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(SL_data_struct.frame_data_pos),'Value',iframe);
        end
        
        try
            id_chan = find(channels_types == SL_data_struct.chan_type{iframe});

            if isempty(id_chan)
                continue;
            end
            fseek(fid,SL_data_struct.frame_data_pos(iframe),'bof');
            tmp = fread(fid,SL_data_struct.packetsize(iframe),'uint8=>uint8');
            r_frame = (SL_data_struct.range_min(iframe)+(0:numel(tmp)-1)*dr(iframe))';

            idx_ping(id_chan) = idx_ping(id_chan)+1;
            
            if idx_ping(id_chan) ==1
                 r_ref{id_chan} = r_frame;
            end

            idx_ping_tmp(id_chan) = idx_ping_tmp(id_chan)+1;
            
            if numel(r_ref{id_chan}) ~= numel(r_frame) || ...
                    ~all(r_ref{id_chan} == r_frame) || ...
                    idx_ping(id_chan) == nb_pings(id_chan) ||...
                    idx_ping_tmp(id_chan)*numel(r_chan{id_chan})> b_size

                idx_r = find(r_chan{id_chan}>=min(r_ref{id_chan}) & r_chan{id_chan}<=max(r_ref{id_chan}));

                tmp_2 = interp1(r_ref{id_chan},single(data_tmp.(chan_type_name{iframe})),r_chan{id_chan}(idx_r),'cubic');         
                
                idx_r = idx_r(1:size(tmp_2,1));

                data_tot.(chan_type_name{iframe})(idx_r,(idx_ping(id_chan)-size(tmp_2,2)):idx_ping(id_chan)-1) = uint8(tmp_2);
                data_tmp.(chan_type_name{iframe})=[];
                idx_ping_tmp(id_chan) = 1;
                r_ref{id_chan} = r_frame;
            end

            data_tmp.(chan_type_name{iframe})(:,idx_ping_tmp(id_chan)) = tmp;
        catch err
            fprintf('Error reading SL dataframe in file %s, channel %s\n',fileN,(chan_type_name{iframe}));
            print_errors_and_warnings([],'error',err);
        end
    end
    fclose (fid);


    for uic  =1:numel(channels_types)
        trans_obj(uic).Data.replace_sub_data_v2(data_tot.(chan_names{uic}),'img_intensity');
    end
    [~,idx_ping_max] = max(nb_pings);
    lay_temp=layer_cl('Filename',{Filename},'Filetype','SLG',...
        'GPSData',gps_data(idx_ping_max),...
        'Transceivers',trans_obj,...
        'EnvData',env_data_obj);
    layers =[layers lay_temp];
    
end
end

function [chan_type,sonar_type] = get_channel_type(chan_type_id)
sonar_type = '';
switch chan_type_id
    case 0
        chan_type = 'Primary (Traditional Sonar)';
        sonar_type = 'single-beam';
    case 1
        chan_type = 'Secondary (Traditional Sonar)';
        sonar_type = 'single-beam';
    case 2
        chan_type = 'DSI (Downscan imaging)';
        sonar_type = 'single-beam';
    case 3
        chan_type = 'Left (Sidescan)';
        sonar_type = 'side-scan';
    case 4
        chan_type = 'Right (Sidescan)';
        sonar_type = 'side-scan';
    case 5
        chan_type = 'Composite (Sidescan)';
        sonar_type = 'side-scan';
    case 9
        chan_type = '3D';
    case 10
        chan_type = 'Debug Digital';
    case 11
        chan_type = 'Debug Noise';
    otherwise
        chan_type = 'invalid';
end
end

function  [f_min,f_max] = get_freq_range(freqID)
f_max =0;
switch freqID
    case 0
        f_min = 200*1e3;
    case 1
        f_min = 50*1e3;
    case 2
        f_min = 83*1e3;
    case 3
        f_min = 455*1e3;
    case 4
        f_min = 800*1e3;
    case 5
        f_min = 38*1e3;
    case 6
        f_min = 28*1e3;
    case 7
        f_min = 130*1e3;
        f_max = 210*1e3;
    case 8
        f_min = 90*1e3;
        f_max = 150*1e3;
    case 9
        f_min = 40*1e3;
        f_max = 60*1e3;
    case 10
        f_min = 25*1e3;
        f_max = 45*1e3;
    otherwise
        f_min = 200*1e3;
end

if f_max ==0
    f_max = f_min;
end
end
