function panel_comp=load_algo_panel(varargin)
esp3_obj=getappdata(groot,'esp3_obj');

if isempty(esp3_obj)
    main_figure_def=[];
else
    main_figure_def=esp3_obj.main_figure;
end

p = inputParser;

addParameter(p,'main_figure',main_figure_def,@(x)isempty(x)||ishandle(x));
addParameter(p,'panel_h',[],@(x)isempty(x)||ishandle(x));
addParameter(p,'input_struct_h',[],@(x) isstruct(x)||isempty(x));
addParameter(p,'algo_name','',@ischar);
addParameter(p,'title','',@ischar);
addParameter(p,'save_fcn_bool',true,@islogical);
parse(p,varargin{:});

main_figure=p.Results.main_figure;
panel_h=p.Results.panel_h;
algo_name=p.Results.algo_name;
title=p.Results.title;
save_fcn_bool=p.Results.save_fcn_bool;
input_struct_h=p.Results.input_struct_h;

algo_panels=getappdata(main_figure,'Algo_panels');

if ~isempty(algo_panels)
    algo_panels(~isvalid(algo_panels))=[];
end

if ~isempty(algo_panels)
    [~,idx_same]=algo_panels.get_algo_panel(algo_name);
    delete(algo_panels(idx_same));
    algo_panels(idx_same)=[];
end

algo_obj = algo_cl('Name',algo_name);

if save_fcn_bool
    panel_comp=algo_panel_cl('container',panel_h,...
        'title',title,...
        'algo',algo_obj,...
        'input_struct_h',input_struct_h,...
        'apply_cback_fcn',{@apply_algo_cback,main_figure,algo_name,region_cl.empty()},...
        'save_cback_fcn',{@save_display_algos_config_callback,main_figure,algo_name},...
        'save_as_cback_fcn',{@save_new_display_algos_config_callback,main_figure,algo_name},...
        'delete_cback_fcn',{@delete_display_algos_config_callback,main_figure,algo_name}...
        );
else
    panel_comp=algo_panel_cl('container',panel_h,...
        'title',title,...
        'algo',algo_obj,...
        'input_struct_h',input_struct_h,...
        'apply_cback_fcn',{@apply_algo_cback,main_figure,algo_name,region_cl.empty()},...
        'save_cback_fcn',{@save_display_algos_config_callback,main_figure,algo_name});
end

if ~isempty(algo_panels)
    algo_panels(numel(algo_panels)+1)=panel_comp;
else
    algo_panels=panel_comp;
end

setappdata(main_figure,'Algo_panels',algo_panels);

end

