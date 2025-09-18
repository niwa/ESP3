function clean_temp_files(obj)

if ~isempty(obj.layers)
    temp_files_in_use = obj.layers.list_memaps();
else
    temp_files_in_use = {};
end

obj.app_path=get_esp3_prop('app_path');

esp3_obj = getappdata(groot,'esp3_obj');
load_bar_comp = show_status_bar(esp3_obj.main_figure);

if ~isempty(load_bar_comp)
    load_bar_comp.progress_bar.setText(sprintf('Deleting unused temp files'));
end

files_in_temp = dir(fullfile(obj.app_path.data_temp.Path_to_folder,'**','*.bin'));

fff = fullfile({files_in_temp(:).folder},{files_in_temp(:).name});
sz = [files_in_temp(:).bytes];
fff_folder = {files_in_temp(:).folder};

[fff_folder,id_f,id_ff]  = unique(fff_folder);

idx_file_del = ~ismember(fff,temp_files_in_use);
temp_folder_in_use = fileparts(temp_files_in_use);
temp_folder_in_use  = unique(temp_folder_in_use);
temp_folder_in_use = union(temp_folder_in_use,obj.app_path.data_temp.Path_to_folder);
sz  = sz(idx_file_del);
idx_folder_del = false(size(id_f));

for uu=1:length(id_f)
    if all(idx_file_del(id_ff == uu)) && ~strcmpi(fff_folder{uu},obj.app_path.data_temp.Path_to_folder)
        idx_file_del(id_ff == uu) = false;
        idx_folder_del(uu) = true;
    end
end

files_to_del = fff(idx_file_del);
folders_to_del  = fff_folder(idx_folder_del);

folders_to_del(strcmpi(folders_to_del,obj.app_path.data_temp.Path_to_folder)) = [];

parent_folder_to_del = fileparts(folders_to_del);
parent_folder_in_use = fileparts(temp_folder_in_use);
parent_folder_to_del = setdiff(parent_folder_to_del,parent_folder_in_use);

tmp_dir = dir(obj.app_path.data_temp.Path_to_folder);
overall_folders = fullfile({tmp_dir(:).folder},{tmp_dir(:).name});
overall_folders(~[tmp_dir(:).isdir] | contains({tmp_dir(:).name},'.'))  = [];
overall_folders = setdiff(overall_folders,parent_folder_in_use);

folders_to_del = unique([folders_to_del parent_folder_to_del overall_folders],"stable");
folders_to_del(strcmpi(folders_to_del,obj.app_path.data_temp.Path_to_folder)) = [];

files_to_del = unique(files_to_del);

if ~isempty(load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(files_to_del), 'Value',0);
end

for ifif=1:length(files_to_del)
    if isfile(files_to_del{ifif})
        try
            print_errors_and_warnings([],'',sprintf('Deleting temporary file %s',files_to_del{ifif}));
            delete(files_to_del{ifif});
        catch err
            print_errors_and_warnings([],'Warning',sprintf('Could not delete temporary file %s',files_to_del{ifif}));
            print_errors_and_warnings([],'Warning',err);
        end
    end
    if ~isempty(load_bar_comp)
        set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(files_to_del), 'Value',ifif);
    end
end

if ~isempty(load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(folders_to_del), 'Value',0);
end

if ~isempty(load_bar_comp)
    load_bar_comp.progress_bar.setText(sprintf('Deleting unused temp folders'));
end

for ifif=1:length(folders_to_del)
    if isfolder(folders_to_del{ifif})
        try
            print_errors_and_warnings([],'',sprintf('Deleting temporary folder %s',folders_to_del{ifif}));
            rmdir(folders_to_del{ifif},'s');
        catch err
            print_errors_and_warnings([],'Warning',sprintf('Could not delete temporary folder %s',folders_to_del{ifif}));
            print_errors_and_warnings([],'Warning',err);
        end
    end
    if ~isempty(load_bar_comp)
        set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(folders_to_del), 'Value',ifif);
    end
end

fprintf('%d files deleted, %.0f Mb\n',length(files_in_temp),sum(sz)/1e6);
hide_status_bar(esp3_obj.main_figure);
end