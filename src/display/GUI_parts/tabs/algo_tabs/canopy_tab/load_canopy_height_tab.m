%% Function
function load_canopy_height_tab(main_figure,algo_tab_panel)
[h,l] = get_top_panel_height(8);
algo_name = 'CanopyHeight';
canopy_detect_tab=uitab(algo_tab_panel,'Title','Canopy');
canopy_panel = uipanel(canopy_detect_tab,'Units','Pixels','Position',[0 0 2*l h]);
panel_h = load_algo_panel('main_figure',main_figure,...
    'panel_h',canopy_panel,...
    'algo_name',algo_name,...
    'save_fcn_bool',false);

end

