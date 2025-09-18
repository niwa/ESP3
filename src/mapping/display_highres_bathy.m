
function [uifig,link] = display_highres_bathy(grid_tot,poly_cov,str_cell,vert_exa,sc_size)

%disp_bathy = 'scatter';
%disp_bathy = 'surf';
disp_bathy = 'pcolor';
uifig = matlab.ui.Figure.empty;
link = [];

cont_col = [0.95 0.95 0.95];
cont_space = 500;

%cmap_struct_bathy = init_cmap('Schwarzwald');
%cmap_struct_bathy = init_cmap('elevation');
cmap_struct_bathy = init_cmap('zeu');
%cmap_struct_bathy.cmap = flipud(cmap_struct_bathy.cmap);
cmap_struct_bs = init_cmap('GMT_gray');
cmap_struct_diff = init_cmap('differences');
cmap_struct_sd = init_cmap('ek60');
cmap_struct_slope = init_cmap('BlueWhiteOrangeRed');
cmap_struct_abs_slope = init_cmap('GMT_split');


depth_range = [nan nan];
slope_max = 0;
for uig = 1:numel(grid_tot)
    g_tmp = grid_tot{uig};
    depth_range(1) = min(depth_range(1),prctile([g_tmp(:).H],5,'all'),'omitmissing');
    depth_range(2) = max(depth_range(2),prctile([g_tmp(:).H],95,'all'),'omitmissing');
    if isfield(g_tmp(1),'AbsSlope')
        slope_max = max(slope_max,prctile([g_tmp(:).AbsSlope],95,"all"),'omitmissing');
    else
        slope_max = 50;
    end
end

nb_cont = 10;
start_c = floor(depth_range(1)/10)*10;
end_c  = ceil(depth_range(2)/10)*10;
cont_list = linspace(start_c,end_c,nb_cont);


cax_bathy = depth_range+range(depth_range)*[-0.1 0.1];
bin_depth = linspace(depth_range(1),depth_range(2),50);
cax_diff = [-depth_range(2)/25 +depth_range(2)/25];
bin_diff = linspace(cax_diff(1),cax_diff(2),50);
bin_slope = linspace(0,slope_max,50);
cax_std = [0 +depth_range(2)/50];
cax_sd = [0 10];
cax_bs = [];
cax_abs_slope = [0 slope_max+1];
cax_slope = [-slope_max-1 slope_max+1];


z_cell = {'Depth(m)' 'Depth(m)' 'Depth(m)' 'Depth Std(m)' 'Sounding Density (n/m^2)' 'Slope (deg.)' 'Slope (deg.)' 'Slope (deg.)' 'Depth diff.(m)'};
cax = {cax_bathy, cax_bs, cax_bs ,cax_std, cax_sd, cax_abs_slope,cax_slope,cax_slope, cax_diff};
grid_fields = {'H' 'BS' 'BS_corr' 'StdH' 'SoundingDensity' 'AbsSlope' 'AcrossSlope' 'AlongSlope' 'Diff'};
grid_fields_H = {'H' 'H' 'H' 'H' 'H' 'H' 'H' 'H' 'Diff'};
cmap_struct = {cmap_struct_bathy cmap_struct_bs cmap_struct_bs cmap_struct_sd cmap_struct_sd cmap_struct_abs_slope cmap_struct_slope cmap_struct_slope cmap_struct_diff};


nb_figs = numel(grid_fields);
nb_ax = numel(grid_tot);

if range(grid_tot{1}.N(:),'all')>range(grid_tot{1}.E(:),'all')
    direction = 'vertical';
    slay = [1 numel(grid_tot)];
else
    direction = 'horizontal';
    slay = [numel(grid_tot) 1];
end

cell_disp_str = cell(nb_ax,nb_figs);
for uir = 1:numel(grid_tot)
    cell_disp_str(uir,:) = str_cell(uir);
end

hist_var = {'H' 'AbsSlope'};
hist_var_label = {'Depth(m)' 'Slope(deg.)'};
bins = {bin_depth bin_slope};

if nb_ax>1
    for ih = 1:numel(hist_var)
        if ~isfield(grid_tot{uir},(hist_var{ih}))
            continue;
        end
        fig_hist(ih) = new_echo_figure([],'UiFigureBool',true,'Name',sprintf('Histogram of differences Vs %s',hist_var{ih}));
        uigl_hist(ih) = uigridlayout(fig_hist(ih),slay);
        for uir = 1:numel(grid_tot)
            if uir < numel(grid_tot)
                id_ref = uir;
                id_sec = uir+1;
            else
                id_ref = uir;
                id_sec = 1;
            end
            grid_tot{uir}.Diff = grid_tot{id_ref}.H-grid_tot{id_sec}.H;
            cell_disp_str{uir,nb_figs} = sprintf('%s - %s',str_cell{id_ref},str_cell{id_sec});
            ax_tmp = uiaxes(uigl_hist(ih),'NextPlot','add','Box','on','XGrid','on','YGrid','on','Nextplot','add','Tag',cell_disp_str{uir,nb_figs});
            [pdf_diff,x_mat_diff,y_mat_depth]=pdf_2d_perso(grid_tot{uir}.Diff(:),grid_tot{uir}.(hist_var{ih})(:),bin_diff,bins{ih},'gauss');
            cax_tmp=[prctile(pdf_diff(pdf_diff>0),5) prctile(pdf_diff(pdf_diff>0),99)];
            [~,idx_max] = max(pdf_diff,[],1);
            
            ph = pcolor(ax_tmp,x_mat_diff,y_mat_depth,pdf_diff);
            ph.FaceColor = 'Flat';
            ph.FaceAlpha = 'Flat';
            ph.LineStyle = 'none';
            ph.EdgeColor = cmap_struct_diff.col_grid;
            ph.AlphaData = single(pdf_diff>=cax_tmp(1));
            plot(ax_tmp,bin_diff(idx_max),bins{ih},'k');
            ax_tmp.YDir = 'reverse';
            colormap(ax_tmp,cmap_struct_sd.cmap);
            if diff(cax_tmp)>0
                ax_tmp.CLim = cax_tmp;
            end
            %xline(ax_tmp,mean(grid_tot{uir}.Diff,"all","omitmissing"),'-',sprintf('Mean = %.2fm',mean(grid_tot{uir}.Diff,"all","omitmissing")));
            title(ax_tmp,cell_disp_str{uir,nb_figs});
            xlabel(ax_tmp,'Depth difference(m)');
            ylabel(ax_tmp,hist_var_label{ih});
        end
    end
else
    nb_figs = nb_figs-1;
end

for uif = 1:nb_figs
    uifig(uif) = new_echo_figure([],'UiFigureBool',true,'Name',grid_fields{uif});
    uigl(uif)  = uigridlayout(uifig(uif),slay);
end

for uir = 1:numel(grid_tot)
    for uif = 1:numel(uigl)

        if ~isfield(grid_tot{uir},grid_fields{uif})
            continue;
        end

        data = grid_tot{uir}.(grid_fields{uif});

        if isempty(data)||all(isnan(data),"all")
            continue;
        end

        h_data = grid_tot{uir}.(grid_fields_H{uif});

        ax_bathy(uir,uif) = uiaxes(uigl(uif),'NextPlot','add','Box','on','XGrid','on','YGrid','on','Nextplot','add','Tag',cell_disp_str{uir,uif});
        switch direction
            case 'vertical'
                ax_bathy(uir,uif).Layout.Row = 1;
                ax_bathy(uir,uif).Layout.Column = uir;
            case 'horizontal'
                ax_bathy(uir,uif).Layout.Row = uir;
                ax_bathy(uir,uif).Layout.Column = 1;
        end

        switch disp_bathy
            case 'surf'
                ph = surf(ax_bathy(uir,uif), grid_tot{uir}.E,grid_tot{uir}.N,h_data,data,'EdgeColor', 'none','FaceColor','flat');
                view(ax_bathy(uir,uif),[30 45])
            case 'pcolor'
                ph = pcolor(ax_bathy(uir,uif), grid_tot{uir}.E,grid_tot{uir}.N,data);
                ph.FaceColor = 'flat';
                ph.EdgeColor = 'none';

                switch grid_fields{uif}
                    case 'H'
                       [~,ch] = contour(ax_bathy(uir,uif), grid_tot{uir}.E,grid_tot{uir}.N,h_data,cont_list,...
                            "ShowText",true,"LabelFormat","%0.0f m",'LabelSpacing',cont_space,'Color',cont_col);
                       ch.LabelColor = cont_col;
                end

                switch grid_fields_H{uif}
                    case 'Diff'
                        id_poly=1:numel(grid_tot);
                    otherwise
                        id_poly=uir;
                end

                for uirr = id_poly
                    if isempty(poly_cov{uirr})
                        continue;
                    end
                    tmp = plot(ax_bathy(uir,uif),poly_cov{uirr});
                    tmp.FaceAlpha = 0;
                    tmp.EdgeColor = tmp.FaceColor;
                    tmp = plot(ax_bathy(uir,uif),poly_cov{uirr});
                    tmp.FaceAlpha = 0;
                    tmp.EdgeColor = tmp.FaceColor;
                end
            case 'scatter'
                ph = scatter3(ax_bathy(uir,uif), grid_tot{uir}.E(:),grid_tot{uir}.N(:), h_data(:), sc_size, data(:),'filled');
                view(ax_bathy(uir,uif),[30 45])
        end

        if isempty(cax{uif})
            clim(ax_bathy(uir,uif),[prctile(data(:),5) prctile(data(:),95)]+[-1 1]);
        else
            clim(ax_bathy(uir,uif),cax{uif});
        end

    end
end

for uir = 1:size(ax_bathy,1)
    for uif = 1:size(ax_bathy,2)
        if isempty(ax_bathy(uir,uif))||~isvalid(ax_bathy(uir,uif))||~isa(ax_bathy(uir,uif),'matlab.ui.control.UIAxes')
            continue;
        end
        colormap(ax_bathy(uir,uif),cmap_struct{uif}.cmap);
        colorbar(ax_bathy(uir,uif));
        daspect(ax_bathy(uir,uif),[1 1 1/vert_exa]);
        ax_bathy(uir,uif).ZDir = "reverse";
        if uir == size(ax_bathy,1) || strcmpi(direction,'vertical')
            xlabel(ax_bathy(uir,uif),'Easting(m)');
        end
        if uir == 1 || strcmpi(direction,'horizontal')
            ylabel(ax_bathy(uir,uif),'Northing(m)');
        end
        title(ax_bathy(uir,uif),ax_bathy(uir,uif).Tag);
        zlabel(ax_bathy(uir,uif),z_cell{uif});
    end
end

for uif = 1:numel(uifig)
    format_color_gui(uifig(uif),'',cmap_struct{uif});
end

linkaxes(ax_bathy(:),'xyz');

switch disp_bathy
    case {'surf' 'scatter'}
        link = linkprop(ax_bathy,{'CameraUpVector', 'CameraPosition', 'CameraTarget'});
end

% link_fig = link(uifig,'Position');
% link = [link link_fig];
end