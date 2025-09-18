function update_display_tab(main_figure)

layer_obj=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
display_tab_comp=getappdata(main_figure,'Display_tab');

[trans_obj,idx_freq]=layer_obj.get_trans(curr_disp);

if isempty(layer_obj.GPSData.Lat)
    Axes_type= {'pings','seconds'};
   else
    Axes_type= {'meters','pings','seconds'};
end

idx_axes=find(strcmp(curr_disp.Xaxes_current,Axes_type));

if isempty(idx_axes)
    idx_axes=1;
    curr_disp.Xaxes_current=Axes_type{1};
end

[idx_field,~]=trans_obj.Data.find_field_idx(curr_disp.Fieldname);
curr_disp.init_grid_val(trans_obj);
[dx,dy]=curr_disp.get_dx_dy();

set(display_tab_comp.grid_x,'String',int2str(dx));
set(display_tab_comp.grid_y,'String',int2str(dy));

ss = layer_obj.Transceivers.get_CID_freq_str();

set(display_tab_comp.tog_freq,'String',ss,'Value',idx_freq);
set(display_tab_comp.tog_type,'String',trans_obj.Data.Type,'Value',idx_field);
set(display_tab_comp.tog_axes,'String',Axes_type,'Value',idx_axes);
set(display_tab_comp.caxis_up,'String',num2str(curr_disp.Cax(2),'%.1f'));
set(display_tab_comp.caxis_down,'String',num2str(curr_disp.Cax(1),'%.1f'));

%set(findobj(display_tab_comp.display_tab, '-property', 'Enable'), 'Enable', 'on');

setappdata(main_figure,'Display_tab',display_tab_comp);
end