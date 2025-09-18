function gain=get_current_gain(trans_obj)
    gains=trans_obj.Config.Gain;

    if isscalar(gains)
        gain = gains;
        return;
    end
    pulse_lengths=trans_obj.Config.PulseLength;
    pulse_length=trans_obj.get_pulse_length(1,[]);

    if trans_obj.ismb 
        pulse_length=shiftdim(pulse_length,1);
    end
    
    [~,idx_pulse]=min(abs(pulse_lengths-pulse_length),[],1);

    gain=gains(idx_pulse+(0:numel(idx_pulse)-1)*size(gains,1));
end