function disp_obj_tag_callback(src,evt)

ax=get(src,'parent');
hfig=ancestor(ax,'Figure');

cp=evt.IntersectionPoint;
x = cp(1,1);
y=cp(1,2);

switch hfig.SelectionType
    case 'normal'
        str=src.UserData.txt;
        u = findobj(ax,'Tag','name');
        delete(u);
        text(ax,x,y,str,'Interpreter','None','Tag','name','EdgeColor','k','BackgroundColor','w','VerticalAlignment','bottom','Clipping','on','ButtonDownFcn',{@open_file_track_cback,src.UserData.file});
    case {'open' 'alt'}
        fprintf('Opening or going to file %s\n',src.UserData.file)
        u = findobj(ax,'Tag','name');
        delete(u);
        layers = get_esp3_prop('layers');
        [old_files,lay_IDs]=layers.list_files_layers();
        idx_already_open=find(cellfun(@(x) any(strcmpi(x,src.UserData.file)),old_files));

        if isempty(idx_already_open)
            open_file_track_cback([],[],src.UserData.file)
        else
            main_figure = get_esp3_prop('main_figure');
            idd = layers.find_layer_idx(lay_IDs{idx_already_open(1)});
            set_current_layer(layers(idd));
            show_status_bar(main_figure,1);

            loadEcho(main_figure);
            hide_status_bar(main_figure);
        end
end
end


function open_file_track_cback(~,~,file)

if isfile(file)
    esp3_obj=getappdata(groot,'esp3_obj');
    choice = question_dialog_fig(esp3_obj.main_figure,'Open file',sprintf('Open file %s',file));
    switch choice
        case 'Yes'
            esp3_obj.open_file('file_id',file);
    end
end

end