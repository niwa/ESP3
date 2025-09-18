function gps_data = get_ping_data_from_db(filenames,freq_ori)

if isempty(filenames)
    gps_data={[]};
    return;
end

if~iscell(filenames)
    filenames ={filenames};
end

[path_cell,~,~] = cellfun(@fileparts,filenames(~isfolder(filenames)),'UniformOutput',false);
path_cell = [path_cell,filenames(isfolder(filenames))];
[path_cell_unique,~,idx_u] = unique(path_cell);


gps_data=cell(1,length(filenames));
idf = 0;
for uip = 1:numel(path_cell_unique)
    db_file=fullfile(path_cell_unique{uip},'echo_logbook.db');

    if ~isfile(db_file)
        continue;
    end
    %tic
    try
        dbconn=connect_to_db(db_file);
        if isempty(dbconn)
            continue;
        end
        subfilenames = filenames(idx_u==uip);
        [~,ftemp,~] = cellfun(@fileparts,subfilenames,'UniformOutput',false);
        for ip=1:length(subfilenames)
            idf = idf+1;
            if isempty(freq_ori)
                try
                    freq=dbconn.fetch(sprintf('SELECT Frequency FROM ping_data WHERE instr(Filename,''%s'') >0 limit 1',ftemp{ip}));
                    freq = freq.Frequency;
                catch
                    freq=[];
                end
            else
                freq=freq_ori;
            end


            if isfolder(subfilenames{ip})
                if isempty(freq)
                    gps_data_f=dbconn.fetch('SELECT Lat,Long,Time FROM ping_data');
                else
                    gps_data_f=dbconn.fetch(sprintf('SELECT Lat,Long,Time FROM ping_data WHERE Frequency = %f',freq));
                end
            else
                if isempty(freq)
                    gps_data_f=dbconn.fetch(sprintf('SELECT Lat,Long,Time FROM ping_data WHERE instr(Filename, ''%s'') >0',ftemp{ip}));
                else
                    gps_data_f=dbconn.fetch(sprintf('SELECT Lat,Long,Time FROM ping_data WHERE instr(Filename, ''%s'') >0 AND Frequency = %f',ftemp{ip},freq));
                end

            end


            if ~isempty(gps_data_f)
                lat=(gps_data_f.Lat);
                lon=(gps_data_f.Long);
                time=datenum(gps_data_f.Time,'yyyy-mm-dd HH:MM:SS');
                idx_nan=isnan(lat);
                gps_data{idf}=gps_data_cl('Lat',lat(~idx_nan),...,...
                    'Long',lon(~idx_nan),...
                    'Time',time(~idx_nan));
            end

        end
%toc;
% tic;
%         if any(cellfun(@isfolder,subfilenames))
%             gps_data_f=dbconn.fetch('SELECT Lat,Long,Time FROM ping_data');
% 
%         else
%             sqlq = sprintf('SELECT Lat,Long,Time,Frequency,Filename FROM ping_data WHERE instr(Filename, ''%s'') >0',ftemp{1});
% 
% 
%             for ip=2:length(subfilenames)
%                 sqlq = [sqlq sprintf(' OR instr(Filename, ''%s'') >0',ftemp{ip})];
%             end
%         end
% 
%         gps_data_t=dbconn.fetch(sqlq);
% 
%         freqs = unique(gps_data_t.Frequency);
%         if ~isempty(freq_ori)
%             id_freq = find(freqs == freq_ori);
%         else
%             id_freq  = 1;
%         end
%         if isempty(id_freq)
%             id_freq  = 1;
%         end
% 
%         ff = unique(gps_data_t.Filename,'stable');
%         nb_f = numel(unique(gps_data_t.Filename));
% 
% 
%         for ig = 1:nb_f
%             id_f = contains(filenames,ff{ig});
%             gps_data_f{id_f} =  gps_data_t(contains(gps_data_t.Filename,ff{ig}) & gps_data_t.Frequency == freqs(id_freq),:);
%         end
%         toc

        close(dbconn);
    catch err
        print_errors_and_warnings([],'error',err);
    end
end
end