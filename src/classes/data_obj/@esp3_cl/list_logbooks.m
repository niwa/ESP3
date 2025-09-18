function logbook_list = list_logbooks(esp3_obj)

app_path = esp3_obj.app_path;

fields_to_search  = {'data', 'data_root'};

logbook_list = {};
folder_list = {};
for ui = 1:numel(fields_to_search)
    folder_tmp = app_path.(fields_to_search{ui}).Path_to_folder;
    if isfolder(folder_tmp)
        folder_list = [folder_tmp folder_list];
    end
end

folder_to_search = unique(folder_list);

for ui = 1:numel(folder_to_search)
    if isfolder(folder_tmp)
        filelist = dir(fullfile(folder_tmp,'**','echo_logbook.db'));
        filelist = filelist(~[filelist.isdir]);
        logbook_list = [logbook_list fullfile({filelist(:).folder},{filelist(:).name})];
    end
end

end