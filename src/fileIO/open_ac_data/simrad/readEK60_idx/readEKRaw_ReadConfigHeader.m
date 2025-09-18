function configheader = readEKRaw_ReadConfigHeader(fid)
%readEKRaw_ReadConfigHeader  Read EK/ES DG configuration header
%   configheader = readEKRaw_ReadConfigHeader(fid) returns a  structure
%       containing an ES/EK file configuration header.
%
%   REQUIRED INPUT:
%               fid:    file handle id
%
%   OPTIONAL PARAMETERS:    None
%       
%   OUTPUT:
%       Output is a data structure containing the file configuration header
%
%   REQUIRES:   None
%

%   Rick Towler
%   NOAA Alaska Fisheries Science Center
%   Midwater Assesment and Conservation Engineering Group
%   rick.towler@noaa.gov
%
%   Based on code by Lars Nonboe Andersen, Simrad.

%-

configheader.surveyname = char(fread(fid,128,'uchar')');
configheader.transectname = char(fread(fid,128,'uchar')');
configheader.soundername = char(fread(fid,128,'uchar')');
configheader.version = deblank(char(fread(fid,30,'uchar')'));
configheader.multiplexing = fread(fid,1,'short');
configheader.TimeBias = fread(fid,1,'long');
configheader.SVmean = fread(fid,1,'float');
configheader.SVtrans = fread(fid,1,'float');
configheader.spare = char(fread(fid,84,'uchar')');
configheader.transceivercount = fread(fid,1,'long');
