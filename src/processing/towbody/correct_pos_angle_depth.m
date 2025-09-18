function [new_lat,new_long,hfig]=correct_pos_angle_depth(old_lat,old_long,angle_deg,depth_m)


distance=depth_m/tand(angle_deg);

n=min(numel(old_lat)-1,10);

[~,heading]=lat_long_to_km(old_lat(1:n:end),old_long(1:n:end));

heading=mode(round(heading));

[x_ship,y_ship,Zone]=ll2utm(old_lat,old_long);

Y_new=y_ship-distance*cosd(heading);%E
X_new=x_ship-distance*sind(heading);%N

[new_lat,new_long] = utm2ll(X_new,Y_new,Zone);

LongLim=[min(union(old_long,new_long)) max(union(old_long,new_long))];

LatLim=[min(union(old_lat,new_lat)) max(union(old_lat,new_lat))];

[LatLim,LongLim]=ext_lat_lon_lim_v2(LatLim,LongLim,0.3);


hfig=new_echo_figure([],'Name','Corrected Navigation');
ax=geoaxes(hfig);
format_geoaxes(ax);

geoplot(ax,old_lat(1),old_long(1),'Marker','o','Markersize',10,'Color',[0 0.5 0],'tag','start');
geoplot(ax,old_lat,old_long,'Color','k','tag','Nav');
geoplot(ax,new_lat(1),new_long(1),'Marker','o','Markersize',10,'Color',[0 0.5 0],'tag','start');
geoplot(ax,new_lat,new_long,'Color','r','tag','Nav');
geolimits(ax,LatLim,LongLim);