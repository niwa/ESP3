function [config_obj,params_obj]=config_from_ifile(ifile,nb_pings)
config_obj=config_cl();
params_obj=params_cl(nb_pings);

if ischar(ifile)&&isfile(ifile)
    ifileInfo=parse_ifile(ifile);
elseif isstruct(ifile)
    ifileInfo = ifile;
else
    return;
end

if isnan(ifileInfo.sound_speed)
    soundspeed=1500;
else
    soundspeed=ifileInfo.sound_speed;
end

switch ifileInfo.sounder_type
    case 'CREST'
        config_obj.SounderType = 'Split-beam (CREST)'; 
    otherwise
        config_obj.SounderType = 'Split-beam (Simrad)'; 
end


  
config_obj.TransceiverName=ifileInfo.sounder_type;
config_obj.AngleSensitivityAlongship=ifileInfo.angle_factor_alongship;
config_obj.AngleSensitivityAthwartship=ifileInfo.angle_factor_alongship;
config_obj.BeamType='split-beam';
config_obj.BeamWidthAlongship=7;
config_obj.BeamWidthAthwartship=7;
config_obj.Frequency=38000;
config_obj.FrequencyMaximum=38000;
config_obj.FrequencyMinimum=38000;
config_obj.TransducerSerialNumber=ifileInfo.transducer_id;
config_obj.Gain=ifileInfo.G0;
config_obj.SaCorrection=ifileInfo.SACORRECT;

if isempty(config_obj.Gain)
    config_obj.Gain = 0;
    config_obj.SaCorrection = 0;
end

config_obj.EquivalentBeamAngle=-20.60;

config_obj.ChannelID = sprintf('%s_%dkHz',config_obj.SounderType,38000/1e3);  
 

if isnan(ifileInfo.transmit_pulse_length)
    config_obj.PulseLength=4/ifileInfo.depth_factor/soundspeed*2;
else
    config_obj.PulseLength=ifileInfo.transmit_pulse_length; 
end

params_obj.FrequencyEnd(:)=38000;
params_obj.FrequencyStart(:)=38000;
params_obj.Frequency(:)=38000;
params_obj.TransmitPower(:)=2000;
params_obj.PulseLength(:)=config_obj.PulseLength;
params_obj.TeffPulseLength(:)=ifileInfo.effective_pulse_width;

params_obj.TeffPulseLength=params_obj.PulseLength;
params_obj.TeffCompPulseLength=params_obj.PulseLength;
params_obj.SampleInterval(:)=2/ifileInfo.depth_factor/soundspeed;

end