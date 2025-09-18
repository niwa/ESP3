function [start_time,end_time] = start_end_time_from_all_wcd_file(filename)

[~,~,tt_f] = fileparts(filename);

switch tt_f
    case '.all'
        BLCK_SIZE = 1e3;
    case '.wcd'
        BLCK_SIZE = 1e6;
end

%% parameters
% block size for reading binary data in file


%% initialize results
start_time = 0;
end_time = 1e9;

[raw_type,b_ordering] = get_ftype(filename);
%% open file
[fid,~] = fopen(filename, 'r',b_ordering);


if fid==-1
    return;
end

%% find start time in file
% by reading blocks of binary and looking for data start tags
found_start=false;
fseek(fid,0,'bof');

while ~feof(fid)&&~found_start
    pos = ftell(fid);

    header_struct  = read_em_header(fid);

    if feof(fid)|| isempty(header_struct.dgSize) ||header_struct.dgSize == 0
        break
    end

    if header_struct.stx~=2
        fseek(fid,pos+4+header_struct.dgSize,-1);
        continue;
    end

    found_start = true;

    start_time = header_struct.time;
    emNumber = header_struct.emNumber;
    systemSerialNumber = header_struct.systemSerialNumber;

end



% go to end of file
fseek(fid,0,'eof');

%% find end time in file
pos = ftell(fid);
fseek(fid,-2*BLCK_SIZE,'cof');
read_all = false;
found_end = false;
while pos >= 0 && ~read_all && ~found_end

    % read block in strings
    pos = ftell(fid);
    int_read = fread(fid,BLCK_SIZE,'uint16')';
    % check if tag is in it

    idx_num = find(int_read == emNumber);
    idx_serial = find(int_read ==systemSerialNumber);

    if isempty(idx_num) || isempty(idx_serial)
        fseek(fid,max(-4*BLCK_SIZE+5,-pos),'cof');
        continue;
    end

    dist = idx_serial'-idx_num;

    if any(dist == 6,'all')
        [~,id_n] = find(dist == 6);
        for iddn = flipud(id_n)'
            idx_end = pos+idx_num(iddn)*2-8;
            fseek(fid,idx_end,-1);

            header_struct  = read_em_header(fid);

            if ~isempty(header_struct.dgSize) && header_struct.stx==2
                end_time = header_struct.time;
                if end_time>start_time&&end_time>datenum('01-Jan-1601')&&end_time<=now
                    found_end = true;
                    break;
                end
            end
        end
    end

    if 2*BLCK_SIZE>pos
        read_all = true;
    end

    fseek(fid,max(-4*BLCK_SIZE+5,-pos),'cof');
end

%% close file
fclose(fid);



end
