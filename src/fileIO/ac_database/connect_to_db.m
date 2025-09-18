function [dbconn,db_type]=connect_to_db(ac_db_filename,varargin)

p = inputParser;

addRequired(p,'ac_db_filename',@ischar);
addParameter(p,'db_type','',@ischar);
addParameter(p,'user',getenv('USERNAME'),@ischar);
addParameter(p,'pwd',getenv('USERNAME'),@ischar);
addParameter(p,'PortNumber',5432,@isnumeric);

parse(p,ac_db_filename,varargin{:});

dbconn=[];


if isempty(p.Results.db_type)
    if isfile(ac_db_filename)||isfolder(ac_db_filename)
        db_type='SQlite';
        if isfolder(ac_db_filename)
            ac_db_filename=fullfile(ac_db_filename,'echo_logbook.db');
        end
    else
        db_type='PostgreSQL';
    end
else
    db_type=p.Results.db_type;
end

fprintf('Connecting to %s\n',ac_db_filename);

conn=strsplit(ac_db_filename,':');
if strcmp(conn{1},'dbfisheriesprod')  
    if ~isSecret("password")
        [pwd_val,cancel]=input_dlg_perso([],'Authentication required',{append('Please enter the password for "',p.Results.user,'" to connect to "',ac_db_filename,'"')},...
            {'%s'},{''}); 
        choice = question_dialog_fig([],'Save credentials','Do you want to save your credentials?','opt',{'Yes','No'},'timeout',10);
        switch choice
            case 'Yes'
                setSecret("password")
        end       
    else
        pwd_val = getSecret("password");
    end
end

switch db_type
    case 'SQlite'
        %bool_func = will_it_work([],'999.999',true);
        bool_func = false;
        if bool_func
            if isfile(ac_db_filename)
                dbconn=sqlite(ac_db_filename,'connect');
            else
                dbconn=[];
                db_type='';
            end
        else
            try
                if ~isfile(ac_db_filename)
                    db_type='';
                    return;
                end
                % Open the DB file
                % jdbc = org.sqlite.JDBC;
                % props = java.util.Properties;
                % dbconn = jdbc.createConnection(['jdbc:sqlite:' ac_db_filename],props);  % org.sqlite.SQLiteConnection object
                % Open the DB file

                user = '';
                password = '';
                driver = 'org.sqlite.JDBC';
                protocol = 'jdbc';
                subprotocol = 'sqlite';
                resource = ac_db_filename;
                url = strjoin({protocol, subprotocol, resource}, ':');
                dbconn = database(ac_db_filename, user, password, driver, url);

                if ~isempty(dbconn.Message)
                    if contains(dbconn.Message,'ERROR')||contains(dbconn.Message,'No suitable driver')||contains(dbconn.Message,'The database has been closed')
                        error(dbconn.Message);
                    end
                end
            catch err
                warning('connect_to_db:cannot use Sqlite JDBC driver! Some functions might not work...');
                
                print_errors_and_warnings(1,'error',err);
                if isfile(ac_db_filename)
                    dbconn=sqlite(ac_db_filename,'connect');
                else
                    dbconn=[];
                    db_type='';
                end
            end
        end

    case 'PostgreSQL'
        try
            %[dbconn,db_type]=connect_to_db('138.71.128.57:das:das','db_type','PostgreSQL','user','dasread');
            
            conn=strsplit(ac_db_filename,':');
            if strcmp(conn{1},'dbfisheriesprod')
                dbconn = database(conn{2},p.Results.user,pwd_val, ...
                    'Vendor','PostgreSQL', ...
                    'PortNumber',p.Results.PortNumber,...
                    'Server',conn{1});
                if ~isempty(dbconn.Message)
                    dbconn = [];
                    return
                end
            else
                dbconn = database(conn{2},p.Results.user,p.Results.pwd, ...
                    'Vendor','PostgreSQL', ...
                    'PortNumber',p.Results.PortNumber,...
                    'Server',conn{1});
            end    
            if ~isempty(dbconn.Message)
                if any(cellfun(@(x) contains(lower(dbconn.Message),x),{'failed','fatal','error'}))
                    dbconn=[];
                    db_type='';
                    return;
                end
            end

            sql_query=sprintf('SET search_path = %s',conn{3});
            dbconn.exec(sql_query);

        catch err
            print_errors_and_warnings(1,'error',err);
            dbconn=[];
            db_type='';
            return;
        end

end


