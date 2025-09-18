function [new_files,files_rem]=update_echo_logbook_dbfile(layers_obj,varargin)

p = inputParser;

ver_fmt=@(x) ischar(x);

addRequired(p,'layers_obj',@(obj) isa(obj,'layer_cl'));
addParameter(p,'SurveyName','',ver_fmt);
addParameter(p,'Voyage','',ver_fmt);
addParameter(p,'Filename','',@ischar);
addParameter(p,'DbFile','',@ischar);
addParameter(p,'NewFilesOnly',false,@islogical);
addParameter(p,'main_figure',[],@(x) isempty(x)||ishandle(x));
addParameter(p,'SurveyData',survey_data_cl.empty(),@(obj) isa(obj,'survey_data_cl')||iscell(obj));
parse(p,layers_obj,varargin{:});

results=p.Results;

new_files={};
files_rem={};

[path_lays,files_lays]=layers_obj.get_path_files();

[path_lays_unique,~,id_u] = unique(path_lays);


for uip = 1:numel(path_lays_unique)

    if ~any(strcmp(p.UsingDefaults,'DbFile'))
        [path_f,~]=fileparts(p.Results.DbFile);
        ilays = [];
    else
        path_f=path_lays_unique{uip};
        ilays  = layers_obj.find_layer_idx_files(files_lays(id_u ==uip));
    end
    
    db_file=fullfile(path_lays_unique{uip},'echo_logbook.db');

    try
        if ~isfile(db_file)
            dbconn = initialize_echo_logbook_dbfile(path_f,0);
        else
            dbconn = connect_to_db(db_file);
        end

        files_logbook=dbconn.fetch('SELECT Filename FROM logbook ORDER BY StartTime');
        survey_data=dbconn.fetch('SELECT SurveyName, Voyage FROM survey');

        if ~isempty(survey_data.SurveyName)
            if ~any(strcmp(p.UsingDefaults,'SurveyName'))
                surv_name=results.SurveyName;
            else
                surv_name=survey_data.SurveyName{1};
            end
        else
            surv_name=results.SurveyName;
        end

        if ~isempty(survey_data.Voyage)
            if ~any(strcmp(p.UsingDefaults,'Voyage'))
                voy=results.Voyage;
            else
                voy=survey_data.Voyage{1};
            end
        else
            voy=results.Voyage;
        end

        files_db = files_logbook.Filename;

        if isempty(files_logbook.Filename)
            files_db  ={};
        end

        [list_raw,~]=list_ac_files(path_f,1);

        [files_rem,~]=setdiff(files_db,list_raw);

        for ifir=1:numel(files_rem)
            dbconn.exec(sprintf('DELETE FROM logbook WHERE instr(Filename, ''%s'')>0',files_rem{ifir}));
        end

        [new_files,~]=setdiff(list_raw,files_db);

        new_files = setdiff(new_files,files_lays(ilays));

        if~isempty(new_files)
            nff = cellfun(@(x) fullfile(path_f,x),new_files,'UniformOutput',0);
            disp_perso(p.Results.main_figure,'Getting file types (this might take a few minutes if there are lots of them)...');
            ftypes = cellfun(@get_ftype,nff,'un',0);
            idx_rem=strcmpi(ftypes,'unknown');
            new_files(idx_rem)=[];
            ftypes(idx_rem)=[];
        end

        survdata_temp=survey_data_cl('Voyage',voy,'SurveyName',surv_name);

        if numel(new_files)==0
            disp_perso(p.Results.main_figure,'The logbook seems to be up to date...');
        else
            disp_perso(p.Results.main_figure,'Updating logbook');
            add_files_to_db(path_f,new_files,ftypes,dbconn,survdata_temp);
        end

        for ilay = ilays
            curr_files=layers_obj(ilay).Filename;
            if p.Results.NewFilesOnly
                curr_files = {};
            end
            for icfi=1:length(curr_files)
                [~,file_curr_temp,end_temp]=fileparts(curr_files{icfi});
                file_curr_short=[file_curr_temp end_temp];
                file_curr=curr_files{icfi};
                f_processed=0;

                if strcmp(file_curr,p.Results.Filename)
                    survey_data_temp=p.Results.SurveyData;
                else
                    survey_data_temp=layers_obj(ilay).SurveyData;
                end

                [start_file_time,end_file_time]=layers_obj(ilay).get_time_bound_files();
                file_lay=layers_obj(ilay).Filename;
                ifi=find(strcmp(file_curr,file_lay));

                if isempty(survey_data_temp)
                    survey_data_temp={[]};
                end

                if ~iscell(survey_data_temp)
                    survey_data_temp={survey_data_temp};
                end

                for  i_cell=1:length(survey_data_temp)
                    if ~isempty(survey_data_temp{i_cell})
                        survdata_temp=survey_data_temp{i_cell};
                        survdata_temp.Voyage=voy;
                        survdata_temp.SurveyName=surv_name;

                        start_time=survdata_temp.StartTime;
                        end_time=survdata_temp.EndTime;

                        if (end_file_time(ifi)<start_time||start_file_time(ifi)>(end_time))
                            continue;
                        end

                        if start_time~=0
                            start_time=max(start_time,start_file_time(ifi));
                        end

                        if end_time~=1
                            end_time=min(end_time,end_file_time(ifi));
                        end

                        f_processed=1;
                        survdata_temp.surv_data_to_logbook_db(dbconn,file_curr_short,'StartTime',start_time,'EndTime',end_time);
                    end


                    if f_processed==0
                        survdata_temp=survey_data_cl('Voyage',voy,'SurveyName',surv_name);
                        end_time=layers_obj(ilay).Transceivers(1).Time(end);
                        start_time=layers_obj(ilay).Transceivers(1).Time(1);
                        survdata_temp.surv_data_to_logbook_db(dbconn,file_curr_short,'StartTime',start_time,'EndTime',end_time);
                        layers_obj(ilay).set_survey_data(survdata_temp);
                    end
                end
            end

        end

        close(dbconn);
    catch err
        print_errors_and_warnings([],'error',err);
    end
end


if isfile(p.Results.Filename)
    try
        [start_time,end_time]=start_end_time_from_file(p.Results.Filename);

        survdata_temp=p.Results.SurveyData;
        [path_f,file_r,end_file]=fileparts(p.Results.Filename);

        db_file = fullfile(path_f,'echo_logbook.db');
        if ~isfile(db_file)
            dbconn = initialize_echo_logbook_dbfile(path_f,0);
        else
            dbconn = connect_to_db(db_file);
        end


        survey_data=dbconn.fetch('SELECT SurveyName, Voyage FROM survey');


        if ~isempty(survey_data.SurveyName)
            if ~any(strcmp(p.UsingDefaults,'SurveyName'))
                survdata_temp.SurveyName=results.SurveyName;
            else
                survdata_temp.SurveyName=survey_data.SurveyName{1};
            end
        else
            survdata_temp.SurveyName=results.SurveyName;
        end

        if ~isempty(survey_data.Voyage)
            if ~any(strcmp(p.UsingDefaults,'Voyage'))
                survdata_temp.Voyage=results.Voyage;
            else
                survdata_temp.Voyage=survey_data.Voyage{1};
            end
        else
            survdata_temp.Voyage=results.Voyage;
        end
        if start_time ==0
            start_time = survdata_temp.StartTime;
        end
        if end_time == 1
            end_time = survdata_temp.EndTime;
        end
        dbconn.exec(sprintf('DELETE FROM logbook WHERE instr(Filename, ''%s'')>0',[file_r end_file]));
        survdata_temp.surv_data_to_logbook_db(dbconn,[file_r end_file],'StartTime',start_time,'EndTime',end_time);
        dbconn.close();
    catch err
        print_errors_and_warnings([],'error',err);
    end
end
disp_perso(p.Results.main_figure,'');

end
%%



