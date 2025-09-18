function format_color_gui(fig,font_choice,cmap,varargin)

if ~isempty(cmap)&&nargin>3
    if isstruct(cmap)
        cmap_struct = cmap;
    else
        cmap_struct = init_cmap(cmap);
        colormap(fig,cmap_struct.cmap);
    end
else
    cmap_struct.col_ax=[0.98 0.98 1];
    cmap_struct.col_lab=[0 0 0.2];
    cmap_struct.col_grid = [0.95 0.95 1];
end

for uif=1:length(fig)
    if ~isvalid(fig(uif))
        continue;
    end
    if isprop(fig(uif),'Color')
        set(fig(uif),'Color',cmap_struct.col_ax);
    end

    if isprop(fig(uif),'BackgroundColor')
        set(fig(uif),'BackgroundColor',cmap_struct.col_ax);
    end

    c_obj=findobj(fig(uif),'Type','colorbar');
    set(c_obj,'Color',cmap_struct.col_lab);

    panel_obj=findobj(fig(uif),'Type','uipanel');
    set(panel_obj,'BackgroundColor',cmap_struct.col_ax,'bordertype','line','ForegroundColor',cmap_struct.col_lab,'HighlightColor',cmap_struct.col_ax);

    uibut_obj=findobj(fig(uif),'Type','uibuttongroup');
    set(uibut_obj,'bordertype','line','HighlightColor',cmap_struct.col_grid);

    tab_obj=findobj(fig(uif),'Type','uitab','-property','BackgroundColor');
    set(tab_obj,'BackgroundColor',cmap_struct.col_ax);

    if nargin>3
        ax_obj=findobj(fig(uif),'Type','axes');
        set(ax_obj,'Color',cmap_struct.col_ax,'GridColor',...
            cmap_struct.col_grid,'MinorGridColor',cmap_struct.col_grid,'XColor',cmap_struct.col_lab,'YColor',cmap_struct.col_lab);
        set([ax_obj(:).Title],'Color',cmap_struct.col_lab);
        uigl_obj =findobj(fig(uif),'Type','uigridlayout');
        set(uigl_obj,'BackgroundColor',cmap_struct.col_ax);
        l_obj=findobj(fig(uif),'Type','legend');
        set(l_obj,'TextColor',cmap_struct.col_lab,'Color',cmap_struct.col_ax);

    end
    buttongroup_obj=findobj(fig(uif),'Type','uibuttongroup','-property','BackgroundColor');
    set(buttongroup_obj,'BackgroundColor',cmap_struct.col_ax,'ForegroundColor',cmap_struct.col_lab);

    control_obj=findobj(fig(uif),'Type','uicontrol','-not',{'Style','popupmenu','-or','Style','edit','-or','Style','pushbutton'});
    %control_obj=findobj(fig(i),'Type','uicontrol');
    set(control_obj,'BackgroundColor',cmap_struct.col_ax);



    load_bar_comp=getappdata(fig(uif),'Loading_bar');
    if ~isempty(load_bar_comp)
        load_bar_comp.progress_bar.progaxes.Color=cmap_struct.col_ax;
        load_bar_comp.progress_bar.progaxes.GridColor=cmap_struct.col_lab;
    end

    if ~isempty(font_choice)
        if strcmp(fig(uif).Tag,'font_choice')
            continue;
        end
        text_obj=findobj(fig(uif),'-property','FontName');
        if ~isempty(text_obj)
            set(text_obj,'FontName',font_choice);
        end
    end

    % size_obj=findobj(fig,'-property','FontSize');
    % set(size_obj,'FontSize',12);
end
end