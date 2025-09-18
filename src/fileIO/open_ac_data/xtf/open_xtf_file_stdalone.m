function [layers,id_rem] = open_xtf_file_stdalone(Filename_cell,varargin)
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

ilay  = 0;
for uu = 1:nb_files
    
    if ~isempty(load_bar_comp)
        str_disp=sprintf('Opening File %d/%d : %s',uu,nb_files,Filename_cell{uu});
        load_bar_comp.progress_bar.setText(str_disp);
    end
    
    Filename = Filename_cell{uu};
    if ~isfile(Filename)
        id_rem = union(id_rem,uu);
        continue;
    end
    
    
    s=dir(Filename);
    f_size_bytes=s.bytes;
    
    fid=fopen(Filename,'r');
    
    xtf_file_header = read_xtf_file_header(fid);
    
    nb_chan  = xtf_file_header.NumberOfSonarChannels;
    ip  =zeros(1,nb_chan);
    while  ~feof(fid)
        
        if ~isempty(load_bar_comp)
            fpos = ftell(fid);
            set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',f_size_bytes,'Value',fpos);
        end
        pos = ftell(fid);
        common_head_struct = read_dg_header(fid);
        
        if isempty(common_head_struct.HeaderType)||~common_head_struct.MagicNumber == hex2dec('FACE')
            break;
        end
        
        switch common_head_struct.HeaderType
            case 'XTF_HEADER_SONAR'
                xtf_ping_data_tmp  = read_xtf_ping_header(fid);
                
                
                for it =1:common_head_struct.NumberOfChansToFollow
                    
                    xtf_ping_data_tmp_2  = read_xtf_ping_chan_header(fid,xtf_ping_data_tmp);
                    id_chan = find([xtf_file_header.ChanInfo(:).SubChannelNumber] == xtf_ping_data_tmp_2.ChannelNumber,1);
                    fmt = 'uint8';
                    switch xtf_file_header.ChanInfo(id_chan).BytesPerSample
                        case 1
                            fmt = 'uint8';
                        case 2
                            fmt = 'uint16';
                    end
                    
                    ip(id_chan) = ip(id_chan)+1;
                    data{id_chan,ip(id_chan)} = fread(fid,xtf_ping_data_tmp_2.NumSamples,fmt);
                    xtf_ping_data{id_chan,ip(id_chan)} = xtf_ping_data_tmp_2;
                    
                end
                %case 'XTF_HEADER_BATHY'
            otherwise
                if ~isempty(common_head_struct.NumBytesThisRecord)
                    fseek(fid,pos+common_head_struct.NumBytesThisRecord,'bof');
                end
        end
    end
    
    env_data_obj = env_data_cl();
    trans_obj = [];
    for it = 1:numel(ip)
        id_chan = find([xtf_file_header.ChanInfo(:).SubChannelNumber] == xtf_ping_data{it,1}.ChannelNumber,1);
        ping_data = [xtf_ping_data{it,:}];
        data_t=cell2mat(data(it,:));
        chaninfo = xtf_file_header.ChanInfo(id_chan);
        [~,curr_filename,~]=fileparts(tempname);
        curr_data_name_t=fullfile(p.Results.PathToMemmap,curr_filename,'ac_data');
        [nb_samples,nb_pings]  = size(data_t);
        ac_data_temp = ac_data_cl('SubData',[],...
            'Nb_samples', nb_samples,...
            'Nb_pings',   nb_pings,...
            'MemapName',  curr_data_name_t);
        config_obj = config_cl();
        config_obj.SerialNumber = deblank(sprintf('%s_%s_%s_%s',xtf_file_header.SonarName,xtf_file_header.SonarType,chaninfo.TypeOfChannel,chaninfo.SubChannelNumber));
        config_obj.ChannelID = deblank(sprintf('%s_%s_%s_%s',xtf_file_header.SonarName,xtf_file_header.SonarType,chaninfo.TypeOfChannel,chaninfo.SubChannelNumber));
        config_obj.TransceiverName = xtf_file_header.SonarName;
        config_obj.TransducerName = xtf_file_header.SonarName;
        switch chaninfo.TypeOfChannel
            case {'PORT' 'STBD'}
                config_obj.TransceiverType = 'Side-scan sonar';
                config_obj.SounderType = 'Side-scan sonar';
        end
        config_obj.ChannelNumber = chaninfo.SubChannelNumber;
              
        config_obj.Frequency = ping_data(1).Frequency;
        config_obj.FrequencyMinimum = ping_data(1).Frequency;
        config_obj.FrequencyMaximum = ping_data(1).Frequency;
        
        config_obj.BeamWidthAlongship = 0.5;
        config_obj.BeamWidthAthwartship = chaninfo.BeamWidth;
        
        config_obj.BeamType = 'single-beam';%single beam (in each of the beams)
        params_obj = params_cl(nb_pings,1);
        
        params_obj.BeamAngleAlongship=zeros(1,nb_pings);
        params_obj.BeamAngleAthwartship=zeros(1,nb_pings);
        
        params_obj.SampleInterval=[ping_data(:).TimeDuration]/nb_samples;
        params_obj.PulseLength=ones(1,nb_pings)*10*mean(params_obj.SampleInterval,'all');
        params_obj.TransmitPower=10*ones(1,nb_pings);
        params_obj.Frequency = [ping_data(:).Frequency];
        params_obj.FrequencyStart = [ping_data(:).Frequency];
        params_obj.FrequencyEnd = [ping_data(:).Frequency];
        time_f  = cellfun(@(x) datetime(x.YMDHMSH(1),x.YMDHMSH(2),x.YMDHMSH(3),x.YMDHMSH(4),x.YMDHMSH(5),x.YMDHMSH(6),x.YMDHMSH(7)),xtf_ping_data(it,:));
        time_f = datenum(time_f);
        ac_data_temp.replace_sub_data_v2(data_t,'img_intensity');
        
        trans_depth  =[ping_data(:).SensorDepth];
        trans_obj_tmp=transceiver_cl('Data',ac_data_temp,...
            'Ping_offset',0,...
            'Time',datenum(time_f),...
            'Config',config_obj,...
            'Params',params_obj,...
            'TransceiverDepth',trans_depth);
        [~,range_t]=trans_obj_tmp.compute_soundspeed_and_range(env_data_obj);
        trans_obj_tmp.set_transceiver_range(range_t);
        trans_obj_tmp.set_absorption(env_data_obj);
        trans_obj = [trans_obj_tmp trans_obj];
    end
    
    att = [ping_data(:).SensorPitchRollHeadingHeaveYaw];
    att_obj = attitude_nav_cl('Time',time_f,...
        'Heading',att(3:5:end),...
        'Pitch',att(1:5:end),...
        'Heave',att(4:5:end),...
        'Yaw',att(5:5:end),...
        'Roll',att(2:5:end));
    
    lat_lon = [ping_data(:). SensorYXcoordinate];
    gps_obj = gps_data_cl('Lat',lat_lon(1:2:end),'Long',lat_lon(2:2:end),'Time',time_f);
    
    lay_temp=layer_cl('Filename',{Filename},...
        'Filetype','XTF',...
        'AttitudeNav',att_obj,...
        'GPSData',gps_obj,...
        'Transceivers',trans_obj,...
        'EnvData',env_data_obj);
    
    pressure_line = line_cl('Name','SensorDepth','Range',trans_depth,'Time',time_f,'Tag','offset');
    lay_temp.add_lines(pressure_line);
    alt_line = line_cl('Name','SensorPrimaryAlititude','Range',[ping_data(:).SensorPrimaryAlititude],'Time',time_f);
    lay_temp.add_lines(alt_line);
    
    ilay = ilay+1;
    layers =[layers lay_temp];
end

end


function   xtf_ping_data = read_xtf_ping_chan_header(fid,xtf_ping_data)
xtf_ping_data.ChannelNumber = fread(fid,1,'uint16');
xtf_ping_data.DownSampleMethod = fread(fid,1,'uint16');
xtf_ping_data.SlantRange = fread(fid,1,'float');
xtf_ping_data.GroundRange = fread(fid,1,'float');
xtf_ping_data.TimeDelay = fread(fid,1,'float');
xtf_ping_data.TimeDuration = fread(fid,1,'float');
xtf_ping_data.SecondsPerPing = fread(fid,1,'float');
xtf_ping_data.ProcessingFlags = fread(fid,1,'uint16');%4 = TVG;8 = BAC&GAC;16 = filter
xtf_ping_data.Frequency = fread(fid,1,'uint16');
xtf_ping_data.InitialGainCode = fread(fid,1,'uint16');
xtf_ping_data.GainCode= fread(fid,1,'uint16');
xtf_ping_data.BandWidth = fread(fid,1,'uint16');
xtf_ping_data.ContactNumber = fread(fid,1,'uint32');
xtf_ping_data.ContactClassification = fread(fid,1,'uint16');
xtf_ping_data.ContactSubNumber = fread(fid,1,'uint8');
xtf_ping_data.ContactType = fread(fid,1,'uint8');
xtf_ping_data.NumSamples = fread(fid,1,'uint32');
xtf_ping_data.MillivoltScale = fread(fid,1,'uint16');
xtf_ping_data.ContactTimeOffTrack = fread(fid,1,'float');
xtf_ping_data.ContactCloseNumber = fread(fid,1,'uint8');
xtf_ping_data.REserved2 = fread(fid,1,'uint8');
xtf_ping_data.FixedVSOP = fread(fid,1,'float');
xtf_ping_data.Weight = fread(fid,1,'short');
xtf_ping_data.ReservedSpace = fread(fid,4,'uint8')';


end

function   common_head_struct = read_dg_header(fid)
common_head_struct.MagicNumber = fread(fid,1,'uint16')';
common_head_struct.HeaderType = get_header_type(fread(fid,1,'uint8'));
common_head_struct.SubChannelNumber = fread(fid,1,'uint8');
common_head_struct.NumberOfChansToFollow = fread(fid,1,'uint16')';
common_head_struct.Reserved1 = fread(fid,2,'uint16')';
common_head_struct.NumBytesThisRecord = fread(fid,1,'uint32')';
end

function chaninfo = read_chaninfo(fid)
chaninfo = [];
for id_chan =1:6
    ch_tmp.TypeOfChannel = get_channel_type(fread(fid,1,'uint8'));
    ch_tmp.SubChannelNumber = fread(fid,1,'uint8');
    ch_tmp.CorrectionFlags = fread(fid,1,'uint16');
    ch_tmp.UniPolar = fread(fid,1,'uint16');
    ch_tmp.BytesPerSample = fread(fid,1,'uint16');
    ch_tmp.Reserved = fread(fid,1,'uint32');
    ch_tmp.ChannelName = fread(fid,16,'*char')';
    ch_tmp.VoltScale = fread(fid,1,'float')';
    ch_tmp.Frequency = fread(fid,1,'float')';
    ch_tmp.HorizBeamAngle = fread(fid,1,'float')';
    ch_tmp.TiltAngle = fread(fid,1,'float')';
    ch_tmp.BeamWidth = fread(fid,1,'float')';
    ch_tmp.OffsetXYZ = fread(fid,3,'float')';
    ch_tmp.YawPitchRoll = fread(fid,3,'float')';
    ch_tmp.BeamsPerArray = fread(fid,1,'uint16')';
    ch_tmp.SampleFormat = fread(fid,1,'uint8');
    ch_tmp.ReservedArea2 = fread(fid,53,'*char')';
    chaninfo = [chaninfo ch_tmp];
end
end

function ctype  = get_channel_type(id)

ctype = '';
switch id
    case 0
        ctype  ='SUBBOTTOM';
    case 1
        ctype  ='PORT';
    case 2
        ctype  ='STBD';
    case 3
        ctype  ='BATHYMETRY';
end

end


function xtf_file_header = read_xtf_file_header(fid)
xtf_file_header.FileFormat  =fread(fid,1,'uint8');
xtf_file_header.SystemType = fread(fid,1,'uint8');
xtf_file_header.RecordingProgramName = fread(fid,8,'*char')';
xtf_file_header.RecordingProgramVersion = fread(fid,8,'*char')';
xtf_file_header.SonarName = fread(fid,16,'*char')';
xtf_file_header.SonarType = get_sonar_type(fread(fid,1,'uint16'));
xtf_file_header.NoteString = fread(fid,64,'*char')';
xtf_file_header.ThisFileName = fread(fid,64,'*char')';
xtf_file_header.NavUnits = get_nav_units(fread(fid,1,'uint16'));
xtf_file_header.NumberOfSonarChannels = fread(fid,1,'uint16');
xtf_file_header.NumberOfBathymetryChannels = fread(fid,1,'uint16');
xtf_file_header.NumberOfSnippetsChannels = fread(fid,1,'uint16');
xtf_file_header.NumberOfEchoStrengthChannels = fread(fid,1,'uint16');
xtf_file_header.NumberOfInterferometryChannels = fread(fid,1,'uint16');
xtf_file_header.reserved = fread(fid,1,'uint16');
xtf_file_header.ReferencePointHeight = fread(fid,1,'float');
%Navigation System Parameters
xtf_file_header.ProjectionType = fread(fid,12,'uint8');%not used
xtf_file_header.SpheroidType = fread(fid,10,'uint8');%not used
xtf_file_header.NavigationLatency = fread(fid,1,'long')/1e3;
xtf_file_header.OriginY = fread(fid,1,'float');
xtf_file_header.OriginX = fread(fid,1,'float');
xtf_file_header.NavOffsetYXZ = fread(fid,3,'float');
xtf_file_header.NavOffsetYaw = fread(fid,1,'float');
xtf_file_header.MRUOffsetYXZ = fread(fid,3,'float');
xtf_file_header.MRUOffsetYaw = fread(fid,1,'float');
xtf_file_header.MRUOffsetPitch = fread(fid,1,'float');
xtf_file_header.MRUOffsetRoll = fread(fid,1,'float');
xtf_file_header.ChanInfo = read_chaninfo(fid);
end

function xtf_ping_header  = read_xtf_ping_header(fid)
xtf_ping_header.YMDHMSH = [fread(fid,1,'uint16')' fread(fid,6,'uint8')'];
xtf_ping_header.JulianDay = fread(fid,1,'uint16')';
xtf_ping_header.EventNumber = fread(fid,1,'uint32')';
xtf_ping_header.PingNumber = fread(fid,1,'uint32')';
xtf_ping_header.SoundVelocity = fread(fid,1,'float')';
xtf_ping_header.OceanTide = fread(fid,1,'float')';
xtf_ping_header.Reserved2 = fread(fid,1,'uint32')';
xtf_ping_header.ConductivityFreq = fread(fid,1,'float')';
xtf_ping_header.TemperatureFreq = fread(fid,1,'float')';
xtf_ping_header.PressureFreq = fread(fid,1,'float')';
xtf_ping_header.PressureTemp = fread(fid,1,'float')';
xtf_ping_header.Conductivity = fread(fid,1,'float')';
xtf_ping_header.WaterTemperature = fread(fid,1,'float')';
xtf_ping_header.Pressure = fread(fid,1,'float')';
xtf_ping_header.ComputedSoundVelocity = fread(fid,1,'float')';
xtf_ping_header.MagXYZ = fread(fid,3,'float')';
xtf_ping_header.AuxVals = fread(fid,6,'float')';
xtf_ping_header.SpeedLog = fread(fid,1,'float')';
xtf_ping_header.Turbidity = fread(fid,1,'float')';
xtf_ping_header.ShipSpeed = fread(fid,1,'float')';
xtf_ping_header.ShipGyro = fread(fid,1,'float')';
xtf_ping_header.ShipYX = fread(fid,2,'double')';
xtf_ping_header.ShipAltitude = fread(fid,1,'uint16')';
xtf_ping_header.ShipDepth = fread(fid,1,'uint16')';
xtf_ping_header.FixTimeHMSH = fread(fid,4,'uint8')';
xtf_ping_header.SensorSpeed = fread(fid,1,'float')';
xtf_ping_header.KP = fread(fid,1,'float')';
xtf_ping_header.SensorYXcoordinate = fread(fid,2,'double')';
xtf_ping_header.SonarStatus = fread(fid,1,'uint16')';
xtf_ping_header.RangeToFish = fread(fid,1,'uint16')';
xtf_ping_header.BearingToFish = fread(fid,1,'uint16')';
xtf_ping_header.CableOut = fread(fid,1,'uint16')';
xtf_ping_header.LayBack = fread(fid,1,'float')';
xtf_ping_header.CableTension = fread(fid,1,'float')';
xtf_ping_header.SensorDepth = fread(fid,1,'float')';
xtf_ping_header.SensorPrimaryAlititude = fread(fid,1,'float')';
xtf_ping_header.SensorAuxAlititude = fread(fid,1,'float')';
xtf_ping_header.SensorPitchRollHeadingHeaveYaw = fread(fid,5,'float')';
xtf_ping_header.AttitudeTimeTag = fread(fid,1,'uint32')/1e3;
xtf_ping_header.DOT = fread(fid,1,'float')';
xtf_ping_header.NavFixMilliseconds = fread(fid,1,'uint32')/1e3;
xtf_ping_header.ComputerClockHMSH = fread(fid,4,'uint8')';
xtf_ping_header.FishPositionDeltaXY = fread(fid,2,'short')';
xtf_ping_header.FishPositionErrorCode = fread(fid,1,'uchar');
xtf_ping_header.ReservedSpace2 = fread(fid,11,'uint8')';
end

function header_type  = get_header_type(id)
header_type ='';
if isempty(id)
    return;
end
switch id
    case 0
        header_type= 'XTF_HEADER_SONAR';
    case 1
        header_type= 'XTF_HEADER_NOTES';
    case 2
        header_type= 'XTF_HEADER_BATHY';
    otherwise
        header_type = num2str(id);
        sprintf('Header Type %d Not supported by ESP3 (yet). Please contact the developers.',id);
end
end

function nav_units  = get_nav_units(id)

switch id
    case 0
        nav_units= 'UTM';%default
    case 3
        nav_units  = 'Lat/Long';
end
end

function sonar_type = get_sonar_type(id)

switch id
    case 0
        sonar_type= 'NONE';%default
    otherwise
        sonar_type  = num2str(id);
        sprintf('Sonar Type %d not supported by ESP3 (yet). Please contact the developers.',id);
end
end