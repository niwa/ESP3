function dbconn=initialize_echo_logbook_dbfile(db_file,just_create)

if isfolder(db_file)
    datapath = db_file;
    db_file=fullfile(datapath,'echo_logbook.db');
else
    datapath = fileparts(db_file);
end

create_vrt_file(db_file,{'ping_data'},{'Long'},{'Lat'});
dbconn = [];

if isfile(db_file)
    try
        dbconn=connect_to_db(db_file);
    catch err

        if isa('dbconn','sqlite')||isa('dbconn','database.jdbc.connection')
            dbconn.close();
        end
        dbconn = [];
        if contains(err.message,'corrupt')
            warning('Sqlite echo_logbook.db file seems corrupted, we will save it anyway, but create a new one so that we can proceed with opening the files...');
            if isfile(db_file)
                copyfile(db_file,fullfile(datapath,'echo_logbook_corrupt.db')) ;
            end
        else
            disp(err.message);
        end
    end

    if ~isempty(dbconn)
        try
            data = dbconn.fetch('SELECT * FROM metaData');
            if ~isempty(data)
                data = data(1,:);
            end
        catch
            data = [];
        end

        if isempty(data)||isempty(data.logbook_version)||data.logbook_version<get_logbook_version
            fprintf('Updating logbook table to version %d\n',get_logbook_version);
            fix_logbook_table(dbconn);
        end
        if isempty(data)||isempty(data.ping_data_version)||data.ping_data_version<get_ping_data_version
            fprintf('Updating ping_data table to version %d\n',get_ping_data_version);
            fix_ping_data_table(dbconn);
        end
        createMetadata_table(dbconn);

        return;
    end
end

xml_file=fullfile(datapath,'echo_logbook.xml');
if isfile(xml_file) && just_create==0
    xml_logbook_to_db(xml_file);
    dbconn=connect_to_db(db_file);
    return;
end

csv_file='echo_logbook.csv';
if isfile(csv_file) && just_create == 0
    csv_logbook_to_db(datapath,csv_file,'','');
    dbconn=connect_to_db(db_file);
    return;
end

create_db_file(db_file)

dbconn=connect_to_db(db_file);

if just_create == 0 %just_create just create the empty database and does not populated it. This is only reached if the database did not exist to start with.
    [list_raw,ftypes]=list_ac_files(datapath,0);
    add_files_to_db(datapath,list_raw,ftypes,dbconn,[])
end



end