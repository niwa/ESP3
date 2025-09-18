function disp_canopy_height_cback(~,~)

layers = get_esp3_prop('layers');
main_figure = get_esp3_prop('main_figure');

if isempty(layers)
    return;
end
r_cal = 100;
map_fig = new_echo_figure(main_figure,'UiFigureBool',true,...
    'Name','Canopy Height Map','tag','canopyHeightmap');
gl  = uigridlayout(map_fig,[2 3]);
gl.RowHeight = {'1x',50};

map_fig_density = new_echo_figure(main_figure,'UiFigureBool',true,...
    'Name','Plant Density Estimation','tag','canopyHeightmap_density');
gl_density  = uigridlayout(map_fig_density,[2 2]);
gl_density.RowHeight = {'1x',50};

curr_disp=get_esp3_prop('curr_disp');
base_curr=curr_disp.Basemap;

gax = geoaxes('Parent', gl,...
    'Tag','Heightmap','basemap', base_curr);
gax.Layout.Row = 1;
gax.Layout.Column = 1;
format_geoaxes(gax);
title(gax,'Canopy Height(m)');
cmap_struct = init_cmap(curr_disp.Cmap,curr_disp.ReverseCmap);
colormap(gax,cmap_struct.cmap);

gax_bio = geoaxes('Parent', gl,...
    'Tag','biovolume','basemap', base_curr);
gax_bio.Layout.Row = 1;
gax_bio.Layout.Column = 2;
format_geoaxes(gax_bio);
title(gax_bio,'Biovolume(%)');
cmap_struct = init_cmap('viridis');
colormap(gax_bio,cmap_struct.cmap);

gax_bathy = geoaxes('Parent', gl,...
    'Tag','Bathymap','basemap', base_curr);
gax_bathy.Layout.Row = 1;
gax_bathy.Layout.Column = 3;
format_geoaxes(gax_bathy);
title(gax_bathy,'Bathymetry(m)');
cmap_struct = init_cmap('GMT_drywet');
colormap(gax_bathy,cmap_struct.cmap);

gax_density = geoaxes('Parent', gl_density,...
    'Tag','Heightmap_density','basemap', base_curr);
gax_density.Layout.Row = 1;
gax_density.Layout.Column = 1;
format_geoaxes(gax_density);
title(gax_density,'Canopy Height relative density(m)');
cmap_struct = init_cmap(curr_disp.Cmap,curr_disp.ReverseCmap);
colormap(gax_density,cmap_struct.cmap);

gax_bio_density = geoaxes('Parent', gl_density,...
    'Tag','biovolume_density','basemap', base_curr);
gax_bio_density.Layout.Row = 1;
gax_bio_density.Layout.Column = 2;
format_geoaxes(gax_bio_density);
title(gax_bio_density,'Biovolume relative density(%)');
cmap_struct = init_cmap('viridis');
colormap(gax_bio_density,cmap_struct.cmap);


gl_ctrl  = uigridlayout(gl,[1 4]);
gl_ctrl.Layout.Row = 2;
gl_ctrl.Layout.Column = [1 2];
gl_ctrl.ColumnWidth = {70 '2x' 50,'1x'};

gl_density_ctrl  = uigridlayout(gl_density,[1 4]);
gl_density_ctrl.Layout.Row = 2;
gl_density_ctrl.Layout.Column = [1 2];
gl_density_ctrl.ColumnWidth = {70 70 50 '1x'};


text_radius = uilabel(gl_ctrl,'Text','Radius used for density calculation (m): ');
text_radius.Layout.Row = 1;
text_radius.Layout.Column = 2;
text_radius.HorizontalAlignment = 'right';

edit_radius = uieditfield(gl_ctrl, 'numeric');
edit_radius.Limits = [1 500];
edit_radius.ValueDisplayFormat = '%.0f';
edit_radius.Layout.Row = 1;
edit_radius.Layout.Column = 3;
edit_radius.Value = r_cal;


[basemap_list,~,~,basemap_dispname_list]=list_basemaps(0,curr_disp.Online,curr_disp.Basemaps);

basemap_list_h = uidropdown(gl_ctrl,'Items',basemap_dispname_list,'ItemsData',basemap_list,...
    'Value',base_curr);
basemap_list_h.Layout.Row = 1;
basemap_list_h.Layout.Column = 4;

cbar = colorbar(gax,'southoutside');
cbar_bio = colorbar(gax_bio,'southoutside');
cbar_bathy = colorbar(gax_bathy,'southoutside');

cbar_bio_density = colorbar(gax_bio_density,'southoutside');
cbar_density = colorbar(gax_density,'southoutside');

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
        sidx = zeros(size(line_obj.Range,2),1);
        for ir=1:size(line_obj.Range,2)
            sidx(ir,1) = find(abs(trans_obj.Range(interid)-r_line(ir))==min(abs(trans_obj.Range(interid)-r_line(ir))));
        end
        data_struct.Sample_number = sidx;
        data_struct.Bathy = [data_struct.Bathy d_bot];
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
        sidx = zeros(size(line_obj.Range,2),1);
        for ir=1:size(line_obj.Range,2)
            sidx(ir,1) = find(abs(trans_obj.Range-r_line(ir))==min(abs(trans_obj.Range-r_line(ir))));
        end
        data_struct.Sample_number = sidx;
        data_struct.Bathy = [data_struct.Bathy d_bot];
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

s_obj=geoscatter(gax,data_struct.Lat,data_struct.Lon,6,data_struct.Height,'filled');
s_obj_bio=geoscatter(gax_bio,data_struct.Lat,data_struct.Lon,6,data_struct.Biovolume_prc,'filled');
s_obj_bathy=geoscatter(gax_bathy,data_struct.Lat,data_struct.Lon,6,data_struct.Bathy,'filled');
s_obj_density=geodensityplot(gax_density,data_struct.Lat,data_struct.Lon,data_struct.Height,'FaceColor','interp','Radius',r_cal);
s_obj_bio_density=geodensityplot(gax_bio_density,data_struct.Lat,data_struct.Lon,data_struct.Biovolume_prc,'FaceColor','interp','Radius',r_cal);
edit_radius.ValueChangedFcn = {@change_edit_radius,[s_obj_bio_density s_obj_density]};
basemap_list_h.ValueChangedFcn = {@change_basemap,[gax gax_bathy gax_bio gax_bio_density gax_density]};
bv_min = 5;
h_min = 0.25;

set(s_obj,'MarkerFaceAlpha','flat','AlphaDataMapping','scaled');
s_obj.AlphaData = double(data_struct.Height>h_min);
set(s_obj_bathy,'MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5);
set(s_obj_bio,'MarkerFaceAlpha','flat','AlphaDataMapping','scaled');
s_obj_bio.AlphaData = double(data_struct.Biovolume_prc>bv_min);
LatLim = [min(data_struct.Lat,[],"all","omitnan") max(data_struct.Lat,[],"all","omitnan")];
LonLim = [min(data_struct.Lon,[],"all","omitnan") max(data_struct.Lon,[],"all","omitnan")];
[LatLim,LongLim] = ext_lat_lon_lim_v2(LatLim,LonLim,0.2);

geolimits(gax,LatLim,LongLim);
geolimits(gax_bathy,LatLim,LongLim);
geolimits(gax_bio,LatLim,LongLim);
geolimits(gax_density,LatLim,LongLim);
geolimits(gax_bio_density,LatLim,LongLim);

clim(gax,prctile(data_struct.Height,[50 95]));
clim(gax_bio,prctile(data_struct.Biovolume_prc(data_struct.Biovolume_prc>bv_min),[10 80]));
clim(gax_bathy,prctile(data_struct.Bathy,[2 95]));

clim(gax_density,prctile(data_struct.Height,[50 95]));
clim(gax_bio_density,prctile(data_struct.Biovolume_prc(data_struct.Biovolume_prc>bv_min),[10 80]));

drawnow();

tmp = uibutton(gl_density_ctrl,'push',...
    'Text','Save',...
    'Tooltip','Save Results',...
    'Position',[10 50 50 50],...
    'BackgroundColor','white',...
    'ButtonPushedFcn',{@save_map_density,data_struct});
tmp.Layout.Column  = 1;

tmp = uibutton(gl_ctrl,'push',...
    'Text','Save',...
    'Tooltip','Save Results',...
    'BackgroundColor','white',...
    'ButtonPushedFcn',{@save_canopy_height});
tmp.Layout.Row  = 1;
tmp.Layout.Column  = 1;

gax.ZoomLevel = 16;
gax_bio.ZoomLevel = 16;
gax_bathy.ZoomLevel = 16;
gax_density.ZoomLevel = 16;
gax_bio_density.ZoomLevel = 16;

uibutton(gl_density_ctrl,'push',...
    'Text','Lock Zoom',...
    'Position',[10 100 50 50],...
    'Tooltip','Lock same values for Lat/Lon axis for all figures',...
    'BackgroundColor','green',...
    'ButtonPushedFcn',{@(src,gax,gax_bio,gax_density,gax_bio_density,gax_bathy)sync_zoom});

function sync_zoom

diff_zoom = zeros(5,1);
diff_zoom(1,:) = gax.ZoomLevel;
diff_zoom(2,:) = gax_bio.ZoomLevel;
diff_zoom(3,:) = gax_bathy.ZoomLevel;
diff_zoom(4,:) = gax_density.ZoomLevel;
diff_zoom(5,:) = gax_bio_density.ZoomLevel;

diff_lat = zeros(5,2);
diff_lon = zeros(5,2);
diff_lat(1,:) = gax.LatitudeLimits;
diff_lat(2,:) = gax_bio.LatitudeLimits;
diff_lat(3,:) = gax_bathy.LatitudeLimits;
diff_lat(4,:) = gax_density.LatitudeLimits;
diff_lat(5,:) = gax_bio_density.LatitudeLimits;
diff_lon(1,:) = gax.LongitudeLimits;
diff_lon(2,:) = gax_bio.LongitudeLimits;
diff_lon(3,:) = gax_bathy.LongitudeLimits;
diff_lon(4,:) = gax_density.LongitudeLimits;
diff_lon(5,:) = gax_bio_density.LongitudeLimits;

[ivft,idft] = uniquetol(diff_zoom,0.0001);
if length(ivft)==2
    idf1 = find(diff_zoom==diff_zoom(idft(1)));
    idf2 = find(diff_zoom==diff_zoom(idft(2)));
    if length(idf1)>1
        idf=idf2;
    else
        idf=idf1;
    end
    geolimits(gax,diff_lat(idf,:),diff_lon(idf,:));
    geolimits(gax_bathy,diff_lat(idf,:),diff_lon(idf,:));
    geolimits(gax_bio,diff_lat(idf,:),diff_lon(idf,:));
    geolimits(gax_density,diff_lat(idf,:),diff_lon(idf,:));
    geolimits(gax_bio_density,diff_lat(idf,:),diff_lon(idf,:));
    gax.ZoomLevel = diff_zoom(idf);
    gax_bathy.ZoomLevel = diff_zoom(idf);
    gax_bio.ZoomLevel = diff_zoom(idf);
    gax_density.ZoomLevel = diff_zoom(idf);
    gax_bio_density.ZoomLevel = diff_zoom(idf);
elseif length(ivft)>2
    idf = find(abs(diff(diff_zoom))==max(abs(diff(diff_zoom))));
    if isscalar(idf)
        if idf==1
            idf=1;
        elseif idf==4
            idf = 5;
        elseif idf==2
            idf = 3;
        elseif idf==3
            if length(unique(diff_zoom(4:5,:)))==2
                idf = 4;
            end
        end
    elseif length(idf)==2 
        idf = 2;
    else 
        idf = 1;
    end
    geolimits(gax,diff_lat(idf,:),diff_lon(idf,:));
    geolimits(gax_bathy,diff_lat(idf,:),diff_lon(idf,:));
    geolimits(gax_bio,diff_lat(idf,:),diff_lon(idf,:));
    geolimits(gax_density,diff_lat(idf,:),diff_lon(idf,:));
    geolimits(gax_bio_density,diff_lat(idf,:),diff_lon(idf,:));
    gax.ZoomLevel = diff_zoom(idf);
    gax_bathy.ZoomLevel = diff_zoom(idf);
    gax_bio.ZoomLevel = diff_zoom(idf);
    gax_density.ZoomLevel = diff_zoom(idf);
    gax_bio_density.ZoomLevel = diff_zoom(idf);
else
     dlg_perso([],'No changes detected','No difference in zoom detected');
end

end

end

function save_canopy_height(src,~)
layers  =get_esp3_prop('layers');
[path_lay,~] = layers.get_path_files();
output_fullfile = fullfile(path_lay{1},'canopy_height.png');
[filename, pathname] = uiputfile('*.png','Export Canopy Height map',output_fullfile);
output_fullfile = fullfile(pathname,filename);
if pathname == 0
    return;
end
exportgraphics(src.Parent.Parent,output_fullfile);
dlg_perso([],'Done','Canopy Height estimation finished and exported...');
end

function change_edit_radius(src,~,hh)
for ui = 1:numel(hh)
    hh(ui).Radius = src.Value;
end
end

function change_basemap(src,~,hh)
for ui = 1:numel(hh)
    hh(ui).Basemap = src.Value;
end
end

function save_map_density(src,~,data_struct)
layers  =get_esp3_prop('layers');
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
dlg_perso([],'Done','Plant Density estimation finished and exported...');
exportgraphics(src.Parent.Parent,fullfile(pathname,'Plant_Density_Estimation.png'));

end


