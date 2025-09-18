function header_struct  = read_em_header(fid)
header_struct.dgSize            = fread(fid,1,'uint32'); % number of bytes in datagram
if ~isempty(header_struct.dgSize)
    header_struct.stx               = fread(fid,1,'uint8');  % STX (always H02)
    header_struct.dgNumber          = fread(fid,1,'uint8');  % SIMRAD type of datagram
    header_struct.emNumber          = fread(fid,1,'uint16'); % EM Model Number
    dateTSMM                        = fread(fid,2,'uint32'); %
    Y = floor(dateTSMM(1)/1e4);
    M = floor((dateTSMM(1)-Y*1e4)/1e2);
    D = floor((dateTSMM(1)-Y*1e4 - M*1e2));
    header_struct.time = datenum(Y,M,D) + dateTSMM(2)./(1000.*60.*60.*24);
    header_struct.number                          = fread(fid,1,'uint16'); % datagram or ping number
    header_struct.systemSerialNumber              = fread(fid,1,'uint16'); % EM system serial number
end
end