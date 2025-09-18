
function day_night_h = DPT(varargin)

default_row_height = 24;
default_col_width = 92;

p = inputParser;
addParameter(p,'logbook_file',{},@(x) iscellstr(x)||isstring(x)||isfile(x)||isfolder(x));

parse(p,varargin{:});

main_figure = get_esp3_prop('main_figure');

day_night_h.fig_h = new_echo_figure(main_figure,'UiFigureBool',true,'Name','DéPiTé: Dataset partitioning Tool','Position',[0 0 20*default_col_width  40*default_row_height],'Tag','DPT');

uigl_temp = uigridlayout(day_night_h.fig_h,[4 4],'Scrollable','on');
uigl_temp.RowHeight = {12*default_row_height 14*default_row_height  3*default_row_height '1x'};
uigl_temp.ColumnWidth = {5*default_col_width 7*default_col_width 5*default_col_width '1x'};


day_night_h.dataset_panel_h = uipanel(uigl_temp,'Title','Dataset selection (1)','Scrollable','on','BackgroundColor','white');

day_night_h.time_part_panel_h = uipanel(uigl_temp,'Title','Dawn/Day/Dusk/Night Timing (2)','Scrollable','on','BackgroundColor','white');
day_night_h.geo_part_panel_h = uipanel(uigl_temp,'Title','Geographical Stratification (3)','Scrollable','on','BackgroundColor','white');

day_night_h.load_process_panel_h = uipanel(uigl_temp,'Title','partitioning (4)','Scrollable','on','BackgroundColor','white');
day_night_h.load_process_panel_h.Layout.Row = 2;
day_night_h.load_process_panel_h.Layout.Column = 1;

day_night_h.final_panel_h = uipanel(uigl_temp,'Title','Export/save results (5)','Scrollable','on','BackgroundColor','white');
day_night_h.final_panel_h.Layout.Row = 3;
day_night_h.final_panel_h.Layout.Column = 1;

day_night_h.map_panel_h = uipanel(uigl_temp,'Title','Chart','Scrollable','on','BackgroundColor','white');
day_night_h.map_panel_h.Layout.Row = [2 4];
day_night_h.map_panel_h.Layout.Column = [2 5];


%%%%%%%%%%%%%%%%%%%Dataset panel%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
variable_names_types = [["Logbook File", "string"]; ...
    ["Voyage", "string"]; ...
    ["Survey", "string"]];

dataset_table = table('Size',[0,size(variable_names_types,1)],...
    'VariableNames', variable_names_types(:,1),...
    'VariableTypes', variable_names_types(:,2));
uigl_tmp = uigridlayout(day_night_h.dataset_panel_h,[2 3],'Scrollable','on');
uigl_tmp.RowHeight = {'1x' default_row_height};
uigl_tmp.ColumnWidth = {'1x' default_col_width '1x'};
uigl_tmp.Padding = [0 10 0 0];
day_night_h.logbook_table = uitable(uigl_tmp,...
    'Data',dataset_table,...
    'ColumnEditable',false,...
    'CellSelectionCallback',@cell_select_cback,...
    'RowName',[]);

day_night_h.logbook_table.Layout.Row = 1;
day_night_h.logbook_table.Layout.Column = [1 3];
day_night_h.logbook_table.UserData.select=[];
day_night_h.logbook_table.Tooltip  = 'Right-clik on the table to add/remove datasets';

rc_menu = uicontextmenu(ancestor(day_night_h.logbook_table,'figure'));
uimenu(rc_menu,'Label','Add Logbook','MenuSelectedFcn',{@add_logbook_cback,1});
uimenu(rc_menu,'Label','Remove entry(ies)','MenuSelectedFcn',{@add_logbook_cback,-1});
day_night_h.logbook_table.ContextMenu =rc_menu;
tmp_h = uibutton(uigl_tmp,'Text','Load dataset(s)','ButtonPushedFcn',@load_datasets_cback);
tmp_h.Layout.Column = 2;
tmp_h.UserData.select = 1;

%%%%%%%%%%%%%%%%%%%partitioning panel%%%%%%%%%%%%%%%%%%%%%%%%
sz  = [9 6];
uigl_day_night_management = uigridlayout(day_night_h.time_part_panel_h ,sz,'Scrollable','on');
uigl_day_night_management.RowHeight = repmat({default_row_height},1,sz(1));
uigl_day_night_management.ColumnWidth = repmat({default_col_width},1,sz(2));


uilabel(uigl_day_night_management,'Text','Area:','HorizontalAlignment','right');
areas = {'Africa'	'Asia'	'Europe' 'America'	'Atlantic'	'Indian' 'Antarctica'	'Australia'	'Pacific' 'Arctic'	'Etc'	'All'};
day_night_h.areas_h = uidropdown(uigl_day_night_management,"Value",'Etc','Items',areas,'ValueChangedFcn',@update_tz_dropdown);
uilabel(uigl_day_night_management,'Text','Timezone:','HorizontalAlignment','right','Tooltip','Timezone in which files have been recorded. If there is an offset from the actual timezone, use the offset box below.');
day_night_h.timezone_h = uidropdown(uigl_day_night_management,'ValueChangedFcn',@update_UTC_DST);
day_night_h.UTCOffset_h = uilabel(uigl_day_night_management);
day_night_h.DSTOffset_h = uicheckbox(uigl_day_night_management);
update_tz_dropdown(day_night_h.areas_h,[]);
update_UTC_DST([],[]);
tmp_h = uilabel(uigl_day_night_management,'Text','File(s) offset:','HorizontalAlignment','right');
tmp_h.Layout.Row = 2;
tmp_h.Layout.Column = 1;
day_night_h.FileOffset = uieditfield(uigl_day_night_management,'numeric','Value',0,'ValueDisplayFormat','%+.0f minutes');


time_partition_struct.Type = {'Dawn';'Day';'Dusk';'Night'};
time_partition_struct.From = [-1.5;1.5;-1.5;1.5];
time_partition_struct.FromRef = {'Sunrise';'Sunrise';'Sunset';'Sunset'};
time_partition_struct.To = circshift(time_partition_struct.From,-1);
time_partition_struct.ToRef = circshift(time_partition_struct.FromRef,-1);

time_partition_table = struct2table(time_partition_struct);

row_init = 2;
for ui = 1:numel(time_partition_table.Type)
    day_night_h.(time_partition_table.Type{ui}) = uicheckbox(uigl_day_night_management,'Text',sprintf('%s:',time_partition_table.Type{ui}),...
        'Value',1,'ValueChangedFcn',@update_time_partition,'Tag',(time_partition_table.Type{ui}));
    day_night_h.(time_partition_table.Type{ui}).Layout.Column = 1;
    day_night_h.(time_partition_table.Type{ui}).Layout.Row = row_init+ui;
    day_night_h.(sprintf('From_%s',time_partition_table.Type{ui})) = uieditfield(uigl_day_night_management,'numeric','Value',time_partition_struct.From(ui),'Limits',[-6 6],...
        'ValueDisplayFormat','%+0.2f hours','ValueChangedFcn',@update_time_partition,'Tag',sprintf('From_%s',time_partition_table.Type{ui}));
    day_night_h.(sprintf('FromRef_%s',time_partition_table.Type{ui})) = uilabel(uigl_day_night_management,'Text', sprintf('from %s',time_partition_table.FromRef{ui}));
    uilabel(uigl_day_night_management,'Text','=====>');
    day_night_h.(sprintf('To_%s',time_partition_table.Type{ui})) = uieditfield(uigl_day_night_management,'numeric','Value',time_partition_struct.To(ui),'Limits',[-6 6],...
        'ValueDisplayFormat','%+0.2f hours','ValueChangedFcn',@update_time_partition,'Tag',sprintf('To_%s',time_partition_table.Type{ui}));
    day_night_h.(sprintf('ToRef_%s',time_partition_table.Type{ui})) = uilabel(uigl_day_night_management,'Text', sprintf('from %s',time_partition_table.ToRef{ui}));
end

day_night_h.mooring_bool_h = uicheckbox(uigl_day_night_management,'Value',false,'Text','Mooring','ValueChangedFcn',@toggle_lat_lon_cback,'Tooltip','fixed position');
uilabel(uigl_day_night_management,'Text','Latitude:','HorizontalAlignment','right');
[lat_str,lat_val_dec_deg] = fmt_coord('48.66','lat');
[lon_str,lon_val_dec_deg] = fmt_coord('-4.5','lon');
day_night_h.lat_str_h = uieditfield(uigl_day_night_management,'Value',lat_str,'UserData',lat_val_dec_deg,'ValueChangedFcn',@fmt_lat_long_cback,'Enable','off','Tag','lat');
uilabel(uigl_day_night_management,'Text','Longitude:','HorizontalAlignment','right');
day_night_h.lon_str_h = uieditfield(uigl_day_night_management,'Value',lon_str,'UserData',lon_val_dec_deg,'ValueChangedFcn',@fmt_lat_long_cback,'Enable','off','Tag','lon');


%%%%%%%%%%%%%%%%%%%Geographical partitioning panel%%%%%%%%%%%%%%%%%%%%%%%%
uigl_tmp = uigridlayout(day_night_h.geo_part_panel_h,[2 3],'Scrollable','on');
uigl_tmp.RowHeight = {'1x' default_row_height};
uigl_tmp.ColumnWidth = {'1x' default_col_width '1x'};
uigl_tmp.Padding = [0 10 0 0];

variable_names_types = [["Shapefile", "string"]; ...
    ["Stratum", "string"]];

strat_table = table('Size',[0,size(variable_names_types,1)],...
    'VariableNames', variable_names_types(:,1),...
    'VariableTypes', variable_names_types(:,2));


day_night_h.strat_table = uitable(uigl_tmp,...
    'Data',strat_table,...
    'ColumnEditable',[false true],...
    'CellSelectionCallback',@cell_select_cback,...
    'CellEditCallback',@strat_cell_edit_cback,...
    'RowName',[]);
day_night_h.strat_table.Layout.Row = 1;
day_night_h.strat_table.Layout.Column = [1 3];
day_night_h.strat_table.UserData.select=[];
day_night_h.strat_table.Tooltip  = 'Right-clik on the table to add/remove stratum definitions';
rc_menu = uicontextmenu(ancestor(day_night_h.strat_table,'figure'));

uimenu(rc_menu,'Label','Add stratum/strata','MenuSelectedFcn',{@add_strat_cback,1});
uimenu(rc_menu,'Label','Remove selected stratum/strata','MenuSelectedFcn',{@add_strat_cback,0});
uimenu(rc_menu,'Label','Remove all stratum/strata','MenuSelectedFcn',{@add_strat_cback,-1});
day_night_h.strat_table.UIContextMenu =rc_menu;

%%%%%%%%%%%%%%%%%%%Chart panel%%%%%%%%%%%%%%%%%%%%%%%%
uigl_tmp = uigridlayout(day_night_h.map_panel_h,[1 2],'Scrollable','on');
uigl_tmp.ColumnWidth = {'1x'};
uigl_tmp.RowHeight = {default_row_height+2*uigl_tmp.Padding(2) '1x'};
uigl_tmp.Padding = [0 0 0 0];
curr_disp=get_esp3_prop('curr_disp');
if isempty(curr_disp)
    base_curr=p.Results.basemap;
    [basemap_list,~,~,basemap_dispname_list]=list_basemaps(0,curr_disp.Online);
else
    base_curr=curr_disp.Basemap;
    [basemap_list,~,~,basemap_dispname_list]=list_basemaps(0,curr_disp.Online,curr_disp.Basemaps);
end
sz = [1 5];
uigl_tmp_2 = uigridlayout(uigl_tmp,sz,'Scrollable','on');
uigl_tmp_2.ColumnWidth = repmat({default_col_width},1,sz(2));


uilabel(uigl_tmp_2,'Text','Basemap:','HorizontalAlignment','right');
day_night_h.basemap_dd_h = uidropdown(uigl_tmp_2,'Items',basemap_dispname_list,'ItemsData',basemap_list,'Value',base_curr,'ValueChangedFcn',@update_basemap);

day_night_h.disp_unpart_h = uicheckbox(uigl_tmp_2,'Text','Disp. unpart.',"Value",true,'ValueChangedFcn',{@update_vis_plots_cback,{''}},'Tooltip','Display un-partitioned part of the dataset.');
day_night_h.disp_part_h = uicheckbox(uigl_tmp_2,'Text','Disp. part.',"Value",true,'ValueChangedFcn',{@update_vis_plots_cback,time_partition_struct.Type},'Tooltip','Display partitioned part of the dataset.');
day_night_h.map_ax = geoaxes(uigl_tmp,'basemap', base_curr);
day_night_h.map_ax.Layout.Column = [1 2];
day_night_h.map_ax.Layout.Row = 2;

format_geoaxes(day_night_h.map_ax);
day_night_h.transect_plots_h = matlab.graphics.chart.primitive.Line.empty();
day_night_h.strata_plots_h = matlab.graphics.chart.primitive.Line.empty();
day_night_h.boundaries_h = matlab.graphics.chart.primitive.Line.empty();


%%%%%%%%%%%%%%%%%%%Processing panel%%%%%%%%%%%%%%%%%%%%%%%%
sz  = [7 4];
uigl_tmp = uigridlayout(day_night_h.load_process_panel_h,sz,'Scrollable','on');
uigl_tmp.RowHeight = repmat({default_row_height},1,sz(1));
uigl_tmp.RowHeight{4} = 2*default_row_height;
uigl_tmp.RowHeight{5} = 4*default_row_height;
uigl_tmp.ColumnWidth = repmat({default_col_width},1,sz(2));
uigl_tmp.ColumnWidth{2} = default_col_width/2;
uigl_tmp.ColumnWidth = repmat({default_col_width},1,sz(2));
uigl_tmp.ColumnWidth{4} = '1x';

day_night_h.time_part_bool_h = uicheckbox(uigl_tmp,'Text','Time-based partitioning','Value',1,'Tooltip','The geographical Time-based partitioning will be appended to the "Type" field of the logbook');
day_night_h.time_part_bool_h.Layout.Column = [1 4];
day_night_h.geo_part_bool_h =  uicheckbox(uigl_tmp,'Text','Geographical partitioning','Value',1,'Tooltip','The geographical stratification will be replacing  the "Stratum" field of the logbook');
day_night_h.geo_part_bool_h.Layout.Column = [1 4];
day_night_h.month_part_bool_h =  uicheckbox(uigl_tmp,'Text','Monthly partitioning','Value',1,'Tooltip','The month will will be appended to the "Stratum" field of the logbook');
day_night_h.month_part_bool_h.Layout.Column = [1 2];
day_night_h.day_part_bool_h =  uicheckbox(uigl_tmp,'Text','Daily partitioning','Value',1,'Tooltip','The day in the the year will be used to populate the "Transect" field of the logbook');
day_night_h.day_part_bool_h.Layout.Column = [3 4];

tmp_h = uilabel(uigl_tmp,'Text','Snapshot(s):','Tooltip','Snapshot(s) to partition:','HorizontalAlignment','right');
tmp_h.Layout.Column = 1;
tmp_h.Layout.Row = 4;
day_night_h.SnapList = uilistbox(uigl_tmp,'Items',{''},'Multiselect','on');
day_night_h.SnapList.Layout.Column = 2;

tmp_h = uilabel(uigl_tmp,'Text','Type(s):','Tooltip','Type(s) to partition:','HorizontalAlignment','right');
tmp_h.Layout.Row = 5;
tmp_h.Layout.Column = 1;
day_night_h.TypeList = uilistbox(uigl_tmp,'Items',{''},'Multiselect','on','Tooltip','Type(s) to partition:');
day_night_h.TypeList.Layout.Column = [2 3];

tmp =  uibutton(uigl_tmp,'Text','Partition logbook(s)','ButtonPushedFcn',@partition_logbooks);
tmp.Layout.Column = [1 4];
tmp.Layout.Row = 6;

%%%%%%%%%%%%%%%%%%%Final/Save/Export panel%%%%%%%%%%%%%%%%%%%%%%%%
sz  = [1 4];
uigl_tmp = uigridlayout(day_night_h.final_panel_h,sz,'Scrollable','on');
uigl_tmp.RowHeight = repmat({default_row_height},1,sz(1));
% uigl_tmp.RowHeight{3} = 2*default_row_height;
% uigl_tmp.RowHeight{4} = 4*default_row_height;
uigl_tmp.ColumnWidth = repmat({default_col_width},1,sz(2));
% uigl_tmp.ColumnWidth{2} = default_col_width/2;
% uigl_tmp.ColumnWidth = repmat({default_col_width},1,sz(2));
% uigl_tmp.ColumnWidth{4} = '1x';

tmp =  uibutton(uigl_tmp,'Text','Save partitioned logbook(s)','ButtonPushedFcn',@save_partition);
tmp.Layout.Column = [1 2];
tmp =  uibutton(uigl_tmp,'Text','Use partitioned logbook(s)','ButtonPushedFcn',@use_partitioned,'Tooltip','Rename the saved logbook appropriately. The previous logbook will be copied with the timestamp of the day in case you want to use it later.');
tmp.Layout.Column = [3 4];

%%%%%%%%%%%%%%%%%%%%%%%%%%% Final steps %%%%%%%%%%%%%%%%%%%%%%%%%%%%
day_night_h.logbook_data = [];
day_night_h.ping_data = [];
day_night_h.logbook_data_partitioned = [];

variable_names_types = [["Shapefile", "string"]; ...
    ["Stratum", "string"]; ...
    ["Latitude_strat", "cell"];...
    ["Longitude_strat", "cell"];...
    ["BoundingBox","cell"];...
    ["Tag_str","cell"]];

day_night_h.strat_data  = table('Size',[0,size(variable_names_types,1)],...
    'VariableNames', variable_names_types(:,1),...
    'VariableTypes', variable_names_types(:,2));
add_logbooks_to_dataset_table(p.Results.logbook_file);

%%%%%%%%%%%%%%%%%%%Nested callbacks and functions, etc...%%%%%%%%%%%%%%%%%%%%%%%%
    function use_partitioned(~,~)
        if isempty(day_night_h.logbook_data_partitioned)
            return;
        end
        day_night_h.ping_data;
        fff = unique(fileparts(day_night_h.logbook_data_partitioned.Logbook));
        logbook_fig = get_esp3_prop('logbook_fig_obj');
        
        for uif = 1:numel(fff)
            db_file_ori = fullfile(fff{uif},'echo_logbook.db');
            db_file_backup = fullfile(fff{uif},sprintf('echo_logbook_%s.db',datestr(now,'yyyymmddHHMM')));
            db_file_new = fullfile(fff{uif},'partitioned_echo_logbook.db');
        
            if ~isempty(logbook_fig)&&isvalid(logbook_fig)
                idx_panel = logbook_fig.find_logbookPanel(db_file_new);
                if ~isempty(idx_panel)
                    delete(logbook_fig.LogBookPanels(idx_panel));
                end
                idx_panel = logbook_fig.find_logbookPanel(db_file_ori);
                if ~isempty(idx_panel)
                    delete(logbook_fig.LogBookPanels(idx_panel));
                end
            end
            
            if ~isfile(db_file_new)
                dlg_perso([],'Could not find partitioned logbook.','Could not find partionned logbook has been copied/renamed in folder %s\nAre you sure you saved it (button on the right of the one you pushed).','Timeout',30,'Type','Information');
                continue;
            end
            
            if isfile(db_file_backup)
                delete(db_file_backup);
            end
            
            if isfile(db_file_ori)
                [status,~] = movefile(db_file_ori,db_file_backup);
            else
                status = true;
            end

            if status
                [status,~] = copyfile(db_file_new,db_file_ori);
                if status
                    dlg_perso([],'partitioned logbook copied/renamed',['Partionned logbook has been copied/renamed in the same folder as the data.'...
                        'It is now ready to be used and abused.'],'Timeout',30,'Type','Information');
                else
                    dlg_perso([],'Could not copy/rename the partitioned logbook',['Logbook (partitioned_echo_logbook.db) could not be copied/renamed.'...
                        'It might still be opened somewhere (as in the logbook window maybe). Please close it and push the button again. We''ll get there.'],'Timeout',30,'Type','Warning');
                end
            else
                dlg_perso([],'Could not rename the logbook',['Logbook (echo_logbook.db) could not be renamed.'...
                    'It might still be opened somewhere (as in the logbook window maybe). Please close it and push the button again. We''ll get there.'],'Timeout',30,'Type','Warning');
            end
        end
        
        layers = get_esp3_prop('layers');
        layers.add_survey_data_db();
        update_tree_layer_tab(main_figure);
        display_survdata_lines(main_figure);
        drawnow;
    end
    function save_partition(~,~)
        if isempty(day_night_h.logbook_data_partitioned)
            return;
        end
        day_night_h.ping_data;
        fff = unique(fileparts(day_night_h.logbook_data_partitioned.Logbook));

        for uif = 1:numel(fff)
            db_file = fullfile(fff{uif},'partitioned_echo_logbook.db');
            if isfile(db_file)
                try
                    delete(db_file);
                catch err
                    dlg_perso([],'Could not initialise the partitioned logbook',['Logbook (partitioned_echo_logbook.db) could not be initialised.'...
                        'It might still be opened somewhere (as in the logbook window maybe). Please close it and push the button again. We''ll get there.'],'Timeout',30,'Type','Warning');
                    print_errors_and_warnings(1,'error',err);
                end
            end
            copyfile(fullfile(fff{uif},'echo_logbook.db'),db_file);

            dbconn=connect_to_db(db_file);
            idx_l = contains(day_night_h.logbook_data_partitioned.Logbook,fff{uif});
            sub_table = day_night_h.logbook_data_partitioned(idx_l,:);
            sub_table =  removevars(sub_table,{'Logbook' 'Logbook_id'});
            id_rem = sub_table.StartTime>sub_table.EndTime;
            sub_table(id_rem,:) = [];
            sub_table.EndTime = cellfun(@(x) datestr(x,'yyyy-mm-dd HH:MM:SS'),num2cell(sub_table.EndTime),'UniformOutput',false);
            sub_table.StartTime = cellfun(@(x) datestr(x,'yyyy-mm-dd HH:MM:SS'),num2cell(sub_table.StartTime),'UniformOutput',false);
            dbconn.exec('DELETE from logbook');
            datainsert_perso(dbconn,'logbook',sub_table);
            dbconn.close;
            load_logbook_fig(get_esp3_prop('main_figure'),false,true,db_file);
            dlg_perso([],'partitioned logbook saved','Partionned logbook has been saved in the same folder as the data under the name "partitioned_echo_logbook.db".','Timeout',30,'Type','Information');


        end

    end

    function toggle_lat_lon_cback(src,~)
        day_night_h.lat_str_h.Enable = src.Value;
        day_night_h.lon_str_h.Enable = src.Value;
    end
    function update_basemap(~,~)
        day_night_h.map_ax.Basemap = day_night_h.basemap_dd_h.Value;
    end

    function strat_cell_edit_cback(src,evt)

        day_night_h.strat_data.Stratum(evt.Indices(1)) = evt.NewData;

        idx = arrayfun(@(x) strcmpi(x.Tag,day_night_h.strat_data.Tag_str(evt.Indices(1))),day_night_h.strata_plots_h);
        delete(day_night_h.strata_plots_h(idx));

        day_night_h.strata_plots_h(idx) = [];
        plot_strat(src,evt);
    end

    function add_strat_cback(~,~,id)
        if id==0
            if ~isempty(day_night_h.strat_table.UserData.select)
                idx = arrayfun(@(x) ismember(x.Tag,day_night_h.strat_data.Tag_str(day_night_h.strat_table.UserData.select(:,1))),day_night_h.strata_plots_h);
                delete(day_night_h.strata_plots_h(idx));
                day_night_h.strata_plots_h(idx) = [];
                day_night_h.strat_data(day_night_h.strat_table.UserData.select(:,1),:) = [];
                day_night_h.strat_table.Data(day_night_h.strat_table.UserData.select(:,1),:) = [];
                day_night_h.strat_table.UserData.select = [];
            end
        elseif id == -1
            delete(day_night_h.strata_plots_h);
            day_night_h.strata_plots_h = [];
            day_night_h.strat_table.Data(:,:) = [];
            day_night_h.strat_data  = [];
            return;
        else
            path_init = [];
            if ~isempty(day_night_h.strat_table.Data.("Shapefile"))&& ~isempty(day_night_h.strat_table.UserData.select)
                path_init= fileparts(day_night_h.strat_table.Data.("Shapefile")(day_night_h.strat_table.UserData.select(:,1)));
            end

            if isempty(path_init)&&~isempty(day_night_h.logbook_table.Data.("Logbook File"))&& ~isempty(day_night_h.logbook_table.UserData.select)
                path_init= fileparts(day_night_h.logbook_table.Data.("Logbook File")(day_night_h.logbook_table.UserData.select(:,1)));
            end

            if isempty(path_init)
                path_init = string(pwd);
            end

            path_init=char(path_init(1));
            [file_select,path_f]= uigetfile({fullfile(path_init,'*.shp')}, 'Pick one/many shapefile(s)','MultiSelect','on');

            if path_f==0
                return;
            end

            add_files_to_strat_table(fullfile(path_f,file_select));

        end

    end

    function fmt_lat_long_cback(src,evt)
        coord_str=src.Value;
        [coord_str,coord_val_dec_deg] = fmt_coord(coord_str,src.Tag);
        if isempty(coord_val_dec_deg)||isnan(coord_val_dec_deg)
            src.Value = evt.PreviousValue;
            return;
        end
        src.Value = coord_str;
        src.UserData = coord_val_dec_deg;
    end

    function [coord_str,coord_val_dec_deg] = fmt_coord(coord_str,tag)
        fmt={'%d %d %d %c', '%d %f %c', '%f %c','%d%c %f%c %c','%f'};
        coord_val_dec_deg = [];
        for ifmt=1:length(fmt)
            tmp=textscan(coord_str,fmt{ifmt});
            if(all(~cellfun(@isempty,tmp)))
                switch fmt{ifmt}
                    case '%d %d %d %c'
                        coord_val_dec_deg=double(tmp{1})+double(tmp{2})/60+double(tmp{3})/60/60;
                        coord_val_dec_deg=check_ewns(coord_val_dec_deg,tmp{4});

                    case '%d %f %c'
                        coord_val_dec_deg=double(tmp{1})+tmp{2}/60;
                        coord_val_dec_deg=check_ewns(coord_val_dec_deg,tmp{3});
                    case '%f %c'
                        coord_val_dec_deg=tmp{1};
                        coord_val_dec_deg=check_ewns(coord_val_dec_deg,tmp{2});
                    case '%d%c %f%c %c'
                        coord_val_dec_deg=double(tmp{1})+tmp{3}/60;
                        coord_val_dec_deg=check_ewns(coord_val_dec_deg,tmp{5});
                    case '%f'
                        coord_val_dec_deg=tmp{1};
                end
                if ~isempty(coord_val_dec_deg)
                    break;
                end
            end

        end
        if isnan(coord_val_dec_deg)||isempty(coord_val_dec_deg)
            return;
        end

        switch tag
            case 'lat'
                if coord_val_dec_deg>90||coord_val_dec_deg<-90
                    coord_val_dec_deg = [];
                end
                [coord_str,~]=print_pos_str(coord_val_dec_deg,0);
            case 'lon'
                if coord_val_dec_deg>180
                    coord_val_dec_deg = coord_val_dec_deg-180;
                end
                if coord_val_dec_deg>180||coord_val_dec_deg<-180
                    coord_val_dec_deg = [];
                end
                [~,coord_str]=print_pos_str(0,coord_val_dec_deg);
        end

    end


    function add_files_to_strat_table(strat_files)
        if ~iscell(strat_files)
            strat_files = {strat_files};
        end

        geo_data_shp=cellfun(@(x) shaperead(x),strat_files,'un',0);
        info_data_shp=cellfun(@(x) shapeinfo(x),strat_files,'un',0);

        for uishp=1:numel(geo_data_shp)

            for i_feat=1:numel(geo_data_shp{uishp})
                try
                    ff = fieldnames(geo_data_shp{uishp}(i_feat));
                    id_strat = contains(ff,'strat','IgnoreCase',true);

                    id = find(id_strat);
                    
                    if isempty(id)
                        str = num2str(i_feat);
                    else
                        if isnumeric(geo_data_shp{uishp}(i_feat).(ff{id}))
                            str=num2str(geo_data_shp{uishp}(i_feat).(ff{id}));
                        else
                            str=geo_data_shp{uishp}(i_feat).(ff{id});
                        end
                    end

                    %str_tag = generate_Unique_ID(1);
                    str_tag = {sprintf('%s_%s',strat_files{uishp},str)};

                    if ~isempty(day_night_h.strat_data) && any(strcmpi(day_night_h.strat_data.Tag_str,str_tag{1}))
                        continue;
                    end

                   

                    x=geo_data_shp{uishp}(i_feat).X;
                    y=geo_data_shp{uishp}(i_feat).Y;
                    try
                        [lat_disp,lon_disp] = projinv(info_data_shp{uishp}.CoordinateReferenceSystem,x,y);
                         [bbox_lat,bbox_lon]=projinv(info_data_shp{uishp}.CoordinateReferenceSystem,...
                             geo_data_shp{uishp}(i_feat).BoundingBox(:,1),geo_data_shp{uishp}(i_feat).BoundingBox(:,2));
                         bbox = [bbox_lon bbox_lat];
                    catch
                        lat_disp = y;
                        lon_disp = x;
                        bbox=geo_data_shp{uishp}(i_feat).BoundingBox;
                    end

                    lon_disp(lon_disp<0)=lon_disp(lon_disp<0)+360;

                    nb_x = numel(lat_disp)-1;
                    dx = 10;
                    lat_disp = interp1(1:dx:dx*nb_x,lat_disp(1:end-1),1:nb_x*dx,'linear');
                    lon_disp = interp1(1:dx:dx*nb_x,lon_disp(1:end-1),1:nb_x*dx,'linear');

                    day_night_h.strat_data = [day_night_h.strat_data;...
                        table(string(strat_files{uishp}),string(str),{lat_disp},{lon_disp},{bbox},str_tag,'VariableNames',["Shapefile" "Stratum" "Latitude_strat" "Longitude_strat" "BoundingBox" "Tag_str"])];

                catch err
                    fprintf('Error displaying shapefile %s \n',strat_files{uishp});
                    print_errors_and_warnings(1,'error',err);
                end

            end

        end
        plot_strat([],[]);

    end

    function plot_strat(~,~)

        h_in = [];
        color = [0.6 0 0];
        sty='-';
        mark='none';

        if isempty(day_night_h.strat_data)
            return;
        end

        for uis = 1:numel(day_night_h.strat_data.Tag_str)
            str = day_night_h.strat_data.Stratum{uis};
            bbox = day_night_h.strat_data.BoundingBox{uis};
            lat_disp = day_night_h.strat_data.Latitude_strat{uis};
            lon_disp = day_night_h.strat_data.Longitude_strat{uis};
            str_tag = day_night_h.strat_data.Tag_str{uis};

            if any(arrayfun(@(x) strcmpi(x.Tag,str_tag),day_night_h.strata_plots_h))
                continue;
            end

            if numel(lat_disp)>1000
                [lat_disp,lon_disp] = reducem(lat_disp',lon_disp');
            end
            temp_txt=text(day_night_h.map_ax,mean(bbox(:,2)),mean(bbox(:,1)),str,...
                'Fontsize',8,'Fontweight','bold','Interpreter','None','VerticalAlignment','bottom','Clipping','on','Color',color,'tag',str_tag);

            tmp_plot=geoplot(day_night_h.map_ax,lat_disp,lon_disp,...
                'color',color,...
                'linestyle',sty,...
                'marker',mark,...
                'tag',str_tag);

            tmp_plot.LatitudeDataMode='manual';
            h_in=[h_in tmp_plot];
            h_in=[h_in temp_txt];
        end

        day_night_h.strata_plots_h = [day_night_h.strata_plots_h h_in];
        day_night_h.strat_table.Data = day_night_h.strat_data(:,{'Shapefile' 'Stratum'});
    end

    function update_time_partition(src,evt)
        switch src.Type
            case 'uicheckbox'
                day_night_h.(sprintf('From_%s',src.Tag)).Enable = src.Value ==1;
                day_night_h.(sprintf('To_%s',src.Tag)).Enable = src.Value == 1;
            case 'uinumericeditfield'
                idx = find(cellfun(@(x) contains(src.Tag,x),time_partition_table.Type));
                time_partition_struct_tmp = time_partition_struct;
                if contains(src.Tag,'From')
                    time_partition_struct_tmp.From(idx) = src.Value;
                    time_partition_struct_tmp.To = circshift(time_partition_struct_tmp.From,-1);
                else
                    time_partition_struct_tmp.To(idx) = src.Value;
                    time_partition_struct_tmp.From = circshift(time_partition_struct_tmp.To,1);
                end
                idx_same_ref = strcmpi(time_partition_struct.FromRef,time_partition_struct.ToRef);
                if any(time_partition_struct_tmp.From(idx_same_ref)>time_partition_struct_tmp.To(idx_same_ref))
                    src.Value = evt.PreviousValue;
                else
                    time_partition_struct = time_partition_struct_tmp;
                end
                for uit = 1:numel(time_partition_table.Type)
                    day_night_h.(sprintf('From_%s',time_partition_table.Type{uit})).Value = time_partition_struct.From(uit);
                    day_night_h.(sprintf('To_%s',time_partition_table.Type{uit})).Value = time_partition_struct.To(uit);
                end
        end
    end

    function partition_logbooks(src,evt)

        if ~istable(day_night_h.ping_data)
            return;
        end

        if day_night_h.time_part_bool_h.Value
            dt = day_night_h.timezone_h.UserData.UTCOffset(day_night_h.timezone_h.Value)+day_night_h.timezone_h.UserData.DSTOffset(day_night_h.timezone_h.Value)+day_night_h.FileOffset.Value/60;
            days_p = floor(day_night_h.ping_data.Time);
            [days_puu,~,id_days] = unique(days_p);


            days_l_s = floor(day_night_h.logbook_data.StartTime);
            days_l_e = floor(day_night_h.logbook_data.EndTime);
            days_l = [];
            for uitt= 1:numel(days_l_s)% a loop on the off chance that a file covers more than one day....
                days_l = union(days_l,days_l_s(uitt):days_l_e(uitt));
            end

            days_l = unique(days_l');

            days_not_in_ping_data = setdiff(days_l,days_puu);

            if ~isempty(day_night_h.ping_data.Lat)
                lat_days = splitapply(@mean,day_night_h.ping_data.Lat,id_days);
                lon_days = splitapply(@mean,day_night_h.ping_data.Long,id_days);
            else
                lat_days = [];
                lon_days = [];
            end

            if day_night_h.mooring_bool_h.Value
                lat_days_m = day_night_h.lat_str_h.UserData;
                lon_days_m = day_night_h.lon_str_h.UserData;
            else
                lat_days_m = mean(lat_days);
                lon_days_m = mean(lon_days);
            end

            if ~isempty(days_not_in_ping_data)
                lat_days_not_in_ping_data = ones(numel(days_not_in_ping_data),1)*lat_days_m;
                lat_days = [lat_days_not_in_ping_data;lat_days];
                lon_days_not_in_ping_data = ones(numel(days_not_in_ping_data),1)*lon_days_m;
                lon_days = [lon_days_not_in_ping_data;lon_days];
                days_puu = [days_not_in_ping_data;days_puu];
            end

            for tti = 1:2
                [days_pu,ia,ib] = union(days_puu,days_puu+1,'stable');
                lon_days = [lon_days(ia); lon_days(ib)];
                lat_days = [lat_days(ia); lat_days(ib)];
            end

            [days_pu,idxs] = sort(days_pu);

            lon_days = lon_days(idxs);
            lat_days = lat_days(idxs);

            if day_night_h.mooring_bool_h.Value
                lon_days  = day_night_h.lon_str_h.UserData*ones(size(lon_days));
                lat_days  = day_night_h.lat_str_h.UserData*ones(size(lon_days));
            end

            % N = 2880;
            %[SunRiseSet,Day,Dec,Alt,Azm,Rad] = suncycle( lat_days , lon_days , days_pu , N );

            [days_part_struct.Sunrise,days_part_struct.Sunset,~] = sunrise(lat_days,lon_days,0,dt,days_pu);
            day_night_h.logbook_data_partitioned = day_night_h.logbook_data;
            day_night_h.ping_data.Time_partition(:)  = {''};
            log_data_to_add = [];

            id_trans = ones(1,numel(time_partition_struct.Type));

            for uit = 1:numel(time_partition_struct.Type)

                if ~day_night_h.(time_partition_table.Type{uit}).Value
                    continue;
                end

                idds = 1:numel(days_pu)-1;
                idde = 1:numel(days_pu)-1;

                timeSpan = [days_part_struct.(time_partition_struct.FromRef{uit})(idds)+time_partition_struct.From(uit)/24 ...
                    days_part_struct.(time_partition_struct.ToRef{uit})(idde)+time_partition_struct.To(uit)/24];

                %Deal with the case where the type in the specified
                %timezone (corresponding to the timezone used for
                %timestamping files) overlaps a change of dates. I think
                %it's right.
                if any(diff(timeSpan')<0)
                    [idds,idde] = find(days_pu+1 == days_pu');
                    timeSpan = [days_part_struct.(time_partition_struct.FromRef{uit})(idds)+time_partition_struct.From(uit)/24 ...
                        days_part_struct.(time_partition_struct.ToRef{uit})(idde)+time_partition_struct.To(uit)/24];
                end

                sub_idx = (isempty(strtrim(day_night_h.logbook_data_partitioned.Type))|ismember(strtrim(day_night_h.logbook_data_partitioned.Type),day_night_h.TypeList.Value))&...
                    ismember(day_night_h.logbook_data_partitioned.Snapshot,day_night_h.SnapList.Value);
                sub_files = unique(day_night_h.logbook_data_partitioned.Filename(sub_idx));

                if ~isempty(day_night_h.ping_data)
                    for uis = 1:size(timeSpan,1)
                        idd_type = day_night_h.ping_data.Time>=timeSpan(uis,1) & day_night_h.ping_data.Time<timeSpan(uis,2)&ismember(day_night_h.ping_data.Filename,sub_files);
                        day_night_h.ping_data.Time_partition(idd_type) = time_partition_struct.Type(uit);
                    end
                end
                [day_night_h.logbook_data_partitioned,id_trans(uit)] = part_logbook_on_timespan(day_night_h.logbook_data_partitioned,timeSpan,sub_idx,id_trans(uit),'Type',time_partition_struct.Type{uit},true);

            end
        else
            day_night_h.logbook_data_partitioned = day_night_h.logbook_data;
        end

        day_night_h.logbook_data_partitioned(day_night_h.logbook_data_partitioned.StartTime == day_night_h.logbook_data_partitioned.EndTime,:) = [];

        if day_night_h.geo_part_bool_h.Value
            if ~isempty(day_night_h.strat_data) && ~isempty(day_night_h.ping_data) && numel(day_night_h.strat_data.Stratum)>0
                id_in_strat = cellfun(@(x,y) (inpolygon(day_night_h.ping_data.Lat,day_night_h.ping_data.Long,x,y)),...
                    day_night_h.strat_data.Latitude_strat,day_night_h.strat_data.Longitude_strat,'UniformOutput',false);

                nb_strat = numel(id_in_strat);
                id_trans = nan(1,nb_strat);

                for uist = 1:nb_strat
                    ffs = day_night_h.ping_data.Filename(id_in_strat{uist});
                    id_tmp = id_in_strat{uist};

                    %                     id_tmp  = ceil(filter2_perso(ones(20,1),id_tmp));
                    %                     id_tmp  = floor(filter2_perso(ones(20,1),id_tmp));
                    %

                    ts = day_night_h.ping_data.Time(diff(id_tmp)>0);

                    if id_tmp(1)
                        ts = [day_night_h.ping_data.Time(1); ts];
                    end

                    te = day_night_h.ping_data.Time(diff(id_tmp)<0);

                    if id_tmp(end)
                        te = [te;day_night_h.ping_data.Time(end)];
                    end

                    timeSpan = [ts te];

                    sub_idx = (isempty(strtrim(day_night_h.logbook_data_partitioned.Type))|ismember(strtrim(day_night_h.logbook_data_partitioned.Type),day_night_h.TypeList.Value))&...
                        ismember(day_night_h.logbook_data_partitioned.Snapshot,day_night_h.SnapList.Value);

                    [day_night_h.logbook_data_partitioned,id_trans(uist)] = part_logbook_on_timespan(day_night_h.logbook_data_partitioned,timeSpan,sub_idx,id_trans(uist),'Stratum',char(day_night_h.strat_data.Stratum(uist)),false);


                end
            end

        end

        if day_night_h.month_part_bool_h.Value
            mm = month(datetime(day_night_h.logbook_data_partitioned.StartTime,'ConvertFrom','datenum'),'Name');
            idx_strat_empty = cellfun(@isempty,day_night_h.logbook_data_partitioned.Stratum);
            day_night_h.logbook_data_partitioned.Stratum(idx_strat_empty) = mm(idx_strat_empty);
            day_night_h.logbook_data_partitioned.Stratum(~idx_strat_empty) = cellfun(@(x,y) sprintf('%s_%s',x,y),...
            day_night_h.logbook_data_partitioned.Stratum(~idx_strat_empty),mm(~idx_strat_empty),'UniformOutput',false);
            day_night_h.logbook_data_partitioned.Transect = day(datetime(day_night_h.logbook_data_partitioned.StartTime,'ConvertFrom','datenum'),"dayofyear");
        end


        if day_night_h.day_part_bool_h.Value
            day_night_h.logbook_data_partitioned.Transect = day(datetime(day_night_h.logbook_data_partitioned.StartTime,'ConvertFrom','datenum'),"dayofyear");
        end

        day_night_h.logbook_data_partitioned(day_night_h.logbook_data_partitioned.StartTime == day_night_h.logbook_data_partitioned.EndTime,:) = [];
        [~,idx_sort] = sort(day_night_h.logbook_data_partitioned.StartTime);
        day_night_h.logbook_data_partitioned = day_night_h.logbook_data_partitioned(idx_sort,:);
        plot_datasets(src,evt);
                    dlg_perso([],'Logbook partitioned','The logbook has been partitioned as you required (most likely). You can viualise some of this on the map, but you will need to move to the next step (saving) to have a proper look at it... ','Timeout',30,'Type','Information');
    end

    function load_datasets_cback(src,evt)
        logbook_files = day_night_h.logbook_table.Data.("Logbook File");
        if ~isempty(day_night_h.logbook_table.UserData.select)
            logbook_files = logbook_files(day_night_h.logbook_table.UserData.select(:,1));
        else
            logbook_files = {};
        end
        day_night_h.logbook_data = [];
        day_night_h.logbook_data_partitioned = [];
        day_night_h.ping_data = [];

        if numel(logbook_files)==0
            return;
        end

        for uill = 1:numel(logbook_files)
            dbconn = connect_to_db(logbook_files{uill});
            if isempty(dbconn)
                continue;
            end
            files_from_logbook = dbconn.fetch('SELECT * FROM logbook');
            files_from_ping_data = dbconn.fetch('SELECT * FROM ping_data');
            dbconn.close();

            files_from_logbook.Logbook = repmat(logbook_files(uill),numel(files_from_logbook.Filename),1);
            files_from_logbook.Logbook_id = repmat(uill,numel(files_from_logbook.Filename),1);
            files_from_logbook.StartTime = datenum(files_from_logbook.StartTime,'yyyy-mm-dd HH:MM:SS');
            files_from_logbook.EndTime = datenum(files_from_logbook.EndTime,'yyyy-mm-dd HH:MM:SS');

            files_from_ping_data.Logbook  = repmat(logbook_files(uill),numel(files_from_ping_data.Filename),1);
            files_from_ping_data.Logbook_id = repmat(uill,numel(files_from_ping_data.Lat),1);
            files_from_ping_data.Time_partition = cell(numel(files_from_ping_data.Time),1);
            files_from_ping_data.Time_partition(:) = {''};
            files_from_ping_data.Geo_partition = cell(numel(files_from_ping_data.Time),1);
            files_from_ping_data.Geo_partition(:) = {''};
            if ~isempty(files_from_ping_data.Time)
                files_from_ping_data.Time = datenum(files_from_ping_data.Time,'yyyy-mm-dd HH:MM:SS');
            end

            day_night_h.logbook_data = [day_night_h.logbook_data;files_from_logbook];
            day_night_h.ping_data = [day_night_h.ping_data;files_from_ping_data];
        end

        [~,idx_sortl] = sort(day_night_h.logbook_data.StartTime);
        day_night_h.logbook_data = day_night_h.logbook_data(idx_sortl,:);
        [~,idx_sortp] = sort(day_night_h.ping_data.Time);
        day_night_h.ping_data = day_night_h.ping_data(idx_sortp,:);
        day_night_h.SnapList.Items = string(unique(day_night_h.logbook_data.Snapshot))';
        day_night_h.SnapList.ItemsData = unique(day_night_h.logbook_data.Snapshot)';
        day_night_h.SnapList.Value = day_night_h.SnapList.ItemsData;
        day_night_h.TypeList.Items = unique(strtrim(day_night_h.logbook_data.Type));
        day_night_h.TypeList.Value = day_night_h.TypeList.Items;
        plot_datasets(src,evt);
        dlg_perso([],'Data loaded','Logbook data has been loaded and is ready to be partitioned.','Timeout',30,'Type','Information');
    end

    function update_vis_plots_cback(~,~,types)
        for uitt = 1:numel(types)
            gobj = findobj(day_night_h.map_ax,'Tag',types{uitt},'Type','Line');
            switch types{uitt}
                case ''
                    vis = day_night_h.disp_unpart_h.Value;
                otherwise
                    vis = day_night_h.disp_part_h.Value;
            end
            arrayfun(@(x) set(x,'Visible',vis),gobj);
            %set(gobj,'Visible',vis)
        end
    end


    function plot_datasets(~,~)
        if isempty(day_night_h.logbook_data)
            return;
        end
        logbook_files = unique(day_night_h.logbook_data.Logbook);

        if numel(logbook_files)==0
            return;
        end

        delete(day_night_h.transect_plots_h);
        day_night_h.transect_plots_h = [];
        delete(day_night_h.boundaries_h);
        day_night_h.boundaries_h = [];
        legend_str = {};
        nb_pt = 100;

        tty = [time_partition_struct.Type;{''}];
        if day_night_h.mooring_bool_h.Value
            tmp_h = geoplot(day_night_h.map_ax,day_night_h.lat_str_h.UserData,day_night_h.lon_str_h.UserData,'o','Color','r','MarkerFaceColor','k','markersize',6,'Tag','mooring');
            day_night_h.transect_plots_h = [day_night_h.transect_plots_h tmp_h];
            geolimits(day_night_h.map_ax,day_night_h.lat_str_h.UserData+[-1 1],day_night_h.lon_str_h.UserData+[-1 1]);
        elseif ~isempty(day_night_h.ping_data)
            for uill = 1:numel(logbook_files)
                for uit = 1:numel(tty)
                    idx_t = strcmpi(tty{uit},day_night_h.ping_data.Time_partition) & day_night_h.ping_data.Logbook_id == uill;
                    switch tty{uit}
                        case ''
                            vis = day_night_h.disp_unpart_h.Value;
                        otherwise
                            vis = day_night_h.disp_part_h.Value;
                    end

                    col = get_col_by_type(tty{uit});
                    if any(idx_t)
                        tmp_h = geoplot(day_night_h.map_ax,day_night_h.ping_data.Lat(idx_t),day_night_h.ping_data.Long(idx_t),'.','Color',col,'markersize',3,'Tag',tty{uit});
                        day_night_h.transect_plots_h = [day_night_h.transect_plots_h tmp_h];
                    end
                end
                str_lgd = sprintf('%s_%s',day_night_h.logbook_table.Data.Voyage{uill},day_night_h.logbook_table.Data.Survey{uill});
                LatLim = [min(day_night_h.ping_data.Lat(day_night_h.ping_data.Logbook_id == uill),[],"all","omitnan") max(day_night_h.ping_data.Lat(day_night_h.ping_data.Logbook_id == uill),[],"all","omitnan")];
                LonLim = [min(day_night_h.ping_data.Long(day_night_h.ping_data.Logbook_id == uill),[],"all","omitnan") max(day_night_h.ping_data.Long(day_night_h.ping_data.Logbook_id == uill),[],"all","omitnan")];

                [LatLim,LonLim] = ext_lat_lon_lim_v2(LatLim,LonLim,0.1);

                lat_poly = [linspace(LatLim(1),LatLim(2),nb_pt),repmat(LatLim(2),1,nb_pt),linspace(LatLim(2),LatLim(1),nb_pt),repmat(LatLim(1),1,nb_pt)];
                lon_poly = [repmat(LonLim(1),1,nb_pt),linspace(LonLim(1),LonLim(2),nb_pt),repmat(LonLim(2),1,nb_pt),linspace(LonLim(1),LonLim(2),nb_pt)];
                tmp_h = geoplot(day_night_h.map_ax,lat_poly,lon_poly,'-','Color',col,'Linewidth',1.5,'Tag',sprintf('Boundaries_%s',str_lgd),'Visible',vis);
                day_night_h.boundaries_h = [day_night_h.boundaries_h tmp_h];
                legend_str = [legend_str {str_lgd}];
            end

            LatLim = [min(day_night_h.ping_data.Lat,[],"all","omitnan") max(day_night_h.ping_data.Lat,[],"all","omitnan")];
            LonLim = [min(day_night_h.ping_data.Long,[],"all","omitnan") max(day_night_h.ping_data.Long,[],"all","omitnan")];
            lat_poly = [linspace(LatLim(1),LatLim(2),nb_pt),repmat(LatLim(2),1,nb_pt),linspace(LatLim(2),LatLim(1),nb_pt),repmat(LatLim(1),1,nb_pt)];
            lon_poly = [repmat(LonLim(1),1,nb_pt),linspace(LonLim(1),LonLim(2),nb_pt),repmat(LonLim(2),1,nb_pt),linspace(LonLim(1),LonLim(2),nb_pt)];

            [LatLim,LonLim] = ext_lat_lon_lim_v2(LatLim,LonLim,0.2);

            geolimits(day_night_h.map_ax,LatLim,LonLim);
            if numel(legend_str)>=1
                legend(day_night_h.boundaries_h,legend_str,'Interpreter','none','AutoUpdate','off');
            end
        end
    end


    function update_tz_dropdown(src,~)
        tz = timezones(src.Value);
        [G,ID] = findgroups(tz(:,{'UTCOffset' 'DSTOffset'}));

        ids = unique(G);
        zones = cell(numel(ids),1);
        for uid = 1:numel(zones)
            zones{uid} = strjoin(tz.Name(ids(uid) == G),';');
        end
        day_night_h.timezone_h.ItemsData = 1:numel(zones);
        day_night_h.timezone_h.Items = zones;
        day_night_h.timezone_h.Value = 1;
        day_night_h.timezone_h.UserData = ID;
    end

    function update_UTC_DST(~,~)
        day_night_h.UTCOffset_h.Text = sprintf('UTC%+g',day_night_h.timezone_h.UserData.UTCOffset(day_night_h.timezone_h.Value));
        switch day_night_h.timezone_h.UserData.DSTOffset(day_night_h.timezone_h.Value)
            case 0
                day_night_h.DSTOffset_h.Enable = false;
                day_night_h.DSTOffset_h.Value = false;
                day_night_h.DSTOffset_h.Visible = 'off';
            case 1
                day_night_h.DSTOffset_h.Enable = true;
                day_night_h.DSTOffset_h.Visible = 'on';
                day_night_h.DSTOffset_h.Text = sprintf('DST%+g',day_night_h.timezone_h.UserData.DSTOffset(day_night_h.timezone_h.Value));
        end
    end

    function add_logbook_cback(src,evt,id)

        if id<0
            if ~isempty(day_night_h.logbook_table.UserData.select)
                idl = day_night_h.logbook_table.UserData.select(:,1);
                day_night_h.logbook_table.Data(idl,:)=[];

                if ~isempty(day_night_h.logbook_data)
                    day_night_h.logbook_data(ismember(day_night_h.logbook_data.Logbook_id,idl),:) = [];
                end
                if ~isempty(day_night_h.ping_data)
                    day_night_h.ping_data(ismember(day_night_h.ping_data.Logbook_id,idl),:) = [];
                end
                if ~isempty(day_night_h.logbook_data_partitioned)
                    day_night_h.logbook_data_partitioned(ismember(day_night_h.logbook_data_partitioned.Logbook_id,idl),:) = [];
                end
                day_night_h.logbook_table.UserData.select = [1 1];
                plot_datasets(src,evt);
            end
        else
            path_init = string(pwd);
            if ~isempty(day_night_h.logbook_table.Data.("Logbook File")) && ~isempty(day_night_h.logbook_table.UserData.select)
                path_init= fileparts(day_night_h.logbook_table.Data.("Logbook File")(day_night_h.logbook_table.UserData.select));
            end

            path_init=path_init(1);
            [ff,path_f]= uigetfile({char(fullfile(path_init,'echo_logbook.db'))}, 'Pick a logbook file','MultiSelect','off');
            if path_f==0
                return;
            end

            if ~isfolder(path_f)||~isfile(fullfile(path_f,ff))
                return;
            end

            add_logbooks_to_dataset_table(fullfile(path_f,ff));
        end
    end

    function add_logbooks_to_dataset_table(logbook_file)

        if ~iscell(logbook_file)
            logbook_file = {logbook_file};
        end
        for uil = 1:numel(logbook_file)
            if isfolder(logbook_file{uil})
                logbook_file{uil} = fullfile(logbook_file{uil},'echo_logbook.db');
            end

            dbconn = connect_to_db(logbook_file{uil});
            if isempty(dbconn)
                return;
            end
            sql_cmd = 'SELECT * FROM survey';
            tt = dbconn.fetch(sql_cmd);
            dbconn.close();

            if isempty(tt)
                continue;
            end

            table_temp = table(logbook_file(uil),tt.Voyage(1),tt.SurveyName(1),'VariableNames',{'Logbook File','Voyage', 'Survey'});
            day_night_h.logbook_table.Data = [day_night_h.logbook_table.Data; table_temp];

        end
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% External Callbacks and functions %%%%%%%%%%%%%%%%%%%%
function col = get_col_by_type(tty)
switch lower(tty)
    case 'dawn'
        col = [1 0.5 0];
    case 'day'
        col = [1 1 0.5];
    case 'dusk'
        col = [0 0 0.8];
    case 'night'
        col = [0.1 0.1 0.1];
    otherwise
        cols = lines(256);
        col = cols(randi(256),:);
end
end

function cell_select_cback(src,evt)
src.UserData.select=evt.Indices;
end

function coord=check_ewns(coord,d)

switch lower(d)
    case {'e', 'n'}

    case {'s', 'w'}
        coord=-coord;
    otherwise
        coord=[];
end

end

function  [logbook_data_partitioned,id_trans] = part_logbook_on_timespan(logbook_data_partitioned,timeSpan,sub_idx,id_trans,field,field_t,append)
log_data_to_add = [];
idx_in = logbook_data_partitioned.StartTime<timeSpan(:,1)'& logbook_data_partitioned.EndTime>timeSpan(:,2)' & sub_idx;
idx_out = logbook_data_partitioned.StartTime>=timeSpan(:,1)'& logbook_data_partitioned.EndTime<=timeSpan(:,2)' & sub_idx;
idx_start_in = logbook_data_partitioned.StartTime>=timeSpan(:,1)' & logbook_data_partitioned.EndTime>timeSpan(:,2)' & logbook_data_partitioned.StartTime<=timeSpan(:,2)' & sub_idx;
idx_end_in = logbook_data_partitioned.StartTime<timeSpan(:,1)'& logbook_data_partitioned.EndTime<=timeSpan(:,2)'& logbook_data_partitioned.EndTime>=timeSpan(:,1)' & sub_idx;
[idx_in_f,idx_in_d] = find(idx_in);%Timespan entirely in 1 file (more likely for long files)
[idx_out_f,idx_out_d] = find(idx_out); %Timespan encompassing files (more likely for short files)
[idx_start_in_f,idx_start_in_d] = find(idx_start_in); %Timespan overlapping with the start of files
[idx_end_in_f,idx_end_in_d] = find(idx_end_in); %Timespan overlapping with the end of files

for ui_in = 1:numel(idx_in_d)
    tmp_data = logbook_data_partitioned(idx_in_f(ui_in),:);
    tmp_data_bis = logbook_data_partitioned(idx_in_f(ui_in),:);
    tmp_data.StartTime = timeSpan(idx_in_d(ui_in),1);
    tmp_data.EndTime = timeSpan(idx_in_d(ui_in),2);

    if (~isempty(deblank(tmp_data.(field){1})) && ~contains(tmp_data.(field){1},field_t)) && append
        tmp_data.(field) = {sprintf('%s_%s',tmp_data.(field){1},field_t)};
    else
        tmp_data.(field) = {field_t};
        if ~isnan(id_trans)
            tmp_data.Transect = id_trans;
            id_trans = id_trans + 1;
        end
    end
    logbook_data_partitioned.EndTime(idx_in_f(ui_in))  = timeSpan(idx_in_d(ui_in),1);
    tmp_data_bis.StartTime = timeSpan(idx_in_d(ui_in),2);
    log_data_to_add = [log_data_to_add;tmp_data;tmp_data_bis];
end


for ui_out = 1:numel(idx_out_d)
    if (~isempty(deblank(logbook_data_partitioned(idx_out_f(ui_out),:).(field){1})) && ~contains(logbook_data_partitioned(idx_out_f(ui_out),:).(field){1},field_t)) && append
        logbook_data_partitioned(idx_out_f(ui_out),:).(field) = {sprintf('%s_%s',logbook_data_partitioned(idx_out_f(ui_out),:).(field){1},field_t)};
    else
        logbook_data_partitioned(idx_out_f(ui_out),:).(field) = {field_t};
        if ~isnan(id_trans)
            logbook_data_partitioned(idx_out_f(ui_out),:).Transect = id_trans;
            id_trans = id_trans+ 1;
        end
    end
end


for ui_start_in = 1:numel(idx_start_in_f)
    tmp_data = logbook_data_partitioned(idx_start_in_f(ui_start_in),:);
    tmp_data.EndTime = timeSpan(idx_start_in_d(ui_start_in),2);
    if(~isempty(deblank(tmp_data.(field){1})) && ~contains(tmp_data.(field){1},field_t)) && append
        tmp_data.(field) = {sprintf('%s_%s',tmp_data.(field){1},field_t)};
    else
        tmp_data.(field) = {field_t};
        if ~isnan(id_trans)
            tmp_data.Transect = id_trans;
            id_trans = id_trans + 1;
        end
    end
    logbook_data_partitioned.StartTime(idx_start_in_f(ui_start_in))  = timeSpan(idx_start_in_d(ui_start_in),2);
    log_data_to_add = [log_data_to_add;tmp_data];
end

for ui_end_in = 1:numel(idx_end_in_f)
    tmp_data = logbook_data_partitioned(idx_end_in_f(ui_end_in),:);
    tmp_data.StartTime = timeSpan(idx_end_in_d(ui_end_in),1);
    if (~isempty(deblank(tmp_data.(field){1})) && ~contains(tmp_data.(field){1},field_t)) && append
        tmp_data.(field) = {sprintf('%s_%s',tmp_data.(field){1},field_t)};
    else
        tmp_data.(field) = {field_t};
        if ~isnan(id_trans)
            tmp_data.Transect = id_trans;
            id_trans = id_trans + 1;
        end
    end
    logbook_data_partitioned.EndTime(idx_end_in_f(ui_end_in))  = timeSpan(idx_end_in_d(ui_end_in),1);
    log_data_to_add = [log_data_to_add;tmp_data];
end

logbook_data_partitioned = [logbook_data_partitioned;log_data_to_add];

end


