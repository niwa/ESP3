function attitude_heading=att_heading_from_gps(gps_data_obj,dt)

attitude_heading=attitude_nav_cl().empty;

n=ceil(dt/(mean(diff(gps_data_obj.Time),'omitnan')*24*60*60));
n=min(n,numel(gps_data_obj.Lat)-1);

if n>0
    [~,heading_g]=lat_long_to_km(gps_data_obj.Lat(1:n:end),gps_data_obj.Long(1:n:end));
    
    th=gps_data_obj.Time(1:n:end);
    th=th+mean(diff(th),'omitnan')/2;
    th=th(1:numel(heading_g));
    attitude_heading=attitude_nav_cl('Heading',heading_g,'Time',th);
    attitude_heading.NMEA_heading=sprintf('Extrapolated Lat/Lon(%s)',gps_data_obj.NMEA);
end

end