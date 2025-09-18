function [dist_in_km,heading_in_deg] = lat_long_to_km(lat,lon)

nb_pt = numel(lat);
try
    if isdeployed() || license('test','MAP_Toolbox')
        lat = lat(:);
        lon = lon(:);
        [dist_in_deg,heading_in_deg] = distance([lat(1:nb_pt-1) lon(1:nb_pt-1)],[lat(2:nb_pt) lon(2:nb_pt)]);
        dist_in_km  = deg2km(dist_in_deg);
    else
        [dist_in_km,heading_in_deg] = perso_fcn(lat,lon);
    end
catch err
    print_errors_and_warnings([],'warning',err);
    dist_in_km=zeros(1,numel(lat)-1);
    heading_in_deg=zeros(1,numel(lat)-1);
end
end

function [dist_in_km,heading_in_deg] = perso_fcn(lat,lon)
nb_pt = numel(lat);
%WGS-84
%could also use easting, northing
a = 6378137;
f = 1/298.257223563;
b = (1-f)*a;
lat1 = lat(1:nb_pt-1).* pi / 180;
lat2 = lat(2:nb_pt).* pi / 180;
lon1 = lon(1:nb_pt-1).* pi / 180;
lon2 = lon(2:nb_pt).* pi / 180;
redLat1 = atan((1-f)*tan(lat1));
redLat2 = atan((1-f)*tan(lat2));
L = lon2-lon1;
lambda = L;
myeps = 1;
while myeps>10^(-12)
    old_lambda = lambda;
    sin_sigma = sqrt((cos(redLat2).*sin(lambda)).^2+(cos(redLat1).*sin(redLat2)-cos(redLat2).*sin(redLat1).*cos(lambda)).^2);
    cos_sigma = sin(redLat1).*sin(redLat2)+cos(redLat1).*cos(redLat2).*cos(lambda);
    sigma = atan2(sin_sigma,cos_sigma);
    az = real(asin(cos(redLat1).*cos(redLat2).*sin(lambda)./sin(sigma)));
    sigmam = real(acos(cos(sigma)-(2*sin(redLat1).*sin(redLat2))./cos(az).^2)/2);
    C = f/16*cos(az).^2.*(4+f*(4-3*cos(az).^2));
    lambda = L+(1-C)*f.*sin(az).*(sigma+C.*sin(sigma).*(cos(2*sigmam)+C.*cos(sigma).*(2*cos(2*sigmam).^2-1)));
    myeps = abs(lambda-old_lambda);
end
u2 = cos(az).^2.*(a^2-b^2)/b^2;
A  = 1 + u2/16384.*(4096+u2.*(u2.*(320-175*u2)-768));
B = u2/1024.*(256+u2.*(u2.*(74-47*u2)-128));
sigma_diff = B.*sin(sigma).*(cos(2*sigmam)+1/4*B.*(cos(sigma).*(2*cos(2*sigmam).^2-1)-B/6.*cos(2*sigmam).*(4*sin(sigma).^2-3).*(4*cos(2*sigmam).^2-3)));
dist_in_km = b*A.*(sigma-sigma_diff)/1000;
heading_in_deg = atan2d(cos(redLat2).*sin(lambda),cos(redLat1).*sin(redLat2)-sin(redLat1).*cos(redLat2).*cos(lambda));
heading_in_deg(heading_in_deg<0) = heading_in_deg(heading_in_deg<0)+360;
end
