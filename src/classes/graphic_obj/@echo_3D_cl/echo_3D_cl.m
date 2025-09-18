classdef echo_3D_cl < handle

    properties
        echo_fig matlab.ui.Figure
        ax_3D matlab.ui.control.UIAxes
        lgt_3D matlab.graphics.primitive.Light
        ax_tab_group matlab.ui.container.TabGroup
        ax_tab matlab.ui.container.Tab
        curtain_surf_h matlab.graphics.chart.primitive.Surface
        WC_fan_h matlab.graphics.chart.primitive.Surface
        cone_h matlab.graphics.primitive.Patch
        scatter_feature_h matlab.graphics.chart.primitive.Scatter
        trisurf_feature_h matlab.graphics.primitive.Patch
        bathy_surf_h matlab.graphics.chart.primitive.Surface
        echoint_3D_horz_surf_h matlab.graphics.chart.primitive.Surface
        echoint_3D_vert_surf_h matlab.graphics.chart.primitive.Surface
        bot_line_h matlab.graphics.chart.primitive.Line
        trans_line_h matlab.graphics.chart.primitive.Line
        text_h matlab.graphics.primitive.Text
        colorbar_h matlab.graphics.illustration.ColorBar
        vert_ex_slider_h matlab.ui.control.Slider
        vert_ex_edit_h matlab.ui.control.NumericEditField
        grid_size_edit_h matlab.ui.control.NumericEditField
        layer_thickness_h matlab.ui.control.NumericEditField
        layer_mean_depth_slider_h matlab.ui.control.Slider
        layer_mean_depth_edit_h matlab.ui.control.NumericEditField
        grid_meth_drop_down_h matlab.ui.control.DropDown
        az_knob_h matlab.ui.control.Slider
        el_knob_h matlab.ui.control.Slider
        full_bathy_data_struct struct
        output_3D_echoint struct

        
        disp_grid = 'on';
        grid_size = 0;
        dmin = 50;
        dmax = 150;
        ac_min = -50;
        ac_max = 50;
        el_val = 45;
        az_val = 45;
        grid_meth = 'accumarrayw'
        ZDir = 'reverse';
        cmap = 'ek60';
        AlphaDataMapping = 'direct';
        offset = true;
        FontSize = 9;
        disp_colorbar = true;
        FaceAlpha = 'flat'
        linked_props = [];
        ax_linked_props = [];

    end

    properties (SetObservable)
        obj_vis = struct('curtain_surf_h','on','bathy_surf_h','on','scatter_feature_h','on','trisurf_feature_h','on','WC_fan_h','on','ax_3D','on');
        vert_exa = 1;
    end

    methods
        function obj = echo_3D_cl(varargin)
            p = inputParser;

            addParameter(p,'cmap','ek60',@ischar);
            addParameter(p,'disp_colorbar',true,@islogical);
            addParameter(p,'disp_grid','on',@(x) ismember(x,{'off','on'}));
            addParameter(p,'FaceAlpha','flat',@ischar);
            addParameter(p,'ZDir','reverse');
            addParameter(p,'AlphaDataMapping','direct',@ischar);
            addParameter(p,'FontSize',9,@isnumeric);
            addParameter(p,'offset',true,@islogical);
            parse(p,varargin{:});

            fields=fieldnames(p.Results);
            for ifi=1:numel(fields)
                if isprop(obj,fields{ifi})
                    obj.(fields{ifi})= p.Results.(fields{ifi});
                end
            end


            parent_h = obj.init_echo_3D_fig();

            import_menu_h = uimenu(obj.echo_fig,'Text','&Import');
            bathy_import_h = uimenu(import_menu_h,'Text','Bathy');
            geotiff_import_h = uimenu(bathy_import_h,'Text','Import bathy from GeoTiff (''*.tiff'', ''*.tif'')');
            geotiff_import_h.MenuSelectedFcn  = @obj.import_bathy_from_geotiff;

            mb_import_h = uimenu(bathy_import_h,'Text','Import bathy from Kongsberg files (''*.all'', ''*.kmall'', ''*.wcd'', ''*.kmwcd'')');
            mb_import_h.MenuSelectedFcn  = @obj.import_bathy_from_kd;

            seafloor_features_import_h = uimenu(import_menu_h,'Text','Features');
            shpfiles_import_h = uimenu(seafloor_features_import_h,'Text','Import point cloud from shapefiles (''*.shp'')');
            shpfiles_import_h.MenuSelectedFcn  = @obj.import_pointcloud_from_shapefiles;

            control_tab_group = uitabgroup(parent_h);
            control_tab = uitab(control_tab_group,"Title",'General');
            control_layout = uigridlayout(control_tab,[16,2]);

            process_tab = uitab(control_tab_group,"Title",'Proc.');
            process_layout = uigridlayout(process_tab,[16,2]);

            disp_tab = uitab(control_tab_group,"Title",'Disp.');
            display_layout = uigridlayout(disp_tab,[16,1]);

            parent_vec = [control_layout process_layout process_layout control_layout control_layout process_layout process_layout];
            prop_cell  ={{'vert_ex_slider_h' 'vert_ex_edit_h'} {'grid_size_edit_h'} {'grid_meth_drop_down_h'} {'az_knob_h'} {'el_knob_h'} {'layer_thickness_h'} {'layer_mean_depth_slider_h' 'layer_mean_depth_edit_h'}};
            value_cell = {obj.vert_exa obj.grid_size obj.grid_meth obj.az_val obj.el_val obj.dmin obj.dmax};
            limits_cell = {[0 500] [0 200] '' [0 360] [0 90] [0 10000] [0 10000]};
            val_disp_fmt = {{'' '%.1f'} {'%.1fm'} {''} {''} {''} {'%.0f m'} {'' '%.0f m'}};
            disp_str = {'Vertical exageration' 'Bathy grid size' 'Bathy gridding meth.' 'Light Azimuth' 'Light Elevation' 'Echo-Int layer thickness' 'Echo-Int layer mean depth'};
            val_change_function = {{@obj.change_vert_exa @obj.change_vert_exa} {@obj.update_grid_size} {@obj.update_grid_meth} {''} {''} {@obj.update_echoint} {@obj.update_echoint @obj.update_echoint}};
            val_changing_fcn  ={{@obj.update_vert_ex_edit_h ''} {''} {''} {@obj.updateLighting} {@obj.updateLighting} {''} {@obj.update_echoint ''}};
            item_data_cell = {'' '' {'accumarrayw' 'griddataw' 'scatteredInterpolantw' 'accumarrayn' 'griddatan' 'scatteredInterpolantn'} '' '' '' ''};
            items_cell = {'' '' {'Weigthed Accumarray' 'Weigthed GridData' 'Weigthed ScatteredInterpolant' 'Non-Weigthed Accumarray' 'Non-Weigthed GridData' 'Non-Weigthed ScatteredInterpolant'} '' '' '' ''};
            
            str_disp = {'Display bathymetry' 'Display curtains' 'Display WC Fan' 'Display features' 'Display features env.' 'Transducer lines' 'Text' 'Axes'};
            fields_disp  = {'bathy_surf_h' 'curtain_surf_h' 'WC_fan_h' 'scatter_feature_h' 'trisurf_feature_h' 'trans_line_h' 'text_h' 'ax_3D'};

            u_parent =unique(parent_vec);

            for uip = 1:numel(u_parent)
                idx_p = find(u_parent(uip) == parent_vec);

                nb_control = 2*numel(idx_p);
                cell_fmt = cell(1,nb_control+1);
                cell_fmt(:) = {'fit'};
                cell_fmt(end) = {'1x'};
                u_parent(uip).RowHeight = cell_fmt;
                u_parent(uip).ColumnWidth = {'3x','1x'};
            end



            ir = zeros(size(u_parent));
            for uic = 1:numel(prop_cell)
                id_parent  = find(parent_vec(uic) == u_parent);
                ir(id_parent) = ir(id_parent)+1;
                if ~isempty(disp_str{uic})
                    tmp_label = uilabel(parent_vec(uic));
                    tmp_label.HorizontalAlignment = 'left';
                    tmp_label.Layout.Row = ir(id_parent);
                    tmp_label.Layout.Column = 1;
                    tmp_label.Text = disp_str{uic};
                end

                for uiic = 1:numel(prop_cell{uic})
                    switch class(obj.(prop_cell{uic}{uiic}))
                        case 'matlab.ui.control.Slider'
                            obj.(prop_cell{uic}{uiic}) = uislider('Parent',parent_vec(uic),'Value',value_cell{uic},'Limits',limits_cell{uic});
                            obj.(prop_cell{uic}{uiic}).ValueChangingFcn = val_changing_fcn{uic}{uiic};
                            ir(id_parent) = ir(id_parent)+1;
                            ic = 1;
                        case 'matlab.ui.control.NumericEditField'
                            obj.(prop_cell{uic}{uiic}) = uieditfield(parent_vec(uic),"numeric",'Value',value_cell{uic},"Limits",limits_cell{uic});
                            obj.(prop_cell{uic}{uiic}).ValueDisplayFormat = val_disp_fmt{uic}{uiic};
                            ic = 2;
                        case 'matlab.ui.control.DropDown'
                            obj.(prop_cell{uic}{uiic})  = uidropdown(parent_vec(uic),'Items',items_cell{uic},'ItemsData',item_data_cell{uic},"Value",value_cell{uic});
                            ir(id_parent) = ir(id_parent)+1;
                            ic = 1;
                    end
                obj.(prop_cell{uic}{uiic}).Tag = prop_cell{uic}{uiic};
                obj.(prop_cell{uic}{uiic}).Layout.Row = ir(id_parent);
                obj.(prop_cell{uic}{uiic}).Layout.Column = ic;
                obj.(prop_cell{uic}{uiic}).ValueChangedFcn = val_change_function{uic}{uiic};
                
                end
            end


            init_pos = 0;
            for uif = 1:numel(str_disp)
                tmp_h = uicheckbox(display_layout,...
                    'Text',str_disp{uif});
                tmp_h.Layout.Row = init_pos+uif;
                tmp_h.Layout.Column = 1;
                tmp_h.Tag = fields_disp{uif};
                tmp_h.Value = true;
                tmp_h.ValueChangedFcn  = @obj.update_vis;
            end

            echo_fig = obj.get_parent_figure();
            curr_disp = get_esp3_prop('curr_disp');
            if isempty(curr_disp)
                curr_disp = curr_disp_cl();
            end
            
            echo_fig.Alphamap = curr_disp.get_alphamap();

            obj.ax_tab_group = uitabgroup(parent_h);
            
            obj.full_bathy_data_struct(1).bot_data_struct = {};
            obj.full_bathy_data_struct(1).slope_data_struct = {};

            addlistener(obj,'obj_vis','PostSet',@obj.set_graphic_handle_vis);
            addlistener(obj,'vert_exa','PostSet',@obj.set_vert_exa);
            %addlistener(obj,'grid_size','PostSet',@obj.change_grid_size);
           
        end

        function updateLighting(obj,src,eventData)
            % Delete existing lights
            for uiax = 1:numel(obj.lgt_3D)
                %lgt = obj.lgt_3D(uiax);
                
                fprintf('Azimuth %.0f\nElevation %.0f\n',obj.az_knob_h.Value,obj.el_knob_h.Value);
                %delete(findall(ax, 'Type', 'light'));

                obj.lgt_3D(uiax) = lightangle(obj.lgt_3D(uiax),obj.az_knob_h.Value,-obj.el_knob_h.Value);
                %obj.lgt_3D(uiax).Visible = 'off';

            end
        end

        function tab = get_ax_tab_per_tag(obj,field_to_disp)

            tab = [];
            if isempty(obj.ax_tab)
                return;
            end

            id = find({obj.ax_tab(:).Tag},field_to_disp);
            if ~isempyty(id)
                tab = obj.ax_tab(id);
            end
        end

        function ax = get_ax_per_tag(obj,field_to_disp)

            ax = [];
            if isempty(obj.ax_3D)
                return;
            end

            id = find(strcmpi({obj.ax_3D(:).Tag},field_to_disp));
            if ~isempty(id)
                ax = obj.ax_3D(id);
            end
        end

        function update_vis(obj,src,evt)
            if src.Value
                obj.obj_vis.(src.Tag) = 'on';
            else
                obj.obj_vis.(src.Tag) = 'off';
            end
        end

        function import_pointcloud_from_shapefiles(obj,~,~)

            lay=get_current_layer();

            if isempty(lay)
                app_path=get_esp3_prop('app_path');
                path_init=app_path.data.Path_to_folder;
            else
                path_init = fileparts(lay.Filename{1});
            end

            ext = {'*.shp'};
            ftypes = {'Shapefiles'};

            [ff,path_f] = uigetfile( {fullfile(path_init,strjoin(ext,';'))}, sprintf('Select %s file(s)',strjoin(ftypes,'/')),'MultiSelect','on');

            % nothing opened
            if isnumeric(path_f)|| ~isfolder(path_f)
                return;
            end

            if ~iscell(ff)
                if (ff==0)
                    return;
                end
                ff = {ff};
            end
            new_shp_f = fullfile(path_f,ff);
            info_data_shp=cellfun(@(x) shapeinfo(x),new_shp_f,'un',0);
            geo_data_shp=cellfun(@(x) shaperead(x),new_shp_f,'un',0);
            idx_points = find(strcmpi(cellfun(@(x) x.ShapeType,info_data_shp,'un',0),'point'));
            
            C = lines(numel(idx_points));
            for uishp = 1:numel(idx_points)
                tmp = geo_data_shp{idx_points(uishp)};
                lat = [tmp(:).Y];
                long = [tmp(:).X];
                if isfield(tmp,'z')
                    dd  = -[tmp(:).z];
                else
                    dd = zeros(size(lat));
                end

                tag_s = sprintf('ptcld_%s_%d',info_data_shp{idx_points(uishp)}.Filename(1,:),uishp);
                ms_ori = 5;
                
                for iax = 1:numel(obj.ax_3D)

                    ax = obj.ax_3D(iax);
                    delete(findobj(ax,'Tag',tag_s));
                    scatter3(ax,...
                        lat,...
                        long,....
                        dd,...
                        ms_ori,...
                        C(uishp,:),'Tag',tag_s,'Marker','.');
                end
            end

        end

        function import_bathy_from_kd(obj,~,~)
            
            lay=get_current_layer();
            if isempty(lay)
                app_path=get_esp3_prop('app_path');
                path_init=app_path.data.Path_to_folder;
            else
                path_init = fileparts(lay.Filename{1});
            end

            ext = {'*.all' '*.wcd' '*kmall' '*kmwcd'};
            ftypes = {'ALL files' 'WCD files' 'KMALL files' 'KMWCD files'};

            [ff,path_f] = uigetfile( {fullfile(path_init,strjoin(ext,';'))}, sprintf('Select %s file(s)',strjoin(ftypes,'/')),'MultiSelect','on');

            % nothing opened
            if isnumeric(path_f)|| ~isfolder(path_f)
                return;
            end

            if ~iscell(ff)
                if (ff==0)
                    return;
                end
                ff = {ff};
            end
            fname = fullfile(path_f,ff);

            layers_to_disp = open_kem_file_standalone(fname,...
                'GPSOnly',ones(1,numel(ff)));
            if ~isempty(layers_to_disp)
                obj.add_bathy(layers_to_disp,'tag','bathy','full_bathy_extract',false);
                for ui = 1:numel(layers_to_disp)
                    trans_obj = layers_to_disp(ui).Transceivers(1);
                    for iax  = 1:numel(obj.ax_3D)
                        ax  = obj.ax_3D(iax);
                        tag_s = sprintf('%s_%s_%s',...
                            trans_obj.Config.ChannelID,layers_to_disp(ui).Filename{1},ax.Tag);
                        output_h = obj.get_graphic_handles({'trans_line_h','text_h'},tag_s);
                        obj.add_line(trans_obj,ax,'tag',tag_s,'handle_cell',{output_h.trans_line_h},'line_type',{'transducer'});
                        [~,str_f,~] = fileparts(layers_to_disp(ui).Filename{1});
                        obj.add_text(trans_obj,ax,'tag',tag_s,'idx_ping',1,'text_h',output_h.text_h,'text',str_f);
                        
                    end
                end
            end

        end

        function import_bathy_from_geotiff(obj,~,~)
            app_path=get_esp3_prop('app_path');
            path_init=app_path.data.Path_to_folder;

            ext = {'*.tiff' '*.tif'};
            ftypes = {'GeoTiff' 'GeoTiff'};

            [ff,path_f] = uigetfile( {fullfile(path_init,strjoin(ext,';'))}, sprintf('Select %s file(s)',strjoin(ftypes,'/')),'MultiSelect','on');

            % nothing opened
            if isnumeric(path_f)|| ~isfolder(path_f)
                return;
            end

            % single file is char. Turn to cell
            if ~iscell(ff)
                if (ff==0)
                    return;
                end
                ff = {ff};
            end
            bathy_val = [];
            lat_val = [];
            lon_val  = [];

            for uif = 1 :numel(ff)
                try
                    fname = fullfile(path_f,ff{uif});

                    if ~isfile(fname)
                        continue;
                    end

                    [~,~,fext] = fileparts(fname);
                    switch fext
                        case {'.tiff' '.tif'}
                            [A,R] = readgeoraster(fname);
                            A = double(A);
                            %info = geotiffinfo(fname);
                            [x,y] = worldGrid(R);
                            [lat,lon] =projinv(R.ProjectedCRS,x,y);

                            idx_keep = (A~=min(A)) & ~isnan(A);
                            bathy_val = [bathy_val A(idx_keep)];
                            lat_val = [lat_val lat(idx_keep)];
                            lon_val = [lon_val lon(idx_keep)];

                        otherwise
                            continue;
                    end

                catch err
                    print_errors_and_warnings([],'warning',err);
                    print_errors_and_warnings([],'warning',sprintf('Could not load baythy file to db %s',fname));
                end
            end
            if ~isempty(bathy_val)
                obj.add_bathy(layer_cl.empty,'tag','bathy','LatLonDepth',{lat_val lon_val -bathy_val});
            end
        end

        function set_cmap(obj,cmap_name,ax_list,cbar_list)
            if ~isempty(cmap_name)
                obj.cmap = cmap_name;
            end
            cmap_struct = init_cmap(obj.cmap);

            if isempty(ax_list)
                ax_list  = obj.ax_3D;
            end
            if isempty(ax_list)
                return;
            end

            if isempty(cbar_list)
                cbar_list = obj.colorbar_h;
            end

            for iab = 1:numel(cbar_list)
                cbar_list(iab).Color = cmap_struct.col_lab;
            end
            
            for iax = 1:numel(ax_list)
                ax = ax_list(iax);
                set(ax,...
                'Color',cmap_struct.col_ax,...
                    'XColor',cmap_struct.col_lab,...
                    'YColor',cmap_struct.col_lab,...
                    'ZColor',cmap_struct.col_lab,...
                    'Colormap',cmap_struct.cmap,...
                    'GridColor',cmap_struct.col_grid,...
                    'MinorGridColor',cmap_struct.col_grid);
                ax.Parent.BackgroundColor = cmap_struct.col_ax;
            end

            fields ={'bathy_surf_h' 'bot_line_h' 'trans_line_h' 'text_h'};

            props = {{'FaceColor'} {'Color'} {'Color'} {'Color'}};

            val = {{1-(cmap_struct.col_ax).*[0.4 0.4 0.4] } {cmap_struct.col_bot} {cmap_struct.col_bot} {cmap_struct.col_lab}};
            output_h = get_graphic_handles(obj,fields,'');
            for uif = 1:numel(fields)
                for uiff = 1:numel(val{uif})
                    set(output_h.(fields{uif}),props{uif}{uiff},val{uif}{uiff});
                end
            end
        end

        function ax = add_ax_tab(obj,field_to_disp)

            ax = obj.get_ax_per_tag(field_to_disp);
            if ~isempty(ax)
                return;
            end
            [~,Type,~]=init_cax(field_to_disp);
            ax_tab_tmp = uitab(obj.ax_tab_group,'Tag',field_to_disp,'Title',Type);
            obj.ax_tab = [obj.ax_tab ax_tab_tmp];
            uigl = uigridlayout(ax_tab_tmp,[1 1]);
            ax_usr_data.disp_EN = false;
            ax=uiaxes(...
                'Parent',uigl,...
                'FontSize',obj.FontSize,...
                'Box','on',...
                'SortMethod','childorder',...
                'XGrid',obj.disp_grid,...
                'YGrid',obj.disp_grid,...
                'ZGrid',obj.disp_grid,...
                'XMinorGrid','off',...
                'YMinorGrid','off',...
                'ZMinorGrid','off',...
                'GridLineStyle','--',...
                'MinorGridLineStyle',':',...
                'NextPlot','add',...
                'ZDir',obj.ZDir,...
                'YDir',obj.ZDir,...
                'Clipping','off',...
                'ClippingStyle','rectangle',...
                'Toolbar',[],...
                'UserData',ax_usr_data,...
                'XLimMode','auto',...
                'YLimMode','auto',...
                'ZLimMode','auto',...
                'Tag',field_to_disp);

               
            lgt = lightangle(ax,obj.az_knob_h.Value,-obj.el_knob_h.Value);
            lgt.Style = 'local';

            axtoolbar(ax,{'restoreview' 'rotate' 'pan' 'zoomin' 'zoomout'});
            ax.Interactions = [rotateInteraction zoomInteraction];
            enableDefaultInteractivity(ax);
            cmap_struct = init_cmap(obj.cmap);
            uigl.BackgroundColor = cmap_struct.col_ax;

            cbar=colorbar(ax,...
                'PickableParts','none',...
                'fontsize',obj.FontSize-2,...
                'Color',cmap_struct.col_lab,'Tag',field_to_disp);
           
            view(ax,[45 45]);
            obj.set_cmap('',ax,cbar);
            switch field_to_disp
                case 'quiver_velocity'
                    ax.ZAxis.TickLabelFormat = '%.0fm';
                    ax.YAxis.TickLabelInterpreter = 'tex';
                    ax.YAxis.TickLabelFormat = '%.0fm';
                    ax.XAxis.TickLabelInterpreter = 'tex';
                    ax.XAxis.TickLabelFormat = '%.0fm';
                    ax.UserData.disp_EN = true;
                otherwise
                    ax.ZAxis.TickLabelFormat = '%.0fm';
                    ax.YAxis.TickLabelInterpreter = 'tex';
                    ax.YAxis.TickLabelFormat = '%.2f^{o}';
                    ax.XAxis.TickLabelInterpreter = 'tex';
                    ax.XAxis.TickLabelFormat = '%.2f^{o}';
            end
            view(ax,[45 45]);

            if (will_it_work(uigl,'9.8',true)||will_it_work(uigl,'',false))
                cbar.UIContextMenu=[];
            end
            obj.colorbar_h = [obj.colorbar_h cbar];
            obj.ax_3D = [obj.ax_3D ax];pause(0.1);
            obj.lgt_3D = [obj.lgt_3D lgt];
            obj.vert_exa = obj.vert_ex_slider_h.Value;

        end

        function echo_fig = get_parent_figure(obj)

            if ~isempty(obj)
                echo_fig = obj.echo_fig;
            else
                echo_fig =  matlab.ui.Figure.empty;
            end
        end


        function output_h = get_graphic_handles(obj,fields,tag)
            for uif = 1:numel(fields)
                output_h.(fields{uif}) = [];
                if ~isempty(tag)
                    output_h.(fields{uif})  = obj.(fields{uif});
                    if ~isempty(tag)
                        if ~isempty(output_h.(fields{uif}))
                            output_h.(fields{uif}) = output_h.(fields{uif})(strcmpi({output_h.(fields{uif})(:).Tag},tag));
                        end
                    end
                end
            end
        end

        function rm_graphic_handles(obj,fields,tag)
            for uif = 1:numel(fields)
                if ~isempty(tag)
                    if ~isempty(obj.(fields{uif}))
                        idx = strcmpi({obj.(fields{uif})(:).Tag},tag);
                        delete(obj.(fields{uif})(idx));
                        obj.(fields{uif})(idx) = [];
                    end
                end
            end
        end

        function add_bathy(obj,lay_obj,varargin)

            p = inputParser;
            addRequired(p,'obj',@(x) isa(x,'echo_3D_cl'));
            addRequired(p,'lay_obj',@(x) isa(x,'layer_cl'));
            addParameter(p,'tag','',@ischar);
            addParameter(p,'BeamAngularLimit',[-inf inf],@(x) all(isnumeric(x)));
            addParameter(p,'rangeBounds',[0 inf],@(x) all(isnumeric(x)));
            addParameter(p,'refRangeBounds',[-inf inf],@(x) all(isnumeric(x)));
            addParameter(p,'depthBounds',[-inf inf],@isnumeric);
            addParameter(p,'timeBounds',[0 inf],@isnumeric);
            addParameter(p,'cax',[-75 -38],@isnumeric);
            addParameter(p,'main_figure',[],@(x) isempty(x)||ishandle(x));
            addParameter(p,'fieldnames',{'sv'},@ischar);
            addParameter(p,'Unique_ID',generate_Unique_ID([]),@ischar);
            addParameter(p,'Ref','Surface',@(x) ismember(x,list_echo_int_ref));
            addParameter(p,'intersect_only',false,@(x) isnumeric(x)||islogical(x));
            addParameter(p,'idx_regs',[],@isnumeric);
            addParameter(p,'regs',region_cl.empty(),@(x) isa(x,'region_cl'));
            addParameter(p,'select_reg','selected',@ischar);
            addParameter(p,'surv_data',survey_data_cl.empty,@(x) isa(x,'survey_data_cl'))
            addParameter(p,'keep_bottom',false,@(x) isnumeric(x)||islogical(x));
            addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
            addParameter(p,'grid_size',0,@(x) x>=0);
            addParameter(p,'nb_points_per_node',7,@(x) x>0);
            addParameter(p,'prc_thr',2,@(x) x>=0);
            addParameter(p,'LatLonDepth',{},@iscell);
            addParameter(p,'full_bathy_extract',true,@islogical);
            addParameter(p,'load_bar_comp',[]);
            addParameter(p,'regrid',false,@islogical);
            parse(p,obj,lay_obj,varargin{:});


            data_struct_tot = [];
            slope_struct_tot = [];

            if ~p.Results.regrid
                if isempty(p.Results.LatLonDepth)

                    for uilay = 1:numel(lay_obj)
                        idx_t = find(lay_obj(uilay).Transceivers.ismb,1);
                        fbool = p.Results.full_bathy_extract;

                        if isempty(idx_t)
                            idx_t = 1:numel(lay_obj(uilay).Transceivers);
                            fbool = true;
                        end

                        for idx = idx_t
                            trans_obj = lay_obj(uilay).Transceivers(idx);
                            idx_pings = find(trans_obj.Time>=p.Results.timeBounds(1) & lay_obj(uilay).Transceivers(idx).Time<=p.Results.timeBounds(2));
                                % profile on;
                                default_val =get_default_bathy_extract_val();
                                if default_val.use_full_att
                                    att = lay_obj(uilay).AttitudeNav;
                                else
                                    att =attitude_nav_cl.empty();
                                end
                                if default_val.use_full_gps
                                    gps = lay_obj(uilay).GPSData;
                                else
                                    gps =gps_data_cl.empty();
                                end

                                [data_struct_tmp,bot_reg,slope_struct] = trans_obj.extract_bathy_from_split_beam(...
                                    'full_attitude',att,...
                                    'full_navigation',gps,...
                                    'idx_ping',idx_pings,...
                                    'field',default_val.field,...
                                    'win_filt',default_val.win_filt,...
                                    'echo_len_fact',default_val.echo_len_fact,...
                                    'fitmeth',default_val.fitmeth,...
                                    'rsq_slope_est_thr',default_val.rsq_slope_est_thr,...
                                    'slope_max',default_val.slope_max,...
                                    'robust_estimation',default_val.robust_estimation,...
                                    'default_slope',default_val.default_slope,...
                                    'thr_echo',default_val.thr_echo,...
                                    'estimate_slope_bool',default_val.estimate_slope_bool,...
                                    'full_bathy_extract',fbool,...
                                    'beam_slope_est_to_display',[],...
                                    'load_bar_comp',p.Results.load_bar_comp);
                                % profile off;
                                % profile viewer;
                                if isempty(data_struct_tmp)
                                    continue;
                                end
                                data_struct_tot = [data_struct_tot data_struct_tmp];
                                slope_struct_tot = [slope_struct_tot slope_struct];
                        end
                    end
                    
                else
                    [E_tot,N_tot,zone] = ll2utm(p.Results.LatLonDepth{1},p.Results.LatLonDepth{2});
                    if isscalar(zone)
                        zone = repmat(zone,size(E_tot));
                    end
                    H_tot = p.Results.LatLonDepth{3};
                    id_rem = isnan(E_tot.*N_tot);
                    N_tot(id_rem) = [];
                    E_tot(id_rem) = [];
                    H_tot(id_rem) = [];
                    zone(id_rem) = [];
                    if ~isempty(E_tot)
                        data_struct_tot.E_t = E_tot;
                        data_struct_tot.N_t = N_tot;
                        data_struct_tot.H = H_tot;
                        data_struct_tot.BS = ones(size(H_tot));
                        data_struct_tot.zone = zone;
                    end
                end
                grid_size_init = p.Results.grid_size;
            else
                data_struct_tot = obj.full_bathy_data_struct.bot_data_struct{1};
                grid_size_init = obj.grid_size;
                fbool = false;
            end
            obj.full_bathy_data_struct.bot_data_struct = {data_struct_tot};
            obj.full_bathy_data_struct.slope_data_struct = {slope_struct_tot};

            if isempty(obj.full_bathy_data_struct.bot_data_struct{1})
                print_errors_and_warnings([],'log','Could not extract Bathy data from this layer.');
                return;
            end 

            if fbool
                if trans_obj.ismb
                    nb_points_per_node = 7;
                else
                    nb_points_per_node = 5;
                end
            else
                nb_points_per_node = 3;
            end

            [grid_tot,poly_cov,grid_size_final,zone_u] = grid_bathy(obj.full_bathy_data_struct.bot_data_struct(1),nb_points_per_node,grid_size_init,obj.grid_meth,p.Results.prc_thr);

            if fbool || isdebugging

                % if ~all(cellfun(@isempty,obj.full_bathy_data_struct.slope_data_struct))
                %     [~,link_slope] =display_slope(obj.full_bathy_data_struct.slope_data_struct,{'All Data'},obj.vert_exa,6);
                % end
                
                for uig = 1:numel(grid_tot)
                    [~,link_h{uig}] = display_highres_bathy(grid_tot{uig},poly_cov{uig},{sprintf('All Data, grid size %.1fm',grid_size_final(uig))},obj.vert_exa,4);
                end

                [~,link_s] = display_soundings_scatter(obj.full_bathy_data_struct.bot_data_struct(1),{'All Data'},p.Results.prc_thr,obj.vert_exa,4);
            end
            obj.grid_size_edit_h.Value = mean(grid_size_final);
            obj.grid_size = mean(grid_size_final);
    
            ax = [];
            H = [];

            for iz = 1:numel(zone_u)

                tag = sprintf('%s_%d',p.Results.tag,zone_u(iz));

                output_h = obj.get_graphic_handles({'bathy_surf_h'},tag);
                H = [H grid_tot{iz}{1}.H(:)];

                if isempty(output_h.bathy_surf_h)
                    
                        if isempty(obj.ax_3D)
                            ax = [];
                            for ifif = 1:numel(p.Results.fieldnames)
                                 ax_tmp = add_ax_tab(obj,p.Results.fieldnames{ifif});
                                ax = [ax_tmp ax];
                            end
                        else
                            ax = obj.ax_3D;
                        end

                        cmap_struct = init_cmap(obj.cmap);
                        for ui = 1:numel(ax)
                            bathy_surf_h_temp = surf(ax(ui),grid_tot{iz}{1}.Lat,grid_tot{iz}{1}.Lon,grid_tot{iz}{1}.H,...
                                'Tag',tag);
                            bathy_surf_h_temp.AlphaData = single(~isnan(grid_tot{iz}{1}.H));
                            %bathy_surf_h_temp.AlphaDataMapping = 'direct';
                            bathy_surf_h_temp.LineStyle = 'none';
                            bathy_surf_h_temp.EdgeColor = 'none';
                            bathy_surf_h_temp.FaceColor =  1-(cmap_struct.col_ax).*[0.4 0.4 0.4];
                            bathy_surf_h_temp.FaceLighting = 'gouraud';
                            bathy_surf_h_temp.EdgeLighting  = 'gouraud';
                            bathy_surf_h_temp.SpecularStrength = 0.5;
                            bathy_surf_h_temp.BackFaceLighting = 'reverselit';
                            uistack(bathy_surf_h_temp,'bottom');
                            obj.bathy_surf_h = [obj.bathy_surf_h bathy_surf_h_temp];
                        end
                else
                    
                    for uib = 1:numel(output_h.bathy_surf_h)
                        output_h.bathy_surf_h(uib).XData = grid_tot{iz}{1}.Lat;
                        output_h.bathy_surf_h(uib).YData = grid_tot{iz}{1}.Lon;
                        output_h.bathy_surf_h(uib).ZData = grid_tot{iz}{1}.H;
                        output_h.bathy_surf_h(uib).AlphaData = single(~isnan(grid_tot{iz}{1}.H));
                        ax = [ax output_h.bathy_surf_h(uib).Parent];
                    end
                end
            end
            tmp = [min(H(:),[],'omitnan') max(H(:),[],'omitnan')];
            tmp = tmp+[-0.05 0.05]*range(tmp);
            for ui = 1:numel(ax)
                ax(ui).ZLim = tmp;
            end
            obj.vert_exa = obj.vert_ex_slider_h.Value;

        end



        function data_struct_new = add_feature(obj,trans_obj,varargin)

            p = inputParser;
            addRequired(p,'obj',@(x) isa(x,'echo_3D_cl'));
            addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
            addParameter(p,'tag','',@ischar);
            addParameter(p,'BeamAngularLimit',[-inf inf],@(x) all(isnumeric(x)));
            addParameter(p,'rangeBounds',[0 inf],@(x) all(isnumeric(x)));
            addParameter(p,'refRangeBounds',[-inf inf],@(x) all(isnumeric(x)));
            addParameter(p,'depthBounds',[-inf inf],@isnumeric);
            addParameter(p,'cax',[-75 -38],@isnumeric);
            addParameter(p,'main_figure',[],@(x) isempty(x)||ishandle(x));
            addParameter(p,'fieldname','sv',@ischar);
            addParameter(p,'Unique_ID',generate_Unique_ID([]),@ischar);
            addParameter(p,'Ref','Surface',@(x) ismember(x,list_echo_int_ref));
            addParameter(p,'intersect_only',false,@(x) isnumeric(x)||islogical(x));
            addParameter(p,'idx_regs',[],@isnumeric);
            addParameter(p,'regs',region_cl.empty(),@(x) isa(x,'region_cl'));
            addParameter(p,'select_reg','selected',@ischar);
            addParameter(p,'surv_data',survey_data_cl.empty,@(x) isa(x,'survey_data_cl'))
            addParameter(p,'keep_bottom',false,@(x) isnumeric(x)||islogical(x));
            addParameter(p,'t_buffer',0,@(x) isnumeric(x));
            addParameter(p,'anim_speed',2,@(x) isnumeric(x));
            addParameter(p,'fname','',@ischar);
            addParameter(p,'disp_gridded_data',false,@islogical);
            addParameter(p,'vert_exa',nan,@(x) isnumeric(x));
            addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
            addParameter(p,'load_bar_comp',[]);

            parse(p,obj,trans_obj,varargin{:});

            if isempty(p.Results.surv_data)
                surv_data  = survey_data_cl();
                surv_data.StartTime = trans_obj.Time(1);
                surv_data.EndTime = trans_obj.Time(end);
            else
                surv_data = p.Results.surv_data;
            end
        
            cax  = p.Results.cax;
            fff = p.Results.fieldname;
            ff = p.Results.fieldname;
            ax_ff = ff;
            data_struct_new = [];

            switch ff
                case 'feature_sv'
                    fff = 'sv';
                    ax_ff = 'sv';
                case 'feature_id'
                    fff = 'sv';
                    ax_ff = 'id';
                case {'sv' 'svdenoised' 'svunmatched'}
                    fff = 'sv';
                case {'sp' 'spdenoised' 'spunmatched' 'sp_comp' 'singletarget' 'ST TS' 'trackedtarget'}
                    ff = 'ts';
                case 'bathy'
                    ff  = 'bathy';
                    fff='sv';
                    if ismember('svdenoised',trans_obj.Data.Fieldname)
                        fff='svdenoised';
                    end
            end
            ax = add_ax_tab(obj,ax_ff);
            ms_ori = 50;
            tag_s = sprintf('%s_%s',p.Results.tag,ff);

            switch ff
                case {'feature_sv' 'feature_id'}
                    if isempty(trans_obj.Features)
                        return;
                    end

                    output_h = obj.get_graphic_handles({'trans_line_h' 'bot_line_h'},tag_s);
                    lim_struct  = trans_obj.Features.get_lim();
                    obj.add_line(trans_obj,ax,'tag',tag_s,'idx_ping',lim_struct.Idx_ping(1):lim_struct.Idx_ping(end),'handle_cell',{output_h.trans_line_h output_h.bot_line_h},'line_type',{'transducer' 'bottom'});

                    nb_features = numel(trans_obj.Features);
                    
                    col_data = lines(nb_features);
                    
                    obj.rm_graphic_handles({'scatter_feature_h' 'trisurf_feature_h'},tag_s);

                    for uid  = 1:nb_features

                        zone_u = unique(trans_obj.Features(uid).Zone);

                        if p.Results.disp_gridded_data
                            if isempty(trans_obj.Features(uid).E_grid)
                                trans_obj.Features(uid).grid_feature(3,1);
                            end
                            switch ff
                                case 'feature_sv'
                                    data_idd_grid = trans_obj.Features(uid).Sv_grid;
                                case 'feature_id'
                                    data_idd_grid = trans_obj.Features(uid).Id*ones(size(trans_obj.Features(uid).Sv_grid));%TOFIX
                                    cax = [min([trans_obj.Features(:).ID]) max([trans_obj.Features(:).ID])]+[-1 1];
                            end

                            E_grid = trans_obj.Features(uid).E_grid;
                            N_grid = trans_obj.Features(uid).N_grid;
                            H_grid = trans_obj.Features(uid).H_grid;

                        else
                            switch ff
                                case 'feature_sv'
                                    data_idd_grid = trans_obj.Features(uid).Sv;
                                case 'feature_id'
                                    data_idd_grid = trans_obj.Features(uid).ID*ones(size(trans_obj.Features(uid).Sv));
                                    cax = [min([trans_obj.Features(:).ID]) max([trans_obj.Features(:).ID])]+[-1 1];
                            end
                            E_grid = trans_obj.Features(uid).E;
                            N_grid = trans_obj.Features(uid).N;
                            H_grid = trans_obj.Features(uid).H;
                        end
                        [lat_t,lon_t] = utm2ll(trans_obj.Features(uid).E,trans_obj.Features(uid).N,zone_u(1));

                        [lat_grid,lon_grid] = utm2ll(E_grid(:),N_grid(:),zone_u(1));
                        lat_grid = reshape(lat_grid,size(E_grid));
                        lon_grid = reshape(lon_grid,size(N_grid));
                        alpha_data = ones(size(data_idd_grid));
                        ms = ms_ori;
                        alphadata_mapping = 'none';

                        switch ff
                            case 'feature_sv'
                                alpha_data = (data_idd_grid - cax(1));
                                alpha_data(alpha_data<0)=0;
                                alpha_data = (alpha_data./prctile(alpha_data,95,'all'));
                                alpha_data(alpha_data<sqrt(0.1)) = 0;
                                alpha_data(alpha_data>1) = 1;
                                ms = ms_ori.*ones(size(alpha_data));  
                                ms(alpha_data == 0) = nan;
                        end

                        tth = scatter3(ax,...
                            lat_grid(:),...
                            lon_grid(:),....
                            H_grid(:),...
                            ms(:),...
                            data_idd_grid(:),...
                            'Tag',tag_s,'Marker','.','MarkerFaceAlpha','flat','MarkerEdgeAlpha','flat');
                        tth.AlphaData  = alpha_data(:);
                        tth.AlphaDataMapping = alphadata_mapping;
                        tsh = trisurf(trans_obj.Features(uid).ConvHull,lat_t,lon_t,trans_obj.Features(uid).H,'FaceColor',col_data(uid,:),'Facealpha',0.1,'tag',tag_s,'Linestyle','none','Parent',ax);
                        uistack(tth,'top');
                        uistack(tsh,'top');

                        obj.scatter_feature_h = [obj.scatter_feature_h tth];
                        obj.trisurf_feature_h = [obj.trisurf_feature_h tsh];
                    end
                    
                    out_lim = trans_obj.Features.get_lim();
                    tmp = out_lim.H;
                    tmp = tmp+[-0.05 0.05]*range(tmp);
                    if diff(tmp) >0
                        ax.ZLim =  tmp;
                    end

                case {'sv' 'svdenoised' 'sp' 'spdenoised' 'TS' 'singletarget' 'trackedtarget' 'alongangle' 'acrossangle' 'bathy' 'ts' 'wc_data'}

                    if isempty(p.Results.regs)
                        return;
                    end

                    reg_obj = p.Results.regs;
                    anim_bool = p.Results.t_buffer>0;
                    anim_speed = p.Results.anim_speed;
                    create_movie = anim_bool && ~isempty(p.Results.fname);
                    if create_movie
                        vidfile = VideoWriter(p.Results.fname);
                    end

                    for uir = 1:numel(reg_obj)
                        tag = sprintf('%s_%s_%s',trans_obj.Config.ChannelID,reg_obj(uir).Unique_ID,ff);
                        output_h = obj.get_graphic_handles({'scatter_feature_h'},tag);
                        up_scat = isempty(output_h.scatter_feature_h);

                        [data_struct_new,no_nav] = reg_obj(uir).get_region_3D_echoes(trans_obj,'field',fff,'other_fields',{},'comp_angle',[true true]);
                        data_struct_new = data_struct_new.(fff);
                        if no_nav
                            ax.UserData.disp_EN = true;
                        end
                        if isempty(data_struct_new)
                            continue;
                        end
                        [cax_def,~,~,AlphaDisp] = init_cax(ax_ff);

                        if isempty(cax)
                            cax = cax_def;
                        end

                        alphadata_mapping = 'direct';
                        
                        switch AlphaDisp
                            case 'AlphaNormed'
                                alphadata_mapping = 'none';
                                alpha_data = db2pow(data_struct_new.data_disp - min(data_struct_new.data_disp,[],'all'));
                                alpha_data(alpha_data<0) = 0;
                                alpha_data = sqrt(alpha_data./prctile(alpha_data(:),90));
                                alpha_data(alpha_data<sqrt(0.1)) = 0;
                                alpha_data(alpha_data>1) = 1;

                                %alpha_data(~isnan(alpha_data)) = 1;
                                
                                if isempty(cax)
                                    cax = prctile(data_struct_new.H,[2 98],'all');
                                end


                            otherwise
                                if isempty(cax)
                                    cax = cax_def;
                                end
                                alpha_data =ones(size(data_struct_new.data_disp ),'single')*numel(obj.echo_fig.Alphamap);
                                %alpha_data(below_bot_sub) = 2;
                                alpha_data(data_struct_new.data_disp <= cax(1)) = 1;
                        end
                        ms = ms_ori * ones(size(data_struct_new.data_disp));
                        data_struct_new.(fff) = data_struct_new.data_disp;
                        switch ff
                            case 'bathy'
                                data_struct_new.data_disp = data_struct_new.depth;
                                alpha_data(data_struct_new.H<= cax(1)) = 0;
                            case {'singletarget','trackedtarget', 'ts'}
                                ms = ms_ori.*...
                                    (db2pow(data_struct_new.data_disp - cax(1)));
                                ms(ms>50*ms_ori) = 50*ms_ori;
                                
                        end

                        if uir == 1
                            [tt,~,~]  =unique(data_struct_new.Time);

                            t_vec = min(tt):median(diff(tt)):max(tt);
                            dt = diff(t_vec)*24*60*60;
                            dt = [0 dt];
                        end



                        if anim_bool
                            if uir == 1 && create_movie
                                fps = ceil(1./median(dt)*anim_speed);
                                vidfile.FrameRate=fps;
                                open(vidfile);
                            end
                        else
                            t_vec = nan;
                        end

                        for uip = 1:numel(t_vec)
                            if ~isnan(t_vec(uip))
                                iii = data_struct_new.Time >= t_vec(uip)-p.Results.t_buffer/(24*60*60) & data_struct_new.Time <= t_vec(uip)+p.Results.t_buffer/(24*60*60);
                            else
                                iii = 1:numel(data_struct_new.data_disp);
                            end

                            if isempty(output_h.scatter_feature_h)
                                output_h.scatter_feature_h = scatter3(ax,...
                                    data_struct_new.Lat(iii),...
                                    data_struct_new.Lon(iii),....
                                    data_struct_new.H(iii),...
                                    ms(iii),...
                                    data_struct_new.data_disp(iii),'Tag',tag,'Marker','.','MarkerFaceAlpha','flat','MarkerEdgeAlpha','flat');
                            else
                                output_h.scatter_feature_h.XData = data_struct_new.Lat(iii);
                                output_h.scatter_feature_h.YData = data_struct_new.Lon(iii);
                                output_h.scatter_feature_h.ZData = data_struct_new.H(iii);
                                output_h.scatter_feature_h.CData = data_struct_new.data_disp(iii);
                                output_h.scatter_feature_h.SizeData = ms(iii);
                            end

                            output_h.scatter_feature_h.AlphaDataMapping  = alphadata_mapping;
                            output_h.scatter_feature_h.AlphaData = alpha_data(iii);
                            clim(ax,cax);
                            
                            if p.Results.vert_exa>0 && uip == 1
                                obj.vert_exa = p.Results.vert_exa;
                                obj.vert_ex_edit_h.Value = p.Results.vert_exa;
                                obj.vert_ex_slider_h.Value = p.Results.vert_exa;
                            end

                            if anim_bool
                                ax.XLim = [min(data_struct_new.Lat) max(data_struct_new.Lat)];
                                ax.YLim = [min(data_struct_new.Lon) max(data_struct_new.Lon)];
                                ax.ZLim = [min(data_struct_new.H) max(data_struct_new.H)];

                                pause(dt(uip)/anim_speed);
                                if create_movie
                                    fr_tmp = getframe(obj.echo_fig);
                                    writeVideo(vidfile,fr_tmp);
                                end

                            end
                        end

                        if up_scat
                            obj.scatter_feature_h = [obj.scatter_feature_h output_h.scatter_feature_h];
                        end
                    end

                    if create_movie
                        close(vidfile);
                    end
            end
            pause(0.1);
            clim(ax,cax);
            obj.vert_exa = obj.vert_ex_slider_h.Value;

        end

        function add_text(obj,trans_obj,ax,varargin)
            p = inputParser;
            addRequired(p,'obj',@(x) isa(x,'echo_3D_cl'));
            addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
            addRequired(p,'ax',@(x) isa(x,'matlab.ui.control.UIAxes'));
            addParameter(p,'idx_ping',1,@isnumeric);
            addParameter(p,'text','',@ischar)
            addParameter(p,'tag','',@ischar);
            addParameter(p,'text_h',[],@(x) isempty(x)||ishandle(x));
            parse(p,obj,trans_obj,ax,varargin{:})

            cmap_struct = init_cmap(obj.cmap);
            idx_ping = p.Results.idx_ping;
            if isempty(idx_ping)
                idx_ping = 1;
            end
            text_h_f = p.Results.text_h;
            dd = trans_obj.get_transducer_depth(idx_ping);

            if isempty(text_h_f)||~isvalid(text_h_f)

                if isempty(text_h_f)
                    text_h_tmp = text(ax,trans_obj.GPSDataPing.Lat(idx_ping(1)),...
                        trans_obj.GPSDataPing.Long(idx_ping(1)),...
                        dd,p.Results.text,...
                        'Color',cmap_struct.col_lab,'Rotation',-90,'Interpreter','none','Tag',p.Results.tag,'visible','on');
                    obj.text_h = [obj.text_h text_h_tmp];
                else
                    text_h_f.Position = [trans_obj.GPSDataPing.Lat(idx_ping) trans_obj.GPSDataPing.Long(idx_ping) dd];
                    text_h_f.String = p.Results.text;
                    text_h_f.Tag = p.Results.tag;
                end
            end
        end


        function add_line(obj,trans_obj,ax,varargin) %add_line(obj,trans_obj,ax,'tag',tag_s,'idx_ping',idx_ping,'handle_cell',{output_h.trans_line_h output_h.bot_line_h},'line_type',{'transducer' 'bottom'})
            p = inputParser;
            addRequired(p,'obj',@(x) isa(x,'echo_3D_cl'));
            addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
            addRequired(p,'ax',@(x) isa(x,'matlab.ui.control.UIAxes'));
            addParameter(p,'tag','',@ischar);
            addParameter(p,'idx_ping',[],@isnumeric);
            addParameter(p,'handle_cell',{},@(x) iscell(x)||isempty(x));
            addParameter(p,'line_type',{'transducer'},@(x) iscell(x)||isempty(x));
            parse(p,obj,trans_obj,ax,varargin{:})

            cmap_struct = init_cmap(obj.cmap);

            [data_struct,~]=trans_obj.get_xxx_ENH('data_to_pos',p.Results.line_type,...
                'idx_ping',p.Results.idx_ping);
            
            for uil  = 1:numel(p.Results.line_type)
                if trans_obj.ismb && strcmpi(p.Results.line_type{uil},'bottom')
                    continue;
                end
                data_struct_tmp = data_struct.(p.Results.line_type{uil});

              
                if isempty(p.Results.handle_cell{uil})
                    h_tmp = plot3(ax,...
                        data_struct_tmp.Lat,...
                        data_struct_tmp.Lon,...
                        data_struct_tmp.H,'Color',cmap_struct.col_bot,'Tag',p.Results.tag,'visible','on');
                    switch (p.Results.line_type{uil})
                        case 'transducer'
                            obj.trans_line_h = [obj.trans_line_h h_tmp];
                        case 'bottom'
                            obj.bot_line_h = [obj.bot_line_h h_tmp];
                    end
                else
                    p.Results.handle_cell{uil}.XData = data_struct_tmp.Lat;
                    p.Results.handle_cell{uil}.YData = data_struct_tmp.Lon;
                    p.Results.handle_cell{uil}.ZData = data_struct_tmp.H;
                end
            end

        end


        function add_wc_fan(obj,trans_obj,varargin)

            p = inputParser;
            addRequired(p,'obj',@(x) isa(x,'echo_3D_cl'));
            addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
            addParameter(p,'tag','WC_fan',@ischar);
            addParameter(p,'fieldname','sv',@ischar);
            addParameter(p,'cax',[],@isnumeric);
            addParameter(p,'main_figure',[],@(x) isempty(x)||ishandle(x));
            addParameter(p,'Unique_ID',generate_Unique_ID([]),@ischar);
            addParameter(p,'idx_ping',1,@(x) x>0);
            addParameter(p,'idx_beam',[]);
            addParameter(p,'idx_r',[]);
            addParameter(p,'fandir','across',@(x) ismember(x,{'along' 'across'}));
            addParameter(p,'load_bar_comp',[]);
            parse(p,obj,trans_obj,varargin{:});

  
            cax = p.Results.cax;

            if isempty(cax)
                cax = init_cax(p.Results.fieldname);
            end

            if ~trans_obj.ismb
                return;
            end

            tag_s  =sprintf('%s_%s',p.Results.tag,p.Results.fieldname);

            output_h = obj.get_graphic_handles({'WC_fan_h'},tag_s);
            ax = obj.get_ax_per_tag(p.Results.fieldname);

            if isempty(ax)
                return;
            end
            %new_z_lim = ax.ZLim ;
            idx_ping = p.Results.idx_ping;

            if ~isempty(idx_ping)

                nb_beams = max(trans_obj.Data.Nb_beams);

                nb_samples = max(trans_obj.Data.Nb_samples);

                if isempty(p.Results.idx_r)
                    idx_r = 1:nb_samples;
                else
                    idx_r = p.Results.idx_r;
                end

                if isempty(p.Results.idx_beam)
                    idx_beams = 1:nb_beams;
                else
                    idx_beams = p.Results.idx_beam;
                end

                db = ceil(nb_beams/500);
                dr = ceil(numel(idx_r)/1e3);

                idx_r = idx_r(1:dr:end);
                idx_beams = idx_beams(1:db:end);

                [data,sc,~] = trans_obj.Data.get_subdatamat('field',p.Results.fieldname,'idx_ping',idx_ping,'idx_beam',idx_beams,'idx_r',idx_r);

                switch sc
                    case 'lin'
                        data=10*log10(abs(data));
                    case 'dB'
                        %amp=amp;
                    otherwise
                        %amp=amp;
                end

                [roll_comp_bool,pitch_comp_bool,yaw_comp_bool,heave_comp_bool] = trans_obj.get_att_comp_bool();
                [data_struct,~,]=trans_obj.get_xxx_ENH('data_to_pos',{'WC','bottom'},...
                    'idx_r',idx_r,'idx_ping',idx_ping,'idx_beam',idx_beams,...
                    'comp_angle',[false false],...
                    'yaw_comp',yaw_comp_bool,...
                    'roll_comp',roll_comp_bool,...
                    'pitch_comp',pitch_comp_bool,...
                    'heave_comp',heave_comp_bool);

                if isempty(data)
                    return;
                end

                data  =squeeze(data);
                
                idx_keep = data>=cax(1);
                bot_depth = squeeze(data_struct.bottom.H);
                dd = squeeze(data_struct.WC.H);

                if ~ax.UserData.disp_EN
                    xg = squeeze(data_struct.WC.Lat);
                    yg = squeeze(data_struct.WC.Lon);
                else
                    xg = squeeze(data_struct.WC.E);
                    yg = squeeze(data_struct.WC.N);
                end

                alpha_data =ones(size(data),'single')*6;
                alphadata_mapping = 'direct';
                alpha_data(bot_depth' <= dd) = 2;
                alpha_data(~idx_keep) = 1;

                alpha_data(data<cax(1)|isnan(data))=1;
                
                if isempty(output_h.WC_fan_h)
                    output_h.WC_fan_h = surf(ax,xg,yg,....
                        dd,...
                        data,'Tag',tag_s);
                    output_h.WC_fan_h.FaceLighting = 'none';
                    output_h.WC_fan_h.EdgeLighting  = 'none';
                    output_h.WC_fan_h.EdgeColor = 'none';
                    output_h.WC_fan_h.LineStyle = 'none';
                    output_h.WC_fan_h.EdgeAlpha =  'flat';
                    obj.WC_fan_h = [obj.WC_fan_h output_h.WC_fan_h];
                else
                    output_h.WC_fan_h.XData = xg;
                    output_h.WC_fan_h.YData = yg;
                    output_h.WC_fan_h.ZData = dd;
                    output_h.WC_fan_h.CData = data;
                end

                output_h.WC_fan_h.AlphaDataMapping  = alphadata_mapping;
                output_h.WC_fan_h.AlphaData = alpha_data;
                output_h.WC_fan_h.FaceAlpha= 'flat';
                output_h.WC_fan_h.FaceColor= 'flat';

                uistack(output_h.WC_fan_h,'top');
                clim(ax,cax);
                obj.vert_exa = obj.vert_ex_slider_h.Value;
            end

        end

        function add_3D_echo_int_results(obj,output_3D,varargin)
             p = inputParser;
            addRequired(p,'obj',@(x) isa(x,'echo_3D_cl'));
            addRequired(p,'output_3D',@(x) isstruct(x));
            addParameter(p,'tag','echo_int',@ischar);
            addParameter(p,'dir','horz',@(x) ismember(x,{'horz' 'vert'}));
            addParameter(p,'cax',[],@isnumeric);
            addParameter(p,'main_figure',[],@(x) isempty(x)||ishandle(x));
            addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
            addParameter(p,'load_bar_comp',[]);
            parse(p,obj,output_3D,varargin{:});


            % output_3D = trans_obj.echo_integrate_3D('field',p.Results.field,'ref',p.Results.ref,'output_grid_ref',p.Results.output_grid_ref,...
            %     'rangeBounds',p.Results.rangeBounds,...
            %     'refRangeBounds',p.Results.refRangeBounds,...
            %     'depthBounds',p.Results.depthBounds,...
            %     'BeamAngularLimit',p.Results.BeamAngularLimit,...
            %     'timeBounds',p.Results.timeBounds,...
            %     'horz_res',p.Results.horz_res,'vert_res',p.Results.vert_res,'along_res',p.Results.along_res,'across_res',p.Results.across_res,'load_bar_comp',p.Results.load_bar_comp);
            
            if isempty(output_3D)
                output_3D = obj.output_3D_echoint;
            end

            if isempty(output_3D)
                return;
            end
            cax = p.Results.cax;
            switch p.Results.dir
                case 'horz'
                    ff = 'sa';
                case 'vert'
                    ff = 'sv';
            end
            ax = obj.add_ax_tab(ff);


            if ax.UserData.disp_EN
                ax.UserData.disp_EN = true;
                xg = output_3D.E;
                yg = output_3D.N;
                zg = output_3D.z;
            else
                xg = output_3D.Lat;
                yg =output_3D.Lon;
                zg = output_3D.z;
            end
            data = output_3D.sv;

            switch p.Results.dir
                case 'horz'                  
                    fact = mean(diff(output_3D.z(1,1,:)));
                    id_disp = squeeze(output_3D.z>obj.dmin & output_3D.z<obj.dmax);
                    mean_dir = 3;
                    func_val = @sum;
                case 'vert'
                    fact = 1;
                    id_disp = output_3D.AcrossDist>obj.ac_min & output_3D.AcrossDist<obj.ac_max;
                    data = output_3D.sv;
                    mean_dir = 1;
                    func_val = @mean;
            end

            data(~id_disp) = nan;
            data  = squeeze(pow2db(func_val(data*fact,mean_dir,'omitmissing')));
            xg(~id_disp) = nan;
            yg(~id_disp) = nan;
            zg(~id_disp) = nan;

            xg =   squeeze(mean(xg,mean_dir,'omitmissing'));
            yg =   squeeze(mean(yg,mean_dir,'omitmissing'));
            zg =   squeeze(mean(zg,mean_dir,'omitmissing'));

            if isempty(cax)
                [cax,~,~,AlphaDisp]=init_cax(ff);
            end

            
            h_name = sprintf('echoint_3D_%s_surf_h',p.Results.dir);
            output_h = obj.get_graphic_handles({h_name},p.Results.tag);

            
            
            alpha_data =ones(size(data),'single')*6;
            alphadata_mapping = 'direct';
            alpha_data(data<cax(1)) = 1;

            if isempty(output_h.(h_name))
                output_h.(h_name) = surf(ax,xg,yg,....
                    zg,...
                    data,'Tag',p.Results.tag);
                output_h.(h_name).FaceLighting = 'none';
                output_h.(h_name).EdgeLighting  = 'none';
                output_h.(h_name).EdgeColor = 'none';
                output_h.(h_name).LineStyle = 'none';
                output_h.(h_name).FaceAlpha= 'flat';
                output_h.(h_name).FaceColor= 'flat';
                output_h.(h_name).EdgeAlpha =  'flat';
                output_h.(h_name).AlphaData = alpha_data;
                output_h.(h_name).AlphaDataMapping  = alphadata_mapping;
                obj.(h_name) = [obj.(h_name) output_h.(h_name)];
            else
                output_h.(h_name).XData = xg;
                output_h.(h_name).YData = yg;
                output_h.(h_name).ZData = zg;
                output_h.(h_name).CData = data;
                output_h.(h_name).AlphaData = alpha_data;
                output_h.(h_name).AlphaDataMapping  = alphadata_mapping;
            end
            uistack(output_h.(h_name),'top');
            pause(0.1);
            clim(ax,cax);
            obj.output_3D_echoint = output_3D;

            obj.layer_mean_depth_slider_h.Limits = [max(min(output_3D.z,[],'all','omitmissing'),0) max(output_3D.z,[],'all','omitmissing')];
            obj.layer_thickness_h.Limits = [1 range(output_3D.z,'all')];
            obj.vert_exa = obj.vert_ex_slider_h.Value;

        end

        function add_surface(obj,trans_obj,varargin)

            p = inputParser;
            addRequired(p,'obj',@(x) isa(x,'echo_3D_cl'));
            addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
            addParameter(p,'tag','',@ischar);
            addParameter(p,'BeamAngularLimit',[-inf inf],@(x) all(isnumeric(x)));
            addParameter(p,'rangeBounds',[0 inf],@(x) all(isnumeric(x)));
            addParameter(p,'refRangeBounds',[-inf inf],@(x) all(isnumeric(x)));
            addParameter(p,'depthBounds',[-inf inf],@isnumeric);
            addParameter(p,'vel_disp','normal',@ischar);
            addParameter(p,'cax',[],@isnumeric);
            addParameter(p,'main_figure',[],@(x) isempty(x)||ishandle(x));
            addParameter(p,'fieldname','sv',@ischar);
            addParameter(p,'Unique_ID',generate_Unique_ID([]),@ischar);
            addParameter(p,'Ref','Surface',@(x) ismember(x,list_echo_int_ref));
            addParameter(p,'intersect_only',false,@(x) isnumeric(x)||islogical(x));
            addParameter(p,'idx_regs',[],@isnumeric);
            addParameter(p,'regs',region_cl.empty(),@(x) isa(x,'region_cl'));
            addParameter(p,'select_reg','selected',@ischar);
            addParameter(p,'surv_data',survey_data_cl.empty,@(x) isa(x,'survey_data_cl'))
            addParameter(p,'keep_bottom',false,@(x) isnumeric(x)||islogical(x));
            addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
            addParameter(p,'load_bar_comp',[]);
            parse(p,obj,trans_obj,varargin{:});


            cax = p.Results.cax;

            if isempty(cax)
                cax = init_cax(p.Results.fieldname);
            end

            BeamAngularLimit = p.Results.BeamAngularLimit;
            idx_beams = trans_obj.get_idx_beams(BeamAngularLimit);

            if isempty(p.Results.surv_data)
                surv_data  = survey_data_cl();
                surv_data.StartTime = trans_obj.Time(1);
                surv_data.EndTime = trans_obj.Time(end);
            else
                surv_data = p.Results.surv_data;
            end

            if (isempty(p.Results.idx_regs) && isempty(p.Results.regs)) || p.Results.intersect_only
                reg_obj = trans_obj.create_WC_region('Ref',p.Results.Ref,'t_min',surv_data.StartTime,'t_max',surv_data.EndTime,'idx_beam',round(mean(idx_beams)));
                idx_regs = p.Results.idx_regs;
                regs = p.Results.regs;

                if isempty(p.Results.tag)
                    tag_s_tot = {sprintf('%s_%s_%s_%s',...
                        trans_obj.Config.ChannelID,datestr(surv_data.StartTime,'yyyymmddHHMMSS'),datestr(surv_data.EndTime,'yyyymmddHHMMSS'),p.Results.fieldname)};
                else
                    tag_s_tot = {p.Results.tag};
                end
            else
                reg_obj =    [p.Results.regs trans_obj.Regions(p.Results.idx_regs)];
                idx_regs = [];
                regs = region_cl.empty();
                tag_s_tot = cell(1,numel(reg_obj));
                for uir = 1:numel(reg_obj)
                    tag_s_tot{uir} = sprintf('%s_%s_curtain',reg_obj.Unique_ID,trans_obj.Config.ChannelID);
                end
            end

            fff = {p.Results.fieldname};
            ff = p.Results.fieldname;

            comp_angle_bool = ismember(ff,{'sp' 'spdenoised' 'spunmatched' 'sp_comp' 'singletarget' 'ST TS' 'bathy' 'wc_data'});
            [roll_comp_bool,pitch_comp_bool,yaw_comp_bool,heave_comp_bool] = trans_obj.get_att_comp_bool();
            switch p.Results.fieldname
                case {'sv' 'svdenoised' 'svunmatched' 'feature_sv'}
                    ff = 'sv';
                    roll_comp_bool = false;
                    pitch_comp_bool = false;
                    yaw_comp_bool = false;

                case {'sp' 'spdenoised' 'spunmatched' 'sp_comp' 'singletarget' 'ST TS'}
                    ff = 'ts';
                    
                case 'quiver_velocity'
                    fff = {'sv' 'velocity_north' 'velocity_east' 'velocity_down'};
                case {'velocity' 'velocity_north' 'velocity_east' 'velocity_down'}
            end

            ax = add_ax_tab(obj,ff);
            new_z_lim = ax.ZLim ;
            [~,~,Units,AlphaDisp]=init_cax(p.Results.fieldname);
            [~,~,~,~,default_values]=init_fields(fff{1});

            dr = 1;
            dp = 1;
            db = 1;

            for uir = 1:numel(reg_obj)
                tag_s = tag_s_tot{uir};
                output_h = obj.get_graphic_handles({'curtain_surf_h' 'text_h' 'trans_line_h' 'bot_line_h'},tag_s);

                for uiff = 1:numel(fff)
                    [data.(fff{uiff}),idx_r,idx_ping,idx_beam,bad_data_mask,bad_trans_vec,intersection_mask,below_bot_mask,mask_from_st] = trans_obj.get_data_from_region(reg_obj(uir),...
                        'rangeBounds',p.Results.rangeBounds,...
                        'refRangeBounds',p.Results.refRangeBounds,...
                        'depthBounds',p.Results.depthBounds,...
                        'BeamAngularLimit',BeamAngularLimit,...
                        'timeBounds',[surv_data.StartTime surv_data.EndTime],...
                        'field',fff{uiff},...
                        'intersect_only',p.Results.intersect_only,...
                        'idx_regs',idx_regs,...
                        'regs',regs,...
                        'select_reg',p.Results.select_reg,...
                        'keep_bottom',p.Results.keep_bottom,...
                        'dr',dr,'dp',dp,'db',db);
                end

                is = find(~bad_trans_vec,1,'first');
                ie = find(~bad_trans_vec,1,'last');

                prc_thr = 100-max(log10(1e4/size(data.(fff{1}),2)),1);
                dmax =  prctile(data.(fff{uiff}),prc_thr,[2 3]);
                idx_last= numel(dmax) - find(flipud(dmax>-900),1)+1;
                if isempty(idx_last)
                    idx_last = numel(idx_r);
                end

                for uiff = 1:numel(fff)
                    data.(fff{uiff}) = data.(fff{uiff})(1:idx_last,:,:);
                end
                bad_data_mask = bad_data_mask(1:idx_last,:,:);
                intersection_mask = intersection_mask(1:idx_last,:,:);
                idx_r = idx_r(1:idx_last);
                below_bot_mask = below_bot_mask(1:idx_last,:,:);
                mask_from_st = mask_from_st(1:idx_last,:,:);

                
                % roll_comp_bool = false;
                % pitch_comp_bool = false;
                % yaw_comp_bool = false;
                % heave_comp_bool = false;
                [data_struct,~] = trans_obj.get_xxx_ENH('data_to_pos',{'WC'},...
                    'idx_r',[idx_r(1) idx_r(end)],'idx_ping',idx_ping,'idx_beam',idx_beam,...
                    'comp_angle',[comp_angle_bool comp_angle_bool],...
                    'yaw_comp',yaw_comp_bool,...
                    'roll_comp',roll_comp_bool,...
                    'pitch_comp',pitch_comp_bool,...
                    'heave_comp',heave_comp_bool);
                data_struct = data_struct.WC;

                %Lon_r(Lon_r>180) = Lon_r(Lon_r>180)-360;


                if ~isempty(is)&&~isempty(ie)
                    idx_ping = idx_ping(is:ie);
                    bad_data_mask = bad_data_mask(:,is:ie,:);

                    for uiff = 1:numel(fff)
                        data.(fff{uiff}) = data.(fff{uiff})(:,is:ie,:);
                    end
                    intersection_mask = intersection_mask(:,is:ie,:);
                    below_bot_mask = below_bot_mask(:,is:ie,:);
                    mask_from_st = mask_from_st(:,is:ie,:);
                    bad_trans_vec = bad_trans_vec(is:ie);
                end

                for uiff = 1:numel(fff)
                    data.(fff{uiff})(repmat(~intersection_mask,1,1,size(data.(fff{uiff}),3))) = nan;
                end


                sub_p = ceil(numel(idx_ping)/1e4/5);
                sub_r = ceil(numel(idx_r)/(2*1e3));

                idx_r_min = min(idx_r,[],'omitnan')+1;
                %idx_p_min = min(idx_ping,[],'omitnan')+1;

                index_r = ceil((1:numel(idx_r))'/sub_r);
                %index_r = index_r-min(index_r,[],'omitnan')+1;
                index_p = ceil((1:numel(idx_ping))/sub_p);
                %index_p = index_p-min(index_p,[],'omitnan')+1;

                index_r_mat = repmat(index_r,1,numel(index_p),size(data.(fff{1}),3));
                index_p_mat = repmat(index_p,numel(index_r),1,size(data.(fff{1}),3));

                [~,ip] = unique(index_p);
                [~,ir] = unique(index_r);

                cax  = p.Results.cax;

                bad_data_mask(:,bad_trans_vec,:) = true;

                bd = repmat(~bad_data_mask,1,1,size(data.(fff{1}),3));

                if contains(Units,'dB')
                    %func = @(x) pow2db_perso(mean(db2pow_perso(x),'omitnan'));
                        func = @(x) max(x,[],'omitnan');
                else
                        func = @(x) mean(x,'omitnan');
                end

                for uiff = 1:numel(fff)
                    data.(fff{uiff})((data.(fff{uiff}) == default_values)) = nan;
                    data_sub.(fff{uiff}) = accumarray([index_r_mat(bd) index_p_mat(bd)],data.(fff{uiff})(bd),[numel(ir) numel(ip)],func,default_values);
                end

                below_bot_sub = accumarray([index_r_mat(bd) index_p_mat(bd)],below_bot_mask(bd),[numel(ir) numel(ip)],@(x) sum(x)>size(data.(fff{1}),3)/4,false);

                E_r_exp = interp1([idx_r(1) idx_r(end)],data_struct.E,idx_r);
                N_r_exp = interp1([idx_r(1) idx_r(end)],data_struct.N,idx_r);
                Along_dist_struct_exp = interp1([idx_r(1) idx_r(end)],data_struct.AlongDist,idx_r);
                
                E_r_exp_sub = accumarray([index_r_mat(bd) index_p_mat(bd)],double(E_r_exp(bd)),[numel(ir) numel(ip)],@(x) mean(x,'omitnan'),nan);
                N_r_exp_sub = accumarray([index_r_mat(bd) index_p_mat(bd)],double(N_r_exp(bd)),[numel(ir) numel(ip)],@(x) mean(x,'omitnan'),nan);
                Along_dist_struct_exp_sub = accumarray([index_r_mat(bd) index_p_mat(bd)],double(Along_dist_struct_exp(bd)),[numel(ir) numel(ip)],@(x) mean(x,'omitnan'),nan);

                data_struct.Zone(isnan(data_struct.Zone)) = round(mean(data_struct.Zone,'all','omitnan'));

                [lat_r_exp_sub,lon_r_exp_sub] = utm2ll(E_r_exp_sub(:),N_r_exp_sub(:),data_struct.Zone(1));

                lat_r_exp_sub = reshape(lat_r_exp_sub,size(E_r_exp_sub));
                lon_r_exp_sub = reshape(lon_r_exp_sub,size(N_r_exp_sub));


                %alpha_map_fig=get(main_figure,'alphamap')%6 elts vector: first: empty, second: under clim(1), third: underbottom, fourth: bad trans, fifth regions, sixth normal]

                alpha_data =ones(size(data_sub.(fff{1})),'single')*6;
                alphadata_mapping = 'direct';

                switch AlphaDisp
                    case {'SpCaxBounds' 'CorrCaxBounds'}
                        switch AlphaDisp
                            case 'SpCaxBounds'
                                field={'sp'};
                                if ismember('spdenoised',trans_obj.Data.Fieldname)
                                    field={'spdenoised'};
                                end
                            case 'CorrCaxBounds'
                                field = {'sv' 'correlation'};
                        end
                        cc = get_esp3_prop('curr_disp');
                        for uiff  =1:numel(field)
                            data_sec = trans_obj.Data.get_subdatamat('idx_r',unique(index_r)*sub_r+idx_r_min-1,'idx_ping',idx_ping(index_p)*sub_p,'field',field{uiff});
                            if isempty(cc)
                                cax_sec = init_cax(field{uiff});
                                cax = init_cax('sv');
                            else
                                cax_sec=cc.getCaxField(field{uiff});
                                cax = cc.getCaxField('sv');
                            end
                            alpha_data(below_bot_sub) = 2;
                            if ~isempty(data_sec)
                                alpha_data(data_sec<cax_sec(1)) = 1;
                            end
                        end
                    case 'InfBounds'

                    case 'AlphaNormed'
                        alpha_data = data_sub.(fff{1}) - min(data_sub.(fff{1}),[],'all');
                        alpha_data = alpha_data./max(alpha_data,[],'all');
                        cax = prctile(data_struct.H,[10 90],'all');
                        alphadata_mapping = 'none';
                    case 'CaxBounds'
                        alpha_data(below_bot_sub) = 2;
                        alpha_data(data_sub.(fff{1})<cax(1)|isnan(data_sub.(fff{1})))=1;
                end


                dd = trans_obj.get_samples_depth(idx_r(ir),idx_ping(ip),idx_beam);

                idx_r_min = find(any(data_sub.(fff{1})>-180,2),1,'first');
                idx_r_max = find(any(data_sub.(fff{1})>-180,2),1,'last');
                idx_r_new = idx_r_min:idx_r_max;

                if isempty(idx_r_new)
                    return;
                end

                if trans_obj.ismb
                    dd = squeeze(dd(:,:,ceil(size(dd,3)/2)));
                end

                dd = dd(idx_r_new,:);
                for uiff = 1:numel(fff)
                    data_sub.(fff{uiff}) = data_sub.(fff{uiff})(idx_r_new,:);
                end
                lon_r_exp_sub = lon_r_exp_sub(idx_r_new,:);

                lat_r_exp_sub = lat_r_exp_sub(idx_r_new,:);
                alpha_data= alpha_data(idx_r_new,:);

               
                if ax.UserData.disp_EN
                    ax.UserData.disp_EN = true;
                    xg = E_r_exp_sub;
                    yg = N_r_exp_sub;
                else
                    obj.add_text(trans_obj,ax,'tag',tag_s,'idx_ping',idx_ping(1),'text_h',output_h.text_h,'text',surv_data.print_survey_data);
                    obj.add_line(trans_obj,ax,'tag',tag_s,'idx_ping',idx_ping,'handle_cell',{output_h.trans_line_h output_h.bot_line_h},'line_type',{'transducer' 'bottom'});
                    xg = lat_r_exp_sub;
                    yg = lon_r_exp_sub;
                end


                if isempty(output_h.curtain_surf_h)
                    output_h.curtain_surf_h = surf(ax,xg,yg,....
                        dd,...
                        data_sub.(fff{1}),'Tag',tag_s);
                    output_h.curtain_surf_h.FaceLighting = 'none';
                    output_h.curtain_surf_h.EdgeLighting  = 'none';
                    output_h.curtain_surf_h.EdgeColor = 'none';
                    output_h.curtain_surf_h.LineStyle = 'none';
                    output_h.curtain_surf_h.FaceAlpha= 'flat';
                    output_h.curtain_surf_h.FaceColor= 'flat';
                    output_h.curtain_surf_h.EdgeAlpha =  'flat';
                    output_h.curtain_surf_h.AlphaData = alpha_data;
                    output_h.curtain_surf_h.AlphaDataMapping  = alphadata_mapping;
                    obj.curtain_surf_h = [obj.curtain_surf_h output_h.curtain_surf_h];
                else
                    output_h.curtain_surf_h.XData = xg;
                    output_h.curtain_surf_h.YData = yg;
                    output_h.curtain_surf_h.ZData = dd;
                    output_h.curtain_surf_h.CData = data_sub.(fff{1});
                    output_h.curtain_surf_h.AlphaData = alpha_data;
                    output_h.curtain_surf_h.AlphaDataMapping  = alphadata_mapping;
                end
                uistack(output_h.curtain_surf_h,'top');
                
                if strcmpi(p.Results.fieldname,'quiver_velocity')

                    delete(output_h.cone_h)
                    res_along = 10;
                    res_z = 5;

                    idx_E = round((Along_dist_struct_exp_sub-min(Along_dist_struct_exp_sub,[],'all'))/res_along)+1;
                    idx_d = round((dd-min(dd,[],'all'))/res_z)+1;

                    E_C = accumarray([idx_E(:) idx_d(:)],E_r_exp_sub(:),[],@(x) mean(x,'omitnan'),nan);
                    N_C = accumarray([idx_E(:) idx_d(:)],N_r_exp_sub(:),[],@(x) mean(x,'omitnan'),nan);
                    H_C = accumarray([idx_E(:) idx_d(:)],dd(:),[],@(x) mean(x,'omitnan'),nan);
                    U_C = accumarray([idx_E(:) idx_d(:)],data_sub.(fff{2})(:),[],@(x) mean(x,'omitnan'),nan);
                    V_C = accumarray([idx_E(:) idx_d(:)],data_sub.(fff{3})(:),[],@(x) mean(x,'omitnan'),nan);
                    W_C = accumarray([idx_E(:) idx_d(:)],data_sub.(fff{4})(:),[],@(x) mean(x,'omitnan'),nan);

                    fact  = [1 1 1];
                    hcone = coneplot(ax,E_C,N_C,H_C,U_C*fact(1),V_C*fact(2),W_C*fact(3),0.1,'nointerp','Tag',tag_s );

                    hcone.FaceColor = 'red';
                    hcone.EdgeColor = 'none';

                    obj.cone_h  = [obj.cone_h hcone];

                end


                tmp = [min(dd(:),[],'omitnan') max(dd(:),[],'omitnan')];
                tmp = tmp+[-0.05 0.05]*range(tmp);

                if ~all(new_z_lim == [0 1])
                    new_z_lim = [min(min(tmp,new_z_lim)) max(max(tmp,new_z_lim))];
                else
                    new_z_lim = tmp;
                end
            end
            ax.ZLim = new_z_lim ;
            
            clim(ax,cax);
            obj.vert_exa = obj.vert_ex_slider_h.Value;

        end

        function rem_surface(obj,trans_obj,varargin)

            p = inputParser;
            addRequired(p,'obj',@(x) isa(x,'echo_3D_cl'));
            addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
            addParameter(p,'tag','',@ischar);
            addParameter(p,'surv_data',survey_data_cl.empty,@(x) isa(x,'survey_data_cl'))
            addParameter(p,'load_bar_comp',[]);
            parse(p,obj,trans_obj,varargin{:});

            if ~isempty(p.Results.tag)
                tag_s = p.Results.tag;
            else
                if isempty(p.Results.surv_data)
                    surv_data  = survey_data_cl();
                    surv_data.StartTime = trans_obj.Time(1);
                    surv_data.EndTime = trans_obj.Time(end);
                else
                    surv_data = p.Results.surv_data;
                end

                tag_s = sprintf('%s_%s_%s',trans_obj.Config.ChannelID,datestr(surv_data.StartTime,'yyyymmddHHMMSS'),datestr(surv_data.EndTime,'yyyymmddHHMMSS'));
            end

            output_h = obj.get_graphic_handles(tag_s);
            delete(output_h.curtain_surf_h);
            delete(output_h.bot_line_h);
            delete(output_h.trans_line_h);
            delete(output_h.text_h);
            delete(output_h.cone_h);

            obj.clean_handles();

        end


        function rem_bathy(obj,trans_obj,varargin)

            p = inputParser;
            addRequired(p,'obj',@(x) isa(x,'echo_3D_cl'));
            addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
            addParameter(p,'tag','',@ischar);
            addParameter(p,'load_bar_comp',[]);
            parse(p,obj,trans_obj,varargin{:});

            if ~isempty(p.Results.tag)
                tag_s = p.Results.tag;
            else

                tag_s = 'bathy';
            end

            output_h = obj.get_graphic_handles(tag_s);
            delete(output_h.bathy_surf_h);

            obj.clean_handles();

        end

        function clean_handles(obj)
            obj.curtain_surf_h(~isvalid(obj.curtain_surf_h))=[];
            obj.bot_line_h(~isvalid(obj.bot_line_h))=[];
            obj.text_h(~isvalid(obj.text_h))=[];
            obj.trans_line_h(~isvalid(obj.trans_line_h))=[];
            obj.bathy_surf_h(~isvalid(obj.bathy_surf_h))=[];
            obj.WC_fan_h(~isvalid(obj.WC_fan_h))=[];

        end

        function parent_h = init_echo_3D_fig(obj)
            obj.echo_fig = new_echo_figure(get_esp3_prop('main_figure'),'Units','Pixels',...
                'Name','3D view','Tag','3D view','WhichScreen','other','UiFigureBool',true,'CloseRequestFcn',@rm_3d_echo_obj);
            parent_h  = uigridlayout(obj.echo_fig,[1,2]);
            parent_h.ColumnWidth = {200,'1x'};
            function rm_3d_echo_obj(src,~)
                delete(obj);
                delete(src);
            end
        end

        function vert_ex = get_vert_exa(obj,src)
            switch class(src)
                case 'matlab.ui.control.NumericEditField'
                    vert_ex = obj.vert_ex_edit_h.Value;
                    obj.vert_ex_slider_h.Value = vert_ex;
                case 'matlab.ui.control.Slider'
                    vert_ex = obj.vert_ex_slider_h.Value;
                    obj.vert_ex_edit_h.Value = vert_ex;
                case 'double'
                    vert_ex = src;
                    obj.vert_ex_edit_h.Value = vert_ex;
                    obj.vert_ex_slider_h.Value = vert_ex;
            end
        end

        function change_vert_exa(obj,src,~)
            obj.vert_exa = get_vert_exa(obj,src); 
        end

        function update_vert_ex_edit_h(obj,~,evt)
            vert_ex = evt.Value;
            obj.vert_ex_edit_h.Value = vert_ex;
        end

        function update_grid_size(obj,~,evt)
            obj.grid_size = evt.Value;
            
            obj.add_bathy(layer_cl.empty,'tag','bathy','regrid',true);
        end

        function update_echoint(obj,src,evt)
            switch src.Tag
                case 'layer_thickness_h' 
                    dir = 'horz';
                case 'layer_mean_depth_slider_h'
                    obj.layer_mean_depth_edit_h.Value = evt.Value;
                    dir = 'horz';
                case 'layer_mean_depth_edit_h'
                     obj.layer_mean_depth_slider_h.Value = evt.Value;
                     dir = 'horz';
            end
            obj.dmin = max(obj.layer_mean_depth_slider_h.Value-obj.layer_thickness_h.Value/2,0);
            obj.dmax = min(obj.layer_mean_depth_slider_h.Value+obj.layer_thickness_h.Value/2,obj.layer_thickness_h.Limits(2));
            switch evt.EventName
                case 'ValueChanging'

                case 'ValueChanged'
                    obj.add_3D_echo_int_results(struct.empty,'dir',dir);
            end

        end

        function update_grid_meth(obj,~,evt)
            obj.grid_meth = evt.Value;
            obj.add_bathy(layer_cl.empty,'tag','bathy','regrid',true);
        end

        function delete(obj)
            delete(obj.linked_props);
            if isvalid(obj.ax_tab_group)
                delete(findall(obj.ax_3D));
                esp3_obj=getappdata(groot,'esp3_obj');
                esp3_obj.echo_3D_obj = echo_3D_cl.empty();
            end
        end

       function set_graphic_handle_vis(obj,metaProp,eventData)

         fields = fieldnames(obj.obj_vis);
         for uif = 1:numel(fields)
            if ~isempty(obj.(fields{uif}))
                for uih = 1:numel(obj.(fields{uif}))
                    obj.(fields{uif})(uih).Visible = obj.obj_vis.(fields{uif});
                end
            end
         end
       end

       function set_vert_exa(obj,metaProp,eventData)
           vert_ex = obj.vert_exa;
            for ui = 1:numel(obj.ax_3D)

                ax = obj.ax_3D(ui);
                d = ax.DataAspectRatio;

                xx_rad = mean(ax.XLim)/180*pi;
                % yy_rad = mean(ax.YLim)/180*pi;
                
                r_earth = 6378*1e3;
                % dx_deg = diff(ax.XLim);
                % dx_rad = dx_deg/180*pi;
                % dx_m = dx_rad*r_earth*cos(xx_rad);

                % dy_deg = diff(ax.YLim);
                % dy_rad = dy_deg/180*pi;
                % dy_m = dy_rad*r_earth;
                % dz_m = diff(ax.ZLim);

                    
                if vert_ex>0
                    if ax.UserData.disp_EN
                        d = [1 1 1/vert_ex];
                    else
                        d(3) = 1/vert_ex*(r_earth)/180*pi;
                        d(1) = 1;
                        d(2) = d(1) / cos(xx_rad);
                        d = d/min(d);
                    end
                    daspect(ax,d);
                end
            end
       end
   end
end


