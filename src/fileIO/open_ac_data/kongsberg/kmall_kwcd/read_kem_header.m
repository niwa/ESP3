function header_struct  = read_kem_header(fid)

header_struct.dgSize = fread(fid,1,'uint32');

if ~isempty(header_struct.dgSize)
    header_struct.dgmType = fscanf(fid,'%c',4);
    header_struct.dgmVersion = fread(fid,1,'uint8');
    header_struct.systemID = fread(fid,1,'uint8');
    header_struct.echoSounderID = fread(fid,1,'uint16');

    time_sec = fread(fid,1,'uint32');
    time_nanosec = fread(fid,1,'uint32');
    header_struct.time = datenum(datetime(time_sec + time_nanosec.*10^-9,'ConvertFrom','posixtime'));
end

end