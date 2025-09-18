
function reset_range_algo_panels(main_figure)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
algo_panels=getappdata(main_figure,'Algo_panels');
if isempty(algo_panels)
    return;
end

[trans_obj,~]=layer.get_trans(curr_disp);

algo_panels(~isvalid(algo_panels))=[];
algo_panels.reset_range_algo_panels(trans_obj.get_samples_range);




