
function set_transceiver_cw_cal(trans_obj,cal)

[pulse_length,~]=trans_obj.get_pulse_length(1,[]);

[~,idx_params]=min(abs(squeeze(pulse_length)'-trans_obj.Config.PulseLength));

for uip = 1:numel(idx_params)
    trans_obj.Config.Gain(idx_params(uip),uip)=cal.G0(uip);
    trans_obj.Config.SaCorrection(idx_params(uip),uip)=cal.SACORRECT(uip);
end

trans_obj.Config.EquivalentBeamAngle=cal.EQA;

config_fields =config_cl.get_config_cal_fields();

for ui = 1:numel(config_fields)
    if isfield(cal,config_fields{ui})
        trans_obj.Config.(config_fields{ui}) = cal.(config_fields{ui});
    end
end
end