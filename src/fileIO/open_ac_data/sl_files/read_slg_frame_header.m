function [SL_data_struct,fsize] = read_slg_frame_header(fid,SL_data_struct,fmt,~,~)

if feof(fid)
    fsize = 0;
    return;
end

if isempty(SL_data_struct)
    ip = 1;
else
    ip = numel(SL_data_struct.offset)+1;
end

% header_len_max = 168;
% valid_channels = [0 1 2 3 4 5 9 10 11];
valid_channels = [0 1 2 3 4 5];

bool_disp_bytes = false&~isdeployed;

switch fmt
    case 3
        
        SL_data_struct.offset(ip) = fread(fid,1,'uint32');
        SL_data_struct.val(ip) = fread(fid,1,'uint32');
        SL_data_struct.framesize(ip) = fread(fid,1,'ushort');
        SL_data_struct.prev_framesize(ip) = fread(fid,1,'ushort');
        fsize = SL_data_struct.framesize(ip);
        SL_data_struct.chan_type_id(ip) = fread(fid,1,'uint32');
        
        if ~ismember(SL_data_struct.chan_type_id(ip),valid_channels) || fsize == 0
            if ip ==1
                SL_data_struct =[];
            else
                SL_data_struct.offset(ip) =[];
                SL_data_struct.val(ip) = [];
                SL_data_struct.framesize(ip) =[];
                SL_data_struct.prev_framesize(ip) =[];
                SL_data_struct.chan_type_id(ip) = [];
            end
            return;
        end
        
        %SL_data_struct.spare1(ip) = fread(fid,1,'ushort');
        SL_data_struct.frame_index(ip) = fread(fid,1,'uint32');
        tmp = fread(fid,2,'float')*0.3048;
        SL_data_struct.range_min(ip) = tmp(1);
        SL_data_struct.range_max(ip) = tmp(2);
        disp_bytes(fid,false,5);
        SL_data_struct.freq_id(ip) = fread(fid,1,'uint8');
        disp_bytes(fid,false,6);
        %SL_data_struct.stuff{ip} = fread(fid,12,'*char')';
        SL_data_struct.posixTime(ip) = fread(fid,1,'uint32');
        SL_data_struct.packetsize(ip) = fread(fid,1,'uint32');  
        SL_data_struct.depth(ip) = fread(fid,1,'float')*0.3048;
        disp_bytes(fid,false,32,'uint8');
        
        SL_data_struct.gps_speed_knots(ip) = fread(fid,1,'float');
        SL_data_struct.temperature(ip) = fread(fid,1,'float');
        SL_data_struct.long(ip) = east_to_long(fread(fid,1,'int32'));
        SL_data_struct.lat(ip) = north_to_lat(fread(fid,1,'int32'));
        SL_data_struct.water_speed(ip) = fread(fid,1,'float');
        SL_data_struct.cog(ip) = fread(fid,1,'float')/180*pi;
        SL_data_struct.altitude(ip) = fread(fid,1,'float');
        SL_data_struct.heading(ip) = fread(fid,1,'float')/180*pi;
        SL_data_struct.flags(ip) = fread(fid,1,'ushort');
        
        disp_bytes(fid,false,2);
        
        SL_data_struct.spare(ip) = fread(fid,1,'uint32');
        SL_data_struct.timeOffset(ip) = fread(fid,1,'uint32');
        SL_data_struct.prev_prim_offset(ip) = fread(fid,1,'uint32');
        SL_data_struct.prev_sec_offset(ip) = fread(fid,1,'uint32');
        SL_data_struct.prev_downscan_offset(ip) = fread(fid,1,'uint32');
        SL_data_struct.prev_left_sidescan_offset(ip) = fread(fid,1,'uint32');
        SL_data_struct.prev_right_sidescan_offset(ip) = fread(fid,1,'uint32');
        SL_data_struct.prev_composite_sidescan_offset(ip) = fread(fid,1,'uint32');
        
        disp_bytes(fid,false,12);
        
        SL_data_struct.prev_dc_offset(ip) = fread(fid,1,'uint32');
        SL_data_struct.header_length(ip) = SL_data_struct.framesize(ip)-SL_data_struct.packetsize(ip);
    case 2
        
        SL_data_struct.offset(ip) = fread(fid,1,'uint32');
        SL_data_struct.prev_prim_offset(ip) = fread(fid,1,'uint32');
        SL_data_struct.prev_sec_offset(ip) = fread(fid,1,'uint32');
        SL_data_struct.prev_downscan_offset(ip) = fread(fid,1,'uint32');
        SL_data_struct.prev_left_sidescan_offset(ip) = fread(fid,1,'uint32');
        SL_data_struct.prev_right_sidescan_offset(ip) = fread(fid,1,'uint32');
        SL_data_struct.prev_composite_sidescan_offset(ip) = fread(fid,1,'uint32');
        
        SL_data_struct.framesize(ip) = fread(fid,1,'ushort');
        SL_data_struct.prev_framesize(ip) = fread(fid,1,'ushort');
        fsize = SL_data_struct.framesize(ip);
        SL_data_struct.chan_type_id(ip) = fread(fid,1,'ushort');
        SL_data_struct.packetsize(ip) = fread(fid,1,'ushort');
        
        if ~ismember(SL_data_struct.chan_type_id(ip),valid_channels)
            if ip ==1
                SL_data_struct =[];
            else
                SL_data_struct.offset(ip) =[];
                SL_data_struct.prev_prim_offset(ip) = [];
                SL_data_struct.prev_sec_offset(ip) = [];
                SL_data_struct.prev_downscan_offset(ip) = [];
                SL_data_struct.prev_left_sidescan_offset(ip) = [];
                SL_data_struct.prev_right_sidescan_offset(ip) = [];
                SL_data_struct.prev_composite_sidescan_offset(ip) = [];
                SL_data_struct.framesize(ip) =  [];
                SL_data_struct.prev_framesize(ip) = [];
                SL_data_struct.chan_type_id(ip) = [];
                SL_data_struct.packetsize(ip) = [];
            end
            return;
        end
        
        SL_data_struct.frame_index(ip) = fread(fid,1,'uint32');
        tmp = fread(fid,2,'float')*0.3048;
        SL_data_struct.range_min(ip) = tmp(1);
        SL_data_struct.range_max(ip) = tmp(2);
        disp_bytes(fid,false,5);
        SL_data_struct.freq_id(ip) = fread(fid,1,'uint8');
        disp_bytes(fid,false,6);
        SL_data_struct.posixTime(ip) = fread(fid,1,'uint32');
        SL_data_struct.depth(ip) = fread(fid,1,'float')*0.3048;
        SL_data_struct.keelDepth(ip) = fread(fid,1,'float')*0.3048;
        disp_bytes(fid,bool_disp_bytes,28);
        SL_data_struct.gps_speed_knots(ip) = fread(fid,1,'float');
        SL_data_struct.temperature(ip) = fread(fid,1,'float');
        SL_data_struct.long(ip) = east_to_long(fread(fid,1,'int32'));
        SL_data_struct.lat(ip) = north_to_lat(fread(fid,1,'int32'));
        SL_data_struct.water_speed(ip) = fread(fid,1,'float');
        SL_data_struct.cog(ip) = fread(fid,1,'float')/180*pi;
        SL_data_struct.altitude(ip) = fread(fid,1,'float');
        SL_data_struct.heading(ip) = fread(fid,1,'float')/180*pi;
        SL_data_struct.flags(ip) = fread(fid,1,'ushort');
        disp_bytes(fid,bool_disp_bytes,6);
        SL_data_struct.timeOffset(ip) = fread(fid,1,'uint32');
        
        SL_data_struct.header_length(ip) = SL_data_struct.framesize(ip)-SL_data_struct.packetsize(ip);
end

end


function long = east_to_long(east)
long = east/6356752.3142/pi*180;
end

function lat = north_to_lat(north)
lat = (2*atan(exp(north/6356752.3142))-pi/2)/pi*180;
end
