function surv_data_struct=get_struct_from_db(path_f)


db_file = fullfile(path_f,'echo_logbook.db');
if ~isfile(db_file)
    dbconn = initialize_echo_logbook_dbfile(path_f,0);
else
    dbconn = connect_to_db(db_file);
end


surv_data_table=dbconn.fetch('SELECT * FROM logbook  order by StartTime');

nb_lines=length(surv_data_table.Snapshot);

surv_data_struct = table2struct(surv_data_table,'ToScalar',true);

surv_data_struct.Voyage=cell(nb_lines,1);
surv_data_struct.SurveyName=cell(nb_lines,1);

surv_data_table_tmp=dbconn.fetch('SELECT * FROM survey');
if ~isempty(surv_data_table_tmp.Voyage) && ~isempty(surv_data_table_tmp.Voyage{1})
    surv_data_struct.Voyage(:)=surv_data_table_tmp.Voyage(1);
    surv_data_struct.SurveyName(:)=surv_data_table_tmp.SurveyName(1);
end

dbconn.close();



end