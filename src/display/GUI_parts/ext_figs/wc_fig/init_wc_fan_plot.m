function init_wc_fan_plot()

esp3_obj = getappdata(groot,'esp3_obj');

lay_obj = get_current_layer();
if isempty(lay_obj)
    return;
end

ismb_trans = arrayfun(@ismb,lay_obj.Transceivers);

if ~any(ismb_trans)
    clean_echo_figures(esp3_obj.main_figure,'Tag','wc_fan');
    if isappdata(esp3_obj.main_figure,'wc_fan')
        rmappdata(esp3_obj.main_figure,'wc_fan');
    end
    return;
end

wc_fan  = getappdata(esp3_obj.main_figure,'wc_fan');

if isempty(wc_fan)||~isvalid(wc_fan.wc_axes)
    wc_fan_fig = new_echo_figure(esp3_obj.main_figure,...
        'Name','WC fan',...
        'tag','wc_fan',...
        'UiFigureBool',true,...
        'CloseRequestFcn',@rm_wc_fan_appdata);
    
    wc_fan_fig.Alphamap = esp3_obj.curr_disp.get_alphamap();  
    wc_fan = create_wc_fan('wc_fig',wc_fan_fig,'curr_disp',esp3_obj.curr_disp);
    setappdata(esp3_obj.main_figure,'wc_fan',wc_fan);
else
    wc_fan = getappdata(esp3_obj.main_figure,'wc_fan');
end

wc_fan.wc_fan_fig.Visible = 'on';
linked_prop=getappdata(esp3_obj.main_figure,'LinkedProps');
if ~isempty(linked_prop)
    linked_prop.WcFanAlphamap = linkprop([esp3_obj.main_figure...
    wc_fan.wc_fan_fig],{'AlphaMap'});
    setappdata(esp3_obj.main_figure,'LinkedProps',linked_prop);
end

end


function rm_wc_fan_appdata(src,~)
delete(src);
esp3_obj = getappdata(groot,'esp3_obj');
rmappdata(esp3_obj.main_figure,'wc_fan');

end