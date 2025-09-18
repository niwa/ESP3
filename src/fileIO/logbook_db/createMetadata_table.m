function createMetadata_table(dbconn)
    
    try
        dbconn.exec('DROP TABLE metaData');
    end

    createmetaData_str = ['CREATE TABLE metaData ' ...
        sprintf('(logbook_version INTEGER DEFAULT %d,',get_logbook_version)...
        sprintf('ping_data_version INTEGER DEFAULT %d,',get_ping_data_version)...
        'UNIQUE (logbook_version,ping_data_version) ON CONFLICT IGNORE);'];
    dbconn.exec(createmetaData_str);
    dbconn.sqlwrite('metaData',table(get_logbook_version,get_ping_data_version,'VariableNames',{'logbook_version' 'ping_data_version'}));
