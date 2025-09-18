
function ifileInfo=parse_ifile(ifile)

if  ischar(ifile)
    %if a d-,n- or t- file was specified instead of an i-file use the corresponding i-file
    tok = ifile(end-7);
    num = ifile((end-6):end);
    if (tok == 'd' || tok == 'n' || tok == 't') && ~isempty(str2double(num))
        ifile(end-7) = 'i';
    end
    
end

ifileInfo=struct('version','','compression','',...
    'snapshot',nan,'stratum','','transect',nan,...
    'ADC_sample_frequency',nan,'decimation_count',nan,...
    'Crest_to_esp_map_factor',1,...
    'rcpnk',nan,...
    'gain_compensation_NE',1,...
    'gain_compensation_SW',1,...
    'gain_compensation_SE',1,...
    'gain_NW',1,...
    'start_date',0,'finish_date',1,...
    'Lat',[nan nan],'Lon',[nan nan],...
    'HDG',[nan nan],'SOG',[nan nan],...
    'GMT',[0 1],....
    'range_offset',0,...
    'depth_factor',1/0.1875,...
    'system_calibration',659200,...
    'current_rms_offset',0,...
    'current_rms_scale_factor',1,...
    'angle_factor',21,...
    'angle_factor_alongship',21,...
    'angle_factor_athwartship',21,....
    'fore_aft_offset',0,...
    'port_stbd_offset',0,...
    'effective_beam_angle',nan,...
    'effective_pulse_width',0.001,...
    'transmit_pulse_length',0.001,...
    'absorption_coefficient',9,...
    'sound_speed',1500,'TVG_type',nan,...
    'TVG','','transducer_id','',...
    'sounder_type','',...
    'channel',nan,....
    'Cal_crest',nan,...
    'rawFileName','',...
    'rawSubDir','ek60',...
    'G0',0,....
    'SACORRECT',0,...
    'convertEk60ToCrest','nope',...
    'es60_zero_error_ping_num',nan,...
    'es60error_method',nan,...
    'es60error_offset',nan,...
    'es60error_min_std',nan,...
    'es60error_min_mean',nan,...
    'es60error_min_GOF',nan);

parameters_search=[fieldnames(ifileInfo); {'start';'finish'}];

%fid=fopen(ifile,'r');
fid=fopen(ifile,'r','n','US-ASCII');

if fid == -1
    warning(['Unable to open file ' ifile]);
    return;
end

tline = fgetl(fid);


while 1

    idx_com = strfind(tline,'#');
    if ~isempty(idx_com)&&idx_com(1)>1
        tline(idx_com(1):end) = [];
    elseif ~isempty(idx_com)
        tline(idx_com) = [];
    end
    tline = strtrim(tline);
    if isempty(tline)
        if feof(fid)
            break;
        end
        tline = fgetl(fid);
        continue;
    end
    
    for iparams=1:length(parameters_search)
        idx_str=contains(tline,parameters_search{iparams});
        if idx_str
            switch parameters_search{iparams}
                case 'start_date'
                    idx_dots=strfind(tline,':');
                    sdl = strtrim(tline(idx_dots(1)+6:end));
                    if ~isempty(sdl)
                        ifileInfo.start_date = datenum(sdl);
                    end
                case 'LAT'
                    if contains(tline,'start')
                        [ifileInfo.Lat(1),ifileInfo.Lon(1)]=parse_lat_long(tline);
                    else
                        [ifileInfo.Lat(2),ifileInfo.Lon(2)]=parse_lat_long(tline);
                    end
                case {'HDG' 'SOG'}
                    if contains(tline,'start')
                        [ifileInfo.HDG(1),ifileInfo.SOG(1)]=parse_HDG_SOG(tline);
                    else
                        [ifileInfo.HDG(2),ifileInfo.SOG(2)]=parse_HDG_SOG(tline);
                    end
                case 'GMT'
                    idx_dots=strfind(tline,':');
                    if contains(tline,'start')
                        nz = datevec(ifileInfo.start_date);
                        gmt = datevec(tline(idx_dots(2)+1:end));
                        tmp = [nz(1) nz(2) nz(3) gmt(4) gmt(5) gmt(6)];
                        offset = abs(nz(4)-tmp(4));
                        ifileInfo.GMT(1) = datenum(nz - [0 0 0 offset 0 0 ]);
                    else
                        nz = datevec(ifileInfo.finish_date);
                        gmt = datevec(tline(idx_dots(2)+1:end));
                        tmp = [nz(1) nz(2) nz(3) gmt(4) gmt(5) gmt(6)];
                        offset = abs(nz(4)-tmp(4));
                        ifileInfo.GMT(2) = datenum(nz - [0 0 0 offset 0 0 ]);
                    end
                case 'finish_date'
                    idx_dots=strfind(tline,':');
                    edl = strtrim(tline(idx_dots(1)+6:end));
                    if ~isempty(edl)
                        ifileInfo.finish_date = datenum(edl);
                    end
                case 'convertEk60ToCrest'            
                    expr='(-r).*(\w+).*(raw)';
                    subline=regexp(tline,expr,'match');
                    if ~isempty(subline)
                        subline=subline{1};
                        idx_str=strfind(subline,' ');
                        idx_str_2=union(strfind(subline,'\'),strfind(subline,'/'));
                        
                        if ~isempty(idx_str)
                            ifileInfo.rawFileName = subline(idx_str_2(end)+1:end);
                        end
                        if ~isempty(idx_str_2)
                            ifileInfo.rawSubDir = subline(idx_str(end)+1:idx_str_2(end));
                        end
                    else
                        ifileInfo.rawSubDir=[];
                        ifileInfo.rawFileName=[];
                    end
                    
                    ifileInfo.G0=get_opt(tline,'-g');
                    ifileInfo.SACORRECT=get_opt(tline,'-s');
                    ifileInfo.Cal_crest=get_opt(tline,'-c');
                    ifileInfo.channel=get_opt(tline,'-o');
                    
                otherwise
                    idx_dots=strfind(tline,':');
                    if isempty(idx_dots)
                        idx_dots=strfind(tline,'=');
                    end
                    if isempty(idx_dots)
                        continue;
                    end
                    if ~isnan(str2double(tline(idx_dots(1)+1:end)))
                        ifileInfo.(parameters_search{iparams})=str2double(tline(idx_dots(1)+1:end));
                    else
                        ifileInfo.(parameters_search{iparams})=strtrim(tline(idx_dots(1)+1:end));
                    end
                    parameters_search(iparams)=[];
                    break;
            end
        end
    end
    if feof(fid)
        break;
    end
    tline = fgetl(fid);
    
end
fclose(fid);

if ~isnan(ifileInfo.ADC_sample_frequency)
    ifileInfo.depth_factor  =  1e3/(ifileInfo.decimation_count/ifileInfo.ADC_sample_frequency*ifileInfo.sound_speed/2);
end

if ~isnan(ifileInfo.angle_factor)&&isnan(ifileInfo.angle_factor_alongship)
    ifileInfo.angle_factor_alongship = ifileInfo.angle_factor;
end
if ~isnan(ifileInfo.angle_factor)&&isnan(ifileInfo.angle_factor_athwartship)
    ifileInfo.angle_factor_athwartship = ifileInfo.angle_factor;
end

switch ifileInfo.sounder_type
    case 'CREST'
        ifileInfo.transmit_pulse_length = ifileInfo.transmit_pulse_length/38000;
end

if isnan(ifileInfo.effective_pulse_width)
    ifileInfo.effective_pulse_width = ifileInfo.transmit_pulse_length;
end


end

function opt=get_opt(tline,opt_str)

idx_opt=strfind(tline,opt_str);
subline_opt=tline(idx_opt:end);
idx_opt=strfind(subline_opt,' ');
if length(idx_opt)>=2
    opt=str2double(subline_opt(idx_opt(1):idx_opt(2)));
elseif isscalar(idx_opt)
    opt=str2double(subline_opt(idx_opt(1):end));
else
    opt=[];
end
end

function [lat,lon]=parse_lat_long(tline)
formatSpec='%s LAT: %f %f %s  LONG: %f %f %s ';
l_old=length(tline);
tline = strrep(tline, ' ', ',');
l_new=0;
while l_new<l_old
    l_old=length(tline);
    tline = strrep(tline, ',,', ',');
    l_new=length(tline);
end

out = textscan(tline,formatSpec,'delimiter',',');
lat = nan;
lon = nan;

if ~isempty(out{2})
    switch out{4}{1}
        case 'S'
            lat=-(double(out{2}) + out{3} / 60);
        otherwise
            lat=(double(out{2}) + out{3} / 60);
    end
end

if ~isempty(out{5})
    switch out{7}{1}
        case 'E'
            lon=(double(out{5}) + out{6} / 60);
        otherwise
            lon=-(double(out{5}) + out{6} / 60);
    end
end
end


function [hdg,sog]=parse_HDG_SOG(tline)
formatSpec='%s HDG: %f SOG: %f';
l_old=length(tline);
tline = strrep(tline, ' ', ',');
l_new=0;
while l_new<l_old
    l_old=length(tline);
    tline = strrep(tline, ',,', ',');
    l_new=length(tline);
end

out = textscan(tline,formatSpec,'delimiter',',');
hdg = nan;
sog = nan;
if ~isempty(out{2})
    hdg=out{2};
end
if ~isempty(out{3})
    sog=out{3};
end
end




