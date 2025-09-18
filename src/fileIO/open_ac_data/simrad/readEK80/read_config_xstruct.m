function [header,config,config_trans]=read_config_xstruct(xstruct,varargin)

conf=xstruct.Configuration;
header=conf.Header.Attributes;

nb_transceivers = 0;
Transceivers=conf.Transceivers;
if isfield(Transceivers,'Transceiver')
    nb_transceivers=length(Transceivers.Transceiver);
end

header.transceivercount=nb_transceivers;
config  = [];
config_trans = [];
i_trans=0;
read_config_bool = true;
if nargin > 1
    read_config_bool = varargin{1};
end

if ~read_config_bool
    return;
end

for itr=1:nb_transceivers

    if nb_transceivers>1
        Transceiver=Transceivers.Transceiver{itr};
    else
        Transceiver=Transceivers.Transceiver;
    end

    config_temp_overall=Transceiver.Attributes;

    if strcmpi(config_temp_overall.SerialNumber,'0')
        tmp = textscan(deblank(config_temp_overall.TransceiverName),'%3c %s');
        config_temp_overall.SerialNumber = tmp{2}{1};
    end

    Channels=Transceiver.Channels;
    if ~isfield(Channels,'Channel')
        continue;
    end

    Channel_tot=Channels.Channel;
    if ~iscell(Channel_tot)
        Channel_tot={Channel_tot};
    end

    for icha=1:length(Channel_tot)
        i_trans=i_trans+1;
        config_temp = config_temp_overall;
        Channel=Channel_tot{icha};
        att=fieldnames(Channel.Attributes);

        for j=1:length(att)
            config_temp.(att{j})=Channel.Attributes.(att{j});
        end

        Transducer=Channel.Transducer;

        config_temp  =read_transducer(Transducer,config_temp);

        config{i_trans}=structfun(@read_conf_fields,config_temp,'un',0);
    end
end


if isfield(conf,'Transducers')

    Transducers=conf.Transducers.Transducer;
    nb_transducers=length(Transducers);

    for itr=1:nb_transducers
        if nb_transducers>1
            Transducer=Transducers{itr};
        else
            Transducer=Transducers;
        end

        config_temp  =read_transducer(Transducer,[]);
        config_temp=structfun(@read_conf_fields,config_temp,'un',0);

        if ~isempty(config) && isfield(config_temp,'TransducerName') && isfield(config_temp,'TransducerSerialNumber')
            if ischar(config_temp.TransducerSerialNumber)
                i_trans=find(cellfun(@(x) strcmpi(x.TransducerName,config_temp.TransducerName),config) & ...
                    cellfun(@(x) strcmpi(deblank(x.TransducerSerialNumber),deblank(config_temp.TransducerSerialNumber)),config));
            else
                i_trans=find(cellfun(@(x) strcmpi(x.TransducerName,config_temp.TransducerName),config) & ...
                    cellfun(@(x) x.TransducerSerialNumber == config_temp.TransducerSerialNumber,config));
            end
        else
            i_trans=[];
        end

        n_fields=fieldnames(config_temp);
        for itrans_out=i_trans
            if ismember(itrans_out,i_trans)
                for ifi = 1:numel(n_fields)
                    config{itrans_out}.(n_fields{ifi}) = config_temp.(n_fields{ifi});
                end
            end
        end

    end
end


sensor=[];
if isfield(conf,'ConfiguredSensors')
    if isfield(conf.ConfiguredSensors,'Sensor')

        Sensors=conf.ConfiguredSensors.Sensor;
        nb_sensors=length(Sensors);

        for itr=1:nb_sensors
            if nb_sensors>1
                Sensor=Sensors{itr};
            else
                Sensor=Sensors;
            end

            sensor_temp=Sensor.Attributes;


            att=fieldnames(Sensor.Attributes);
            for j=1:length(att)
                sensor_temp.(att{j})=Sensor.Attributes.(att{j});
            end

            fields=fieldnames(sensor_temp);

            for jj=1:length(fields)
                val_temp=sscanf([sensor_temp.(fields{jj}) ';'],'%f;');
                if any(isnan(val_temp))||isempty(val_temp)
                    sensor(itr).(fields{jj})=sensor_temp.(fields{jj});
                else
                    sensor(itr).(fields{jj})=val_temp;
                end

            end
        end
    end
end

end

function config_temp  =read_transducer(Transducer,config_temp)

att=fieldnames(Transducer.Attributes);
for j=1:length(att)
    if strcmp((att{j}),'SerialNumber')
        config_temp.TransducerSerialNumber=Transducer.Attributes.(att{j});
    else
        config_temp.(att{j})=Transducer.Attributes.(att{j});
    end
end


if isfield(Transducer,'FrequencyPar')
    att=fieldnames(Transducer.FrequencyPar{1}.Attributes);
    length_cal_fm=length(Transducer.FrequencyPar);
    for iat=1:length(att)
        freq_struct.(att{iat})=nan(1,length_cal_fm);

        for ic=1:length_cal_fm
            freq_struct.(att{iat})(ic)=str2double(Transducer.FrequencyPar{ic}.Attributes.(att{iat}));
        end
    end
    config_temp.Cal_FM=freq_struct;
end
end



function y = read_conf_fields(x)

if isstruct(x)
    y=x;
    return;
end

if contains(x,';')
    val_temp=sscanf([x ';'],'%f;');
else
    val_temp  = str2double(x);
end

if any(isnan(val_temp))||isempty(val_temp)
    y=deblank(x);
else
    y=val_temp;
end

end