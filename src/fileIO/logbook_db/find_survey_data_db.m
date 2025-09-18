function missing_files=find_survey_data_db(file_layer)

[path_f,files,term]=cellfun(@fileparts,file_layer,'UniformOutput',0);

missing_files={};

[unique_paths,~,idx_unique]=unique(path_f);

for ip=1:length(unique_paths)
    files_temp=files(idx_unique==ip);
    term_file=term(idx_unique==ip);
    db_file=fullfile(unique_paths{ip},'echo_logbook.db');
    
    if ~isfile(db_file)
        dbconn = initialize_echo_logbook_dbfile(unique_paths{ip},0);
    else
        dbconn = connect_to_db(db_file);    
    end


    for i=1:length(files_temp)

        curr_file_data=dbconn.fetch(sprintf('SELECT Snapshot,Type,Stratum,Transect,StartTime,EndTime,Comment FROM logbook WHERE instr(Filename, ''%s%s'')>0',files_temp{i},term_file{i}));
        if isempty(curr_file_data)
            continue;
        end

        nb_data=size(curr_file_data.Snapshot,1);

        for id=1:nb_data
            curr_file_data.Stratum(ismissing(curr_file_data.Stratum)) = {''};
            if curr_file_data.Snapshot(id)==0&&(strcmp(deblank(curr_file_data.Stratum{id}),''))&&curr_file_data.Transect(id)==0
                continue;
            end

            missing_file_temp=dbconn.fetch(sprintf('SELECT Filename FROM logbook WHERE Snapshot=%.0f and Type is "%s" AND Stratum IS "%s" AND Transect=%.0f',...
                curr_file_data.Snapshot(id),curr_file_data.Type{id},curr_file_data.Stratum{id},curr_file_data.Transect(id)));
            missing_files=union(missing_files,fullfile(unique_paths{ip},missing_file_temp.Filename));


        end

    end
    close(dbconn);
    missing_files=unique(missing_files);
    missing_files=setdiff(missing_files,file_layer);
    if isstring(missing_files)
        missing_files = cellstr(missing_files);
    end

end
