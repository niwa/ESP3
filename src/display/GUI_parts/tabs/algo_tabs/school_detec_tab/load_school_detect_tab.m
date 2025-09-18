%% load_school_detect_tab.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |main_figure|: TODO: write description and info on variable
% * |algo_tab_panel|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-03-28: header (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function load_school_detect_tab(main_figure,algo_tab_panel)
[h,l] = get_top_panel_height(8);

%%%%%%%%%%%%%%%% School Detection%%%%%%%%%%%%%%%%%%%%%%%%%
algo_name = 'SchoolDetection';
school_detect_tab=uitab(algo_tab_panel,'Title','Schools');

t = load_algo_panel('main_figure',main_figure,...
    'panel_h',uipanel(school_detect_tab,'Units','Pixels','Position',[0 0 2*l h]),...
    'algo_name',algo_name,...
    'save_fcn_bool',true);

%%%%%%%%%%%%%%%% School Detection%%%%%%%%%%%%%%%%%%%%%%%%%
algo_name = 'school_detect_3D';
t_3D_school_panel=uipanel(school_detect_tab,'Units','Pixels','Position',[t.container.Position(1)+t.container.Position(3) 0 2*l h],'Title','3D school detection');
tt = load_algo_panel('main_figure',main_figure,...
    'panel_h',t_3D_school_panel,...
    'algo_name',algo_name,...
    'save_fcn_bool',true);

%%%%%%%%%%%%%%%% Classification Panel%%%%%%%%%%%%%%%%%%%%%%%%%
classification_panel=uipanel(school_detect_tab,'Units','Pixels','Position',[tt.container.Position(1)+tt.container.Position(3) 0 2*l h],'Title','Classification');
algo_name= 'Classification';

load_algo_panel('main_figure',main_figure,...
    'panel_h',classification_panel,...
    'algo_name',algo_name,...
    'save_fcn_bool',false);

gui_fmt=init_gui_fmt_struct();
gui_fmt.txt_w=gui_fmt.txt_w*1.2;
pos=create_pos_3(7,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);

p_button=pos{7,1}{1};
p_button(3)=gui_fmt.button_w;

uicontrol(classification_panel,gui_fmt.pushbtnStyle,'String','Reload','pos',p_button+[3*gui_fmt.button_w 0 0 0],'callback',{@reload_classification_trees_cback,main_figure});
uicontrol(classification_panel,gui_fmt.pushbtnStyle,'String','Edit','pos',p_button+[4*gui_fmt.button_w 0 0 0],'callback',{@edit_classif_file_cback,main_figure});

end

function edit_classif_file_cback(~,~,main_figure)

algo_panels = getappdata(main_figure,'Algo_panels');
al_c_panel=algo_panels.get_algo_panel('Classification');

if isempty(al_c_panel)
    return;
end
idx_val=get(al_c_panel.classification_file,'value');
open_txt_file(al_c_panel.classification_file.String{idx_val});

end

function reload_classification_trees_cback(~,~,main_figure)
algo_panels = getappdata(main_figure,'Algo_panels');
al_c_panel=algo_panels.get_algo_panel('Classification');

if isempty(al_c_panel)
    return;
end
[files_classif,~,~]=list_classification_files();

if isempty(files_classif)
    files_classif={'--'};
end
set(al_c_panel.classification_file,'string',files_classif,'value',1);
if ~all(cellfun(@(x) strcmpi(x,'--'),files_classif))
    al_c_panel.algo.set_input_param_value_range('classification_file',files_classif);
end
update_algos('algo_name',{'Classification'});

end




