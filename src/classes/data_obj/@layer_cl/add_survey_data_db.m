function add_survey_data_db(layers_obj)

[pathtofile,files_lays]=layers_obj.get_path_files();

[pathtofile,~,id_u]=unique(pathtofile);

pathtofile(cellfun(@isempty,pathtofile))=[];

for uip = 1:numel(pathtofile)

    path_f = pathtofile{uip};
    if isempty(path_f)||~isfolder(path_f)
        continue;
    end

    ilays  = layers_obj.find_layer_idx_files(files_lays(id_u ==uip));

    db_file = fullfile(path_f,'echo_logbook.db');
    try
        if ~isfile(db_file)
            dbconn = initialize_echo_logbook_dbfile(path_f,0);
        else
            dbconn = connect_to_db(db_file);
        end

        for ilay=ilays
            surv_data={};
            [start_time,end_time]=layers_obj(ilay).get_time_bound_files();

            for ifi=1:length(layers_obj(ilay).Filename)
                if isfile(layers_obj(ilay).Filename{ifi})
                    surv_data_temp=get_file_survey_data_from_db(dbconn,layers_obj(ilay).Filename{ifi},start_time(ifi),end_time(ifi));
                    surv_data=[surv_data surv_data_temp];
                end
            end

            layers_obj(ilay).set_survey_data(surv_data);
        end
        dbconn.close();

    catch err
        print_errors_and_warnings([],'error',err);
    end
end