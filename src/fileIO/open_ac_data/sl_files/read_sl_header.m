function header_struct = read_sl_header(fid)

tmp =  fread(fid,3,'ushort');
header_struct.format = tmp(1);
header_struct.version = tmp(2);
header_struct.framesize = tmp(3);
header_struct.debug = fread(fid,1,'int8');
header_struct.spare = fread(fid,1,'int8');
if header_struct.format ==0
    header_struct.spare2 = fread(fid,1,'int8');
else
    header_struct.spare2 = 0;
end

end