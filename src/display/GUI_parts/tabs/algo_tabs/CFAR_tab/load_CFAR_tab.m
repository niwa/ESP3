%% Function
function load_CFAR_tab(main_figure,algo_tab_panel)
[h,l] = get_top_panel_height(8);
algo_name = 'CFARdetection';
CFAR_detect_tab=uitab(algo_tab_panel,'Title','CFAR detector');
CFAR_panel = uipanel(CFAR_detect_tab,'Units','Pixels','Position',[0 0 2*l h]);

panel_h = load_algo_panel('main_figure',main_figure,...
    'panel_h',CFAR_panel,...
    'algo_name',algo_name,...
    'title','CFAR feature detection',...
    'save_fcn_bool',true);


end