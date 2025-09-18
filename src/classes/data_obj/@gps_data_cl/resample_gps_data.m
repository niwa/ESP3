function obj=resample_gps_data(gps_obj,time)

if ~isempty(gps_obj)&&~isempty(gps_obj.Lat)&&~all(isnan(gps_obj.Lat))
    if iscolumn(time)
        time=time';
    end
    
    idx_keep  = ~isnan(gps_obj.Lat)&~isnan(gps_obj.Long);
    gps_obj_lat = gps_obj.Lat(idx_keep);
    gps_obj_lon = gps_obj.Long(idx_keep);
    gps_obj_time = gps_obj.Time(idx_keep);
    
    [lat,time]=resample_data_v2(gps_obj_lat,gps_obj_time,time,'Type','Angle');
    long=resample_data_v2(gps_obj_lon,gps_obj_time,time,'Type','Angle');    
    long(long<0) = long(long<0)+360;
    
    corr_max_lat = max(2*prctile(abs(diff(gps_obj_lat)),99),1e-6);
    corr_max_lon = max(2*prctile(abs(diff(gps_obj_lon)),99),1e-6);
    
    idx_nan_before = find(time<gps_obj_time(1)); 
    idx_nan_after = find(time>gps_obj_time(end));

    
    if ~isempty(idx_nan_before)
        idx_nan_before = idx_nan_before(abs(lat(idx_nan_before)-gps_obj_lat(1))>corr_max_lat.*(idx_nan_before(end)-idx_nan_before+1)|...
            abs(long(idx_nan_before)-gps_obj_lon(1))>corr_max_lon.*(idx_nan_before(end)-idx_nan_before+1));
    end
    
    if ~isempty(idx_nan_after)
        idx_nan_after = idx_nan_after(abs(lat(idx_nan_after)-gps_obj_lat(end))>corr_max_lat.*(idx_nan_after(end)-idx_nan_after+1)|...
            abs(long(idx_nan_after)-gps_obj_lon(end))>corr_max_lon.*(idx_nan_after(end)-idx_nan_after+1));
    end
    
    idx_nan = union(idx_nan_before,idx_nan_after);
     
    lat(idx_nan)=nan;
    long(idx_nan)=nan;
    
    nmea=gps_obj.NMEA;
    
    if sum((size(long)==size(time)))<2
        time=time';
    end
    
    if ~isempty(lat)
        if any(isnan(lat))
            warning('Issue with navigation data... No position for every pings');
        end
        obj=gps_data_cl('Lat',lat,'Long',long,'Time',time,'NMEA',nmea);
    else
        warning('Issue with navigation data...')
        obj=gps_data_cl('Time',time);
    end
else
    obj=gps_data_cl('Time',time);
end


end