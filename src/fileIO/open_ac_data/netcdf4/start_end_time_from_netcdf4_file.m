function [start_time,end_time] = start_end_time_from_netcdf4_file(filename)

%% initialize results
start_time = 0;
end_time = 1e9;


try
    finfo = h5info(filename);
    
    Groups_name  = {finfo.Groups(:).Name};
    %     idx_g_top  = find(contains(Groups_name,'Top-level'));
    %     idx_g_env  = find(contains(Groups_name,'Environment'));
    idx_g_sonar  = find(contains(Groups_name,'Sonar'));
    
    if ~isempty(idx_g_sonar)
        names = {finfo.Groups(idx_g_sonar).Groups(1).Datasets(:).Name};
        idx_ping_time = strcmpi(names,'ping_time');
        if any(idx_ping_time)
            nb_pings = finfo.Groups(idx_g_sonar).Groups(1).Datasets(idx_ping_time).Dataspace.Size;
            time_file_start = h5read(filename,sprintf('%s/%s',finfo.Groups(idx_g_sonar).Groups(1).Name,'ping_time'),1,1);
            start_time = datenum(1601, 1, 1, 0, 0, double(time_file_start)/1e9);
            time_file_end = h5read(filename,sprintf('%s/%s',finfo.Groups(idx_g_sonar).Groups(1).Name,'ping_time'),nb_pings,1);
            end_time = datenum(1601, 1, 1, 0, 0, double(time_file_end)/1e9);
        end
    end
    
catch err
   print_errors_and_warnings(1,'error',err);
end
