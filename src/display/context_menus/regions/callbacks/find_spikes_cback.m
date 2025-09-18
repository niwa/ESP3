function find_spikes_cback(~,~,select_plot,main_figure)

alg_name = 'SpikesRemoval';
update_algos('algo_name',{alg_name});

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~]=layer.get_trans(curr_disp);

switch class(select_plot)
    case 'region_cl'
        select_plot=trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
end

if isempty(select_plot)
    return;
end

show_status_bar(main_figure);
load_bar_comp=getappdata(main_figure,'Loading_bar');
trans_obj.apply_algo_trans_obj(alg_name,'load_bar_comp',load_bar_comp,'reg_obj',select_plot);

hide_status_bar(main_figure);

set_alpha_map(main_figure,'update_under_bot',0,'update_cmap',0);


end