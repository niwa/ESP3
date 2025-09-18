function survey_data=get_survey_data_from_db(filenames)
survey_data={};
if isempty(filenames)
    return;
end

if~iscell(filenames)
    filenames ={filenames};
end

[path_cell,~,~] = cellfun(@fileparts,filenames(~isfolder(filenames)),'UniformOutput',false);
path_cell = [path_cell,filenames(isfolder(filenames))];
[path_cell_unique,~,idx_u] = unique(path_cell);

survey_data=cell(1,numel(filenames));
idf = 0;
for uip = 1:numel(path_cell_unique)
    db_file=fullfile(path_cell_unique{uip},'echo_logbook.db');

    if ~isfile(db_file)
        continue;
    end
    dbconn=connect_to_db(db_file);
    subfilenames = filenames(idx_u==uip);

    for ip=1:length(subfilenames)
        try
            idata=1;
            idf = idf+1;
            survey_data_db=dbconn.fetch('SELECT Voyage,SurveyName FROM survey ');

            if isempty(survey_data_db)
                voy = '';
                sname = '';
            else
                voy = survey_data_db.Voyage{1};
                sname = survey_data_db.SurveyName{1};
            end

            if ~isfolder(subfilenames{ip})
                [~,file,~]=fileparts(subfilenames{ip});
                sql_query = sprintf('SELECT Snapshot,Type,Stratum,Transect,StartTime,EndTime,Comment FROM logbook WHERE instr(Filename, ''%s'')>0',file);
                %opts = databaseImportOptions(dbconn,sql_query);

                %opts.VariableTypes(ismember(opts.VariableNames,{'StartTime','EndTime'})) = {'datetime'};

                curr_file_data=dbconn.fetch(sql_query);
                nb_data=size(curr_file_data,1);

                for id=1:nb_data
                    survey_data{idf}{idata}=survey_data_cl('Voyage',voy,...
                        'SurveyName',sname,...
                        'Type',curr_file_data.Type{id},...
                        'Snapshot',curr_file_data.Snapshot(id),...
                        'Stratum',curr_file_data.Stratum{id},...
                        'Transect',curr_file_data.Transect(id),...
                        'StartTime',datenum(curr_file_data.StartTime(id)),...
                        'EndTime',datenum(curr_file_data.EndTime(id)));
                    idata=idata+1;
                end
            else
                survey_data{idf}{1}=survey_data_cl('Voyage',voy,...,...
                    'SurveyName',sname);
            end

        catch err
            print_errors_and_warnings([],'error',err);
        end
    end
    close(dbconn);
end


end
