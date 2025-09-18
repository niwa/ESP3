function [dgType,ntSecs]=readEK60Header_v3(fobj)

%  read datagram type
dgType = fobj.readf(4,'uchar')';

%  read datagram time (NT Time - number of 100-nanosecond
%  intervals since January 1, 1601)
time_tot=double(fobj.readf(2,'uint32'));
%  convert NT time to seconds
if numel(time_tot)>=2
    ntSecs = (time_tot(2) * 2 ^ 32 + time_tot(1)) / 10000000;
else
    ntSecs = 0;
end
end