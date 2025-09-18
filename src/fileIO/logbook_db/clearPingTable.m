function clearPingTable(dbconn,filename,freq,t_lim)
    sql_cmd=sprintf('DELETE FROM ping_data WHERE instr(filename, ''%s'')>0 AND frequency =%d AND time >= ''%s'' AND time <= ''%s'';',...
        filename,freq,datestr(t_lim(1),'yyyy-mm-dd HH:MM:SS'),datestr(t_lim(end),'yyyy-mm-dd HH:MM:SS'));
    
    dbconn.exec(sql_cmd);  
end