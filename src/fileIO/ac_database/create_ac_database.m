function create_ac_database(ac_db_filename,file_sql,overwrite_db,verbose)

if isfile(ac_db_filename)
    if overwrite_db==1
        delete(ac_db_filename);
    end
end

if overwrite_db==0
    dbconn=connect_to_db(ac_db_filename);
else
    dbconn=[];
end

if isempty(dbconn)
    fid=fopen(file_sql,'r','n');
    str_sql_ori=fread(fid,'*char')';
    fclose(fid);
    str_sql=strrep(str_sql_ori,'SERIAL PRIMARY KEY','INTEGER PRIMARY KEY AUTOINCREMENT');
    str_sql=strrep(str_sql,'COMMENT','--COMMENT');
    idx_com_start=strfind(str_sql,'/*');
    idx_com_end=strfind(str_sql,'*/');
    idx_rem=[];

    for icom=1:numel(idx_com_start)
        if verbose
            fprintf('%s\n\n',str_sql(idx_com_start(icom):idx_com_end(icom)+1));
        end
        idx_rem=union(idx_rem,(idx_com_start(icom):idx_com_end(icom)+1));
    end
    str_sql(idx_rem)=[];

    idx_command=strfind(str_sql,');');
    idx_command=[-1 idx_command];


    dbconn=sqlite(ac_db_filename,'create');


    for icom=1:numel(idx_command)-1
        sql_cmd=str_sql(idx_command(icom)+2:idx_command(icom+1)+1);
        if verbose
            fprintf('%s\n\n',sql_cmd);
        end
        dbconn.exec(sql_cmd);
    end

    idx_trigger_start=strfind(str_sql,'CREATE TRIGGER');
    idx_trigger_end=strfind(str_sql,'END;');
    idx_trigger_end=idx_trigger_end+numel('END;')-1;

    for icom=1:numel(idx_trigger_start)
        sql_cmd=str_sql(idx_trigger_start(icom):idx_trigger_end(icom));
        if verbose
            fprintf('%s\n\n',sql_cmd);
        end
        dbconn.exec(sql_cmd);
    end

    dbconn.close();

    dbconn=connect_to_db(ac_db_filename);

    dbconn.exec("PRAGMA recursive_triggers = ON;");
    dbconn.exec("PRAGMA foreign_keys = ON;");

    dbconn.close();

end



end