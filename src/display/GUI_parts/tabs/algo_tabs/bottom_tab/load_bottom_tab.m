
%% Function
function load_bottom_tab(main_figure,algo_tab_panel)

tab_main=uitab(algo_tab_panel,'Title','Bottom');

[h,l] = get_top_panel_height(8);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Version 1%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
algo_name= 'BottomDetection';

t = load_algo_panel('main_figure',main_figure,...
        'panel_h',uipanel(tab_main,'Units','Pixels','Position',[0 0 2*l h]),...
        'algo_name',algo_name,...
        'save_fcn_bool',true);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

algo_name= 'BottomDetectionV2';
t = load_algo_panel('main_figure',main_figure,...
        'panel_h',uipanel(tab_main,'Units','Pixels','Position',[t.container.Position(1)+t.container.Position(3) 0 2*l h]),...
        'algo_name',algo_name,...
        'save_fcn_bool',true);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

algo_name= 'BottomFeatures';

load_algo_panel('main_figure',main_figure,...
        'panel_h',uipanel(tab_main,'Units','Pixels','Position',[t.container.Position(1)+t.container.Position(3) 0 2*l h]),...
        'algo_name',algo_name,...
        'save_fcn_bool',false);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Multiple Bottom Echo Detection%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
algo_name = 'MBecho';
load_algo_panel('main_figure',main_figure,...
        'panel_h',uipanel(tab_main,'Units','Pixels','Position',[t.container.Position(1)*2+t.container.Position(3) 0 l h]),...
        'algo_name',algo_name,...
        'save_fcn_bool',true);
    
    
end
