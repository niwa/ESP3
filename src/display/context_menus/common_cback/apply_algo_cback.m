
function apply_algo_cback(~,~,main_figure,algo_name,select_plot)


esp3_obj = getappdata(groot,'esp3_obj');
curr_disp = get_esp3_prop('curr_disp');
layer_obj = get_current_layer();
load_bar_comp = getappdata(main_figure,'Loading_bar');
show_status_bar(main_figure);

if isempty(layer_obj)
    return;
end

[trans_obj,idx_chan]=layer_obj.get_trans(curr_disp);

switch class(select_plot)
    case 'region_cl'
        if ~isempty(select_plot)
            select_plot = trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
            if isempty(select_plot)
                hide_status_bar(main_figure);hide_status_bar(main_figure);
                return;
            end
        end
    case 'matlab.graphics.primitive.Patch'


end

update_algos('algo_name',{algo_name},'idx_chan',idx_chan);

switch algo_name

    case {'CFARdetection' 'school_detect_3D'}
        layer_obj.apply_algo(algo_name,'idx_chan',idx_chan,'load_bar_comp',load_bar_comp,'bpool',esp3_obj.bpool,'reg_obj',select_plot);
        set_alpha_map(main_figure,'update_bt',0);
        hide_status_bar(main_figure);
       
    case 'Classification'
        update_survey_opts(main_figure);

        old_regs=trans_obj.Regions;

        layer_obj.apply_algo(algo_name,'idx_chan',idx_chan,'load_bar_comp',load_bar_comp,'bpool',esp3_obj.bpool,'reg_obj',select_plot);

        add_undo_region_action(main_figure,trans_obj,old_regs,trans_obj.Regions);
        update_multi_freq_disp_tab(main_figure,'sv_f',0);
        update_multi_freq_disp_tab(main_figure,'ts_f',0);

        hide_status_bar(main_figure);

        display_regions('both');
        curr_disp.setActive_reg_ID(trans_obj.get_reg_first_Unique_ID());

        update_echo_int_tab(main_figure,0);

    case {'BottomDetection' 'BottomDetectionV2'}

        old_bot=trans_obj.Bottom;

        layer_obj.apply_algo(algo_name,'idx_chan',idx_chan,'load_bar_comp',load_bar_comp,'bpool',esp3_obj.bpool,'reg_obj',select_plot);
        hide_status_bar(main_figure);
        bot=trans_obj.Bottom;
        add_undo_bottom_action(main_figure,trans_obj,old_bot,bot);
        curr_disp.Bot_changed_flag = 1;
        set_alpha_map(main_figure,'update_bt',0);
        display_bottom(main_figure);


    case 'Denoise'
        layer_obj.apply_algo(algo_name,'idx_chan',idx_chan,'load_bar_comp',load_bar_comp,'bpool',esp3_obj.bpool,'reg_obj',select_plot);
        hide_status_bar(main_figure);
        curr_disp.setField('svdenoised');

    case {'BadPingsV2' 'SpikesRemoval' 'DropOuts' 'Bad_pings_from_attitude'}

        old_bot = trans_obj.Bottom;

        layer_obj.apply_algo(algo_name,'idx_chan',idx_chan,'load_bar_comp',load_bar_comp,'bpool',esp3_obj.bpool,'reg_obj',select_plot);

        hide_status_bar(main_figure);

        bot = trans_obj.Bottom;

        add_undo_bottom_action(main_figure,trans_obj,old_bot,bot);
        curr_disp.Bot_changed_flag = 1;
        set_alpha_map(main_figure,'update_cmap',0,'update_under_bot',0);
        display_bottom(main_figure);

    case {'SchoolDetection' 'MBecho'}

        old_regs=trans_obj.Regions;

        out = layer_obj.apply_algo(algo_name,'idx_chan',idx_chan,'load_bar_comp',load_bar_comp,'bpool',esp3_obj.bpool,'reg_obj',select_plot);

        add_undo_region_action(main_figure,trans_obj,old_regs,trans_obj.Regions);

        hide_status_bar(main_figure);

        if out{1}.done
            update_multi_freq_disp_tab(main_figure,'sv_f',0);
            update_multi_freq_disp_tab(main_figure,'ts_f',0);

            curr_disp.Reg_changed_flag = 1;
            display_regions('both');
            curr_disp.setActive_reg_ID(trans_obj.get_reg_first_Unique_ID());
        end

    case 'SingleTarget'

        out = layer_obj.apply_algo(algo_name,'idx_chan',idx_chan,'load_bar_comp',load_bar_comp,'bpool',esp3_obj.bpool,'reg_obj',select_plot);

        hide_status_bar(main_figure);
        if out{1}.done
            curr_disp.setField('singletarget');
            display_tracks(main_figure);
            update_st_tracks_tab(main_figure,'histo',1,'st',1);
        end

    case 'TrackTarget'

        layer_obj.apply_algo(algo_name,'idx_chan',idx_chan,'load_bar_comp',load_bar_comp,'bpool',esp3_obj.bpool,'reg_obj',select_plot);
        hide_status_bar(main_figure);
        if~isempty(layer_obj.Curves)
            layer_obj.Curves(contains({layer_obj.Curves(:).Unique_ID},'track'))=[];
        end

        display_tracks(main_figure);
        update_multi_freq_disp_tab(main_figure,'ts_f',1);
        update_st_tracks_tab(main_figure,'histo',1,'st',0);

    case 'CanopyHeight'
        layer_obj.apply_algo(algo_name,'idx_chan',idx_chan,'load_bar_comp',load_bar_comp,'bpool',esp3_obj.bpool,'reg_obj',select_plot);
        hide_status_bar(main_figure);
        update_lines_tab(main_figure);
        display_lines();

    case 'BottomFeatures'

        layer_obj.apply_algo(algo_name,'idx_chan',idx_chan,'load_bar_comp',load_bar_comp,'bpool',esp3_obj.bpool,'reg_obj',select_plot);
        hide_status_bar(main_figure);
        curr_disp.Bot_changed_flag = 1;
        h_fig = new_echo_figure(main_figure,'Tag','E1/E2');

        ax1 =  axes(h_fig,'nextplot','add','OuterPosition',[0.05 0.55 0.9 0.45]);
        E1 = trans_obj.Bottom.Bottom_params.E1;
        E1(E1==-999) = NaN;
        plot(ax1,E1,'b-');
        ylabel(ax1,'E1 (dB)');
        box(ax1,'on');
        grid(ax1,'on');
        xlabel(ax1,'Ping Number');
        xlim(ax1,[1 numel(E1)]);

        ax2 =  axes(h_fig,'nextplot','add','OuterPosition',[0.05 0.05 0.9 0.45]);
        E2= trans_obj.Bottom.Bottom_params.E2;
        E2(E2==-999) = NaN;
        plot(ax2,E2,'r-');
        ylabel(ax2,'E2 (dB)');
        box(ax2,'on');
        grid(ax2,'on');
        xlabel(ax2,'Ping Number');
        xlim(ax2,[1 numel(E2)]);

end



hide_status_bar(main_figure);
%curr_disp.setField('feature_sv');


end