function sacorr=get_current_sacorr(trans_obj)
sacorrs=trans_obj.Config.SaCorrection;

if isscalar(sacorrs)
    sacorr = sacorrs;
    return;
end

pulse_lengths=trans_obj.Config.PulseLength;
pulse_length=trans_obj.get_pulse_length(1,[]);

if trans_obj.ismb
    pulse_length=shiftdim(pulse_length,1);
end

[~,idx_pulse]=min(abs(pulse_lengths-pulse_length),[],1);

sacorr=sacorrs(idx_pulse+(0:numel(idx_pulse)-1)*size(sacorrs,1));
end