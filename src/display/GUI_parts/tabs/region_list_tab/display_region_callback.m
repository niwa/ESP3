function display_region_callback(~,~,main_figure,opt,anim_bool)
lay_obj=get_current_layer();

if isempty(lay_obj)
    return;
end

curr_disp=get_esp3_prop('curr_disp');
esp3_obj = getappdata(groot,'esp3_obj');

[trans_obj,~]=lay_obj.get_trans(curr_disp);
load_bar_comp=getappdata(main_figure,'Loading_bar');

for ireg=1:length(curr_disp.Active_reg_ID)

    reg_curr=trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID{ireg});

    if isempty(reg_curr)
        return;
    end
    line_obj=[];
    %field = 'sv';
    switch opt
        case '2D'
            switch reg_curr.Reference
                case 'Line'
                    line_obj=lay_obj.get_first_line();
            end

            if ismember('svdenoised',trans_obj.Data.Fieldname)
                field='svdenoised';
            else
                field='sv';
            end

            show_status_bar(main_figure);
            reg_curr.display_region(trans_obj,'main_figure',main_figure,'line_obj',line_obj,'field',field,'load_bar_comp',load_bar_comp);

        otherwise
            switch opt
                case '3D'
                    if ismember('spdenoised',trans_obj.Data.Fieldname)
                        field='spdenoised';
                    else
                        field='sp';
                    end
                case '3D_bathy'
                        field='bathy';
                case '3D_sv'
                    if ismember('svdenoised',trans_obj.Data.Fieldname)
                        field='svdenoised';
                    else
                        field='sv';
                    end
                case '3D_curr_field'
                    field = curr_disp.Fieldname;
                case '3D_ST'
                    field ='singletarget';
                case '3D_tracks'
                    field = 'trackedtarget';
                case '3D_quiver'
                    field = 'quiver_velocity';
                otherwise
                    return;
            end

            switch field
                case 'trackedtarget'
                    field_cax = 'singletarget';
                otherwise
                    field_cax = field;
            end
            fname = '';
            t_buffer = nan;
            vert_exa = nan;
            anim_speed = 20;

            if anim_bool
                [answers,cancel]=input_dlg_perso(main_figure,...
                    '3D animation parameters',{'Save as movie' 'Time window (s)' 'Vertical exageration' 'Animation speed (x)' },{'bool' '%.0f'  '%.1f' '%.1f'},{false 6 1 anim_speed});

                if ~cancel
                    t_buffer = answers{2};
                    vert_exa = answers{3};
                    anim_speed = answers{4};
                    if answers{1}
                        path_f = esp3_obj.app_path.data.Path_to_folder;

                        path_f = uigetdir(path_f,...
                            'Select destination folder');

                        if ~isequal(path_f,0)
                            layers_Str=list_layers(lay_obj,'nb_char',80,'valid_filename',true);
                            fname = fullfile(path_f,layers_Str{1});
                        end
                    end
                else
                    return;
                end
            end

            echo_3D_obj = init_echo_3D();

            cax=curr_disp.getCaxField(field_cax);

            switch field
                case {'sv' 'svdenoised','alongangle','acrossangle' 'velocity' 'velocity_north' 'velocity_east' 'velocity_down' 'quiver_velocity'}
                    echo_3D_obj.add_surface(trans_obj,'fieldname',field,'cax',cax,'regs',reg_curr,'BeamAngularLimit',curr_disp.BeamAngularLimit);
                    echo_3D_obj.change_vert_exa(echo_3D_obj.vert_ex_slider_h,[]);
                otherwise
                    echo_3D_obj.add_feature(trans_obj,'fieldname',field,'cax',cax,'regs',reg_curr,'fname',fname,'t_buffer',t_buffer,'vert_exa',vert_exa,'anim_speed',anim_speed);
                    echo_3D_obj.change_vert_exa(echo_3D_obj.vert_ex_slider_h,[]);
            end
    end
end

hide_status_bar(main_figure);

end
