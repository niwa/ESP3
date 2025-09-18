

%% update the list of algorithms to be applied
function update_process_list(~,~,main_figure)

update_algos()

layer               = get_current_layer();
process_list        = get_esp3_prop('process');
processing_tab_comp = getappdata(main_figure,'Processing_tab');

idx_freq = get(processing_tab_comp.tog_freq, 'value');

trans_obj = layer.Transceivers(idx_freq);

if isempty(trans_obj.Algo)
    return;
end


algo_panels = getappdata(main_figure,'Algo_panels');
algo_names=list_algos();

for ui = 1:numel(algo_names)
    [algo_panel,~]=algo_panels.get_algo_panel(algo_names{ui});
    add = get(processing_tab_comp.(algo_names{ui}),'value') == get(processing_tab_comp.(algo_names{ui}),'max');
    if ~isempty(algo_panel)
        if isempty(process_list) && add
            process_list=process_cl('CID', layer.ChannelID{idx_freq},'Freq',layer.Frequencies(idx_freq),'Algo', algo_panel.algo.copy_algo());
        elseif ~isempty(process_list)
            process_list = process_list.set_process_list(layer.ChannelID{idx_freq},layer.Frequencies(idx_freq),algo_panel.algo.copy_algo(),add);
        end
    end
end

set_esp3_prop('process',process_list);

end