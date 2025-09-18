
function cal = get_transceiver_cw_cal(trans_obj)
    cal  = init_cal_struct(1);

    cal.G0=trans_obj.get_current_gain();
    cal.SACORRECT=trans_obj.get_current_sacorr();
    cal.EQA=trans_obj.Config.EquivalentBeamAngle;
    cal.alpha=squeeze(mean(trans_obj.get_absorption(),1,'omitnan')*1e3)';
    cal.pulse_length = trans_obj.get_pulse_length(1);
    cal.CID = trans_obj.Config.ChannelID;
    cal.FREQ = trans_obj.Config.Frequency;
    cal = trans_obj.Config.get_cal_fields(cal);
end