function load_logbook_fig(main_figure,varargin)

p = inputParser;
addRequired(p,'main_figure',@ishandle);
addOptional(p,'reload_only',false,@islogical);
addOptional(p,'new_logbook',false,@islogical);
addOptional(p,'dbfile','',@ischar);
addParameter(p,'layer_obj',layer_cl.empty,@(x) isa(x,'layer_cl'));
parse(p,main_figure,varargin{:});

new_logbook=p.Results.new_logbook;
%%%%%%%%%%%%%%%%%%%%%%%%
%new_logbook = false;
%%%%%%%%%%%%%%%%%%%%%%%%
reload_only=p.Results.reload_only;

if isempty(p.Results.layer_obj)
    layer_obj=get_current_layer();
else
    layer_obj=p.Results.layer_obj;
end

app_path=get_esp3_prop('app_path');

try
    if isempty(layer_obj)||new_logbook>0
        if isempty(p.Results.dbfile)||~isfile(p.Results.dbfile)
            [~,path_f]= uigetfile({fullfile(app_path.data.Path_to_folder,'echo_logbook.db')}, 'Pick a logbook file','MultiSelect','off');
            if path_f==0
                return;
            end
            dbFile={fullfile(path_f,'echo_logbook.db')};
        else
            dbFile = p.Results.dbfile;
            if ~isfile(dbFile)
                [path_f,~,~]=fileparts(p.Results.dbfile);
                dbFile={fullfile(path_f,'echo_logbook.db')};
            else
                dbFile = {dbFile};
            end
        end
        file_add = {};
    else
        [path_lay,~]=get_path_files(layer_obj);
        path_f=path_lay{1};
        dbFile=fullfile(path_f,'echo_logbook.db');
        [file_added,files_rem]=layer_obj.update_echo_logbook_dbfile('main_figure',main_figure,'DbFile',dbFile);
        file_add=union(file_added,files_rem);
        dbFile = {dbFile};
    end
    
    dbFile = unique(dbFile);
    
    for up=1:numel(dbFile)
        path_f=fileparts(dbFile{up});
        
        if ~isfolder(path_f)
            dlg_perso(main_figure,'Could not connect to Logbook','Could not connect to Logbook');
            continue;
        end
        if ~isfile(dbFile{up})
            dbconn = initialize_echo_logbook_dbfile(path_f,0);
            dbconn.close();
        end
        
        layer_cl().update_echo_logbook_dbfile('main_figure',main_figure,'DbFile',dbFile{up});
        
        logbook_fig = get_esp3_prop('logbook_fig_obj');
        
        if (isempty(logbook_fig)||~isvalid(logbook_fig))||~isvalid(logbook_fig.LogbookFigure)&&~reload_only
            logbook_fig =  logbook_fig_cl();
            esp3_obj=getappdata(groot,'esp3_obj');
            esp3_obj.logbook_fig_obj = logbook_fig;
        end
        
        idx_panel = logbook_fig.find_logbookPanel(dbFile{up});
        
        if isempty(idx_panel) && reload_only
            continue
        elseif reload_only || ~isempty(idx_panel)
            logbook_panel = logbook_fig.LogBookPanels(idx_panel);
        else
            logbook_panel = logbook_fig.load_logbook_panel(dbFile{up});
        end
        
        if ~reload_only && isempty(idx_panel)        
            set(logbook_panel.LogbookTable,'CellEditCallback',{@edit_surv_data_db,logbook_panel,main_figure});
            set(logbook_panel.LogbookTable,'CellSelectionCallback',{@cell_select_cback,logbook_panel});
            
            rc_menu = uicontextmenu(ancestor(logbook_panel.LogbookTable,'figure'));
            logbook_panel.LogbookTable.UIContextMenu =rc_menu;
            open_menu=uimenu(rc_menu,'Label','Open');
            select_menu=uimenu(rc_menu,'Label','Select');
            mod_survey_menu=uimenu(rc_menu,'Label','Edit SurveyData');
            survey_menu=uimenu(rc_menu,'Label','Export SurveyData');
            process_menu=uimenu(rc_menu,'Label','Process');
            map_menu=uimenu(rc_menu,'Label','Map');
            
            uimenu(open_menu,'Label','Open highlighted file(s)','Callback',{@open_files_callback,logbook_panel,main_figure,'high',false});
            uimenu(open_menu,'Label','Open highlighted file(s) in the background','Callback',{@open_files_callback,logbook_panel,main_figure,'high',true});
            uimenu(open_menu,'Label','Open selected file(s)','Callback',{@open_files_callback,logbook_panel,main_figure,'sel',false});
            uimenu(open_menu,'Label','Open selected file(s) in the background','Callback',{@open_files_callback,logbook_panel,main_figure,'sel',true});
            uimenu(open_menu,'Label','Open Script Builder with selected file(s)','Callback',{@generate_xml_callback,logbook_panel,main_figure});
            
            copy_menu=uimenu(rc_menu,'Label','Copy');
            uimenu(copy_menu,'Label','Copy highlighted file(s) to other folder','Callback',{@copy_to_other_cback,logbook_panel,main_figure,'high'});
            uimenu(copy_menu,'Label','Copy selected file(s) to other folder','Callback',{@copy_to_other_cback,logbook_panel,main_figure,'sel'});
            
            uimenu(select_menu,'Label','Select all','Callback',{@selection_callback,logbook_panel},'Tag','se');
            uimenu(select_menu,'Label','Deselect all','Callback',{@selection_callback,logbook_panel},'Tag','de');
            uimenu(select_menu,'Label','Invert Selection','Callback',{@selection_callback,logbook_panel},'Tag','inv');
            uimenu(select_menu,'Label','Select highlighted files','Callback',{@selection_callback,logbook_panel},'Tag','high');
            uimenu(select_menu,'Label','De-Select highlighted files','Callback',{@selection_callback,logbook_panel},'Tag','dehigh');
            uimenu(process_menu,'Label','Plot/Display bad pings per files','Callback',{@plot_bad_pings_callback,logbook_panel,main_figure});
            uimenu(process_menu,'Label','Apply process from Processing tab to selected files','Callback',{@proc_files_callback,logbook_panel,main_figure});
            uimenu(process_menu,'Label','Get average depth of instrument from highlighted files','Callback',{@get_avg_d_instrument,logbook_panel,main_figure});
            uimenu(process_menu,'Label','Apply time correction on highlighted files','Callback',{@tcorr,logbook_panel,main_figure});

            path_f = fileparts(logbook_panel.DbFile);
            
            uimenu(survey_menu,'Label','Export metadata to .csv','Callback',{@export_metadata_to_csv_callback,path_f});
            uimenu(survey_menu,'Label','Export to html and display','Callback',{@export_metadata_to_html_callback,path_f});
            
            uimenu(map_menu,'Label','Display selected file(s) positions','Callback',{@display_files_tracks_cback,logbook_panel,main_figure,''})
            uimenu(map_menu,'Label','Export selected file(s) positions to .shp/.csv','Callback',{@display_files_tracks_cback,logbook_panel,main_figure,'save'})
            
            uimenu(mod_survey_menu,'Label','Edit highlighted files survey_data','Callback',{@edit_survey_data_log_cback,logbook_panel,main_figure,'high'});
        else
            logbook_panel.update_logbook_panel(file_add);
        end
        
        logbook_fig.LogbookFigure.Visible = 'on';
    end
catch err
    dlg_perso(main_figure,'Could not connect to Logbook','Could not connect to Logbook');
    print_errors_and_warnings(1,'error',err);
end
end



%%
function edit_survey_data_log_cback(src,evt,obj,main_figure,sel_or_high)

dbconn=obj.DbConn;

if strcmpi(dbconn.ReadOnly,'on')
    fprintf('Database file is readonly... Check file permissions\n');
    return;
end

switch sel_or_high
    case 'sel'
        idx=find([obj.LogbookTable.Data.("Sel.")]);
    case 'high'
        idx=obj.LogbookTable.UserData.highlighted_idx;
end

if isempty(idx)
    return;
end


surv=survey_data_cl();
tt='Edit survey Data';

[surv,modified]=edit_survey_data_fig(main_figure,surv,{'off' 'off' 'on' 'on' 'on' 'on' 'on'},tt);

if isempty(surv)||all(modified==0)
    return;
end
load_bar_comp=show_status_bar(main_figure,0);
%set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',100, 'Value',0);
load_bar_comp.progress_bar.setText('Updating Logbook');


fields = properties(surv);
fields(ismember(fields,{'StartTime' 'EndTime'}))=[];

fields=string(fields);

disp('Updating Logbook')

for id=1:numel(idx)
    filename=obj.LogbookTable.Data.Filename{idx(id)};
    st=obj.LogbookTable.Data.StartTime{idx(id)};
    %st_java = datenum_to_javatime(st);
    st_java = datestr(st,'yyyy-mm-dd HH:MM:SS');
    et=obj.LogbookTable.Data.EndTime{idx(id)};
    %et_java = datenum_to_javatime(st);
    et_java = datestr(et,'yyyy-mm-dd HH:MM:SS');

    fprintf('Updating Survey data for file %s (StartTime %s EndTime %s)\n',filename,st_java,et_java);
    for ifi=1:numel(fields)
        if modified(ifi)
            if isnumeric(surv.(fields{ifi}))
                fprintf('   %s to %.0f\n',fields{ifi},surv.(fields{ifi}));
                sql_query=sprintf('UPDATE logbook SET %s=%d WHERE instr(Filename, ''%s'')>0 and instr(''%s'',StartTime)>0',...
                    (fields{ifi}),surv.(fields{ifi}),filename,st_java);
            else
                fprintf('   %s to %s\n',fields{ifi},surv.(fields{ifi}));
                sql_query=sprintf('UPDATE logbook SET %s="%s" WHERE instr(Filename, ''%s'')>0 and instr(''%s'',StartTime)>0',...
                    (fields{ifi}),surv.(fields{ifi}),filename,st_java);

            end
            dbconn.exec(sql_query);
        end
%                    sql_query=sprintf('SELECT * FROM logbook WHERE instr(Filename, ''%s'')>0 and instr(''%s'',StartTime)>0',...
%                     filename,st_java);
%                    tt = dbconn.fetch(sql_query);
    end
end

idx_struct=obj.LogbookTable.Data.Id(idx);

for ifi=1:numel(fields)
    if modified(ifi)
        if ismember(fields(ifi),obj.FullData.Properties.VariableNames)
            obj.FullData.(fields(ifi))(idx_struct)= surv.(fields{ifi});
            obj.LogbookTable.Data.(fields(ifi))(idx)= surv.(fields{ifi});
        end
    end
end

layers = get_esp3_prop('layers');
if ~isempty(layers)
    [idx_lay,found] = find_layer_idx_files(layers,cellstr(obj.LogbookTable.Data.Filename(idx)));
    if any(found)
        layers(idx_lay).add_survey_data_db();
    end
end
update_tree_layer_tab(main_figure);
display_survdata_lines(main_figure);
update_axis(main_figure,1,'main_or_mini','mini');
create_context_menu_sec_echo();
set(load_bar_comp.progress_bar,'Value',100);
load_bar_comp.progress_bar.setText('');
hide_status_bar(main_figure);
disp('Done.');

end

%%


function copy_to_other_cback(src,evt,obj,main_figure,sel_or_high)

path_f=fileparts(obj.DbFile);
switch sel_or_high
    case 'sel'
        selected_files=unique(obj.FullData.Filename([obj.FullData{:,1}]));
    case 'high'
        selected_files=unique(obj.LogbookTable.UserData.highlighted_files);
end

files=fullfile(path_f,selected_files);

path_tmp = uigetdir(path_f,...
    'Copy to folder');
if isequal(path_tmp,0)
    return;
end
show_status_bar(main_figure);
load_bar_comp = getappdata(main_figure,'Loading_bar');

set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(files), 'Value',0);

for ui=1:numel(files)
    load_bar_comp.progress_bar.setText(sprintf('Copying %s',files{ui}));
    [status,msg,~] = copyfile(files{ui}, path_tmp, 'f');
%     switch ispc
%         case 1
%             [status,~] = system(sprintf('copy %s %s',files{ui},path_tmp),'-echo');
%         case 0
%             [status,~] = system(sprintf('cp %s %s',files{ui},path_tmp),'-echo');
%     end
    
    if ~status
        dlg_perso(main_figure,'Error copying file',sprintf('Error copying %s: \n%s',files{ui},msg));
        %dlg_perso(main_figure,'Error copying file',sprintf('Error copying %s',files{ui}));
    end
    set(load_bar_comp.progress_bar,'Value',ui);
end

hide_status_bar(main_figure);
end


%%
function display_files_tracks_cback(src,evt,obj,main_figure,f_save)

selected_files=unique(obj.FullData.Filename([obj.FullData{:,1}]));
if isempty(selected_files)
    return;
end
path_f=fileparts(obj.DbFile);
disp=1;

if ~isempty(f_save)
    % prompt for output file
    [csvfilename, csvpathname] = uiputfile({'*.shp', 'Shapefile';'*.csv' 'CSV';},...
        'Define output .csv/.shp file for GPS data',...
        fullfile(path_f,'gps_data.shp'));
    if isequal(csvfilename,0) || isequal(csvpathname,0)
        return
    end
    f_save=fullfile(csvpathname,csvfilename);
    disp=0;
end
files=cellstr(fullfile(path_f,selected_files));

plot_gps_track_from_filenames(main_figure,files,disp,f_save);

end

function proc_files_callback(src,~,obj,main_figure)

selected_files=cellstr(unique(obj.FullData.Filename([obj.FullData{:,1}])));
path_f=fileparts(obj.DbFile);
files=fullfile(path_f,selected_files);

 process_layers_cback([],[],main_figure,3,files);

end

function plot_bad_pings_callback(src,~,obj,main_figure)

selected_files=cellstr(unique(obj.FullData.Filename([obj.FullData{:,1}])));
path_f=fileparts(obj.DbFile);
files=fullfile(path_f,selected_files);

[nb_bad_pings,nb_pings,files_out,freq_vec,cids]=get_bad_ping_number_from_bottom_xml(files);

[filename, pathname]=uiputfile({'*.txt','Text File'},'Save Bad Ping file',...
    fullfile(path_f,'bad_pings_f'));

if isequal(filename,0) || isequal(pathname,0)
    fid=1;
else
    fid_f=fopen(fullfile(pathname,filename),'w');
    if fid_f~=-1
        fid=[1 fid_f];
    end
end
h_fig=new_echo_figure(main_figure);
ax=axes(h_fig);hold(ax,'on');grid(ax,'on');ylabel('%')
title(ax,filename,'Interpreter','none');
for ifreq=1:length(freq_vec)
    plot_temp=plot(ax,nb_bad_pings{ifreq}./nb_pings{ifreq}*100,'Marker','+');
    
    set(plot_temp,'ButtonDownFcn',{@display_filename_callback,files_out{ifreq}});
    
    for i=1:length(fid)
        fprintf(fid(i),'Bad Pings for channel %s\n',cids{ifreq});
        for i_sub=1:length(nb_bad_pings{ifreq})
            fprintf(fid(i),'%s %.2f %s}\n',files_out{ifreq}{i_sub},nb_bad_pings{ifreq}(i_sub)./nb_pings{ifreq}(i_sub)*100,cids{ifreq});
        end
        fprintf(fid(i),'\n');
    end
    
end
legend(ax,cids);
for i=1:length(fid)
    if fid(i)~=1
        fclose(fid(i));
    end
end


end

function cell_select_cback(src,evt,obj)
% parent=ancestor(src,'figure');
% pathf=fileparts(obj.DbFile);
src.UserData.highlighted_idx=unique(evt.Indices(:,1));
src.UserData.highlighted_files=cellstr(obj.LogbookTable.Data.Filename(unique(evt.Indices(:,1))));

% switch parent.SelectionType
%     case 'open'
%         if ~isempty(evt.Indices)
%             esp3_obj=getappdata(groot,'esp3_obj');
%             esp3_obj.open_file(fullfile(pathf,obj.LogbookTable.Data.Filename{evt.Indices(1,1)}));
%         end
% end


end

function selection_callback(src,~,obj)
switch src.Tag
    case 'se'
        obj.LogbookTable.Data.("Sel.")(:)=true;
    case 'de'
        obj.LogbookTable.Data.("Sel.")(:)=false;
    case 'inv'
        obj.LogbookTable.Data.("Sel.")=~obj.LogbookTable.Data.("Sel.");
    case 'high'
        idx_sel=obj.LogbookTable.UserData.highlighted_idx;
        obj.LogbookTable.Data.("Sel.")(idx_sel)=true;
    case 'dehigh'
        idx_sel=obj.LogbookTable.UserData.highlighted_idx;
        obj.LogbookTable.Data.("Sel.")(idx_sel)=false;
end
obj.FullData.("Sel.")(obj.LogbookTable.Data.Id)=obj.LogbookTable.Data.("Sel.");

end

function edit_surv_data_db(src,evt,obj,main_figure)

if isempty(evt.Indices)
    return;
end
if ~isvalid(obj.DbConn)
    obj.DbConn = connect_to_db(obj.DbFile);
end

dbconn = obj.DbConn;

idx_struct = obj.LogbookTable.Data.Id(evt.Indices(1,1));

fields = obj.LogbookTable.Data.Properties.VariableNames;

col_id = evt.Indices(1,2);
curr_field = fields{col_id};

row_id = evt.Indices(1,1);
st = obj.LogbookTable.Data.StartTime{row_id};
filename = char(obj.LogbookTable.Data.Filename{row_id});

new_val = evt.NewData;

obj.FullData.(string(curr_field))(idx_struct) = obj.LogbookTable.Data.(string(curr_field))(row_id);

if ~ismember(curr_field,properties(survey_data_cl))
    return;
end

db_file = obj.DbFile;

db_conn_tmp = initialize_echo_logbook_dbfile(fileparts(db_file),0);
db_conn_tmp.close();

if strcmpi(dbconn.ReadOnly,'on')
    fprintf('Database file is readonly... Check file permissions\n');
    return;
end

if isnumeric(new_val)
    fmt = '%d';
else
    fmt = '%s';
    fmt=['''' fmt ''''];  
end


disp_perso(main_figure,'Updating Logbook');
%sql_query = sprintf(['UPDATE logbook SET %s=' fmt ' WHERE instr(Filename, ''%s'')>0 AND StartTime = %d'],curr_field,new_val,filename,datenum_to_javatime(datenum(st,'yyyy-mm-dd HH:MM:SS')));
sql_query = sprintf(['UPDATE logbook SET %s=' fmt ' WHERE instr(Filename, ''%s'')>0 AND instr(''%s'',StartTime)>0'],curr_field,new_val,filename,st);
dbconn.exec(sql_query);

% % %sql_query = sprintf('SELECT Filename FROM logbook WHERE instr(Filename, ''%s'')>0 AND StartTime = %d',filename,datenum_to_javatime(datenum(st,'yyyy-mm-dd HH:MM:SS')));
% sql_query = sprintf('SELECT Filename FROM logbook WHERE instr(Filename, ''%s'')>0 AND instr(''%s'',StartTime)>0',filename,st);
% %sql_query = sprintf('SELECT Filename, StartTime FROM logbook WHERE instr(Filename, ''%s'')>0',filename);
% %  
%  tt = dbconn.fetch(sql_query);

layers = get_esp3_prop('layers');
if ~isempty(layers)
    [idx_lay,found] = find_layer_idx_files(layers,filename);
    if found==1
        layers(idx_lay).add_survey_data_db();
    end
end

update_tree_layer_tab(main_figure);
display_survdata_lines(main_figure);
drawnow;

disp_perso(main_figure,'');
hide_status_bar(main_figure);

end


%%
function open_files_callback(src,evt,obj,main_figure,sel_or_high,parallel_process)

switch sel_or_high
    case 'sel'
        selected_files=cellstr(unique(obj.LogbookTable.Data.Filename([obj.LogbookTable.Data{:,1}])));
    case 'high'
        selected_files=unique(obj.LogbookTable.UserData.highlighted_files);
end

path_f=fileparts(obj.DbFile);
files=fullfile(path_f,selected_files);

esp3_obj=getappdata(groot,'esp3_obj');
esp3_obj.open_file('file_id',files,'parallel_process',parallel_process);


end

%%
function generate_xml_callback(~,~,obj,main_figure)

path_f=fileparts(obj.DbFile);
surv_data_struct=get_struct_from_db(path_f);
data_ori=obj.FullData;

idx_struct=unique(data_ori.Id(data_ori.("Sel.")));

survey_input_obj=survey_input_cl();

if isempty(idx_struct)
    return;
end

survey_input_obj.Infos.SurveyName=surv_data_struct.SurveyName{idx_struct(1)};
survey_input_obj.Infos.Voyage=surv_data_struct.Voyage{idx_struct(1)};
surv_data_struct.Folder=cell(size(surv_data_struct.Snapshot));
surv_data_struct.Folder(:)={path_f};
survey_input_obj.complete_survey_input_cl_from_struct(surv_data_struct,idx_struct,[],[]);

create_xml_script_gui('survey_input_obj',survey_input_obj,'logbook_file',path_f);


end

function tcorr(~,~,obj,main_figure)
    pathsave = fileparts(obj.DbFile);
    db_file = obj.DbFile;
    dbconn = connect_to_db(db_file);
    selected_files=unique(obj.LogbookTable.UserData.highlighted_files);

    defaultanswer = {0,0,0};
    prompt = {'Time offset (seconds)','Time offset (minutes)','Time offset (hours)'};
    [Time_offset,cancel] = input_dlg_perso([],'Correct time in files',prompt,...
    {'%.0f' '%.0f' '%.0f'},defaultanswer);
    TimeCorrection.File_names = selected_files;
    TimeCorrection.Time_offset = Time_offset;

    fsave = append(pathsave,"\TimeCorrection");
    save(fsave,"TimeCorrection");

    t_offset = seconds(Time_offset{3}*3600+Time_offset{2}*60+Time_offset{1});

    if iscell(selected_files)
        for iifn = 1:length(selected_files)
            tmp=dbconn.fetch(sprintf('SELECT StartTime,EndTime FROM logbook WHERE Filename ="%s"',selected_files{iifn}));
            if iscell(tmp.StartTime)
                stime = tmp.StartTime{1};
                etime = tmp.EndTime{1};
            else
                stime = tmp.StartTime;
                etime = tmp.EndTime;
            end  
            new_stime = datenum(stime)+t_offset;
            new_etime = datenum(etime)+t_offset;
            sql_cmd1=sprintf('UPDATE logbook SET StartTime = "%s" WHERE Filename="%s"',datestr(new_stime,"yyyy-mm-dd HH:MM:SS"),selected_files{iifn});
            sql_cmd2=sprintf('UPDATE logbook SET EndTime = "%s" WHERE Filename="%s"',datestr(new_etime,"yyyy-mm-dd HH:MM:SS"),selected_files{iifn});
            dbconn.execute(sql_cmd1);
            dbconn.execute(sql_cmd2);
        end
    else
        tmp=dbconn.fetch(sprintf('SELECT StartTime,EndTime FROM logbook WHERE Filename ="%s"',selected_files));
        stime = tmp.StartTime;
        etime = tmp.EndTime;
        new_stime = datenum(stime+t_offset);
        new_etime = datenum(etime+t_offset);
        sql_cmd1=sprintf('UPDATE logbook SET StartTime = "%s" WHERE Filename="%s"',datestr(new_stime,"yyyy-mm-dd HH:MM:SS"),selected_files);
        sql_cmd2=sprintf('UPDATE logbook SET EndTime = "%s" WHERE Filename="%s"',datestr(new_etime,"yyyy-mm-dd HH:MM:SS"),selected_files);
        dbconn.execute(sql_cmd1);
        dbconn.execute(sql_cmd2);
    end

dbconn.close();
end

function get_avg_d_instrument(~,~,obj,main_figure)    
    steps = 300;
    cmap = winter(steps)*100;
    sn=3;
    files_to_load=unique(obj.LogbookTable.UserData.highlighted_files);
    if ~isempty(files_to_load)
        path_f=fileparts(obj.DbFile);
        files=fullfile(path_f,files_to_load);
        %try
        missing_files = find_survey_data_db(files);
        if ~isempty(missing_files)
            war_str=sprintf('It looks like you are trying to process results from incomplete transects (%.0f missing files)... Do you want load the rest as well?',numel(missing_files));
            choice=question_dialog_fig(main_figure,'',war_str,'timeout',10);                
            switch choice
                case 'Yes'
                    files = union(files,missing_files);
                case 'No'
                    
                otherwise
                    
            end
        end
        
        ftype_cell = cellfun(@get_ftype,files,'un',0);
        [f_type_u,~]=unique(ftype_cell);
        for ift=1:length(f_type_u)
            switch f_type_u{ift}
                case {'EK80' 'EK60'}
        
                    warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
                    jframe=get(gcf,'javaframe');
                    app_path_main=whereisEcho();
                    esp3_icon = fullfile(app_path_main,'icons','echoanalysis.png');
                    jIcon=javax.swing.ImageIcon(esp3_icon);
                    jframe.setFigureIcon(jIcon);
                    esp3_obj=getappdata(groot,'esp3_obj');
                
                    dlg = uiprogressdlg(esp3_obj.logbook_fig_obj.LogbookFigure,'Icon',esp3_icon, ...
                        'Interpreter','html');
                    for stepi = 1:steps/sn
                        r = num2str(cmap(stepi,1));
                        g = num2str(cmap(stepi,2));
                        b = num2str(cmap(stepi,3));
                        msg = ['<p style=color:rgb(' r '%,' g '%,' b '%)>','Reading files','... </p>'];
                        dlg.Message = msg;
                        dlg.Value = stepi/steps;
                        pause(0.05);
                    end
                    [layers,~]=open_EK_file_stdalone(files,'Frequencies',38000);
                    for stepi = steps/sn:2*steps/sn
                        r = num2str(cmap(stepi,1));
                        g = num2str(cmap(stepi,2));
                        b = num2str(cmap(stepi,3));
                        msg = ['<p style=color:rgb(' r '%,' g '%,' b '%)>','Processing results ','... </p>'];    
                        dlg.Message = msg;
                        dlg.Value = stepi/steps;
                        pause(0.05);
                    end

                    layers.load_echo_logbook_db();
                    compt = 1;
                    for ilay=1:numel(layers)
                        layers(ilay).load_bot_regs('Frequencies',38000);
                        layers(ilay).get_gps_data_from_csv({},0);
                        for iis=1:numel(layers(ilay).SurveyData)
                            if (layers(ilay).SurveyData{iis}.Snapshot>0)&&(strcmp(layers(ilay).SurveyData{iis}.Type,'Acoustic'))
                                snl(compt,:)=ilay;
                                stn(compt,:)=iis;
                                surveydata{compt,:} = append('Snapshot',num2str(layers(ilay).SurveyData{iis}.Snapshot),'_Type',layers(ilay).SurveyData{iis}.Type,'_Stratum',layers(ilay).SurveyData{iis}.Stratum,'_transect',num2str(layers(ilay).SurveyData{iis}.Transect));
                                compt = compt+1;
                            end
                        end
                    end
                
                    Survey_Data=unique(surveydata,'stable');
                    idata=cellfun(@(x) ismember(surveydata,x),Survey_Data,'un',0);
                    for iib=1:length(idata)
                        s = snl(idata{iib});
                        t = stn(idata{iib});
                        DI = [];
                        BD = [];
                        S = [];
                        nbpt = 0;
                        nbgp = 0;
                        dist_transect = 0;
                        for jjb=1:length(s)
                            id1 = find(layers(s(jjb)).Transceivers(1).Time>=layers(s(jjb)).SurveyData{t(jjb)}.StartTime,1);
                            id2 = find(layers(s(jjb)).Transceivers(1).Time>=layers(s(jjb)).SurveyData{t(jjb)}.EndTime,1);
                            if isempty(id1)
                                id1 = 1;
                            end
                            if isempty(id2)
                                id2 = size(layers(s(jjb)).Transceivers(1).Time,2);
                            end
                            DI = [DI,layers(s(jjb)).Transceivers(1).get_transducer_depth(id1:id2)];
                            BD = [BD,layers(s(jjb)).Transceivers(1).get_bottom_depth(id1:id2)];
                            S = [S,layers(s(jjb)).Transceivers(1).GPSDataPing.Speed(id1:id2)];
                            ts{jjb,:} = datestr(layers(s(jjb)).Transceivers(1).Time(id1),'yyyy-mm-dd HH:MM:SS');
                            te{jjb,:} = datestr(layers(s(jjb)).Transceivers(1).Time(id2),'yyyy-mm-dd HH:MM:SS');
                            nbpt = nbpt+id2-id1;
                            nbgp = nbgp+(id2-id1)-size(layers(s(jjb)).Transceivers(1).get_badtrans_idx(id1:id2),2);
                            dist_transect_interm = layers(s(jjb)).Transceivers(1).get_dist(id1:id2);
                            dist_transect = dist_transect+(dist_transect_interm(end)-dist_transect_interm(1));
                            slat(jjb,:) = layers(s(jjb)).Transceivers(1).GPSDataPing.Lat(id1);
                            elat(jjb,:) = layers(s(jjb)).Transceivers(1).GPSDataPing.Lat(id2);
                            slon(jjb,:) = layers(s(jjb)).Transceivers(1).GPSDataPing.Long(id1);
                            elon(jjb,:) = layers(s(jjb)).Transceivers(1).GPSDataPing.Long(id2);
                        end
                        time_start{iib,:} = ts{1};
                        time_end{iib,:} = te{end};
                        start_lat(iib,:) = slat(1);
                        end_lat(iib,:) = elat(end);
                        start_lon(iib,:) = slon(1);
                        end_lon(iib,:) = elon(end);
                        nb_ping_tot(iib,:) = nbpt;
                        nb_good_ping(iib,:) = nbgp;
                        avg_depth_instrument(iib,:) = mean(DI);         
                        avg_bottom_d(iib,:) = mean(BD);
                        avg_speed(iib,:) = mean(S);
                        std_depth_instrument(iib,:) = nanstd(DI);         
                        std_bottom_d(iib,:) = nanstd(BD);
                        std_speed(iib,:) = nanstd(S);
                        transect_length(iib,:) = dist_transect;
                    end

                    T = table(Survey_Data,time_start,time_end,start_lat,end_lat,start_lon,end_lon,nb_good_ping,nb_ping_tot,avg_speed,std_speed,...
                        avg_depth_instrument,std_depth_instrument,avg_bottom_d,std_bottom_d,transect_length);
                    T(T.avg_depth_instrument==0,:) = [];
                    T.Properties.VariableNames = {'Survey Data','Time at the start of layer','Time at the end of layer',...
                    'Latitude at the start of layer','Latitude at the end of layer','Longitude at the start of layer',...
                    'Longitude at the end of layer','Number of good pings','Total number of pings','Average speed (knots)',...
                    'Standard deviation of speed (knots)','Average depth of instrument (m)','Standard deviation of depth of instrument (m)',...
                    'Average bottom depth (m)','Standard deviation of bottom depth (m)','Length of the layer (m)'};
                    for stepi = 2*steps/sn:3*steps/sn
                        r = num2str(cmap(stepi,1));
                        g = num2str(cmap(stepi,2));
                        b = num2str(cmap(stepi,3));
                        msg = ['<p style=color:rgb(' r '%,' g '%,' b '%)>','Exporting results ','... </p>'];    
                        dlg.Message = msg;
                        dlg.Value = stepi/steps;
                        pause(0.05);
                    end
                    writetable(T,append(path_f,'/','Average_depth_of_instrument.csv'));
                otherwise
                    war_str=sprintf('This functionnality is not available for the type of file you selected');
                    war_dlg=dlg_perso(main_figure,'',war_str,'timeout',10);
            end
        end
    end
end

