function [gps_data,attitude_data,depth_line]=read_n_file(filename,start_time,end_time)

filename(end-7)='n';

%fid=fopen(filename,'r');

gps_data = gps_data_cl.empty();
attitude_data = attitude_nav_cl.empty();
depth_line = line_cl.empty();

if ~isfile(filename)
        warning('No navigation file %s' ,filename);
    return;

end

fid=fopen(filename,'r','l','US-ASCII');

if fid == -1
    warning('Unable to open file %s',filename);
    return;
end

%'4 LAT: 43 18.2600 S LONG: 174 7.4600 E HDG: 164 SOG: 7.3 HDT: Depth: No HPR';
formatSpec='%f LAT: %f %f %c LONG: %f %f %c HDG: %f SOG: %f HDT: %f Depth: %f ';
lat = [];
lon = [];
heading = [];
sog = [];

ui=0;

str_to_find = {'LAT:' 'LONG:' 'HDG:' 'SOG:' 'HDT:' 'Depth:' 'No HPR'};


while (true)
    if (feof(fid))
        break;
    end

    t_line = fgetl(fid);
    if ~ischar(t_line)
        break;
    end

    t_line=strtrim(t_line);
    id_find = cellfun(@(x) strfind(t_line,x),str_to_find,'UniformOutput',false);
    id_find(cellfun(@isempty,id_find)) = {NaN};
    id_find  =cell2mat(id_find);
    [id_find,ia] = sort(id_find);
    str_to_find = str_to_find(ia(~isnan(id_find)));
    id_find = id_find(~isnan(id_find));

    ui_s = id_find+cellfun(@numel,str_to_find);
    ui_e = [ui_s(2:end)-cellfun(@numel,str_to_find(2:end))-1 numel(t_line)];

    ui=ui+1;

    lat(ui) = nan;
    lon(ui) = nan;
    sog(ui) = nan;
    heading(ui) = nan;
    depth(ui) = nan;


    for istr = 1:numel(ui_s)
        tmp_str = strtrim(t_line(ui_s(istr):ui_e(istr)));
        switch str_to_find{istr}
            case 'LAT:'
                out = textscan(tmp_str,'%f %f %c');
                switch out{3}
                    case 'S'
                        lat(ui)=-(double(out{1}) + out{2} / 60);
                    otherwise
                        lat(ui)=(double(out{1}) + out{2} / 60);
                end
            case 'LONG:'
                out = textscan(tmp_str,'%f %f %c');
                switch out{3}
                    case 'E'
                        lon(ui)=(double(out{1}) + out{2} / 60);
                    otherwise
                        lon(ui)=-(double(out{1}) + out{2} / 60);
                end
            case 'HDG:'
                heading(ui) = str2double(tmp_str);
            case 'SOG:'
                sog(ui) = str2double(tmp_str);
            case 'HDT:'
                heading(ui) = str2double(tmp_str);
            case 'Depth:'
                depth(ui) = str2double(tmp_str);
            case 'No HPR'

        end
    end

end
fclose(fid);

if ~isempty(lat)
    time=linspace(start_time,end_time,length(lat));

    gps_data=gps_data_cl('Lat',lat,'Long',lon,'Speed',sog,'Time',time,'NMEA','Esp2');
    attitude_data=attitude_nav_cl('Heading',heading,'Time',time);
    if any(~isnan(depth))
        depth_line = line_cl('Name','Transceiver Depth(m)','Range',depth(~isnan(depth)),'Time',time(~isnan(depth)),'Tag','offset');
    else
        depth_line = [];
    end
end

end
