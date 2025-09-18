function [start_time,end_time] = start_end_time_from_kem_file(filename)

%% parameters
% block size for reading binary data in file
BLCK_SIZE = 1e6;

%% initialize results
start_time = 0;
end_time = 1e9;

%% open file
fid = fopen(filename,'r','l','US-ASCII');

if fid==-1
    return;
end

%% find start time in file
% by reading blocks of binary and looking for data start tags
found_start=false;
fseek(fid,0,'bof');
while ~feof(fid)&&~found_start
    
    pos = ftell(fid);
    
    % read block in strings
    str_read = fread(fid,BLCK_SIZE,'*char')';
    
    % check if tag is in it
    idx_dg = unique([strfind(str_read,'#IIP') strfind(str_read,'#IOP') strfind(str_read,'#MRZ') strfind(str_read,'#MWC')]);
    
    for ui=1:numel(idx_dg)
        % rewind till beggining of data packet
        idx_start = pos+idx_dg(ui)-5;
        fseek(fid,idx_start,-1);
        % and read time from the header
        header = read_kem_header(fid);
        start_time = header.time;
        % exit if date is good
        if start_time>datenum('01-Jan-1601')&&start_time<=now
            found_start=true;
            break;
        end       
    end
    
    % if data not found, increase the data being read and reloop
    if ~feof(fid)
        fseek(fid,-3,'cof');
    end
end

% go to end of file
fseek(fid,0,'eof');

%% find end time in file
pos = ftell(fid);
BLCK_SIZE = min(pos,BLCK_SIZE);
fseek(fid,-BLCK_SIZE,'cof');
found_end=false;

while pos >0&&~found_end
    
    % read block in strings
    pos = ftell(fid);    
    str_read = fread(fid,BLCK_SIZE,'*char')';    
    % check if tag is in it
    idx_dg = unique([strfind(str_read,'#IIP') strfind(str_read,'#IOP') strfind(str_read,'#MRZ') strfind(str_read,'#MWC')]);
    for ui=numel(idx_dg):-1:1
        % rewind till beggining of data packet
        idx_end = pos+idx_dg(ui)-5;
        fseek(fid,idx_end,-1);
        % and read time from the header
        header = read_kem_header(fid);
        end_time = header.time;
        % exit if date is good
        if end_time>start_time&&end_time>datenum('01-Jan-1601')&&end_time<=now
            found_end=true;
            break;
        end
    end
    % if data not found, move back some more and reloop
    fseek(fid,-2*BLCK_SIZE+3,'cof');
end



%% close file
fclose(fid);

[pathsave,name,ext] = fileparts(filename);
fsave = append(pathsave,'\',"TimeCorrection.mat");

if isfile(fsave)
    TimeCorrection = load(fsave);
    filenames = TimeCorrection.TimeCorrection.File_names;
    fname=strcat(name,ext);
    if all(ismember(fname, filenames))
        t_offset = seconds(TimeCorrection.TimeCorrection.Time_offset{3}*3600+TimeCorrection.TimeCorrection.Time_offset{2}*60+TimeCorrection.TimeCorrection.Time_offset{1});   
        start_time = datenum(start_time+seconds(t_offset));
        end_time = datenum(end_time+seconds(t_offset));
    end
end

end
