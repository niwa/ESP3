function fix_ping_data_table(dbconn)
try
    data = dbconn.sqlread('ping_data');
    dbconn.exec('DROP TABLE ping_data');
catch err
    data = [];
    print_errors_and_warnings([],'warning',err);
end
createPingTable(dbconn);
if ~isempty(data)
    sd = 1e4;
    numel_data = size(data(:,1),1);
    num_ite = ceil(numel_data/sd);

    for ui = 1:num_ite
        idx_data = (ui-1)*sd+1:ui*sd;
        idx_data(idx_data>numel_data) = [];
        %dbconn.sqlwrite('ping_data',data);
        datainsert_perso(dbconn,'ping_data',data(idx_data,:));
    end

end