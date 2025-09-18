function listenYDir(~,listdata,main_figure)

axes_panel_comp=getappdata(main_figure,'Axes_panel');

set(axes_panel_comp.echo_obj.main_ax,'YDir',listdata.AffectedObject.YDir);
if isappdata(main_figure,'wc_fan')
    wc_fan  = getappdata(main_figure,'wc_fan');
    wc_fan.wc_axes.YDir = listdata.AffectedObject.YDir;
end

end