function update_survey_opts(main_figure)

echo_int_tab_comp=getappdata(main_figure,'EchoInt_tab');

layer_obj=get_current_layer();
curr_disp = get_esp3_prop('curr_disp');

if isempty(layer_obj)
    return;
end

surv_options_obj=layer_obj.get_survey_options();

if isempty(surv_options_obj)
    surv_options_obj=survey_options_cl();
end

if isempty(echo_int_tab_comp.cell_w_unit.Value)
    echo_int_tab_comp.cell_w_unit.Value=idx_w;
end

surv_options_obj.Vertical_slice_units.set_value(echo_int_tab_comp.cell_w_unit.String{echo_int_tab_comp.cell_w_unit.Value});
surv_options_obj.Vertical_slice_size.set_value(str2double(echo_int_tab_comp.cell_w.String));
surv_options_obj.Horizontal_slice_size.set_value(str2double(echo_int_tab_comp.cell_h.String));
surv_options_obj.IntRef.set_value(echo_int_tab_comp.ref.String{echo_int_tab_comp.ref.Value});

surv_options_obj.Denoised.set_value(echo_int_tab_comp.denoised.Value);
if echo_int_tab_comp.sv_thr_bool.Value
    surv_options_obj.SvThr.set_value(str2double(echo_int_tab_comp.sv_thr.String));
else
    surv_options_obj.SvThr.set_value(-999);
end

surv_options_obj.Shadow_zone.set_value(echo_int_tab_comp.shadow_zone.Value);
surv_options_obj.Shadow_zone_height.set_value(str2double(echo_int_tab_comp.shadow_zone_h.String));

surv_options_obj.DepthMin.set_value(str2double(echo_int_tab_comp.d_min.String));
surv_options_obj.DepthMax.set_value(str2double(echo_int_tab_comp.d_max.String));

surv_options_obj.RangeMin.set_value(surv_options_obj.RangeMin.Value_range(1));
surv_options_obj.RangeMax.set_value(surv_options_obj.RangeMax.Value_range(2));

surv_options_obj.RefRangeMin.set_value(surv_options_obj.RefRangeMin.Value_range(1));
surv_options_obj.RefRangeMax.set_value(surv_options_obj.RefRangeMax.Value_range(2));

switch lower(echo_int_tab_comp.ref.String{echo_int_tab_comp.ref.Value})
    case 'bottom'
        surv_options_obj.RefRangeMin.set_value(-str2double(echo_int_tab_comp.r_max.String));
        surv_options_obj.RefRangeMax.set_value(-str2double(echo_int_tab_comp.r_min.String));
    case 'transducer'
        surv_options_obj.RangeMin.set_value(str2double(echo_int_tab_comp.r_min.String));
        surv_options_obj.RangeMax.set_value(str2double(echo_int_tab_comp.r_max.String));
    otherwise
        surv_options_obj.RefRangeMin.set_value(str2double(echo_int_tab_comp.r_min.String));
        surv_options_obj.RefRangeMax.set_value(str2double(echo_int_tab_comp.r_max.String));
end
surv_options_obj.AngleMin.set_value(curr_disp.BeamAngularLimit(1));
surv_options_obj.AngleMax.set_value(curr_disp.BeamAngularLimit(2));

surv_options_obj.Motion_correction.set_value(echo_int_tab_comp.motion_corr.Value);
surv_options_obj.Remove_ST.set_value(echo_int_tab_comp.rm_st.Value);

if echo_int_tab_comp.reg_only.Value
    surv_options_obj.IntType.set_value('By Regions');
else
    surv_options_obj.IntType.set_value('WC');
end

surv_options_obj.Salinity.set_value(layer_obj.EnvData.Salinity);
surv_options_obj.Temperature.set_value(layer_obj.EnvData.Temperature);
surv_options_obj.SoundSpeed.set_value(layer_obj.EnvData.SoundSpeed);

layer_obj.create_survey_options_xml(surv_options_obj);

end