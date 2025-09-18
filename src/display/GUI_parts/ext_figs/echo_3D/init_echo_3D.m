function echo_3D_obj = init_echo_3D()

echo_3D_obj = get_esp3_prop('echo_3D_obj');
curr_disp=get_esp3_prop('curr_disp');
main_figure = get_esp3_prop('main_figure');
linked_prop=getappdata(main_figure,'LinkedProps');

if isempty(echo_3D_obj)
    echo_3D_obj = echo_3D_cl('cmap',curr_disp.Cmap);
    esp3_obj=getappdata(groot,'esp3_obj');
    esp3_obj.echo_3D_obj = echo_3D_obj;
    if ~isempty(linked_prop)
        linked_prop.WcFanAlphamap = linkprop([main_figure...
            echo_3D_obj.echo_fig],{'AlphaMap'});
        setappdata(main_figure,'LinkedProps',linked_prop);
    end
end

esp3_obj=getappdata(groot,'esp3_obj');
esp3_obj.echo_3D_obj = echo_3D_obj;


end