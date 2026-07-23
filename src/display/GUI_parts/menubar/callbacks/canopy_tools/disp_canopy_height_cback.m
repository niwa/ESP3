function disp_canopy_height_cback(~,~,main_figure)

    layer = get_current_layer();
    layers = get_esp3_prop('layers');
    app_path_main=whereisEcho();
    esp3_icon = fullfile(app_path_main,'icons','echoanalysis.png');
    esp3_obj = getappdata(groot,'esp3_obj');
    main_figure = get_esp3_prop('main_figure');
    curr_disp  = esp3_obj.curr_disp;

    app_path = get_esp3_prop('app_path');
    path_save = append(app_path.results.Path_to_folder,'\','Canopy_results');
	
	if isfile(append(app_path.data_root.Path_to_folder,'\private\canopy\ESP3_canopy_maps.exe'))
		if ~isfolder(path_save)
			mkdir(path_save) 
		end

				if isempty(layers)
				return;
			end
			
			data_struct.Time = [];
			data_struct.Ping_number = [];
			data_struct.Sample_number = [];
			data_struct.Bathy = [];
			data_struct.Height = [];
			data_struct.Lat = [];
			data_struct.Lon = [];
			
			win_size = 21;
			
			for uilay = 1 : numel(layers)
				trans_obj = layers(uilay).get_trans(curr_disp);
				idx = layers(uilay).get_lines_per_Tag('canopy');
			
				if isempty(trans_obj) || isempty(layers(uilay).Lines) || isempty(idx)
					continue;
				end
			
				nb_lines=numel(layers(uilay).Lines);
				lines_tab_comp=getappdata(main_figure,'Lines_tab');
				line_obj = layers(uilay).Lines(min(nb_lines,get(lines_tab_comp.tog_line,'value')));
			
				if size(layers(uilay).SurveyData,2)>1
					interid = intersect(find(line_obj.Time<=trans_obj.Time(end)),find(line_obj.Time>=trans_obj.Time(1)));
			
					curr_dist=trans_obj.GPSDataPing.Dist(interid)';
			
					[~,~,r_line] = line_obj.get_time_dist_and_range_corr(trans_obj.get_transceiver_time(),curr_dist);
					r_line = r_line(interid);
					r_bot = trans_obj.get_bottom_range();
					r_bot = r_bot(interid);
					d_bot = trans_obj.get_bottom_depth();
					d_bot = d_bot(interid);
				
					if numel(r_bot)>2*win_size
						d_bot = filter2_perso(gausswin(win_size)',d_bot);
						r_bot = filter2_perso(gausswin(win_size)',r_bot);
					end
				
					data_struct.Time = datestr(trans_obj.Time(interid),'yyyy-mm-dd HH:MM:SS');
					data_struct.Ping_number = 1:size(trans_obj.Time(interid),2);

					sidx = nan(size(r_bot,2),1);
					if size(line_obj.Range,2)<size(line_obj.Range,1)&&size(line_obj.Range,2)==1
						for ir=1:size(line_obj.Range,1)
							sidx(ir,1) = find(abs(trans_obj.Range-r_line(ir))==min(abs(trans_obj.Range-r_line(ir))));
						end
					else
						for ir=1:size(line_obj.Range,2)
							sidx(ir,1) = find(abs(trans_obj.Range-r_line(ir))==min(abs(trans_obj.Range-r_line(ir))));
						end
					end
					data_struct.Sample_number = sidx;
					data_struct.Bathy = [data_struct.Bathy r_bot];
					data_struct.Height = [data_struct.Height r_bot-r_line];
					data_struct.Lat = [data_struct.Lat trans_obj.GPSDataPing.Lat(interid)];
					data_struct.Lon = [data_struct.Lon trans_obj.GPSDataPing.Long(interid)];
			
				else
					curr_dist=trans_obj.GPSDataPing.Dist(:)';
				
					[~,~,r_line] = line_obj.get_time_dist_and_range_corr(trans_obj.get_transceiver_time(),curr_dist);
					r_bot = trans_obj.get_bottom_range();
					d_bot = trans_obj.get_bottom_depth();
				
					if numel(r_bot)>2*win_size
						d_bot = filter2_perso(gausswin(win_size)',d_bot);
						r_bot = filter2_perso(gausswin(win_size)',r_bot);
					end
				
					data_struct.Time = datestr(trans_obj.Time,'yyyy-mm-dd HH:MM:SS');
					data_struct.Ping_number = 1:size(trans_obj.Time,2);

					sidx = nan(size(r_bot,2),1);
					if size(line_obj.Range,2)<size(line_obj.Range,1)&&size(line_obj.Range,2)==1
						for ir=1:size(line_obj.Range,1)
							sidx(ir,1) = find(abs(trans_obj.Range-r_line(ir))==min(abs(trans_obj.Range-r_line(ir))));
						end
					else
						for ir=1:size(line_obj.Range,2)
							sidx(ir,1) = find(abs(trans_obj.Range-r_line(ir))==min(abs(trans_obj.Range-r_line(ir))));
						end
					end
					data_struct.Sample_number = sidx;
					data_struct.Bathy = [data_struct.Bathy r_bot];
					data_struct.Height = [data_struct.Height r_bot-r_line];
					data_struct.Lat = [data_struct.Lat trans_obj.GPSDataPing.Lat];
					data_struct.Lon = [data_struct.Lon trans_obj.GPSDataPing.Long];
				end
			
			end
			data_struct.Height(data_struct.Height<0) = 0;
			
			if isempty(data_struct.Lon)
				return;
			end
			
			data_struct.Biovolume_prc = data_struct.Height./data_struct.Bathy*100;
			
			%% Saving files
			app_path = get_esp3_prop('app_path');
			path_save = append(app_path.results.Path_to_folder,'\','Canopy_results');
			if ~isfolder(path_save)
				mkdir(path_save) 
			end
			
			%path_root = app_path.data_root;
			
			[~,file_start,~] = fileparts(layers(1).Filename{1});
			[~,file_end,~] = fileparts(layers(end).Filename{end});
			
			lat = data_struct.Lat;
			lon = data_struct.Lon;
			height = data_struct.Height;
			bio = data_struct.Biovolume_prc;
			bathy = data_struct.Bathy;
			
			save(append(path_save,'\','lat.mat'),"lat")
			save(append(path_save,'\','lon.mat'),"lon")
			save(append(path_save,'\','canopy_height.mat'),"height")
			save(append(path_save,'\','biovolume.mat'),"bio")
			save(append(path_save,'\','bathymetry.mat'),"bathy")
			
			if strcmp(file_start,file_end)
				save(append(path_save,'\','file_start.mat'),"file_start")
			else
				save(append(path_save,'\','file_start.mat'),"file_start")
				save(append(path_save,'\','file_end.mat'),"file_end")
			end


		%% Maps diplay tool
		
		reg_fig=new_echo_figure(main_figure,'UiFigureBool',true,...
			'WindowStyle','normal','Resize','off',...
			'Position',[697 311 560 660],...
			'Name','Choose parameters to display maps','Tag','create_reg');
		
		uicontrol(reg_fig, ...
			'Style','text',...
			'BackgroundColor','white',...
			'Units','normalized',...
			'Position',[0.2 0.85 0.6 0.1],...
			'fontsize',14,...
			'String','Canopy detection maps');
		
		named_colorscales={'aggrnyl',
		 'agsunset',
		 'blackbody',
		 'bluered',
		 'blues',
		 'blugrn',
		 'bluyl',
		 'brwnyl',
		 'bugn',
		 'bupu',
		 'burg',
		 'burgyl',
		 'cividis',
		 'darkmint',
		 'electric',
		 'emrld',
		 'gnbu',
		 'greens',
		 'greys',
		 'hot',
		 'inferno',
		 'jet_r',
		 'magenta',
		 'magma',
		 'mint',
		 'orrd',
		 'oranges',
		 'oryel',
		 'peach',
		 'pinkyl',
		 'plasma',
		 'plotly3',
		 'pubu',
		 'pubugn',
		 'purd',
		 'purp',
		 'purples',
		 'purpor',
		 'rainbow_r',
		 'rdbu',
		 'rdpu',
		 'redor',
		 'reds',
		 'sunset',
		 'sunsetdark',
		 'teal',
		 'tealgrn',
		 'turbo_r',
		 'viridis',
		 'ylgn',
		 'ylgnbu',
		 'ylorbr',
		 'ylorrd',
		 'algae',
		 'amp',
		 'deep',
		 'dense',
		 'gray',
		 'haline',
		 'ice',
		 'matter',
		 'solar',
		 'speed',
		 'tempo',
		 'thermal',
		 'turbid',
		 'armyrose',
		 'brbg',
		 'earth',
		 'fall',
		 'geyser',
		 'prgn',
		 'piyg',
		 'picnic',
		 'portland',
		 'puor',
		 'rdgy',
		 'rdylbu',
		 'rdylgn',
		 'spectral',
		 'tealrose',
		 'temps',
		 'tropic',
		 'balance',
		 'curl',
		 'delta',
		 'oxy',
		 'edge',
		 'hsv',
		 'icefire',
		 'phase',
		 'twilight',
		 'mrybm',
		 'mygbm'};
		default_color = 22;
		
		%% Colorscale bathy
		% text
		uicontrol(reg_fig,...
			'Style','Text',...
			'BackgroundColor','white',...
			'String','Colorscale bathy:',...
			'units','normalized',...
			'TooltipString',['Choose the colorscale to be used for bathymetry maps' newline...
			'See colorscales pop up window'],...
			'HorizontalAlignment','right',...
			'Position',[0 0.70 0.26 0.07]);
		
		% value
		bathyc = uicontrol(reg_fig,...
			'Style','popupmenu',...
			'String',named_colorscales,...
			'Value',default_color,...
			'units','normalized',...
			'TooltipString',['Choose the colorscale to be used for bathymetry maps' newline...
			'See colorscales pop up window'],...
			'Position',[0.27 0.68 0.2 0.1]);

		
		%% Zoom level
		% text
		default_zoom=10;
		uicontrol(reg_fig,...
			'Style','Text',...
			'BackgroundColor','white',...
			'String','Zoom level:',...
			'units','normalized',...
			'HorizontalAlignment','right',...
			'TooltipString','Choose the start zoom level for your maps [0 24]',...
			'Position',[0.49 0.55 0.26 0.07]);
		
		% value
		zl = uicontrol(reg_fig,...
			'Style','edit',...
			'unit','normalized',...
			'position',[0.78 0.55 0.1 0.07],...
			'string',default_zoom,...
			'TooltipString','Choose the start zoom level for your maps [0 24]',...
			'Tag','w');
		
		
		%% Colorscale Biovolume
		% possible values and default
		named_colorscales_bio_height={'aggrnyl',
		 'agsunset',
		 'blackbody_r',
		 'bluered',
		 'blues',
		 'blugrn',
		 'bluyl',
		 'brwnyl',
		 'bugn',
		 'bupu',
		 'burg',
		 'burgyl',
		 'cividis',
		 'darkmint',
		 'electric',
		 'emrld',
		 'gnbu',
		 'greens',
		 'greys',
		 'hot',
		 'inferno',
		 'jet',
		 'magenta',
		 'magma',
		 'mint',
		 'orrd',
		 'oranges',
		 'oryel',
		 'peach',
		 'pinkyl',
		 'plasma', 
		 'plotly3',
		 'pubu',
		 'pubugn',
		 'purd',
		 'purp',
		 'purples',
		 'purpor',
		 'rainbow',
		 'rdbu_r',
		 'rdpu',
		 'redor',
		 'reds',
		 'sunset',
		 'sunsetdark',
		 'teal',
		 'tealgrn',
		 'turbo',
		 'viridis',
		 'ylgn',
		 'ylgnbu',
		 'ylorbr',
		 'ylorrd',
		 'algae',
		 'amp',
		 'deep',
		 'dense',
		 'gray',
		 'haline',
		 'ice',
		 'matter',
		 'solar',
		 'speed',
		 'tempo',
		 'thermal',
		 'turbid',
		 'armyrose',
		 'brbg',
		 'earth',
		 'fall',
		 'geyser',
		 'prgn',
		 'piyg',
		 'picnic',
		 'portland',
		 'puor',
		 'rdgy',
		 'rdylbu',
		 'rdylgn',
		 'spectral',
		 'tealrose',
		 'temps',
		 'tropic',
		 'balance',
		 'curl',
		 'delta',
		 'oxy',
		 'edge',
		 'hsv',
		 'icefire',
		 'phase',
		 'twilight',
		 'mrybm',
		 'mygbm'};
		default_color2 = 3;
		default_color3 = 22;
		
		% text
		uicontrol(reg_fig,...
			'Style','Text',...
			'String','Colorscale bio:',...
			'units','normalized',...
			'TooltipString',['Choose the colorscale to be used for biovolume maps' newline...
			'See colorscales pop up window'],...
			'HorizontalAlignment','right',...
			'BackgroundColor','white',...
			'Position',[0.5 0.70 0.27 0.07]);
		
		% value
		bioc = uicontrol(reg_fig,...
			'Style','popupmenu',...
			'String',named_colorscales_bio_height,...
			'Value',default_color2,...
			'units','normalized',...
			'TooltipString',['Choose the colorscale to be used for biovolume maps' newline...
			'See colorscales pop up window'],...
			'Position',[0.78 0.68 0.2 0.1]);

		
		%% Colorscale height
		
		% text
		uicontrol(reg_fig,...
			'Style','Text',...
			'String','Colorscale height:',...
			'units','normalized',...
			'TooltipString',['Choose the colorscale to be used for canopy height maps' newline...
			'See colorscales pop up window'],...
			'HorizontalAlignment','right',...
			'BackgroundColor','white',...
			'Position',[0 0.55 0.26 0.07]);
		
		% value
		heightc = uicontrol(reg_fig,...
			'Style','popupmenu',...
			'String',named_colorscales_bio_height,...
			'Value',default_color3,...
			'units','normalized',...
			'TooltipString',['Choose the colorscale to be used for canopy height maps' newline...
			'See colorscales pop up window'],...
			'Position',[0.27 0.555 0.2 0.1]);


		%% Map base
		basemaps_vals={"open-street-map",
		"satellite",    
		"carto-positron",
		"carto-darkmatter",
		"white-bg"};
		default_basemap = 2;
		
		% text
		uicontrol(reg_fig,...
			'Style','Text',...
			'String','Basemap for all maps:',...
			'units','normalized',...
			'TooltipString','Choose the basemap to be used for all maps',...
			'HorizontalAlignment','right',...
			'BackgroundColor','white',...
			'Position',[0 0.42 0.26 0.07]);
		
		% value
		map_base = uicontrol(reg_fig,...
			'Style','popupmenu',...
			'String',basemaps_vals,...
			'Value',default_basemap,...
			'units','normalized',...
			'TooltipString','Choose the basemap to be used for all maps',...
			'Position',[0.27 0.425 0.2 0.1]);


		%% Point size
		
		% text
		uicontrol(reg_fig,...
			'Style','Text',...
			'BackgroundColor','white',...
			'String','Point size:',...
			'units','normalized',...
			'HorizontalAlignment','right',...
			'TooltipString','Choose the point size for scatter plots',...
			'Position',[0.49 0.45 0.26 0.07]);
		
		% value
		points = uicontrol(reg_fig,...
			'Style','edit',...
			'unit','normalized',...
			'position',[0.78 0.457 0.1 0.07],...
			'string',8,...
			'TooltipString','Choose the point size for scatter plots',...
			'Tag','h');


		
		%% Interpolation method
		interp_methods={"none",
		"linear",    
		"cubic",
		"nearest"}; 
		default_interp = 1;
		
		% text
		uicontrol(reg_fig,...
			'Style','Text',...
			'String','Interpolation method:',...
			'units','normalized',...
			'TooltipString',['Choose the interpolation method for interpolated bathymetry,biovolume and canopy height estimation maps' newline...
			'If none is selected no maps with interpolated data values will be produced'],...
			'HorizontalAlignment','right',...
			'BackgroundColor','white',...
			'Position',[0 0.29 0.26 0.07]);
		
		% value
		interp_method = uicontrol(reg_fig,...
			'Style','popupmenu',...
			'String',interp_methods,...
			'Value',default_interp,...
			'units','normalized',...
			'TooltipString',['Choose the interpolation method for interpolated bathymetry,biovolume and canopy height estimation maps' newline...
			'If none is selected no maps with interpolated data values will be produced'],...
			'Position',[0.27 0.295 0.2 0.1]);

		
		%% RUN BUTTON
		uicontrol(reg_fig,...
			'Style','pushbutton',...
			'units','normalized',...
			'string','Run',...
			'pos',[0.35 0.04 0.25,0.1],...
			'TooltipString','Run canopy maps display tool',...
			'HorizontalAlignment','left',...
			'BackgroundColor','red',...
			'callback',{@run_canopy_maps});
		
		%% Display colorscale help figure button    
		display_help = uicontrol(reg_fig,...
			'Style','Radiobutton',...
			'String','Colormaps doc',...
			'TooltipString','Display help on colorscales (pop up windows)',...
			'Value',0,...
			'BackgroundColor',[1 1 1],...
			'Position',[150 100 100 100],...
			'callback',{@disp_help});

		%% Save files or not (cvs and shp)
			uicontrol(reg_fig,...
			'Style','pushbutton',...
			'units','normalized',...
			'string',['Save' newline...
			'results'],...
			'pos',[0.78 0.32 0.1,0.1],...
			'TooltipString','Save results to .csv or .shp files',...
			'HorizontalAlignment','left',...
			'BackgroundColor','green',...
			'callback',{@save_canopy_files});
		
		
		% %% Choose files or not
		% 
		% reopen_data = uicontrol(reg_fig,...
		%     'Style','Radiobutton',...
		%     'String','Choose files',...
		%     'TooltipString',['Choose data files you want displayed' newline...
		%     'If left unchecked, the algorithm will work on the current layer if it was already processed for canopy detection'],...
		%     'Value',0,...
		%     'BackgroundColor',[1 1 1],...
		%     'Position',[350 100 100 100],...
		%     'callback',{@reopening_files});
		
		
		%% make window visible
		set(reg_fig,'visible','on');
		
		%% sub functions
		function disp_help(~,~) 
			path_to_colorscales_plot = append(app_path.data_root.Path_to_folder,'\docs\canopy_colorscales.png');
			switch display_help.Value
				case 1
					reg_colorscales=new_echo_figure(reg_fig,'UiFigureBool',true,...
						'WindowStyle','normal','Resize','off',...
						'Name','Colorscales','Tag','create_reg');   
					imshow(path_to_colorscales_plot)
				case 0
					%close(findall(0, 'Type', 'figure', '-not', 'Name', 'Choose parameters to display maps'));
			end

			% % Define the zoom function
			% function zoomWithScroll(~,~)
			%     zoomFactor = 2; % Define zoom intensity
			%     if event.VerticalScrollCount > 0
			%         % Zoom out
			%         ax.XLim = ax.XLim + diff(ax.XLim) * 0.1;
			%         ax.YLim = ax.YLim + diff(ax.YLim) * 0.1;
			%     elseif event.VerticalScrollCount < 0
			%         % Zoom in
			%         ax.XLim = ax.XLim - diff(ax.XLim) * 0.1;
			%         ax.YLim = ax.YLim - diff(ax.YLim) * 0.1;
			%     end
			% end
		end

		function run_canopy_maps(~,~) 
			
			dlg = uiprogressdlg(reg_fig,'Icon',esp3_icon, ...
			'Interpreter','html');

			steps = 300;
			sn = 3;
			sk1 = 1;

			cmap = winter(steps)*100;
		   
			for stepi = 1:steps/sn
				r = num2str(cmap(stepi,1));
				g = num2str(cmap(stepi,2));
				b = num2str(cmap(stepi,3));
				msg = ['<p style=color:rgb(' r '%,' g '%,' b '%)>','Starting canopy height estimation display, this might take a few seconds... </p>'];
				dlg.Message = msg;
				dlg.Value = stepi/steps;
				pause(0.05);
			end
		

			colorscale_bathy = bathyc.Value;
			save(append(path_save,'\','colorscale_bathy.mat'),"colorscale_bathy")

			zoom_level = str2double(zl.String);
			save(append(path_save,'\','zoom_level.mat'),"zoom_level")
		 
			colorscale_bio = bioc.Value;
			save(append(path_save,'\','colorscale_biovolume.mat'),"colorscale_bio") 
		
			colorscale_height = heightc.Value;
			save(append(path_save,'\','colorscale_canopy_height.mat'),"colorscale_height")
		 
			basemaps = map_base.Value;
			save(append(path_save,'\','basemap.mat'),"basemaps")
		 
			point_size = str2double(points.String);
			save(append(path_save,'\','point_size.mat'),"point_size")
		
			interpolation_method = interp_method.Value;
			save(append(path_save,'\','interpolation_method.mat'),"interpolation_method")
			% function reopening_files(~,~) 
			%      switch reopen_data.Value
			%          case 0
			% 
			%          case 1                
			%              [Filename,PathToFile]= uigetfile( {fullfile(app_path.results.Path_to_folder,'*_bathymetry.mat;*_canopy_height.mat;*_biovolume.mat;*_lat.mat;*_lon.mat')}, 'Pick your latitude, longitude, bathymetry, biovolume and canopy height files','MultiSelect','on'); 
			%      end
			%  end 
			if isempty(layers)
				return;
			end

			data_struct.Time = [];
			data_struct.Ping_number = [];
			data_struct.Sample_number = [];
			data_struct.Bathy = [];
			data_struct.Height = [];
			data_struct.Lat = [];
			data_struct.Lon = [];

			win_size = 21;

			for uilay = 1 : numel(layers)
				trans_obj = layers(uilay).get_trans(curr_disp);
				idx = layers(uilay).get_lines_per_Tag('canopy');

				if isempty(trans_obj) || isempty(layers(uilay).Lines) || isempty(idx)
					continue;
				end

				nb_lines=numel(layers(uilay).Lines);
				lines_tab_comp=getappdata(main_figure,'Lines_tab');
				line_obj = layers(uilay).Lines(min(nb_lines,get(lines_tab_comp.tog_line,'value')));

				if size(layers(uilay).SurveyData,2)>1
					interid = intersect(find(line_obj.Time<=trans_obj.Time(end)),find(line_obj.Time>=trans_obj.Time(1)));

					curr_dist=trans_obj.GPSDataPing.Dist(interid)';

					[~,~,r_line] = line_obj.get_time_dist_and_range_corr(trans_obj.get_transceiver_time(),curr_dist);
					r_line = r_line(interid);
					r_bot = trans_obj.get_bottom_range();
					r_bot = r_bot(interid);
					d_bot = trans_obj.get_bottom_depth();
					d_bot = d_bot(interid);

					if numel(r_bot)>2*win_size
						d_bot = filter2_perso(gausswin(win_size)',d_bot);
						r_bot = filter2_perso(gausswin(win_size)',r_bot);
					end

					data_struct.Time = datestr(trans_obj.Time(interid),'yyyy-mm-dd HH:MM:SS');
					data_struct.Ping_number = 1:size(trans_obj.Time(interid),2);

					sidx = nan(size(r_bot,2),1);
					if size(line_obj.Range,2)<size(line_obj.Range,1)&&size(line_obj.Range,2)==1
						for ir=1:size(line_obj.Range,1)
							sidx(ir,1) = find(abs(trans_obj.Range-r_line(ir))==min(abs(trans_obj.Range-r_line(ir))));
						end
					else
						for ir=1:size(line_obj.Range,2)
							sidx(ir,1) = find(abs(trans_obj.Range-r_line(ir))==min(abs(trans_obj.Range-r_line(ir))));
						end
					end
					data_struct.Sample_number = sidx;
					data_struct.Bathy = [data_struct.Bathy r_bot];
					data_struct.Height = [data_struct.Height r_bot-r_line];
					data_struct.Lat = [data_struct.Lat trans_obj.GPSDataPing.Lat(interid)];
					data_struct.Lon = [data_struct.Lon trans_obj.GPSDataPing.Long(interid)];

				else
					curr_dist=trans_obj.GPSDataPing.Dist(:)';

					[~,~,r_line] = line_obj.get_time_dist_and_range_corr(trans_obj.get_transceiver_time(),curr_dist);
					r_bot = trans_obj.get_bottom_range();
					d_bot = trans_obj.get_bottom_depth();

					if numel(r_bot)>2*win_size
						d_bot = filter2_perso(gausswin(win_size)',d_bot);
						r_bot = filter2_perso(gausswin(win_size)',r_bot);
					end

					data_struct.Time = datestr(trans_obj.Time,'yyyy-mm-dd HH:MM:SS');
					data_struct.Ping_number = 1:size(trans_obj.Time,2);

					sidx = nan(size(r_bot,2),1);
					if size(line_obj.Range,2)<size(line_obj.Range,1)&&size(line_obj.Range,2)==1
						for ir=1:size(line_obj.Range,1)
							sidx(ir,1) = find(abs(trans_obj.Range-r_line(ir))==min(abs(trans_obj.Range-r_line(ir))));
						end
					else
						for ir=1:size(line_obj.Range,2)
							sidx(ir,1) = find(abs(trans_obj.Range-r_line(ir))==min(abs(trans_obj.Range-r_line(ir))));
						end
					end
					data_struct.Sample_number = sidx;
					data_struct.Bathy = [data_struct.Bathy r_bot];
					data_struct.Height = [data_struct.Height r_bot-r_line];
					data_struct.Lat = [data_struct.Lat trans_obj.GPSDataPing.Lat];
					data_struct.Lon = [data_struct.Lon trans_obj.GPSDataPing.Long];
				end

			end
			data_struct.Height(data_struct.Height<0) = 0;

			if isempty(data_struct.Lon)
				return;
			end

			data_struct.Biovolume_prc = data_struct.Height./data_struct.Bathy*100;

			%% Saving files
			app_path = get_esp3_prop('app_path');
			path_save = append(app_path.results.Path_to_folder,'\','Canopy_results');
			if ~isfolder(path_save)
				mkdir(path_save) 
			end

			%path_root = app_path.data_root;

			[~,file_start,~] = fileparts(layers(1).Filename{1});
			[~,file_end,~] = fileparts(layers(end).Filename{end});

			lat = data_struct.Lat;
			lon = data_struct.Lon;
			height = data_struct.Height;
			bio = data_struct.Biovolume_prc;
			bathy = data_struct.Bathy;

			save(append(path_save,'\','lat.mat'),"lat")
			save(append(path_save,'\','lon.mat'),"lon")
			save(append(path_save,'\','canopy_height.mat'),"height")
			save(append(path_save,'\','biovolume.mat'),"bio")
			save(append(path_save,'\','bathymetry.mat'),"bathy")

			if strcmp(file_start,file_end)
				save(append(path_save,'\','file_start.mat'),"file_start")
			else
				save(append(path_save,'\','file_start.mat'),"file_start")
				save(append(path_save,'\','file_end.mat'),"file_end")
			end

			for stepi = steps/sn:sk1*steps/sn
				r = num2str(cmap(stepi,1));
				g = num2str(cmap(stepi,2));
				b = num2str(cmap(stepi,3));
				msg = ['<p style=color:rgb(' r '%,' g '%,' b '%)> ESP3_canopy_maps.exe starting...' newline... 
					 'Getting maps ready to be displayed in browser... </p>'];
				dlg.Message = msg;
				dlg.Value = stepi/steps;
				pause(0.05);
			end
		
			%% Launch external module
			process = System.Diagnostics.Process();
			process.StartInfo.FileName = append(app_path.data_root.Path_to_folder,'\private\canopy\ESP3_canopy_maps.exe');
			process.Start(); 
			while(~process.HasExited)
				pause(1);
			end
			try
				process.Kill; % kill the process if needed.
			catch
			end

			for stepi = sk1*steps/sn:steps
				r = num2str(cmap(stepi,1));
				g = num2str(cmap(stepi,2));
				b = num2str(cmap(stepi,3));
				msg = ['<p style=color:rgb(' r '%,' g '%,' b '%)> Saving maps and exiting ESP3_canopy_maps.exe... </p>'];
				dlg.Message = msg;
				dlg.Value = stepi/steps;
				pause(0.05);
			end
			
			%% Deleting all temp .mat var files
			delete(append(path_save,'\','*.mat'))
			dlg_perso(reg_fig,'Done',append('Plant density estimation finished, maps open in browser and exported to: ',path_save,'...'));
			close(dlg)
		end

		function save_canopy_files(~,~)     
			%% Saving shapefile and csv
		
		
			[path_lay,~] = layers.get_path_files();
			output_fullfile = fullfile(path_lay{1},'canopy_data.shp');
			[filename, pathname] = uiputfile('*.shp','Export Canopy data to shapefile and .csv',output_fullfile);
			output_fullfile = fullfile(pathname,filename);
			output_fullfile_csv = strrep(output_fullfile,'.shp','.csv');
			output = data_struct;
			ff=fieldnames(output);
			
			for idi=1:numel(ff)
				if isrow(output.(ff{idi}))
					output.(ff{idi})=output.(ff{idi})';
				end
			end
			struct2csv(output,output_fullfile_csv);
			
			data_struct_shp = cell(1,numel(data_struct.Bathy));

			for il = 1:numel(data_struct.Bathy)
				for idi=1:numel(ff)
					data_struct_shp{il}.(ff{idi})=data_struct.(ff{idi})(il);
				end
				data_struct_shp{il}.Geometry = 'Point';
			end
			
			
			try
				shapewrite(vertcat(data_struct_shp{:}),output_fullfile);
			catch
				fprintf('Could not save shapefile')
			end
		end
	else
		fprintf('External module not found, request it form developpers at alicia.maurice@earthsciences.nz/pablo.escobarflores@earthsciences.nz')
	end
end

    
    
    
    
    









