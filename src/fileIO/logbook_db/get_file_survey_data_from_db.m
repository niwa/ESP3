function surv_data=get_file_survey_data_from_db(dbconn,filename,fst,fet)

    [~,filename_s,end_file]=fileparts(filename);

    survey_data=dbconn.fetch('SELECT SurveyName,Voyage FROM survey');
        
    try
        data_logbook=dbconn.fetch(sprintf('SELECT Snapshot,Stratum,Transect,StartTime,EndTime,Comment,Type FROM logbook WHERE instr(Filename, ''%s%s'')>0 ORDER BY StartTime',filename_s,end_file));
    catch
        data_logbook=dbconn.fetch(sprintf('SELECT Snapshot,Stratum,Transect,StartTime,EndTime,Comment FROM logbook WHERE instr(Filename, ''%s%s'')>0 ORDER BY StartTime',filename_s,end_file));
    end
    
    
    nb_surv_data=size(data_logbook,1);
    surv_data=cell(1,nb_surv_data);
    
    for ids=1:nb_surv_data
        if ismember('Type',data_logbook.Properties.VariableNames)
            type=data_logbook.Type{ids};
        else
            type=' ';
        end
        
        surv_data{ids}=survey_data_cl(...
            'Voyage',survey_data.Voyage{1},...
            'SurveyName',survey_data.SurveyName{1},...
            'Snapshot',data_logbook.Snapshot(ids),...
            'Type',type,...
            'Stratum',data_logbook.Stratum{ids},...
            'Transect',data_logbook.Transect(ids),...
            'StartTime',datenum(data_logbook.StartTime{ids},'yyyy-mm-dd HH:MM:SS'),...
            'EndTime',datenum(data_logbook.EndTime{ids},'yyyy-mm-dd HH:MM:SS'),...
            'Comment',data_logbook.Comment{ids});
    end
    
    if ~isempty(surv_data)
        st=surv_data{1}.StartTime;
        et=surv_data{end}.EndTime;
%         st_str = datestr(st,'yyyy-mm-dd HH:MM:SS');
        et_str = datestr(et,'yyyy-mm-dd HH:MM:SS');
        upped = false;
        if abs(st-fst)>1/(24*60*60)
            survdata_temp =  survey_data_cl('StartTime',fst,'EndTime',fet);
            survdata_temp.surv_data_to_logbook_db(dbconn,[filename_s end_file],'StartTime',fst,'EndTime',fet);
            surv_data = [{survdata_temp} surv_data];
            upped = true;
        end

        if abs(fet-et)>1/(24*60*60) && ~upped
            surv_data{end}.EndTime=fet;
            dbconn.exec(sprintf('UPDATE logbook SET EndTime = "%s" WHERE instr(Filename, ''%s%s'')>0 AND EndTime = ''%s''',datestr(fet,'yyyy-mm-dd HH:MM:SS'),filename_s,end_file,et_str));
        end
        
    end




end