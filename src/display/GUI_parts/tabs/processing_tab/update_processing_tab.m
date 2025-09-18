function update_processing_tab(main_figure)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
processing_tab_comp=getappdata(main_figure,'Processing_tab');
process_list=get_esp3_prop('process');
[~,idx_freq]=layer.get_trans(curr_disp);

set(processing_tab_comp.tog_freq,'String',layer.Transceivers.get_CID_freq_str(),'Value',idx_freq);

% find algos already set for that channel
algo_names=list_algos();

for ui = 1:numel(algo_names)
    if ~isempty(process_list)
        [~,~,found]=find_process_algo(process_list,curr_disp.ChannelID,curr_disp.Freq,algo_names{ui});
    else
        found = 0;
    end
    set(processing_tab_comp.(algo_names{ui}),'value',found);
end

setappdata(main_figure,'Processing_tab',processing_tab_comp);

end