function enter_new_trip_in_database(main_figure,db_file)

if isempty(db_file)
    db_folder= fullfile(whereisEcho(),'config','db');
    handles.db_file= fullfile(db_folder,'ac_db.db');
else
    handles.db_file=db_file;
end

if~isfile(handles.db_file)
    file_sql=fullfile(whereisEcho,'config','db','ac_db.sql');
    create_ac_database(handles.db_file,file_sql,1,true);
end

size_max = get(0,'ScreenSize');
gui_fmt=init_new_gui_fmt_struct();
gui_fmt.txt_w=gui_fmt.txt_w*2;
gui_fmt.box_w=gui_fmt.box_w*2;
pdd = [0 0 0 0];


db_fig=new_echo_figure(main_figure,'Resize','on',...
    'Visible','off',...
    'Position',[0 0 size_max(3)*0.95 size_max(4)*0.80],'Name','Database loading tool','tag','ac_db_tool','UiFigureBool',true);

if ~isdeployed
    db_fig.HandleVisibility  = 'on';
end

main_menu_db.m_files = uimenu(db_fig,'Label','File(s)');

%uimenu(m_files,'Label','Save current db_file','MenuSelectedFcn',{@save_init_db,db_fig});
uimenu(main_menu_db.m_files,'Label','Create empty db file','MenuSelectedFcn',{@create_empty_db_file_cback,db_fig});
uimenu(main_menu_db.m_files,'Label','Import db file from ESP3 database','MenuSelectedFcn',{@import_other_db_cback,db_fig,'esp3'});
uimenu(main_menu_db.m_files,'Label','Import another initial db_file','MenuSelectedFcn',@load_db_file_cback);

setappdata(db_fig,'main_menu_db',main_menu_db);


% db_file='pgdb.niwa.local:acoustic_test:esp3';
dbconn=connect_to_db(handles.db_file);
ship_type_t=dbconn.fetch('SELECT * from t_ship_type');
platform_type=dbconn.fetch('SELECT * from t_platform_type');
transducer_location_type=dbconn.fetch('SELECT * from t_transducer_location_type');
transducer_orientation_type=dbconn.fetch('SELECT * from t_transducer_orientation_type');

if istable(ship_type_t)
    s_type=ship_type_t.ship_type';
elseif iscell(ship_type_t)
    s_type=ship_type_t(:,2)';
end

if istable(platform_type)
    pt=platform_type.platform_type';
elseif iscell(platform_type)
    pt=platform_type(:,2)';
end

if istable(transducer_location_type)
    tlt=transducer_location_type.transducer_location_type';
elseif iscell(transducer_location_type)
    tlt=transducer_location_type(:,2)';
end


if istable(transducer_orientation_type)
    tot= transducer_orientation_type.transducer_orientation_type';
elseif iscell(transducer_orientation_type)
    tot=transducer_orientation_type(:,2)';
end

dbconn.close();

mission_col_fmt={'logical' 'numeric' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char'};

mission_colnames={...
    'edit',...
    'mission_pkey',...
    'mission_name',...
    'mission_abstract',...
    'mission_start_date',...
    'mission_end_date',...
    'principal_investigator'...
    'principal_investigator_email',...
    'institution',...
    'data_centre',...
    'data_centre_email',...
    'mission_id',...
    'creator',...
    'contributor'...
    'mission_comments'...
    };

ship_col_fmt={'logical' 'numeric' 'char' s_type 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'numeric' 'numeric' 'numeric' 'numeric' 'numeric' 'char' 'char' 'char'};
empty_ship_data={true 1 '' s_type{1} '' '' '' '' '' '' '' 0 0 0 0 0 '' '' ''};

ship_colnames={...
    'edit'               ,...
    'ship_pkey'          ,...
    'ship_name'          ,...
    'ship_type'          ,...
    'ship_code'          ,...
    'ship_platform_code' ,...
    'ship_platform_class',...
    'ship_callsign'      ,...
    'ship_alt_callsign'  ,...
    'ship_IMO'           ,...
    'ship_operator'      ,...
    'ship_length'        ,...
    'ship_breadth'       ,...
    'ship_draft'         ,...
    'ship_tonnage'       ,...
    'ship_engine_power'  ,...
    'ship_noise_design'  ,...
    'ship_aknowledgement',...
    'ship_comments'      ,...
    };


deployment_col_fmt={'logical' 'numeric' {'---'} {'---'} 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char'};

deployment_colnames={...
    'edit'               ,...
    'deployment_pkey'        ,...
    'deployment_type'        ,...
    'deployment_ship'        ,...
    'deployment_name'            ,...
    'deployment_id'              ,...
    'deployment_description'     ,...
    'deployment_area_description',...
    'deployment_operator'        ,...
    'deployment_summary_report'  ,...
    'deployment_start_date'      ,...
    'deployment_end_date'        ,...
    'deployment_start_port'      ,...
    'deployment_end_port'        ,...
    'deployment_comments'        ,...
    };


handles.general_layout = uigridlayout(db_fig,[4 1]);
handles.general_layout.ColumnWidth = {'1x'};
handles.general_layout.RowHeight = {'1x' '1x' '1x' '1.2x' 25};
handles.general_layout.BackgroundColor = [1 1 1];
handles.general_layout.Padding = pdd;

handles.mission_table = uitable(handles.general_layout,...
    'Data',[],...
    'ColumnName',mission_colnames,...
    'ColumnFormat',mission_col_fmt,...
    'ColumnEditable',true,...
    'CellEditCallBack',{@cell_edit_cback,db_fig},...
    'CellSelectionCallback',@cell_select_cback,...
    'ColumnWidth','fit',...
    'RowName',[],...
    'Tag','t_mission');
handles.mission_table.Layout.Row = 1;
handles.mission_table.Layout.Column = 1;
handles.mission_table.UserData.select=[];


handles.deployment_table = uitable(handles.general_layout,...
    'Data',[],...
    'ColumnName',deployment_colnames,...
    'ColumnFormat',deployment_col_fmt,...
    'ColumnEditable',true,...
    'CellEditCallBack',{@cell_edit_cback,db_fig},...
    'CellSelectionCallback',@cell_select_cback,...
    'RowName',[],...
    'ColumnWidth','fit',...
    'Tag','t_deployment');
handles.deployment_table.UserData.select=[];
handles.ship_table.Layout.Row = 2;
handles.ship_table.Layout.Column = 1;

handles.ship_table = uitable(handles.general_layout,...
    'Data',[],...
    'ColumnName', ship_colnames,...
    'ColumnFormat',ship_col_fmt,...
    'ColumnEditable',true,...
    'CellEditCallBack',{@cell_edit_cback,db_fig},...
    'CellSelectionCallback',@cell_select_cback,...
    'RowName',[],...
    'ColumnWidth','fit',...
    'Tag','t_ship');
handles.ship_table.Layout.Row = 3;
handles.ship_table.Layout.Column = 1;

handles.ship_table.UserData.empty_data=empty_ship_data;
handles.ship_table.UserData.select=[];

create_table_txt_menu([handles.mission_table handles.ship_table handles.deployment_table])

% Create add_panel_Layout
add_panel_Layout = uigridlayout(handles.general_layout,[1 4]);
add_panel_Layout.Layout.Row = 4;
add_panel_Layout.Layout.Column = 1;
add_panel_Layout.ColumnWidth = {'1x' '1x' '2x' '3x'};
add_panel_Layout.RowHeight = {'1x'};
add_panel_Layout.BackgroundColor = [1 1 1];
add_panel_Layout.Padding = pdd;

mission_layout = uigridlayout(add_panel_Layout);
mission_layout.ColumnWidth = {'1x'};
mission_layout.RowHeight = {gui_fmt.txt_h '1x'};
mission_layout.Layout.Row = 1;
mission_layout.Layout.Column = 1;
mission_layout.BackgroundColor = [1 1 1];
mission_layout.Padding = pdd;

mission_str_h = uilabel(mission_layout,gui_fmt.txtTitleStyle,'text','Mission');
mission_str_h.Layout.Row = 1;
mission_str_h.Layout.Column = 1;


handles.mission_pop=uilistbox(mission_layout,gui_fmt.lstboxStyle,'Items',{'--'},'Multiselect','off');
handles.mission_pop.Layout.Row = 2;
handles.mission_pop.Layout.Column = 1;

deployment_layout = uigridlayout(add_panel_Layout,[2 1]);
deployment_layout.ColumnWidth = {'1x'};
deployment_layout.RowHeight = {gui_fmt.txt_h '1x'};
deployment_layout.Layout.Row = 1;
deployment_layout.Layout.Column = 2;
deployment_layout.BackgroundColor = [1 1 1];
deployment_layout.Padding = pdd;


deployment_str_h = uilabel(deployment_layout,gui_fmt.txtTitleStyle,'text','Deployment');
deployment_str_h.Layout.Row = 1;
deployment_str_h.Layout.Column = 1;

handles.deployment_pop=uilistbox(deployment_layout,gui_fmt.lstboxStyle,'Items',{'--'},'Multiselect','off');
handles.deployment_pop.Layout.Row = 2;
handles.deployment_pop.Layout.Column = 1;

app_path_main=whereisEcho();
% icon = get_icons_cdata(fullfile(app_path_main,'icons'));

fold_icon = fullfile(app_path_main,'icons','folder.png');

folder_layout = uigridlayout(add_panel_Layout,[3 5]);
folder_layout.ColumnWidth = {'1x' gui_fmt.txt_h gui_fmt.box_w '1x' gui_fmt.box_w/2};
folder_layout.RowHeight = {gui_fmt.txt_h gui_fmt.box_h '1x'};
folder_layout.Layout.Row = 1;
folder_layout.Layout.Column = 3;
folder_layout.BackgroundColor = [1 1 1];
folder_layout.Padding = pdd;


input_folder_label = uilabel(folder_layout,...
    'text','Input Data Folder',...
    'HorizontalAlignment','left');
input_folder_label.Layout.Row = 1;
input_folder_label.Layout.Column = 1;


handles.path_edit = uitextarea(folder_layout,...
    'BackgroundColor','w',...
    'Value','',...
    'HorizontalAlignment','left');
handles.path_edit.WordWrap = 'on';
handles.path_edit.Layout.Row = 2;
handles.path_edit.Layout.Column = 1;

handles.path_button = uibutton(folder_layout,'push',...
    'Text','',...
    'Icon',fold_icon);
handles.path_button.Layout.Row = 2;
handles.path_button.Layout.Column = 2;
handles.path_button.ButtonPushedFcn = {@select_folder_callback,handles.path_edit};

handles.add_button=uibutton(folder_layout,...
    'Text','Add');
handles.add_button.Layout.Row = 2;
handles.add_button.Layout.Column = 3;
handles.add_button.ButtonPushedFcn = {@add_folder_callback,db_fig};


output_folder_label = uilabel(folder_layout,...
    'Text','Ouput MINIDB file',...
    'HorizontalAlignment','left');
output_folder_label.Layout.Row = 1;
output_folder_label.Layout.Column = 4;

handles.sqlite_schema = uitextarea(folder_layout,...
    'Value','',...
    'Enable','off',...
    'HorizontalAlignment','left');
handles.sqlite_schema.WordWrap = 'on';
handles.sqlite_schema.Layout.Row = 2;
handles.sqlite_schema.Layout.Column = 4;

tmp1 = uibutton(folder_layout,'push',...
    'Text','',...
    'Icon',fold_icon,...
    'BackgroundColor','white');
tmp1.Layout.Row = 2;
tmp1.Layout.Column = 5;
tmp1.ButtonPushedFcn = {@choose_output_file,db_fig};

handles.summary_table = uitable(folder_layout,...
    'Data',[],...
    'ColumnName',{'------Input Data folder------' 'Mission PKEY' 'Deploy. PKEY' 'Deploy. ID' 'Platform Type' 'Transd. Location' 'Trand. Orientation'},...
    'ColumnFormat',{'char' 'numeric' 'numeric' 'char' pt tlt tot},...
    'ColumnEditable',[false false false false true true true],...
    'CellSelectionCallback',@cell_select_cback,...
    'RowName',[],...
    'ColumnWidth','fit',...
    'Tag','t_deployment');
handles.summary_table.Layout.Row = 3;
handles.summary_table.Layout.Column = [1 5];
handles.summary_table.UserData.select=[];

rc_menu = uicontextmenu(ancestor(handles.summary_table,'figure'));
uimenu(rc_menu,'Label','Remove','MenuSelectedFcn',{@rm_folder_cback,handles.summary_table});
handles.summary_table.ContextMenu =rc_menu;

db_layout = uigridlayout(add_panel_Layout,[3 3]);
db_layout.ColumnWidth = {'1x' '1x' '1x'};
db_layout.RowHeight = {gui_fmt.txt_h gui_fmt.box_h gui_fmt.box_h '1x'};
db_layout.Layout.Row = 1;
db_layout.Layout.Column = 4;
db_layout.BackgroundColor = [1 1 1];
db_layout.Padding = pdd;


tmp2 = uibutton(db_layout,'push',...
    'Text','Generate MINIDB');
tmp2.Layout.Row = 2;
tmp2.Layout.Column = 1;
tmp2.ButtonPushedFcn = {@generate_db_cback,db_fig};

handles.sqlite_table = uitable(db_layout,...
    'Data',[],...
    'ColumnName',{'Mission' 'Deploy' 'ID'},...
    'ColumnFormat',{'char' 'char' 'char'},...
    'ColumnEditable',[false false false],...
    'CellSelectionCallback',@cell_select_cback,...
    'RowName',[],...
    'ColumnWidth','fit',...
    'Tag','sqlite');
handles.sqlite_table.Layout.Row = [3 4];
handles.sqlite_table.Layout.Column = 1;
handles.sqlite_table.UserData.select=[];

load_label = uilabel(db_layout,...
    'Text','Loading to Database process',...
    'HorizontalAlignment','left');
load_label.Layout.Row = 1;
load_label.Layout.Column = 2;

handles.load_bttn = uibutton(db_layout,'push',...
    'Text','Load to LOAD schema',...
    'Enable','off');
handles.load_bttn.Layout.Row = 2;
handles.load_bttn.Layout.Column = 2;
handles.load_bttn.ButtonPushedFcn = {@load_to_db_cback,db_fig,'load'};

handles.load_schema = uitextarea(db_layout,...
    'Value','dbfisheriesprod:acoustic:load',...
    'HorizontalAlignment','left');
handles.load_schema.WordWrap = 'on';
handles.load_schema.Layout.Row = 3;
handles.load_schema.Layout.Column = 2;
handles.load_schema.ValueChangedFcn = {@check_connection_cback,db_fig,'load'};

handles.load_table = uitable(db_layout,...
    'Data',[],...
    'ColumnName',{'Mission' 'Deploy' 'ID'},...
    'ColumnFormat',{'char' 'char' 'char'},...
    'ColumnEditable',[false false false],...
    'CellSelectionCallback',@cell_select_cback,...
    'RowName',[],...
    'ColumnWidth','fit',...
    'Tag','load');
handles.load_table.Layout.Row = 4;
handles.load_table.Layout.Column = 2;
handles.load_table.UserData.select=[];

handles.esp3_bttn=uibutton(db_layout,'push',...
    'Text','Load to ESP3 schema',...
    'Enable','off');
handles.esp3_bttn.Layout.Row = 2;
handles.esp3_bttn.Layout.Column = 3;
handles.esp3_bttn.ButtonPushedFcn = {@load_to_db_cback,db_fig,'esp3'};

handles.esp3_schema = uitextarea(db_layout,...
    'Value','dbfisheriesprod:acoustic:esp3',...
    'HorizontalAlignment','left');
handles.esp3_schema.WordWrap = 'on';
handles.esp3_schema.Layout.Row = 3;
handles.esp3_schema.Layout.Column = 3;
handles.esp3_schema.ValueChangedFcn = {@check_connection_cback,db_fig,'esp3'};

handles.esp3_table = uitable(db_layout,...
    'Data',[],...
    'ColumnName',{'Mission' 'Deploy' 'ID'},...
    'ColumnFormat',{'char' 'char' 'char'},...
    'ColumnEditable',[false false false],...
    'CellSelectionCallback',@cell_select_cback,...
    'RowName',[],...
    'ColumnWidth','fit',...
    'Tag','esp3');
handles.esp3_table.Layout.Row = 4;
handles.esp3_table.Layout.Column = 3;
handles.load_table.UserData.select=[];
db_fig.Visible = 'on';

load_bar_comp.panel=uipanel(handles.general_layout,...
    'BackgroundColor',[1 1 1],'tag','load_panel','visible','on','BorderType','line');
load_bar_comp.panel.Layout.Row = 5;
load_bar_comp.panel.Layout.Column = 1;
load_bar_comp.progress_bar=progress_bar_panel_cl(load_bar_comp.panel);
setappdata(db_fig,'Loading_bar',load_bar_comp);

setappdata(db_fig,'handles',handles);

check_connection_cback(handles.load_schema,[],db_fig,'load');
check_connection_cback(handles.esp3_schema,[],db_fig,'esp3');

create_table_db_menu([handles.sqlite_table handles.load_table handles.sqlite_table handles.esp3_table]);

update_data_tables(db_fig);


end

function  load_db_file_cback(src,~)

db_fig=ancestor(src,'figure');
handles=getappdata(db_fig,'handles');

db_file_ori=handles.db_file;
folder_ori=fileparts(db_file_ori);

[filename, pathname] = uigetfile('*.db',...
    'Output .db file',...
    folder_ori);
if isequal(filename,0) || isequal(pathname,0)
    return;
end
import_other_db_cback([],[],db_fig,fullfile(pathname,filename));

end

function import_other_db_cback(~,~,db_fig,str_db)

handles=getappdata(db_fig,'handles');

switch str_db
    case 'esp3'
       new_ac_db_file=retrieve_ac_db_from_other_db(handles.esp3_schema.Value{1});
       str_disp = handles.esp3_schema.Value{1};
    otherwise
      new_ac_db_file=str_db;
      str_disp = str_db;
end


if ~isempty(new_ac_db_file)
   [folder,~,~]=fileparts(handles.db_file);
   old_ac_db_dest=fullfile(folder,sprintf('ac_db%s.db',datestr(now,'HHMMSS_ddmmyyyy')));
   new_ac_db_dest=fullfile(folder,'ac_db.db');
   copyfile(handles.db_file,old_ac_db_dest,'f');
   copyfile(new_ac_db_file,new_ac_db_dest,'f');
   
   
   handles.summary_table.Data=[];
   setappdata(db_fig,'handles',handles);
   update_data_tables(db_fig);
   update_str(db_fig,'mission');
   update_str(db_fig,'deployment');
   update_data_tables(db_fig);   
   
   dlg_perso([],'Sucess',sprintf('Data imported from %s. Old database saved as %s',str_disp,old_ac_db_dest));
else
    dlg_perso([],'Failed',sprintf('Could not import data from %s',str_disp));
end


end

function new_ac_db_file=retrieve_ac_db_from_other_db(db_to_copy)
new_ac_db_file=fullfile(tempdir,'ac_db.db');
file_sql=fullfile(whereisEcho,'config','db','ac_db.sql');
create_ac_database(new_ac_db_file,file_sql,1,false);

dbconn=connect_to_db(db_to_copy);
if isempty(dbconn)
    delete(new_ac_db_file);
    new_ac_db_file=[];
    return;
end
mission_t=dbconn.fetch('SELECT * from t_mission ORDER BY mission_start_date');
deployment_t=dbconn.fetch('SELECT * from t_deployment ORDER BY deployment_start_date');
ship_t=dbconn.fetch('SELECT * from t_ship');
deployment_type_t=dbconn.fetch('SELECT * from t_deployment_type');
ship_type_t=dbconn.fetch('SELECT * from t_ship_type');
dbconn.close();
d_struct=table2struct(deployment_t,'ToScalar',true);
m_struct=table2struct(mission_t,'ToScalar',true);
dbconn=connect_to_db(new_ac_db_file);

add_mission_struct_to_t_mission(dbconn,'mission_struct',m_struct);
add_deployment_struct_to_t_deployment(dbconn,'deployment_struct',d_struct);
dbconn.sqlwrite('t_ship',ship_t);
dbconn.exec('DELETE from t_deployment_type');
dbconn.sqlwrite('t_deployment_type',deployment_type_t);
dbconn.exec('DELETE from t_ship_type');
dbconn.sqlwrite('t_ship_type',ship_type_t);

dbconn.close();



end

function update_data_tables(db_fig)
handles=getappdata(db_fig,'handles');

if~isfile(handles.db_file)
    file_sql=fullfile(whereisEcho,'config','db','ac_db.sql');
    create_ac_database(handles.db_file,file_sql,1,false);
end

db_file=handles.db_file;
%db_file='pgdb.niwa.local:acoustic_test:esp3';

dbconn=connect_to_db(db_file);

mission_t=dbconn.fetch('SELECT * FROM t_mission ORDER BY mission_start_date DESC');
deployment_t=dbconn.fetch('SELECT * FROM t_deployment ORDER BY deployment_start_date DESC');
ship_t=dbconn.fetch('SELECT * FROM t_ship');
deployment_type_t=dbconn.fetch('SELECT * FROM t_deployment_type');
ship_type_t=dbconn.fetch('SELECT * FROM t_ship_type');
dbconn.close();

if~isempty(mission_t)
    %mission_t.mission_pkey=[];
    data_mission=table2cell(mission_t);
    data_mission=[num2cell(false(1,size(data_mission,1)));data_mission']';
else
    data_mission=[];
end
handles.mission_table.UserData.select=[];
handles.mission_table.Data=data_mission;

if~isempty(ship_t)
    ship_t.ship_type_key = ship_type_t.ship_type(ship_t.ship_type_key);
    ship_t.Properties.VariableNames(strcmp(ship_t.Properties.VariableNames,'ship_type_key'))={'ship_type'};
    data_ship=table2cell(ship_t);
    data_ship=[num2cell(false(1,size(data_ship,1)));data_ship']';
else
    data_ship=[];
end
handles.ship_table.UserData.select=[];
handles.ship_table.Data=data_ship;

if~isempty(deployment_t)
    id_type=nan(1,numel(deployment_t.deployment_type_key));
    id_ship=nan(1,numel(deployment_t.deployment_type_key));
    
    for id=1:numel(deployment_t.deployment_ship_key)
        id_type(id)=find(deployment_t.deployment_type_key(id)==deployment_type_t.deployment_type_pkey);
        id_ship(id)=find(ship_t.ship_pkey==deployment_t.deployment_ship_key(id));
    end
    
    deployment_t.deployment_type_key=cell(numel(deployment_t.deployment_type_key),1);
    deployment_t.deployment_ship_key=cell(numel(deployment_t.deployment_type_key),1);
    
    deployment_t.deployment_type_key = deployment_type_t.deployment_type(id_type);
    deployment_t.deployment_ship_key = ship_t.ship_name(id_ship);
    
    deployment_t.Properties.VariableNames(strcmp(deployment_t.Properties.VariableNames,'deployment_type_key'))={'deployment_type'};
    deployment_t.Properties.VariableNames(strcmp(deployment_t.Properties.VariableNames,'deployment_ship_key'))={'deployment_ship'};
    deployment_t.deployment_northlimit=[];
    deployment_t.deployment_eastlimit=[];
    deployment_t.deployment_southlimit=[];
    deployment_t.deployment_westlimit=[];
    deployment_t.deployment_uplimit=[];
    deployment_t.deployment_downlimit=[];
    deployment_t.deployment_units=[];
    deployment_t.deployment_zunits=[];
    deployment_t.deployment_projection=[];
    
    if any(contains(deployment_t.Properties.VariableNames,'deployment_start_BODC_code'))
        deployment_t.deployment_start_BODC_code=[];
        deployment_t.deployment_end_BODC_code=[];
    else
        deployment_t.deployment_start_bodc_code=[];
        deployment_t.deployment_end_bodc_code=[];
    end
    data_deployment=table2cell(deployment_t);
    data_deployment=[num2cell(false(1,size(data_deployment,1)));data_deployment']';
else
    data_deployment=[];
end
handles.deployment_table.UserData.select=[];
handles.deployment_table.Data=data_deployment;
handles.deployment_table.ColumnFormat={'logical' 'numeric' deployment_type_t.deployment_type' {'---'} 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char'};

if ~isempty(handles.ship_table.Data)
    handles.deployment_table.ColumnFormat(contains(handles.deployment_table.ColumnName,'deployment_ship'))={unique(handles.ship_table.Data(:,3))'};
end

update_str(db_fig,'mission');
update_str(db_fig,'deployment');

end


function update_db_tables(db_fig,schema)
handles=getappdata(db_fig,'handles');
for i=1:numel(schema)
    try
        if strcmpi(schema{i},'sqlite')
            if ~isfile(handles.([schema{i} '_schema']).Value{1})
                return;
            end
        end
		
        dbconn=connect_to_db(handles.([schema{i} '_schema']).Value{1});
        sql_query=['SELECT m.mission_name,'...
            'd.deployment_name, '...
            'd.deployment_id '...
            'FROM t_mission m,'...
            't_deployment d,'...
            't_mission_deployment md '...
            'WHERE m.mission_pkey=md.mission_key '...
            'AND d.deployment_pkey=md.deployment_key ORDER BY m.mission_start_date DESC;'];
        data=dbconn.fetch(sql_query);
        dbconn.close();
        if istable(data)
            data=table2cell(data);
        end
        
    catch
        data=[];
    end
    handles.([schema{i} '_table']).Data=data;
end
end


function check_connection_cback(src,~,db_fig,schema)
handles=getappdata(db_fig,'handles');

try
    dbconn=connect_to_db(src.Value{1});
catch
    dbconn=[];
end

if isempty(dbconn)
    state='off';
    col=[0.8 0 0];
else
    col=[0 0.8 0];
    state='on';
    dbconn.close();
end

switch schema
    case 'load'
        he=handles.load_schema;
        hb=handles.load_bttn;
        
    case 'esp3'
        he=handles.esp3_schema;
        hb=handles.esp3_bttn;
end

hb.Enable=state;
set(he,'BackgroundColor',col);
%update_db_tables(db_fig,{schema});
end

function load_to_db_cback(~,~,db_fig,schema)

% get handles for database source and destination
handles = getappdata(db_fig,'handles');

switch schema
    case 'load'
        db_source = handles.sqlite_schema.Value{1};
        db_dest   = handles.load_schema.Value{1};
        bck_and_rem = 0;
        choice=question_dialog_fig([],'Clear destination','Do you want to clear the LOAD schema before starting the transfer?','timeout',10,'default_answer',1);  
        switch choice
            case 'Yes'
                clear_dest = 1;
            case 'No'
                clear_dest = 0;
        end
    case 'esp3'
        db_source = handles.load_schema.Value{1};
        db_dest   = handles.esp3_schema.Value{1};
        bck_and_rem = 1;
        clear_dest = 0;
    otherwise
        return;
end

% transfer source to destination
transfer_ac_database(db_source,db_dest,'clear_dest',clear_dest,'backup_and_remove_src',bck_and_rem);

% update GUI tables
update_db_tables(db_fig,{'sqlite' 'load' 'esp3'});

end

function save_init_db(~,~,~)
disp('Saving init_db file...');

end

function  generate_db_cback(src,evt,db_fig)

handles = getappdata(db_fig,'handles');
summary_data = handles.summary_table.Data;
database_filename = handles.sqlite_schema.Value{1};

if ~isempty(summary_data)
        
    dbconn = connect_to_db(handles.db_file);
    %     ship_type_t=dbconn.fetch('SELECT * FROM t_ship_type');
    %     deployment_type_t=dbconn.fetch('SELECT * FROM t_deployment_type');
    
    deployment_t = dbconn.fetch('SELECT * FROM t_deployment');
    mission_t = dbconn.fetch('SELECT * FROM t_mission');
    ship_t = dbconn.fetch('SELECT * FROM t_ship');
    
    dbconn.close();
    
    deployment_struct = table2struct(deployment_t,'ToScalar',true);
    mission_struct    = table2struct(mission_t,'ToScalar',true);
    ship_struct       = table2struct(ship_t,'ToScalar',true);
    
    if ~isempty(database_filename)
        file_sql=fullfile(whereisEcho,'config','db','ac_db.sql');
        create_ac_database(database_filename,file_sql,1,true);
        
        ship_pkeys = add_ship_struct_to_t_ship(database_filename,'ship_struct',ship_struct);
        
        % number of data folders
        nb_f = size(summary_data,1);
        
        for ifi = 1:nb_f
            
            % getting mission and deployment pkeys FROM summary_data
            idx_mission    = find(mission_struct.mission_pkey==[summary_data{ifi,2}]);
            idx_deployment = find(deployment_struct.deployment_pkey==[summary_data{ifi,3}]);
            
            % see if database already has this mission in it
            [~,mission_pkey] = get_cols_from_table(database_filename,'t_mission','input_struct',mission_struct,'output_cols',{'mission_pkey'},'row_idx',idx_mission);
            
            if isempty(mission_pkey)
                % if not, insert it
                datainsert_perso(database_filename,'t_mission',mission_struct,'idx_insert',idx_mission);
                [~,mission_pkey] = get_cols_from_table(database_filename,'t_mission','input_struct',mission_struct,'output_cols',{'mission_pkey'},'row_idx',idx_mission);
            end
            
            % see if database already has this deployment in it
            %[~,deployment_pkey,SQL_query] = get_cols_from_table(database_filename,'t_deployment','input_struct',deployment_struct,'output_cols',{'deployment_pkey'},'row_idx',idx_deployment);
            [~,deployment_pkey,~] = get_cols_from_table(database_filename,'t_deployment',...
                'input_cols',{'deployment_id'},'input_vals',deployment_struct.deployment_id(idx_deployment),'output_cols',{'deployment_pkey'});
            
            if isempty(deployment_pkey)
                % if not, insert it
                datainsert_perso(database_filename,'t_deployment',deployment_struct,'idx_insert',idx_deployment);
                %[~,deployment_pkey] = get_cols_from_table(database_filename,'t_deployment','input_struct',deployment_struct,'output_cols',{'deployment_pkey'},'row_idx',idx_deployment);
                [~,deployment_pkey,~] = get_cols_from_table(database_filename,'t_deployment',...
                    'input_cols',{'deployment_id'},'input_vals',deployment_struct.deployment_id(idx_deployment),'output_cols',{'deployment_pkey'});
            end
            
            populate_ac_db_from_folder(db_fig,summary_data{ifi,1},...
                'ac_db_filename',database_filename,...
                'mission_pkey',mission_pkey{1,1},...
                'deployment_pkey',deployment_pkey{1,1},...
                'platform_type',summary_data{ifi,5},...
                'transducer_location_type',summary_data{ifi,6},...
                'transducer_orientation_type',summary_data{ifi,7},...
                'overwrite_db',0,...
                'populate_t_navigation',1);
            
        end
    else
        warning('Output not defined.')
    end
end
save_init_db(src,evt,db_fig);
update_db_tables(db_fig,{'sqlite'});
end

function create_empty_db_file_cback(~,~,db_fig)
handles=getappdata(db_fig,'handles');
folder=fileparts(handles.db_file);
f_def=fullfile(folder,'empty_ac_db.db');
[filename, pathname] = uiputfile('*.db',...
    'Output .db file',...
    f_def);
if isequal(filename,0) || isequal(pathname,0)
    return;
end
file_sql=fullfile(whereisEcho,'config','db','ac_db.sql');
create_ac_database(fullfile(pathname,filename),file_sql,1,false);
end

function choose_output_file(~,~,db_fig)
handles=getappdata(db_fig,'handles');
folder=handles.path_edit.Value{1};
out_file=handles.sqlite_schema.Value{1};

if isfile(out_file)
    folder=fileparts(out_file);
end
if ~isfolder(folder)
    folder=pwd;
end

data_deployment=handles.deployment_table.Data;
data_summary=handles.summary_table.Data;
if ~isempty(data_deployment)&&~isempty(data_summary)
    idx=(ismember([data_deployment{:,2}],[data_summary{:,3}]));
    deploy_id=data_deployment(idx,6);
    f_def=fullfile(folder,sprintf('%s_ac_db.db',strjoin(deploy_id,'_')));
else
    f_def=fullfile(folder,'ac_db.db');
end

[filename, pathname] = uiputfile('*.db',...
    'Output .db file',...
    f_def);
if isequal(filename,0) || isequal(pathname,0)
    return;
end
handles.sqlite_schema.Value = fullfile(pathname,filename);
update_db_tables(db_fig,{'sqlite'});
end

function add_folder_callback(~,~,db_fig)
handles=getappdata(db_fig,'handles');
folder=get(handles.path_edit,'Value');
data_mission=handles.mission_table.Data;
data_deployment=handles.deployment_table.Data;

if isfolder(folder)&&~isempty(data_mission)&&~isempty(data_deployment)
    mission_idx=find(strcmp(handles.mission_pop.Value,handles.mission_pop.Items));
    deployment_idx=find(strcmp(handles.deployment_pop.Value,handles.deployment_pop.Items));
    data_add={folder data_mission{mission_idx,2} data_deployment{deployment_idx,2} data_deployment{deployment_idx,6} '' '' ''};
    handles.summary_table.Data=table2cell(unique(cell2table([handles.summary_table.Data;data_add])));
end

end

function select_folder_callback(~,~,edit_box)

path_ori=get(edit_box,'Value');
path_ori = path_ori{1};
if ~isfolder(path_ori)
    path_ori=pwd;
end
new_path = uigetdir(path_ori);
if new_path~=0
    set(edit_box,'Value',new_path);
end

end

function rm_folder_cback(~,~,tb)
if ~isempty(tb.Data)&&~isempty(tb.UserData.select)
    tb.Data(tb.UserData.select(:,1),:)=[];
end
end

function create_table_txt_menu(tb)

for i=1:numel(tb)
    rc_menu = uicontextmenu(ancestor(tb(i),'figure'));
    uimenu(rc_menu,'Label','Add entry','MenuSelectedFcn',{@add_entry_cback,tb(i)});
    uimenu(rc_menu,'Label','Remove entry(ies)','MenuSelectedFcn',{@rm_entry_cback,tb(i)});
    tb(i).ContextMenu =rc_menu;
end
end

function create_table_db_menu(tb)
for i=1:numel(tb)
    rc_menu = uicontextmenu(ancestor(tb(i),'figure'));
    uimenu(rc_menu,'Label','Edit/View Setups','MenuSelectedFcn',{@edit_setup_cback,tb(i)});
    %uimenu(rc_menu,'Label','Edit/Add calibration','MenuSelectedFcn',{@edit_cal_cback,tb(i)});
    tb(i).ContextMenu =rc_menu;
end
end

function edit_setup_cback(src,~,tb)
db_fig=ancestor(src,'figure');
if ~isfield(tb.UserData,'select')
    return;
end
if ~isempty(tb.Data)&&~isempty(tb.UserData.select)
    idx=tb.UserData.select(end,1);
    handles=getappdata(db_fig,'handles');
    dbconn=connect_to_db(handles.([tb.Tag '_schema']).Value{1});
    switch tb.Tag
        case 'sqlite'
            dbtab='';
        otherwise
            dbtab=[tb.Tag '.'];
    end
    
    sql_cmd=[...
        'SELECT DISTINCT '...
        'trsc.transceiver_manufacturer,'...
        'trsc.transceiver_model,'...
        'trsc.transceiver_serial,'...
        'trsd.transducer_manufacturer,'...
        'trsd.transducer_model,'...
        'trsd.transducer_serial'...
        ' FROM '...
        dbtab 't_setup s,'...
        dbtab 't_deployment d,'...
        dbtab 't_file f,'...
        dbtab 't_file_setup fs,'...
        dbtab 't_transceiver trsc,'...
        dbtab 't_transducer trsd'...
        ' WHERE '...
        'd.deployment_id=''' tb.Data{idx,3} ''' AND '...
        'f.file_pkey=fs.file_key AND s.setup_pkey=fs.setup_key AND '...
        'f.file_deployment_key=d.deployment_pkey AND '...
        's.setup_transceiver_key=trsc.transceiver_pkey AND '...
        's.setup_transducer_key=trsd.transducer_pkey'];
    data=dbconn.fetch(sql_cmd);
    dbconn.close()
    if istable(data)
        data_t=table2cell(data);
    else
        data_t=data;
    end
    col_names={'transceiver_manufacturer' 'transceiver_model' 'transceiver_serial' 'transducer_manufacturer' 'transducer_model' 'transducer_serial'};
    col_fmt={'char' 'char' 'char' 'char' 'char' 'char'};
    sub_db_fig=new_echo_figure([],'WindowStyle','normal','Resize','off','Position',[0 0 600 200],'Name',tb.Data{idx,3});
    uitable(sub_db_fig,...
        'Data',data_t,...
        'ColumnName',col_names,...
        'ColumnFormat',col_fmt,...
        'ColumnEditable',[true true true true true true],...
        'CellEditCallBack',{@setup_edit_cback,tb,db_fig},...
        'CellSelectionCallback',[],...
        'RowName',[],...
        'Units','Norm',...
        'Position',[0 0 1 1]);
    
end
end

function setup_edit_cback(src,evt,tb,db_fig)
handles=getappdata(db_fig,'handles');
idx_edit=evt.Indices;
data_edit=src.Data(idx_edit(1),:);
data_old=data_edit;

data_old{idx_edit(2)}=evt.PreviousData;
switch idx_edit(2)
    case {1,2,3}
        sql_cmd=sprintf('UPDATE t_transceiver SET transceiver_manufacturer=''%s'', transceiver_model=''%s'', transceiver_serial=''%s'' WHERE transceiver_manufacturer=''%s'' AND transceiver_model=''%s'' AND transceiver_serial=''%s''',...
            data_edit{1},data_edit{2},data_edit{3},data_old{1},data_old{2},data_old{3});
    case {4,5,6}
        sql_cmd=sprintf('UPDATE t_transducer SET transducer_manufacturer=''%s'', transducer_model=''%s'', transducer_serial=''%s'' WHERE transducer_manufacturer=''%s'' AND transducer_model=''%s'' AND transducer_serial=''%s''',...
            data_edit{4},data_edit{5},data_edit{6},data_old{4},data_old{5},data_old{6});
end

dbconn=connect_to_db(handles.([tb.Tag '_schema']).Value{1});
out=dbconn.exec(sql_cmd);
dbconn.close();
end



function update_str(db_fig,tb_name)
handles=getappdata(db_fig,'handles');
data=handles.([tb_name '_table']).Data;
if isempty(data)
    str={'--'};
else
    str=data(:,contains(handles.([tb_name '_table']).ColumnName,([tb_name '_name'])));  
end

set(handles.(([tb_name '_pop'])),'Items',str,'Value',str{1});
end

function rm_entry_cback(~,~,tb)
if ~isempty(tb.Data)&&~isempty(tb.UserData.select)
    db_fig=ancestor(tb,'figure');
    handles=getappdata(db_fig,'handles');
    switch tb.Tag
        case 't_deployment'
            p_key='deployment_pkey';
        case 't_mission'
            p_key='mission_pkey';
        case 't_ship'
            p_key='ship_pkey';
    end
    dbconn=connect_to_db(handles.db_file);
    for i=[tb.Data{tb.UserData.select(:,1),2}]
        sql_cmd=sprintf('DELETE FROM %s where %s=%d',tb.Tag,p_key,i);
        try
            dbconn.exec(sql_cmd);
        catch
            disp('Could not delete entry');
        end
    end
    dbconn.close();
    update_str(db_fig,'mission');
    update_str(db_fig,'deployment');
    update_data_tables(db_fig);
end

end

function add_entry_cback(~,~,tb)
db_fig=ancestor(tb,'figure');
handles=getappdata(db_fig,'handles');

switch tb.Tag
    case 't_deployment'
        add_deployment_struct_to_t_deployment(handles.db_file);
    case 't_mission'
        add_mission_struct_to_t_mission(handles.db_file);
    case 't_ship'
        add_ship_struct_to_t_ship(handles.db_file);
end

update_str(db_fig,'mission');
update_str(db_fig,'deployment');
update_data_tables(db_fig);
end

function cell_select_cback(src,evt)
src.UserData.select=evt.Indices;
end

function cell_edit_cback(src,evt,db_fig)
handles=getappdata(db_fig,'handles');
colnames=src.ColumnName;
idx=evt.Indices;
row_id=idx(1);
colname=src.ColumnName{idx(2)};
if (src.Data{row_id,1}||idx(2)==1)
    pkey=src.Data{row_id,2};
    if ~iscell(src.ColumnFormat{idx(2)})
        switch src.ColumnFormat{idx(2)}
            case 'char'
                if contains(src.ColumnName{idx(2)},'date')||contains(src.ColumnName{idx(2)},'time')
                    try
                        tmp=datenum(evt.NewData);
                        tmp_str=datestr(tmp,'yyyy-mm-dd HH:MM:SS.FFF');
                        src.Data{row_id,idx(2)}=tmp_str(1:end-2);
%                         if contains(src.ColumnName{idx(2)},'date')
%                             src.Data{row_id,idx(2)}=datestr(tmp,'yyyy-mm-dd HH:MM:SS');
%                         else
%                             src.Data{row_id,idx(2)}=datestr(tmp,'yyyy-mm-dd HH:MM:SS');
%                         end
                    catch
                        src.Data{row_id,idx(2)}=evt.PreviousData;
                    end
                elseif contains(src.ColumnName{idx(2)},'ship_name')
                    fmt=handles.deployment_table.ColumnFormat(contains(handles.deployment_table.ColumnName,'deployment_ship'));
                    if any(strcmp(fmt{:},evt.NewData))
                        src.Data{row_id,idx(2)}=evt.PreviousData;
                    else
                        handles.deployment_table.ColumnFormat(contains(handles.deployment_table.ColumnName,'deployment_ship'))={unique(src.Data(:,idx(2)))'};
                    end
                end
                if isnumeric(src.Data{row_id,idx(2)})
                    src.Data{row_id,idx(2)}=strtrim(num2str(src.Data{row_id,idx(2)}));
                else
                    src.Data{row_id,idx(2)}=strtrim(src.Data{row_id,idx(2)});
                end
            case 'numeric'
                if isnan(evt.NewData)
                    src.Data{row_id,idx(2)}=evt.PreviousData;
                end
                
        end
    end
    data_ins=src.Data{row_id,idx(2)};
    if idx(2)~=1
        switch src.Tag
            case 't_deployment'
                pkey_name='deployment_pkey';
            case 't_mission'
                pkey_name='mission_pkey';
            case 't_ship'
                pkey_name='ship_pkey';
        end
        try
            dbconn=connect_to_db(handles.db_file);
            switch colname
                case 'deployment_ship'
                    data_ins_name='deployment_ship_key';
                    data_ins=dbconn.fetch(sprintf('SELECT ship_pkey FROM t_ship  WHERE ship_name=''%s''',src.Data{row_id,contains(colnames,'deployment_ship')}));
                    
                case 'deployment_type'
                    data_ins_name='deployment_type_key';
                    data_ins=dbconn.fetch(sprintf('SELECT deployment_type_pkey FROM t_deployment_type  WHERE deployment_type=''%s''',src.Data{row_id,contains(colnames,'deployment_type')}));
                    
                case 'ship_type'
                    data_ins_name='ship_type_key';
                    data_ins=dbconn.fetch(sprintf('SELECT ship_type_pkey FROM t_ship_type  WHERE ship_type=''%s''',src.Data{row_id,contains(colnames,'ship_type')}));
                    
                case 'edit'
                    return;
                otherwise
                    data_ins_name=colname;
            end
            if istable(data_ins)
                data_ins=data_ins{1,1};
            end
            
            if iscell(data_ins)
                data_ins=data_ins{1};
            end
            if isnumeric(data_ins)
                fmt='%d';
            else
                fmt='''%s''';
            end
            sql_cmd=sprintf(['UPDATE %s SET %s' '=' fmt ' WHERE %s=%d'],src.Tag,data_ins_name,data_ins,pkey_name,pkey);
            dbconn.exec(sql_cmd);
            dbconn.close();
            
            update_str(db_fig,'deployment');
            update_str(db_fig,'mission');
        catch
            src.Data{idx(1),idx(2)}=evt.PreviousData;
        end
    end
else
    src.Data{idx(1),idx(2)}=evt.PreviousData;
end
end
% function set_multi_select(h_m_table,m)
%
% j_scrollpane = findjobj(h_m_table);
%
% j_table = j_scrollpane.getViewport.getView;
% j_table.setNonContiguousCellSelection(false);
% j_table.setColumnSelectionAllowed(false);
% j_table.setRowSelectionAllowed(true);
%
% j_table.setSelectionMode(m);
%
% end