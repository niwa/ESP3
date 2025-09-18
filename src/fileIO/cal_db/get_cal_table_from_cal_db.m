function cal_table = get_cal_table_from_cal_db(dbconn)
close_bool = false;
cal_table = [];

switch class(dbconn)
    case 'char'
        if ~isfile(dbconn)
            file_sql=fullfile(whereisEcho,'config','db','cal_db.sql');
            create_ac_database(dbconn,file_sql,1,false);
        end

        dbconn = sqlite(dbconn);
        close_bool = true;
    case {'database.jdbc.connection','sqlite'}

    otherwise
        return;
end

sql_cmd = 'SELECT ';
db_to_cal_struct_cell = translate_db_to_cal_cell();

for uic = 1:numel(db_to_cal_struct_cell)
    sql_cmd = [sql_cmd sprintf('%s AS %s, ',db_to_cal_struct_cell{uic}{1},db_to_cal_struct_cell{uic}{2})];
end

sql_cmd = sql_cmd(1:end-2);

sql_cmd = [sql_cmd ' FROM t_calibration'];

cal_table = dbconn.fetch(sql_cmd);

if close_bool
    dbconn.close();
end

