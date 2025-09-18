classdef logbook_panel_cl < handle
    properties
        LogbookTab      matlab.ui.container.Tab
        LogbookLayout  matlab.ui.container.GridLayout
        SearchPanel    matlab.ui.container.Panel
        VoyLabel       matlab.ui.control.Label
        FileBox        matlab.ui.control.CheckBox
        SnapBox       matlab.ui.control.CheckBox
        TypeBox       matlab.ui.control.CheckBox
        StratBox      matlab.ui.control.CheckBox
        TransBox      matlab.ui.control.CheckBox
        RegBox        matlab.ui.control.CheckBox
        SearchField    matlab.ui.control.EditField
        TablePanel     matlab.ui.container.Panel
        FullData           = [];
        LogbookTable   matlab.ui.control.Table
        DbConn        
        DbFile
    end
    
    
    
    methods
        function obj=logbook_panel_cl(parenth,dbconn,varargin)
            
            p = inputParser;
            addRequired(p,'parenth',@(x) isa(x,'matlab.ui.container.TabGroup'));
            addRequired(p,'dbconn',@(x) isa(x,'database.jdbc.connection')||isa(x,'sqlite')||ischar(x));
            
            parse(p,parenth,dbconn,varargin{:});
            
            switch class(dbconn)
                case {'database.jdbc.connection'}
                    if isprop(dbconn,'DataSource')
                        dbfile=dbconn.DataSource;
                    else
                        dbfile=dbconn.Database;
                    end

                case {'sqlite'}
                    if isprop(dbconn,'DataSource')
                        dbfile=dbconn.DataSource;
                    else
                        dbfile=dbconn.Database;
                    end
                    dbconn.close();
                    dbconn = connect_to_db(dbfile);
                case 'char'
                    dbfile  =dbconn;
                    try
                        if isfile(dbfile)
                            dbconn = connect_to_db(dbfile);
                        else
                            return;
                        end
                    catch err
                        print_errors_and_warnings([],'warning',err);
                        print_errors_and_warnings([],'warning',sprintf('Could not connect to db %s',dbfile));
                        return;
                    end
                otherwise
                    return;
            end
            
            obj.DbFile = dbfile;

            obj.DbConn = dbconn;

            pan_height=get_top_panel_height(0.5);
            
            obj.LogbookTab = uitab(parenth,'Tag',dbfile);
            tab_menu = uicontextmenu(ancestor(obj.LogbookTab,'figure'));
            obj.LogbookTab.UIContextMenu=tab_menu;
            
            uimenu(tab_menu,'Label','Close Logbook','CallBack',@close_logbook_tab);
            uimenu(tab_menu,'Label','Fix Logbook','CallBack',@fix_logbook_tab);
            
            % Create GridLayout
            obj.LogbookLayout = uigridlayout(obj.LogbookTab);
            obj.LogbookLayout.RowHeight = {pan_height '1x'};
            obj.LogbookLayout.ColumnWidth = {'1x'};
            
            obj.LogbookLayout.RowSpacing = 0;
            obj.LogbookLayout.Padding = [0 0 0 0];
            obj.LogbookLayout.Scrollable = 'on';
            
            % Create SearchPanel
            obj.SearchPanel = uipanel(obj.LogbookLayout);
            obj.SearchPanel.Layout.Row = 1;
            obj.SearchPanel.Layout.Column = 1;
            SearchPanelLayout = uigridlayout(obj.SearchPanel);
            SearchPanelLayout.RowHeight  = {'1x'};
            SearchPanelLayout.ColumnWidth  = {'fit' '1x' '3x' '1x' '1x' '1x' '1x' '1x' '1x' };
            
            obj.VoyLabel      =   uilabel(SearchPanelLayout,'text','','FontWeight','bold');
            uilabel(SearchPanelLayout,'Text','Search:');
            obj.SearchField   =   uieditfield(SearchPanelLayout,'ValueChangedFcn',@search_ValueChangedFcn);
            obj.FileBox       =   uicheckbox(SearchPanelLayout,'Text','File','Value',1,'Tag','Filename','ValueChangedFcn',@search_ValueChangedFcn);
            obj.SnapBox       =   uicheckbox(SearchPanelLayout,'Text','Snap.','Value',1,'Tag','Snapshot','ValueChangedFcn',@search_ValueChangedFcn);
            obj.TypeBox       =   uicheckbox(SearchPanelLayout,'Text','Type','Value',1,'Tag','Type','ValueChangedFcn',@search_ValueChangedFcn);
            obj.StratBox      =   uicheckbox(SearchPanelLayout,'Text','Strat.','Value',1,'Tag','Stratum','ValueChangedFcn',@search_ValueChangedFcn);
            obj.TransBox      =   uicheckbox(SearchPanelLayout,'Text','Trans.','Value',1,'Tag','Transect','ValueChangedFcn',@search_ValueChangedFcn);
            obj.RegBox        =   uicheckbox(SearchPanelLayout,'Text','Reg.','Value',1,'Tag','Reg','ValueChangedFcn',@search_ValueChangedFcn);
            
            % Create TablePanel
            obj.TablePanel = uipanel(obj.LogbookLayout);
            obj.TablePanel.Layout.Row = 2;
            obj.TablePanel.Layout.Column = 1;
            nb_files=obj.DbConn.fetch(sprintf('SELECT COUNT(Filename) FROM logbook ORDER BY StartTime'));

            t = obj.init_table(nb_files.(1));

            tlay = uigridlayout(obj.TablePanel,[1 1]);
            tlay.Padding = [0 0 0 0];
            obj.LogbookTable = uitable(tlay,'Data',t,'ColumnWidth','auto');
            obj.FullData = t;
            cedit = [true false true true true true false false true false false];
            csort = [false true true true true true false false true true true];
            obj.LogbookTable.ColumnEditable = cedit;
            obj.LogbookTable.ColumnSortable = csort;
            obj.LogbookTable.UserData.highlighted_idx  =[];
            obj.LogbookTable.UserData.highlighted_files = {};
            obj.init_logbook_table();
            
            
            function close_logbook_tab(~,~)
                delete(obj);
            end

            function fix_logbook_tab(~,~)
                try
                    data = obj.DbConn.fetch('SELECT * FROM metaData');
                    data = data(1,:);
                catch
                    data = [];
                end
                fix_logbook_table(obj.DbConn);
                if isempty(data)||isempty(data.logbook_version)||data.logbook_version<get_logbook_version
                    fprintf('Updating logbook table to version %.1f\n',get_logbook_version);
                    fix_logbook_table(obj.DbConn);
                end

                if isempty(data)||isempty(data.ping_data_version)||data.ping_data_version<get_ping_data_version
                    fprintf('Updating ping_data table to version %.1f\n',get_ping_data_version);
                    fix_ping_data_table(obj.DbConn);
                end
                createMetadata_table(obj.DbConn);
            end

            function search_ValueChangedFcn(~,~)
                obj.search_fcn();   
            end
            
            
        end
        %%
        
        
        function init_logbook_table(obj)
            data_survey=obj.DbConn.fetch('SELECT Voyage,SurveyName FROM survey');

            if isempty(data_survey.Voyage)||ismissing(data_survey.Voyage)
                voy = '';
            else
                voy = data_survey.Voyage{1};
            end


            if isempty(data_survey.SurveyName)||ismissing(data_survey.SurveyName)
                sname = '';
            else
                sname = data_survey.SurveyName{1};
            end


            obj.VoyLabel.Text =  sprintf('Voyage %s, Survey: %s',voy,sname);
            obj.LogbookTab.Title = sprintf('Logbook %s',voy);

            files_in_log=obj.DbConn.fetch(sprintf('SELECT Filename FROM logbook'));
            path_f  = fileparts(obj.DbFile);
            try
                files = files_in_log.Filename;
                if isempty(files)
                    files = {};
                end

                sql_cmd = sprintf('SELECT Filename,Snapshot,Type,Stratum,Transect,Comment,StartTime,EndTime FROM logbook WHERE Filename IN (''%s'')',strjoin(files,''','''));   
                data_logbook_to_up=obj.DbConn.fetch(sql_cmd);
                
                if isempty(data_logbook_to_up)
                    return;
                end
                obj.LogbookTable.Data(:,data_logbook_to_up.Properties.VariableNames) = data_logbook_to_up;
                
                for il=1:numel(data_logbook_to_up.Filename)
                    [path_xml,bot_file_str,reg_file_str]=create_bot_reg_xml_fname(fullfile(path_f,data_logbook_to_up.Filename{il}));
                    obj.LogbookTable.Data.Bot(il)=exist(fullfile(path_xml,bot_file_str),'file')==2;
                    if exist(fullfile(path_xml,reg_file_str),'file')==2
                        tags = list_tags_only_regions_xml(fullfile(path_xml,reg_file_str));
                        if ~isempty(tags)
                            str_reg=cell2mat(cellfun(@(x) [ x ' ' ], unique(tags), 'UniformOutput', false));
                            obj.LogbookTable.Data.("Reg. Tags"){il}=str_reg;
                        else
                            obj.LogbookTable.Data.("Reg. Tags"){il}='';
                        end
                    else
                        obj.LogbookTable.Data.("Reg. Tags"){il}='';
                    end
                    
                end
                 
                obj.FullData = obj.LogbookTable.Data;
            catch err
                print_errors_and_warnings([],'warning',err);
                
            end
        end

        function search_fcn(obj)
            
            file=obj.FileBox.Value;
            snap=obj.SnapBox.Value;
            type=obj.TypeBox.Value;
            strat=obj.StratBox.Value;
            trans=obj.TransBox.Value;
            reg=obj.RegBox.Value;
            nb_lines  = size(obj.FullData,1);
            text_search_tot=strtrim(obj.SearchField.Value);
            if isempty(text_search_tot)||(~file&&~snap&&~trans&&~strat&&~reg&&~type)
                obj.LogbookTable.Data=obj.FullData;
            else
                text_search_tot=strsplit(obj.SearchField.Value,' ');
                
                idx_tot=true(nb_lines,1);
                
                for i=1:numel(text_search_tot)
                    text_search=strtrim(text_search_tot{i});
                    if isempty(text_search)
                        continue;
                    end
                    
                    if snap
                        idx_snap=obj.FullData.Snapshot==str2double(text_search);
                    else
                        idx_snap=false(nb_lines,1);
                    end
                    
                    if type
                        idx_type=contains(string(obj.FullData.Type),text_search,'IgnoreCase',true);
                    else
                        idx_type=false(nb_lines,1);
                    end
                    
                    
                    if trans
                        idx_trans=obj.FullData.Transect==str2double(text_search);
                    else
                        idx_trans=false(nb_lines,1);
                    end
                    
                    if strat
                        idx_strat=contains(obj.FullData.Stratum,text_search,'IgnoreCase',true);
                    else
                        idx_strat=false(nb_lines,1);
                    end
                    
                    if file
                        idx_files=contains(obj.FullData.Filename,text_search,'IgnoreCase',true);
                    else
                        idx_files=false(nb_lines,1);
                    end
                    
                    if reg
                        idx_regs=contains(obj.FullData.("Reg. Tags"),text_search,'IgnoreCase',true);
                    else
                        idx_regs=false(nb_lines,1);
                    end
                    
                    idx_tot=idx_tot&(idx_snap|idx_type|idx_strat|idx_files|idx_trans|idx_regs);
                end
                obj.LogbookTable.Data=obj.FullData(idx_tot,:);
                obj.LogbookTable.UserData.highlighted_idx  = intersect(obj.LogbookTable.UserData.highlighted_idx,1:numel(obj.LogbookTable.Data.Id));
                obj.LogbookTable.UserData.highlighted_files = cellstr(obj.LogbookTable.Data.Filename(obj.LogbookTable.UserData.highlighted_idx));
            end
        end
        
        function update_logbook_panel(obj,new_files)
            
            files_in_log=obj.DbConn.fetch(sprintf('SELECT Filename FROM logbook'));
            
            survey_data_db=obj.DbConn.fetch('SELECT Voyage,SurveyName FROM survey');

            if isempty(survey_data_db)
                voy = '';
                sname = '';
            else
                voy = survey_data_db.Voyage{1};
                sname = survey_data_db.SurveyName{1};
            end

            obj.VoyLabel.Text =  sprintf('Voyage %s, Survey: %s',voy,sname);
            obj.LogbookTab.Title = sprintf('Logbook %s',voy);
            
            if isempty(new_files)
                return;
            else
                [path_f_tot,file_c,ext_c]=cellfun(@(x) fileparts(x),new_files,'un',0);
                files  = cellfun(@(x,y) [x y],file_c,ext_c,'un',0);
            end
            
            try
                sql_cmd=  sprintf('SELECT Filename,Snapshot,Type,Stratum,Transect,Comment,StartTime,EndTime FROM logbook WHERE Filename IN (''%s'')',strjoin(files,''','''));
                data_logbook_to_up=obj.DbConn.fetch(sql_cmd);
                
                files_to_update = data_logbook_to_up.Filename;
                files_in_table = obj.FullData.Filename;
                
                idx_mod = ismember(files_in_table,files);
                
                if any(idx_mod)
                    obj.FullData(idx_mod,:)=[];
                end
                
                nb_lines = numel(files_to_update);
                if isempty(files_to_update)
                    return;
                end
                
                t = obj.init_table(nb_lines);
                
                t(:,data_logbook_to_up.Properties.VariableNames) = data_logbook_to_up;
                
                for il=1:nb_lines
                    id_path = find(contains(new_files,data_logbook_to_up.Filename{il}),1);
                    if isempty(id_path)
                        continue;
                    end
                    [path_xml,bot_file_str,reg_file_str]=create_bot_reg_xml_fname(fullfile(path_f_tot{id_path},data_logbook_to_up.Filename{il}));
                    t.Bot(il)=exist(fullfile(path_xml,bot_file_str),'file')==2;
                    if exist(fullfile(path_xml,reg_file_str),'file')==2
                        tags = list_tags_only_regions_xml(fullfile(path_xml,reg_file_str));
                        if ~isempty(tags)
                            str_reg=cell2mat(cellfun(@(x) [ x ' ' ], unique(tags), 'UniformOutput', false));
                            t.("Reg. Tags"){il}=str_reg;
                        else
                            t.("Reg. Tags"){il}='';
                        end
                    else
                        t.("Reg. Tags"){il}='';
                    end
                    
                end
                
                data = [obj.FullData;t];
                [~,idx_sort]=sort(cellfun(@(x) datenum(x,'yyyy-mm-dd HH:MM:SS'),data.StartTime));
                data=data(idx_sort,:);
                data.Id = (1:numel(data.Id))';
                [~,idx_rem]=setdiff(data.Filename,files_in_log.Filename);
                if ~isempty(idx_rem)
                    data(idx_rem,:)=[];
                end
                obj.FullData = data;
                obj.LogbookTable.Data=data;
                    obj.search_fcn();
            catch err
                print_errors_and_warnings([],'warning',err);
            end
        end
        
        function delete(obj)
            if ismethod(obj.DbConn,'close')
                obj.DbConn.close();
            end
            delete(obj.LogbookTab);
            if  isdebugging
                c = class(obj);
                disp(['Destructor called for class ',c])
            end
        end
    end
    methods(Static)
        function t = init_table(nb_files)
            columnname = {'Sel.','Filename','Snapshot','Type','Stratum','Transect','Bot','Reg. Tags','Comment','StartTime','EndTime' 'Id'};
            vtypes = {'logical' 'string','uint32','categorical','string','uint32','logical','string','string','string','string' 'uint32'};
            
            [types,~]=init_trans_type();
            types(cellfun(@(x) isempty(deblank(x)),types)) = [];
            %ctypes =  categorical(types);
            
            t = table('Size',[nb_files numel(columnname)],'VariableTypes',vtypes,'VariableNames',columnname);
            t.Type = categorical(t.Type,types, ...
                'Protected',false);
            t.Id = (1:nb_files)';
            
        end
        
        
    end
end