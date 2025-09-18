function [header,config]=read_EK80_config(filename,varargin)

HEADER_LEN=12;
if ischar(filename)
    fid=fopen(filename,'r','l','US-ASCII');
else
    fid = filename;
end

len=fread(fid, 1, 'int32');
header=-1;
config=-1;
read_config_bool = true;

if nargin > 1
    read_config_bool = varargin{1};
end
    

[dgType, ~] =readEK60Header_v2(fid);

switch (dgType)
    case 'XML0'

        t_line=(fread(fid,len-HEADER_LEN,'*char'))';
        t_line=deblank(t_line);

        if ~contains(lower(t_line),'xml')
            header=-1;
            config=-1;
            fclose(fid);
            return;
        end

        fread(fid, 1, 'int32');
        [header,config,~]=read_xml0(t_line,read_config_bool);
        if ~isempty(config) && read_config_bool
            config = cellfun(@(x)config_obj_from_EK80_xml_struct(x,'',[]),config,'UniformOutput',false);
        end
    case 'CON0'
        header = readEKRaw_ReadConfigHeader(fid);
        header.time = dgTime;
    otherwise
        disp(dgType);
        disp('First Datagram is not XML0... EK60 file?');
end

if ischar(filename)
    fclose(fid);
end

