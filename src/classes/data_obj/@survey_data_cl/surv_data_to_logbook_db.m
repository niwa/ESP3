function surv_data_to_logbook_db(surv_data_obj,dbconn,filename,varargin)

p = inputParser;

addRequired(p,'surv_data_obj',@(x) isa(x,'survey_data_cl'));
addRequired(p,'dbconn',@(x) isa(x,'database.jdbc.connection')||isa(x,'sqlite'));
addRequired(p,'filename',@ischar);
addParameter(p,'StartTime',0,@isnumeric);
addParameter(p,'EndTime',1,@isnumeric);
parse(p,surv_data_obj,dbconn,filename,varargin{:});
et_num=1e9;

if p.Results.StartTime==0
        if isprop(dbconn,'DataSource')
            [path_f,~,~]=fileparts(dbconn.DataSource);
        else
            [path_f,~,~]=fileparts(dbconn.Database);
        end
    [st_num,et_num,~]=start_end_time_from_file(fullfile(path_f,filename));
else
    st_num=p.Results.StartTime;   
end

%st = datetime(st_num,'ConvertFrom','datenum','format','yyyy-MM-dd HH:mm:ss');
st=datestr(st_num,'yyyy-mm-dd HH:MM:SS');

if p.Results.EndTime~=1
    et_num=p.Results.EndTime;
end

%et = datetime(et_num,'ConvertFrom','datenum','format','yyyy-MM-dd HH:mm:ss');
et=datestr(et_num,'yyyy-mm-dd HH:MM:SS');

if et_num<=st_num
    return;
end
strat=surv_data_obj.Stratum;
snap=surv_data_obj.Snapshot;
trans=surv_data_obj.Transect;
type=surv_data_obj.Type;
comm=surv_data_obj.Comment;

try
    
    createsurveyTable(dbconn);

    tz=dbconn.fetch(sprintf('SELECT Timezone FROM survey'));
    dbconn.exec('DELETE from survey');
    
    if ~isempty(tz.Timezone)
        dbconn.sqlwrite('survey',table({surv_data_obj.Voyage}, {surv_data_obj.SurveyName},tz.Timezone(1),'VariableNames',{'Voyage' 'SurveyName' 'Timezone'}));
    else
       dbconn.sqlwrite('survey',table({surv_data_obj.Voyage},{surv_data_obj.SurveyName},'VariableNames',{'Voyage' 'SurveyName'}));
    end
    %end
    

     fprintf('Insert Survey data for file %s Snap. %d Type %s Strat. %s Trans. %d StartTime %s EndTime %s\n',filename,snap,type,strat,trans,st,et); 
    
%     t.Filename = filename;
%     t.Snapshot = snap;
%     t.Type = type;
%     t.Stratum = strat;
%     t.Transect = trans;
%     t.StartTime  = st;
%     t.EndTime = et;
%     t.Comment = comm;
%     
tmp = dbconn.fetch(sprintf('SELECT StartTime,EndTime FROM logbook WHERE Filename = "%s"',filename));
if ~isempty(tmp)
    stf = cellfun(@(x) datenum(x,'yyyy-mm-dd HH:MM:SS'),tmp.StartTime);
    etf = cellfun(@(x) datenum(x,'yyyy-mm-dd HH:MM:SS'),tmp.EndTime);

    if ~isempty(stf) && any(stf>etf)
        dbconn.exec(sprintf('DELETE FROM logbook WHERE Filename = "%s"',filename));
    end
end

    t = table({filename},snap,{type},{strat},trans,{st},{et},{comm},'VariableNames',{'Filename' 'Snapshot' 'Type' 'Stratum' 'Transect' 'StartTime' 'EndTime' 'Comment'});
   
    try
        datainsert_perso(dbconn,'logbook',t);
        %dbconn.sqlwrite('logbook',t);
    catch
        fprintf('Updating logbook structure to latest version\n');
        fix_logbook_table(dbconn);
        %dbconn.sqlwrite('logbook',t);
        datainsert_perso(dbconn,'logbook',t);
    end
        %     after_log=dbconn.fetch(sprintf('select * from logbook where Filename is "%s"',filename))
        %     after=dbconn.fetch('select * from survey')
catch err
    print_errors_and_warnings([],'error',err);
end

end