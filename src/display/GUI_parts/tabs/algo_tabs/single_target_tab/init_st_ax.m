function init_st_ax(~,ax)

layer=get_current_layer();
if isempty(layer)
    return;
end
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~]=layer.get_trans(curr_disp);

if isempty(trans_obj)
    return;
end
cax=curr_disp.getCaxField('sp');
cmap_name=curr_disp.Cmap;

cmap_struct = init_cmap(cmap_name,curr_disp.ReverseCmap);
clim(ax,cax);
colormap(ax,cmap_struct.cmap);

x0=trans_obj.Config.AngleOffsetAthwartship;
y0=trans_obj.Config.AngleOffsetAlongship;
[faBW,psBW] = trans_obj.get_beamwidth_at_f_c([]);

[x1,y1]=get_ellipse_xy(max(psBW),max(faBW),...
    x0,y0,100);
[x2,y2]=get_ellipse_xy(max(psBW)/2,max(faBW)/2,...
    x0,y0,100);

ax.Color=cmap_struct.col_ax;
ax.YRuler.Color=cmap_struct.col_grid;
ax.XRuler.Color=cmap_struct.col_grid;
ax.YRuler.FirstCrossoverValue = x0;
ax.XRuler.FirstCrossoverValue = y0;

plot(ax,x2,y2,'--','Color',cmap_struct.col_grid);
plot(ax,x1,y1,'Color',cmap_struct.col_grid);
