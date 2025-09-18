function update_logbook_panel_f(new_files)

logbook_fig = get_esp3_prop('logbook_fig_obj');

if isempty(logbook_fig)||~isvalid(logbook_fig)
    return;
end
[path_f,~,ib] = unique(cellfun(@fileparts,new_files,'UniformOutput',false));

for uif = 1:numel(path_f)
    dbFile = fullfile(path_f{uif},'echo_logbook.db');
    idx_t = logbook_fig.find_logbookPanel(dbFile);
    
    if ~isempty(idx_t)
        logbook_panel = logbook_fig.LogBookPanels(idx_t);
        logbook_panel.update_logbook_panel(new_files(ib==uif));
    else
        continue;
    end
    
end