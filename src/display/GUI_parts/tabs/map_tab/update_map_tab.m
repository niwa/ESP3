function update_map_tab(main_figure,varargin)
% profile on;

p = inputParser;
addRequired(p,'main_figure',@(obj) isa(obj,'matlab.ui.Figure'));
addParameter(p,'src',[],@(obj) isempty(obj)|ishandle(obj));

parse(p,main_figure,varargin{:});
src=p.Results.src;
up_plots=0;
up_lim=0;
up_basemap=0;
%profile on;

map_tab_comp=getappdata(main_figure,'Map_tab');
if isempty(map_tab_comp)
    return;
end
layers=get_esp3_prop('layers');
curr_disp = get_esp3_prop('curr_disp');
map_tab_comp = getappdata(main_figure,'Map_tab');
gax = map_tab_comp.ax;

[~,~,lat_lays,lon_lays] = get_lat_lon_lim(layers);

fnames = cell(size(layers));
for iil=1:size(layers,2)
    fnames{iil} = layers(iil).Filename{1};
end

if isempty(layers)
    return;
end

[load_bar_comp,init_state]=show_status_bar(main_figure,0);
load_bar_comp.progress_bar.setText('Updating Map...');
layer=get_current_layer();
[folders,~]=layers.get_path_files();
folders=unique(folders);

try
    if ~isempty(src)

        switch src
            case {map_tab_comp.rad_all  map_tab_comp.rad_curr}
                up_lim=1;
                up_plots=1;
            case map_tab_comp.basemap_list
                up_basemap=1;
        end

        map_tab_comp.all_lays=map_tab_comp.rad_all.Value;

        setappdata(main_figure,'Map_tab',map_tab_comp);

        if up_plots==0&&up_lim==0&&up_basemap==0
            if ~init_state
                hide_status_bar(main_figure);
            end
            return;
        end
    else
        up_plots=1;
        up_lim=1;
    end

    map_tab_comp=getappdata(main_figure,'Map_tab');

    if ~isvalid(map_tab_comp.curr_track)
        map_tab_comp.curr_track=matlab.graphics.chart.primitive.Line('Parent',map_tab_comp.ax,'Color',[0.8 0 0],'linestyle','-','linewidth',1,'tag','curr_track','ButtonDownFcn',@disp_obj_tag_callback);
        map_tab_comp.curr_track.LatitudeDataMode='manual';
    end

    idx_keep=~isnan(layer.GPSData.Long);

    set(map_tab_comp.curr_track,'LatitudeData',layer.GPSData.Lat(idx_keep),'LongitudeData',layer.GPSData.Long(idx_keep));

    if up_plots>0
        layers=get_esp3_prop('layers');
        if ~isempty(map_tab_comp.idx_lays)
            layers=layers_tmp(map_tab_comp.idx_lays);
        end
        replot=0;

        idx_list=[];
        for uil=1:numel(layers)
            if ~isempty(layers(uil).GPSData.Lat)
                idx_list=union(idx_list,uil);
            end
        end

        if isempty(layers)&&~isempty(idx_list)
            files={};
        else
            files=layers(idx_list).list_files_layers();
        end

        if ~isempty(map_tab_comp.tracks_plots)
            map_tab_comp.tracks_plots(~isvalid(map_tab_comp.tracks_plots))=[];
        end

        if ~isempty(map_tab_comp.tracks_plots)
            idx_rem=~ismember({map_tab_comp.tracks_plots(:).Tag},files);
            if any(idx_rem)
                replot=1;
            end
            delete(map_tab_comp.tracks_plots(idx_rem));
            map_tab_comp.tracks_plots(idx_rem)=[];
            [~,idx_new]=setdiff(files,{map_tab_comp.tracks_plots(:).Tag});
            if ~isempty(idx_new)
                replot=1;
            end
            files=files(idx_new);
        end

        if replot
            delete(map_tab_comp.shapefiles_plot)
            map_tab_comp.shapefiles_plot=[];
        end

        if ~isempty(files)||replot
            file_old=cell(1,numel(map_tab_comp.tracks_plots));
            gps_data_old=cell(1,numel(map_tab_comp.tracks_plots));
            txt_old=cell(1,numel(map_tab_comp.tracks_plots));

            for iold=1:numel(map_tab_comp.tracks_plots)
                gps_data_old{iold}=map_tab_comp.tracks_plots(iold).UserData.gps;
                file_old{iold}=map_tab_comp.tracks_plots(iold).UserData.file;
                txt_old{iold}=map_tab_comp.tracks_plots(iold).UserData.txt;
            end
            [~,idx_keep]=unique(file_old);

            txt_old=txt_old(idx_keep);
            file_old=file_old(idx_keep);
            gps_data_old=gps_data_old(idx_keep);


            if ~isempty(files)
                survey_data=get_survey_data_from_db(files);
                idx_rem=cellfun(@numel,survey_data)==0;
            else
                survey_data={};
            end

            if ~isempty(files)
                gps_data=get_ping_data_from_db(files,[]);
            else
                gps_data={};
            end

            txt = cell(1,numel(files));
            txt(:) = {''}; 

            for ifi=1:numel(files)
                if ~isempty(gps_data{ifi})
                    [~,text_str,ext_str]=fileparts(files{ifi});
                    text_str=[text_str ext_str ' '];
                    for is=1:length(survey_data{ifi})
                        text_str=[text_str survey_data{ifi}{is}.print_survey_data ' '];
                    end
                    txt{ifi}=text_str;
                end
            end

            %             gps_data=[gps_data gps_data_old];
            %             txt=[txt txt_old];
            %             files=[files file_old];

            if all(cellfun(@isempty,gps_data))&&~up_lim>0
                setappdata(main_figure,'Map_tab',map_tab_comp);
                if ~init_state
                    hide_status_bar(main_figure);
                end
                latLim=[min(map_tab_comp.curr_track.LatitudeData) max(map_tab_comp.curr_track.LatitudeData)];
                longLim=[min(map_tab_comp.curr_track.LongitudeData) max(map_tab_comp.curr_track.LongitudeData)];
                [latLim,longLim] = ext_lat_lon_lim_v2(latLim,longLim,0.2);
                if ~isempty(longLim)
                    if~any(isnan(latLim)|isinf(latLim)|isnan(longLim)|isinf(longLim))
                        geolimits(map_tab_comp.ax,latLim,longLim);
                    end
                end
            else


                LatLim=[inf -inf];
                LongLim=[inf -inf];

                for ifi=1:numel(files)
                    if ~isempty(gps_data{ifi})
                        LongLim(1)=min(LongLim(1),min(gps_data{ifi}.Long));
                        LongLim(2)=max(LongLim(2),max(gps_data{ifi}.Long));
                        LatLim(1)=min(LatLim(1),min(gps_data{ifi}.Lat));
                        LatLim(2)=max(LatLim(2),max(gps_data{ifi}.Lat));
                    end
                end


                map_info.LatLim=LatLim;
                map_info.LongLim=LongLim;

                map_tab_comp.map_info=map_info;
                map_tab_comp.ax.UserData.LatLim  = LatLim;
                map_tab_comp.ax.UserData.LongLim = LongLim ;
                dg = 15;
                files(cellfun(@isempty,gps_data)) = [];
                gps_data(cellfun(@isempty,gps_data)) = [];

                [lat_disp_cell,lon_disp_cell] = cellfun(@(x) reducem_perso(x.Lat,x.Long,dg),gps_data,'UniformOutput',false);
                
                for ifi=1:numel(files)
                    if ~isempty(gps_data{ifi})
                        try
                            userdata.txt=txt{ifi};
                            userdata.gps=gps_data{ifi};
                            userdata.file=files{ifi};


                            if isdebugging()
                                fprintf('%d in navigation instead of %d\n',numel(lat_disp_cell{ifi}),numel(gps_data{ifi}.Lat));
                            end
                            map_tab_comp.curr_track.LineStyle = '-';

                            new_plots=[geoplot(map_tab_comp.ax,gps_data{ifi}.Lat(1),gps_data{ifi}.Long(1),'Marker','o','Tag',files{ifi},'Color',[0 0.6 0],'UserData',userdata,'Markersize',2,'LineWidth',0.7,'MarkerFaceColor',[0 0.6 0]) ...
                                    geoplot(map_tab_comp.ax,lat_disp_cell{ifi},lon_disp_cell{ifi},'Tag',files{ifi},'UserData',userdata,'LineWidth',0.7,'Color',[0 0 0],'ButtonDownFcn',@disp_obj_tag_callback)] ;
 
                            new_plots(1).LatitudeDataMode='manual';
                            new_plots(2).LatitudeDataMode='manual';

                            map_tab_comp.tracks_plots=[map_tab_comp.tracks_plots new_plots];

                            %set hand pointer when on that line
                            pointerBehavior.enterFcn    = [];
                            pointerBehavior.exitFcn     = @(src, evt) exit_map_plot_fcn(src, evt,new_plots);
                            pointerBehavior.traverseFcn = @(src, evt) traverse_map_plot_fcn(src, evt,new_plots);
                            iptSetPointerBehavior(new_plots,pointerBehavior);

                        catch err
                            if ~isdeployed()
                                print_errors_and_warnings(1,'error',err);
                            end
                            warning('Could not display track for file %s',files{ifi});
                        end
                    end
                    idx_lays  = layers.find_layer_idx_files(files);
                    for il = idx_lays
                        trans_obj = layers(il).get_trans(curr_disp);
                        if isempty(trans_obj)
                            trans_obj = layers(il).Transceivers(1);
                        end
                          
                        trans_obj.disp_reg_tag_on_map('gax',gax);
                    end
                    %drawnow;
                end

            end
        end
    end
    if up_lim>0
        if map_tab_comp.all_lays
            lays=get_esp3_prop('layers');
        else
            lays=get_current_layer();
        end
        [latLim,longLim]=arrayfun(@get_geo_bounds,lays,'un',0);

        idx_rem=cellfun(@(x) all(x==[-90 90]),latLim)|cellfun(@(x) all(x==[-180 180]),longLim);
        
        latLim(idx_rem)=[];
        longLim(idx_rem)=[];

        if~isempty(latLim)
            latLim2=max(cellfun(@max,latLim));
            latLim1=min(cellfun(@min,latLim));

            longLim2=max(cellfun(@max,longLim));
            longLim1=min(cellfun(@min,longLim));

            [latLim,longLim] = ext_lat_lon_lim_v2([latLim1 latLim2],[longLim1 longLim2],0.2);
            if~any(isnan(latLim)|isinf(latLim)|isnan(longLim)|isinf(longLim))
                geolimits(map_tab_comp.ax,latLim,longLim);
            end
        end
    end

    if up_basemap>0
        basemap_str=map_tab_comp.basemap_list.UserData{map_tab_comp.basemap_list.Value};
        geobasemap(map_tab_comp.ax,basemap_str)

    end

    map_tab_comp.shapefiles_plot=geoplot_shp(map_tab_comp.ax,folders,map_tab_comp.shapefiles_plot);

    uistack(map_tab_comp.curr_track,'top');

    setappdata(main_figure,'Map_tab',map_tab_comp);
catch err
    disp('Error updating map tab:');
    print_errors_and_warnings(1,'error',err);
end
if ~init_state
    hide_status_bar(main_figure);
end
%  profile off;
%  profile viewer;
end
