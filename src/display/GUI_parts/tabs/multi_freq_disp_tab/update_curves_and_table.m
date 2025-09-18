function update_curves_and_table(main_figure,tab_tag,id_new)

layer=get_current_layer();

if isempty(layer)
    return;
end


if ~iscell(id_new)
    id_new={id_new};
end

multi_freq_disp_tab_comp=getappdata(main_figure,tab_tag);


s_method = multi_freq_disp_tab_comp.filter.UserData{multi_freq_disp_tab_comp.filter.Value};
win_s = multi_freq_disp_tab_comp.win_size.UserData(multi_freq_disp_tab_comp.win_size.Value);

curves=layer.get_curves_per_type(tab_tag);
id_c_tot=multi_freq_disp_tab_comp.ax.Children;
id_c_tot=id_c_tot(arrayfun(@(x) strcmp(x.Type,'errorbar'),id_c_tot));

tags = unique({curves(:).Tag});
nb_class = numel(tags);

cols = lines(nb_class);

[col_from_xml,tags_from_xml,~] = esp3_cl.get_reg_colors_from_xml();

for uit = 1:nb_class
    if ~isempty(col_from_xml)
        id_col = find(strcmpi(tags{uit},tags_from_xml));
        if ~isempty(id_col)
            cols(id_col,:) = col_from_xml{id_col};
        end
    end
end

for i_id=1:numel(id_new)

    if ~isempty(id_c_tot)
        id_c=id_c_tot(arrayfun(@(x) contains(x.Tag,id_new{i_id}),id_c_tot));
    else
        id_c = matlab.graphics.GraphicsPlaceholder.empty;
    end
    
    idx=find(contains({curves(:).Unique_ID},id_new{i_id})&strcmp({curves(:).Type},tab_tag));
    
    if isempty(idx)
        continue;
    end
    
    if multi_freq_disp_tab_comp.show_sd_bar.Value>0
        sd=curves(idx).SD;
    else
        sd=[];
    end
    
    switch multi_freq_disp_tab_comp.fref.String{multi_freq_disp_tab_comp.fref.Value}
        case 'None'
            f_ref = 0;
        case 'Norm 2'
            f_ref = -1;
        otherwise
            f_ref = multi_freq_disp_tab_comp.fref_val.UserData(multi_freq_disp_tab_comp.fref_val.Value)/1e3;
    end
    
    if isempty(id_c)
        id_c(numel(idx)) = matlab.graphics.GraphicsPlaceholder;
    end
    
    for ui=1:numel(id_c)  
        
        yd = curves(idx(ui)).filter_curve(s_method,win_s);
        yd = scattering_model_cl.norm_scat(curves(idx(ui)).XData,yd,f_ref);
        
        yd(yd<-160)=nan;
        
        if numel(properties(id_c(ui)))==0
            id_c(ui)=errorbar(multi_freq_disp_tab_comp.ax,curves(idx(ui)).XData,yd,sd,...
                'Tag',curves(idx(ui)).Unique_ID,'ButtonDownFcn',{@display_line_cback,main_figure,tab_tag},'Marker','o','Markersize',2,'Linewidth',0.5);
            if ~isempty(curves(idx(ui)).Tag)
                if ~isempty(strcmpi(curves(idx(ui)).Tag,tags))
                    id_c(ui).Color = cols(strcmpi(curves(idx(ui)).Tag,tags),:);
                end
            end
            id_c(ui).MarkerFaceColor = id_c(ui).Color;
        else
            set(id_c(ui),'XData',curves(idx(ui)).XData,'YData',yd,'YNegativeDelta',sd,'YPositiveDelta',sd,'Tag',curves(idx(ui)).Unique_ID,'Marker','o','Markersize',2,'Linewidth',0.5);
            
            if ~isempty(curves(idx(ui)).Tag)
                cc = cols(strcmpi(curves(idx(ui)).Tag,tags));
                id_c(ui).Color = cc;
                id_c(ui).MarkerFaceColor = id_c(ui).Color;
            end
        end
    end
    
    
    if ~isempty(multi_freq_disp_tab_comp.table.Data)
        u=find(contains(multi_freq_disp_tab_comp.table.Data(:,5),id_new{i_id}));
    else
        u=[];
    end
    
    if isempty(u)
        for ui=1:numel(idx)
            u=size(multi_freq_disp_tab_comp.table.Data,1)+1;
            color_str=sprintf('rgb(%.0f,%.0f,%.0f)',floor(get(id_c(ui),'Color')*255));
            multi_freq_disp_tab_comp.table.Data{u,1}=strcat('<html><FONT color="',color_str,'">',curves(idx(ui)).Name,'</html>');
            multi_freq_disp_tab_comp.table.Data{u,2}=curves(idx(ui)).Depth;
            multi_freq_disp_tab_comp.table.Data{u,3}=curves(idx(ui)).Tag;
            multi_freq_disp_tab_comp.table.Data{u,4}=true;
            multi_freq_disp_tab_comp.table.Data{u,5}=curves(idx(ui)).Unique_ID;
        end
    else
        for ui=1:numel(u)
                color_str=sprintf('rgb(%.0f,%.0f,%.0f)',floor(get(id_c(ui),'Color')*255));
                idx=find(strcmp({curves(:).Unique_ID}, multi_freq_disp_tab_comp.table.Data{u(ui),5})&strcmp({curves(:).Type},tab_tag));
               multi_freq_disp_tab_comp.table.Data{u(ui),1}=strcat('<html><FONT color="',color_str,'">',curves(idx).Name,'</html>');
               multi_freq_disp_tab_comp.table.Data{u(ui),3}=curves(idx).Tag;
        end
    end
end
if ~isempty(multi_freq_disp_tab_comp.table.Data)
    [~,ids] = sort([multi_freq_disp_tab_comp.table.Data{:,2}]);
    multi_freq_disp_tab_comp.table.Data = multi_freq_disp_tab_comp.table.Data(ids,:);
end
end


function display_line_cback(src,~,main_figure,tab_tag)
multi_freq_disp_tab_comp=getappdata(main_figure,tab_tag);
layer=get_current_layer();
cp=multi_freq_disp_tab_comp.ax.CurrentPoint;
x1 = cp(1,1);
y1 = cp(1,2);

idx_data=strcmp(src.Tag,multi_freq_disp_tab_comp.table.Data(:,5));
idx_c=strcmp(src.Tag,{layer.Curves(:).Unique_ID});
if any(idx_data)&&any(idx_c)
    text_obj=findobj(multi_freq_disp_tab_comp.ax,'Tag','DataText');
    txt_disp=sprintf('%s:\n%.1fdB @ %.0fkHz,',layer.Curves(idx_c).Name,y1,x1);
    if ~isempty(text_obj)
        set(text_obj,'Position',[x1,y1,0],'String',txt_disp,'Color',src.Color);
    else
        text(multi_freq_disp_tab_comp.ax,x1,y1,txt_disp,'Tag','DataText','Color',src.Color)
    end
end

end

