
function [uifig_slope,link] = display_slope(slope_struct_cell,str_cell,vert_exa,sc_size)

uifig_slope = matlab.ui.Figure.empty;
ax_slope = matlab.ui.control.UIAxes.empty;
slope_max_disp = 0;
link = [];

for uit = 1:numel(slope_struct_cell)
    tt = slope_struct_cell{uit}(:);
    slope_max_disp = max(slope_max_disp,ceil(prctile([tt(:).AbsSlope],90,"all")),'omitnan');
end

%for phase pm3d08
cmap_struct_slope = init_cmap('BlueWhiteOrangeRed');
cmap_struct_abs_slope = init_cmap('GMT_split');
cmap_struct_rsq_slope = init_cmap('turbo');
cmap_cell = {cmap_struct_abs_slope cmap_struct_slope cmap_struct_slope cmap_struct_rsq_slope cmap_struct_slope}; 
cax_slope  = {[0 slope_max_disp] [-slope_max_disp slope_max_disp] [-slope_max_disp slope_max_disp] [] []};


slope_disp_val = {'AbsSlope' 'AcrossSlope' 'AlongSlope' 'RSQSlope'};
slope_disp_val_str = {'Absolute slope' 'Acrossship slope' 'Alongship slope' 'R-Square'};

if range([tt(:).N],'all')>range([tt(:).E],'all')
    direction = 'vertical';
    slay_slope = [1 numel(slope_disp_val)];
else
    direction = 'horizontal';
    slay_slope = [numel(slope_disp_val) 1];
end

uir = 0;
for ir = 1:numel(slope_struct_cell)
    tt = slope_struct_cell{ir}(:);

    if all(isnan([tt(:).AbsSlope]),'all')
        continue;
    end
    uir = uir+1;

    uifig_slope(uir) = new_echo_figure([],'UiFigureBool',true,'Name',sprintf('Slope %s',str_cell{uir}));
    uigl_slope(uir)  = uigridlayout(uifig_slope(uir),slay_slope);
    ff_slopes = fieldnames(slope_struct_cell{1}(1));

    for uf  =1:numel(ff_slopes)
        slopes_cell{uir}.(ff_slopes{uf})= [];
    end

    for uis = 1:numel(slope_struct_cell{uir})
        for uf = 1:numel(ff_slopes)
            slopes_cell{uir}.(ff_slopes{uf}) = [slopes_cell{uir}.(ff_slopes{uf}) slope_struct_cell{ir}(uis).(ff_slopes{uf})(:)'];
        end
    end

    for uid = 1:numel(slope_disp_val)
        ax_slope(uir,uid) = uiaxes(uigl_slope(uir),'NextPlot','add','Box','on','XGrid','on','YGrid','on','Tag',str_cell{uir});

        switch direction
            case 'vertical'
                ax_slope(uir,uid).Layout.Row = 1;
                ax_slope(uir,uid).Layout.Column = uid;
            case 'horizontal'
                ax_slope(uir,uid).Layout.Row = uid;
                ax_slope(uir,uid).Layout.Column = 1;
        end

        ph = scatter3(ax_slope(uir,uid),slopes_cell{uir}.E,slopes_cell{uir}.N,zeros(size(slopes_cell{uir}.(slope_disp_val{uid}))),sc_size,slopes_cell{uir}.(slope_disp_val{uid}),'filled');
    end
end

for uir = 1:size(ax_slope,1)
    for uid =  1:size(ax_slope,2)
        colormap(ax_slope(uir,uid),cmap_cell{uid}.cmap);
        colorbar(ax_slope(uir,uid));
        daspect(ax_slope(uir,uid),[1 1 1/vert_exa]);
        ax_slope(uir,uid).ZDir = "reverse";
        if uid == size(ax_slope,2) || strcmpi(direction,'vertical')
            xlabel(ax_slope(uir,uid),'Easting(m)');
        end
        if uid == 1 || strcmpi(direction,'horizontal')
            ylabel(ax_slope(uir,uid),'Northing(m)');
        end
        title(ax_slope(uir,uid),sprintf('%s %s',slope_disp_val_str{uid},ax_slope(uir,uid).Tag));
        zlabel(ax_slope(uir,uid),'Slope (deg)');

        if isempty(cax_slope{uid})
            clim(ax_slope(uir,uid),[prctile(slopes_cell{uir}.(slope_disp_val{uid})(:),5) prctile(slopes_cell{uir}.(slope_disp_val{uid})(:),95)]+[-0.1 0.1]);
        else
            clim(ax_slope(uir,uid),cax_slope{uid});
        end
    end
end

for uif = 1:numel(uifig_slope)
    format_color_gui(uifig_slope(uif),'',cmap_struct_slope);
end

if ~isempty(ax_slope)
    linkaxes(ax_slope(:),'xyz');
end