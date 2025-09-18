function [config_obj,params_obj]=config_from_ek60(pings,config,stype)
config_obj=config_cl();
params_obj=params_cl();

if ~isempty(pings)
    params_obj=params_cl(length(pings.time));

    ping_fields = {'bandwidth' 'mode' 'frequency' 'frequency' 'frequency' 'pulselength' 'sampleinterval' 'transmitpower'};
    params_fields = {'BandWidth' 'ChannelMode' 'Frequency' 'FrequencyEnd' 'FrequencyStart' 'PulseLength' 'SampleInterval' 'TransmitPower'};

    for uif = 1:numel(ping_fields)
        if isfield(pings,ping_fields{uif}) && isprop(params_obj,params_fields{uif})
            if isscalar(pings.(ping_fields{uif}))
                params_obj.(params_fields{uif}) = pings.(ping_fields{uif})*ones(1,length(pings.time));
            else
                params_obj.(params_fields{uif}) = pings.(ping_fields{uif});
            end
        end
    end

    params_obj.Slope=zeros(1,length(pings.time));
    params_obj.PulseForm=zeros(1,length(pings.time));
end

config_obj.EthernetAddress='';
config_obj.IPAddress='';
config_obj.ChannelID=deblank(config.channelid);
%''GPT 200 kHz 00907205da23 5-1 ES200-7C'

config_obj.SerialNumber='--';
config_obj.TransducerSerialNumber='--';
config_obj.TransceiverType= stype;
switch stype
    case {'ME70' 'MS70'}
        config_obj.TransducerName = stype;
    otherwise
        config_obj.TransducerName='';
end
out=textscan(config_obj.ChannelID,'GPT %d kHz %s %d-%d %s');

if ~isempty(out{2})
    config_obj.SerialNumber=out{2}{1};
end

if ~isempty(out{5})
    config_obj.TransducerName=deblank(out{5}{1});
else
    out=textscan(config_obj.ChannelID,'GPT %d kHz %s %d %s');
    if ~isempty(out{4})
        config_obj.TransducerName=deblank(out{4}{1});
    end
end

config_obj.TransceiverName=config.soundername;
% config_obj.TransceiverNumber=[];
config_obj.TransceiverSoftwareVersion=deblank(config.version);

config_obj.TransducerOffsetX = config.posx;
config_obj.TransducerOffsetY = config.posy;
config_obj.TransducerOffsetZ = config.posz;

switch stype
    case {'ME70' 'MS70'}
        params_obj.BeamAngleAlongship = config.dirx*ones(size(params_obj.PingNumber));
        params_obj.BeamAngleAthwartship = config.diry*ones(size(params_obj.PingNumber));
    otherwise
        config_obj.TransducerAlphaX = config.dirx;
        config_obj.TransducerAlphaY = config.diry;
        config_obj.TransducerAlphaZ = config.dirz;
end

% config_obj.ChannelNumber=[];
% config_obj.HWChannelConfiguration=[];
% config_obj.MaxTxPowerTransceiver=[];
config_obj.PulseLength=config.pulselengthtable;
config_obj.AngleOffsetAlongship=config.anglesoffsetalongship;
config_obj.AngleOffsetAthwartship=config.angleoffsetathwartship;
config_obj.AngleSensitivityAlongship=config.anglesensitivityalongship;
config_obj.AngleSensitivityAthwartship=config.anglesensitivityathwartship;

switch config.beamtype
    case 0
        config_obj.BeamType='single-beam';
    otherwise
        config_obj.BeamType='split-beam';
end
config_obj.BeamWidthAlongship=config.beamwidthalongship;
config_obj.BeamWidthAthwartship=config.beamwidthathwartship;
% config_obj.DirectivityDropAt2XBeamWidth=[];
config_obj.EquivalentBeamAngle=config.equivalentbeamangle;
config_obj.Frequency=config.frequency;
config_obj.FrequencyMaximum=config.frequency;
config_obj.FrequencyMinimum=config.frequency;
config_obj.Gain=config.gaintable;
config_obj.MaxTxPowerTransducer=0;
config_obj.SaCorrection=config.sacorrectiontable;





end