
function [uifig,Link] = display_soundings_scatter(data_struct_cell,cell_str,prc_thr,vert_exa,sc_size)

uifig = matlab.ui.Figure.empty;
Link = [];



%cmap_struct_bathy = init_cmap('Schwarzwald');
%cmap_struct_bathy = init_cmap('elevation');
cmap_struct_bathy = init_cmap('zeu');
%cmap_struct_bathy.cmap = flipud(cmap_struct_bathy.cmap);
cmap_struct_bs = init_cmap('GMT_gray');
cmap_struct_bs.cmap = flipud(cmap_struct_bs.cmap);
cmap = {cmap_struct_bathy cmap_struct_bs};

zone_tot = [];
E_tot = [];
N_tot = [];
H_tot = [];
BS_tot = [];
icell_tot = [];

for icell = 1:numel(data_struct_cell)
    data_struct_tot = data_struct_cell{icell};
    zone_tot = [zone_tot [data_struct_tot(:).Zone]];
    E_tot = [E_tot [data_struct_tot(:).E]];
    N_tot = [N_tot [data_struct_tot(:).N]];
    H_tot = [H_tot [data_struct_tot(:).H]];
    BS_tot = [BS_tot [data_struct_tot(:).BS]];
    icell_tot = [icell_tot icell*ones(size([data_struct_tot(:).H]))];
end

fields_to_disp = {'H' 'BS'};

zones = unique(zone_tot);

depth_range = prctile(H_tot,[5 95]);
cax_bathy = depth_range+range(depth_range)*[-0.2 0.2];
cax = {cax_bathy []};

if range(E_tot(:),'all')<range(N_tot(:),'all')
    direction = 'vertical';
    slay = [1 numel(data_struct_cell)];
else
    direction = 'horizontal';
    slay = [numel(data_struct_cell) 1];
end

for uiz = 1:numel(zones)

    for uif = 1:numel(fields_to_disp)
        uifig(uif) = new_echo_figure([],'uifigureBool',true,'Name',sprintf('Scattered soundings zone %d: %s',zones(uiz),fields_to_disp{uif}));
        uigl(uif)  = uigridlayout(uifig(uif),slay);
        switch fields_to_disp{uif}
            case 'BS'
                data = BS_tot;
            case 'H'
                data  = H_tot;
        end
        w = db2pow(BS_tot);
        for uic = 1:numel(data_struct_cell)
            ax_bathy(uif,uic) = uiaxes(uigl(uif),'NextPlot','add','Box','on','XGrid','on','YGrid','on','Nextplot','add','Tag',cell_str{uic});
            switch direction
                case 'vertical'
                    ax_bathy(uif,uic).Layout.Row = 1;
                    ax_bathy(uif,uic).Layout.Column = uic;
                case 'horizontal'
                    ax_bathy(uif,uic).Layout.Row = uic;
                    ax_bathy(uif,uic).Layout.Column = 1;
            end

            idx_current = zone_tot == zones(uiz) &  icell_tot == uic;

            

            if prc_thr>0
                bds = prctile(w,prc_thr);
                idx_current = (w>=bds) & idx_current;
            end

            ph = scatter3(ax_bathy(uif,uic), E_tot(idx_current),N_tot(idx_current), H_tot(idx_current), sc_size, data(idx_current),'filled');
            view(ax_bathy(uif,uic),[30 45])

            if isempty(cax{uif})
                clim(ax_bathy(uif,uic),[prctile(data(idx_current),5) prctile( data(idx_current),95)]+[-1 1]);
            else
                clim(ax_bathy(uif,uic),cax{uif});
            end
        end


    end

    for uif = 1:size(ax_bathy,1)
        for uic = 1:size(ax_bathy,2)
            if isempty(ax_bathy(uif,uic))||~isvalid(ax_bathy(uif,uic))
                continue;
            end
            colormap(ax_bathy(uif,uic),cmap{uif}.cmap);
            colorbar(ax_bathy(uif,uic));
            daspect(ax_bathy(uif,uic),[1 1 1/vert_exa]);
            ax_bathy(uif,uic).ZDir = "reverse";
            if 1 == size(ax_bathy,1) || strcmpi(direction,'vertical')
                xlabel(ax_bathy(uif,uic),'Easting(m)');
            end
            if 1 == 1 || strcmpi(direction,'horizontal')
                ylabel(ax_bathy(uif,uic),'Northing(m)');
            end
            title(ax_bathy(uif,uic),ax_bathy(uif,uic).Tag);
            zlabel(ax_bathy(uif,uic),'Depth(m)');
        end

    end

    for uif = 1:numel(uifig)
        format_color_gui(uifig(uif),'',cmap_struct_bathy);
    end

    linkaxes(ax_bathy(:),'xyz');

    Link = linkprop(ax_bathy(:),{'CameraUpVector', 'CameraPosition', 'CameraTarget'});

end