function fix_logbook_table(dbconn)

data = dbconn.sqlread('logbook');
dbconn.exec('DROP TABLE logbook');
createlogbookTable(dbconn);
if ~isempty(data)
    %dbconn.sqlwrite('logbook',data);
    datainsert_perso(dbconn,'logbook',data);
end

end