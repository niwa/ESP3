function [lat_disp,lon_disp] = reducem_perso(lat,long,dg)
try
    [lat_disp,lon_disp] = reducem(lat(:),long(:));
    if isempty(lat_disp)
        lat_disp = lat;
        lon_disp = long;
    end
catch
    [lat_disp,~,ia]=unique([lat(1:dg:end) lat(end)],'stable');
    lon_disp=long(ia);
end