function configXcvr = readEKRaw_ReadTransceiverConfig(fid)
%readEKRaw_ReadTransceiverConfig  Read EK/ES transceiver configuration data
%   configXcvr = readEKRaw_ReadTransceiverConfig(fid) returns a
%       structure containing the transceiver configuration from a EK/ES raw
%       data file.
%
%   REQUIRED INPUT:
%               fid:    file handle id
%
%   OPTIONAL PARAMETERS:    None
%       
%   OUTPUT:
%       Output is a data structure containing the transceiver configuration
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

configXcvr.channelid = char(fread(fid,128,'uchar')');
configXcvr.beamtype = fread(fid,1,'int32');
configXcvr.frequency = fread(fid,1,'float32');
configXcvr.gain = fread(fid,1,'float32');
configXcvr.equivalentbeamangle = fread(fid,1,'float32');
configXcvr.beamwidthalongship = fread(fid,1,'float32');
configXcvr.beamwidthathwartship = fread(fid,1,'float32');
configXcvr.anglesensitivityalongship = fread(fid,1,'float32');
configXcvr.anglesensitivityathwartship = fread(fid,1,'float32');
configXcvr.anglesoffsetalongship = fread(fid,1,'float32');
configXcvr.angleoffsetathwartship = fread(fid,1,'float32');
configXcvr.posx = fread(fid,1,'float32');
configXcvr.posy = fread(fid,1,'float32');
configXcvr.posz = fread(fid,1,'float32');
configXcvr.dirx = fread(fid,1,'float32');
configXcvr.diry = fread(fid,1,'float32');
configXcvr.dirz = fread(fid,1,'float32');
configXcvr.pulselengthtable = fread(fid,5,'float32');
configXcvr.spare2 = char(fread(fid,8,'uchar')');
configXcvr.gaintable = fread(fid,5,'float32');
configXcvr.spare3 = char(fread(fid,8,'uchar')');
configXcvr.sacorrectiontable = fread(fid,5,'float32');
configXcvr.spare4 = char(fread(fid,8,'uchar')');
configXcvr.GPTSoftwareVersion = char(fread(fid,16,'uchar')');
configXcvr.spare5 = char(fread(fid,28,'uchar')');
