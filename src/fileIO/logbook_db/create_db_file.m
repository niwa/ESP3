function create_db_file(db_file)
disp_perso(get_esp3_prop('main_figure'),'Creating .db logbook file, this might take a couple minutes...');
if isfile(db_file)
    delete(db_file);
end
fprintf('Initialising to %s\n',db_file);
dbconn=sqlite(db_file,'create');

createlogbookTable(dbconn);
createsurveyTable(dbconn);
createPingTable(dbconn);
createMetadata_table(dbconn);

%creategpsTable(dbconn);

dbconn.sqlwrite('survey',table({' '},{' '},'VariableNames',{'SurveyName' 'Voyage'}));

close(dbconn);
end