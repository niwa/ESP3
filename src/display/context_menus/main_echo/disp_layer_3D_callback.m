function disp_layer_3D_callback(~,~,main_figure,rem,regs_only)

layer=get_current_layer();
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~]=layer.get_trans(curr_disp);
trans=trans_obj;

ax_main=axes_panel_comp.echo_obj.main_ax;
x_lim=double(get(ax_main,'xlim'));

cp = ax_main.CurrentPoint;
x=cp(1,1);

x=max(x,x_lim(1));
x=min(x,x_lim(2));

xdata=trans.get_transceiver_pings();

[~,idx_ping]=min(abs(xdata-x));

t_n=trans.Time(idx_ping);

[surv_to_modif,~]=layer.get_survdata_at_time(t_n);

[trans_obj,found]=layer.get_trans(curr_disp);

if ~found
    return;
end
echo_3D_obj = get_esp3_prop('echo_3D_obj');

if isempty(echo_3D_obj)&&rem
    return;
end
echo_3D_obj = init_echo_3D();

field = curr_disp.Fieldname;

if ~rem
    if regs_only
        active_regs = trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
    else
        active_regs = region_cl.empty();
    end


    switch field
        case 'trackedtarget'
            field_cax = 'singletarget';
        otherwise
            field_cax = field;
    end

    echo_3D_obj = init_echo_3D();

    cax=curr_disp.getCaxField(field_cax);
    vel_disp  = 'normal';


    switch field
        case {'sv' 'svdenoised','alongangle','acrossangle' 'velocity' 'velocity_north' 'velocity_east' 'velocity_down'}
            echo_3D_obj.add_surface(trans_obj,'fieldname',field,'cax',cax,'intersect_only',regs_only,'regs',active_regs,'BeamAngularLimit',curr_disp.BeamAngularLimit,'vel_disp',vel_disp);
            echo_3D_obj.change_vert_exa(echo_3D_obj.vert_ex_slider_h,[]);
        otherwise
            echo_3D_obj.add_feature(trans_obj,'fieldname',field,'cax',cax,'intersect_only',regs_only,'regs',active_regs);
            echo_3D_obj.change_vert_exa(echo_3D_obj.vert_ex_slider_h,[]);
    end

else
    switch field
        case {'sv' 'svdenoised','alongangle','acrossangle' 'velocity' 'velocity_north' 'velocity_east' 'velocity_down'}
            echo_3D_obj.rem_surface(trans_obj,'surv_data',surv_to_modif)
        otherwise
            echo_3D_obj.rem_feature(trans_obj,'surv_data',surv_to_modif)

    end

end


