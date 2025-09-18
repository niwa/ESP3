function display_file_lines(main_figure)

main_menu=getappdata(main_figure,'main_menu');
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();

[trans_obj,~]=layer.get_trans(curr_disp);

cmap_struct = init_cmap(curr_disp.Cmap,curr_disp.ReverseCmap);

idx_change_file=find(diff(trans_obj.Data.FileId)>0);

state_file_lines=get(main_menu.display_file_lines,'checked');

xdata=trans_obj.get_transceiver_pings();

obj_line=findobj(axes_panel_comp.echo_obj.main_ax,'Tag','file_id');
delete(obj_line);

for ifile=1:length(idx_change_file)
    xline(axes_panel_comp.echo_obj.main_ax,xdata(idx_change_file(ifile))+1/2,...
        'Color',cmap_struct.col_lab,...
        'Tag','file_id',...
        'Label',layer.Filename{ifile},...
        'Interpreter','none');
end

obj_line=findobj(axes_panel_comp.echo_obj.main_ax,'Tag','file_id');

for i=1:length(obj_line)
    set(obj_line(i),'vis',state_file_lines); 
end

end
