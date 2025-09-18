function  index_files_callback(~,~,main_figure)
layer=get_current_layer();

if ~isempty(layer)
    [path_lay,~]=get_path_files(layer);
    if ~isempty(path_lay)
        file_path=path_lay{1};
    else
        file_path=pwd;
    end
else
    file_path=pwd;
end

Filename=get_compatible_ac_files(file_path);

if isempty(Filename)||isequal(Filename,0)
    return;
end

show_status_bar(main_figure);
load_bar_comp=getappdata(main_figure,'Loading_bar');
str_disp='Indexing Files';
if ~isempty(load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(Filename), 'Value',0);
    load_bar_comp.progress_bar.setText(str_disp);
else
    disp(str_disp);
end
for ifif=1:length(Filename)
    if ~isempty(load_bar_comp)
        set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(Filename), 'Value',ifif);
    end
    fileN=Filename{ifif};
    [PathToFile,fname,ext]=fileparts(Filename{ifif});

    if ~strcmpi(ext,'.raw')
        continue;
    end
    echo_folder = get_esp3_file_folder(PathToFile,true);

    fileIdx=fullfile(echo_folder,[fname '_echoidx.mat']);
    
    if ~isfile(fileIdx)
        idx_raw_obj=raw_idx_cl(fileN,load_bar_comp);
        save(fileIdx,'idx_raw_obj');
    else
        obj_load = load(fileIdx);
        idx_raw_obj = obj_load.idx_raw_obj;
        [~,et]=start_end_time_from_file(fileN);
        dgs=find((strcmp(idx_raw_obj.type_dg,'RAW0')|...
            strcmp(idx_raw_obj.type_dg,'RAW3'))&idx_raw_obj.chan_dg==min(idx_raw_obj.chan_dg,[],'omitnan'));
        if et-idx_raw_obj.time_dg(end)>2*max(diff(idx_raw_obj.time_dg(dgs)),[],'omitnan')||idx_raw_obj.Version<raw_idx_cl.get_curr_raw_idx_cl_version()
            fprintf('Re-Indexing file: %s\n',Filename{ifif});
            delete(fileIdx);
            idx_raw_obj=raw_idx_cl(fileN,load_bar_comp);
            save(fileIdx,'idx_raw_obj');
        end
    end
    
    if exist(fileIdx,'file')>0
       delete(fileIdx); 
    end
    
    save(fileIdx,'idx_raw_obj');

end
hide_status_bar(main_figure);



