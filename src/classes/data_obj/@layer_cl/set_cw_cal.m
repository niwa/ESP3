function set_cw_cal(layer_obj,cal_cw_struct)

for uil = 1:numel(layer_obj)
    for uit = 1:numel(layer_obj(uil).Transceivers)
        trans_obj = layer_obj(uil).Transceivers(uit);
        [pulse_length,~]=trans_obj.get_pulse_length(1);
        idx_chan = strcmpi(cal_cw_struct.CID,trans_obj.Config.ChannelID);
        idx_freq = cal_cw_struct.FREQ == trans_obj.Config.Frequency;
        idx_pulse = (cal_cw_struct.pulse_length == pulse_length);

        idx_cal = find(idx_chan & idx_freq & idx_pulse,1);

        if isempty(idx_cal)
            idx_cal = find(idx_chan & idx_freq,1);
        end

        if isempty(idx_cal)
            idx_cal = find(idx_freq,1);
        end

        if ~isempty(idx_cal)
            cal_table = struct2table(cal_cw_struct);
            cal = table2struct(cal_table(idx_cal,:));
            trans_obj.set_transceiver_cw_cal(cal);
        end
    end
    
end