%% load_processing_tab.m
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
% * |option_tab_panel|: TODO: write description and info on variable
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
function load_processing_tab(main_figure,option_tab_panel)

processing_tab_comp.processing_tab = uitab(option_tab_panel,'Title','Processing','Tag','proc');
gui_fmt = init_gui_fmt_struct();
gui_fmt.txt_w = gui_fmt.txt_w*1.5;
algo_names=list_algos();
nb_algos_per_col = 6;
nb_cols = ceil(numel(algo_names)/nb_algos_per_col)+1;
nb_rows = nb_algos_per_col+2;

pos = cell(nb_rows,nb_cols);

for j = 1:1:size(pos,1)
    for i = 1:size(pos,2)
        pos{j,i} = [gui_fmt.x_sep+(i-1)*(gui_fmt.x_sep+gui_fmt.txt_w+gui_fmt.x_sep) gui_fmt.y_sep+(j-1)*(gui_fmt.y_sep+gui_fmt.txt_h)  gui_fmt.txt_w gui_fmt.txt_h];
    end
end
pos = flipud(pos);

% channel selection
uicontrol(processing_tab_comp.processing_tab,gui_fmt.txtStyle,'String','Channel:','Position',pos{1,1});
processing_tab_comp.tog_freq = uicontrol(processing_tab_comp.processing_tab,gui_fmt.popumenuStyle,...
    'String','--',...
    'Value',1,...
    'Position',pos{1,2},...
    'Callback',{@tog_freq,main_figure});

% algos checkboxes


for ui = 1:numel(algo_names)
    irow  = rem(ui,nb_algos_per_col);
    irow(irow == 0) = nb_algos_per_col;
    irow = irow+1;
    algo_obj  = algo_cl('Name',algo_names{ui});
    processing_tab_comp.(algo_names{ui}) = uicontrol(processing_tab_comp.processing_tab,gui_fmt.chckboxStyle,'Value',0,'String',algo_obj.Display_name,'Position',pos{irow,ceil(ui/6)},...
        'Callback',{@update_process_list,main_figure});   
end


% buttons

uicontrol(processing_tab_comp.processing_tab,gui_fmt.pushbtnStyle,'String','Apply to current layer','pos',pos{3,nb_cols},'callback',{@process_layers_cback,main_figure,0,{}});
uicontrol(processing_tab_comp.processing_tab,gui_fmt.pushbtnStyle,'String','Apply to all loaded layers','pos',pos{4,nb_cols},'callback',{@process_layers_cback,main_figure,1,{}});
uicontrol(processing_tab_comp.processing_tab,gui_fmt.pushbtnStyle,'String','Select files','pos',pos{5,nb_cols},'callback',{@process_layers_cback,main_figure,2,{}});
processing_tab_comp.save_results = uicontrol(processing_tab_comp.processing_tab,gui_fmt.chckboxStyle,'Value',0,'String','Save Results','Position',pos{6,nb_cols});
processing_tab_comp.load_new_lays = uicontrol(processing_tab_comp.processing_tab,gui_fmt.chckboxStyle,'Value',1,'String','Load New layers','Position',pos{7,nb_cols});
setappdata(main_figure,'Processing_tab',processing_tab_comp);

end




%% callback channel selection
function tog_freq(~,~,main_figure)

%choose_freq(src,[],main_figure);
%curr_disp=get_esp3_prop('curr_disp');
process_list        = get_esp3_prop('process');
processing_tab_comp = getappdata(main_figure,'Processing_tab');
layer               = get_current_layer();

idx_freq = get(processing_tab_comp.tog_freq,'value');
cid = layer.ChannelID(idx_freq);
freq = layer.Frequencies(idx_freq);
%curr_disp.ChannelID=layer.ChannelID{idx_freq};


% find algos already set for that channel
algo_names=list_algos();

for ui = 1:numel(algo_names)
    if ~isempty(process_list)
        [~,~,found]=find_process_algo(process_list,cid,freq,algo_names{ui});
    else
        found = 0;
    end
    set(processing_tab_comp.(algo_names{ui}),'value',found);
end

end



