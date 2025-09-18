function create_line_context_menu(line_plot)
layer=get_current_layer();
%curr_disp=get_esp3_prop('curr_disp');

line_idx=layer.get_lines_per_ID(line_plot.UserData.ID);

if isempty(line_idx)
    return;
end

line_obj=layer.Lines(line_idx);

context_menu=uicontextmenu(ancestor(line_plot,'figure'),'Tag','LineContextMenu','UserData',line_obj.ID);

%uimenu(context_menu,'Label','Create Line referenced region','Callback',{@create_line_ref_region_cback,line_plot,main_figure});
uimenu(context_menu,'Label','Display line _data','Callback',{@display_line_data,line_plot,line_obj});

line_plot.UIContextMenu=context_menu;
end

function display_line_data(~,~,~,line_obj)

main_figure = get_esp3_prop('main_figure');
line_data_figure  = new_echo_figure(main_figure,'UiFigureBool',true,'Tag','line_data');

layout = uigridlayout(line_data_figure,[1 1]);

ax = uiaxes(layout,'XGrid','on','YGrid','on','box','on');

plot(ax,line_obj.Time,line_obj.Data);

title(ax,line_obj.Tag);

[echo_obj,trans_obj_tot,~,~]=get_axis_from_cids(main_figure,{'main'});
ipings = round(echo_obj.main_ax.XLim);

xlim(ax,trans_obj_tot.Time(ipings));
datetick(ax,'x','HH:MM:SS','keeplimits');  

end

% function create_line_ref_region_cback(src,evtdata,line_plot,main_figure)
% layer=get_current_layer();
% 
% line_idx=layer.get_lines_per_ID(line_plot.UserData);
% 
% if isempty(line_idx)
%     return;
% end
% 
% line_obj=layer.Lines(line_idx);
% 
% end