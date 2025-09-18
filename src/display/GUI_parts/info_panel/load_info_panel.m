function load_info_panel(main_figure,info_panel)

if isappdata(main_figure,'Info_panel')
    info_panel_comp=getappdata(main_figure,'Info_panel');
    if isvalid(info_panel_comp.info_panel)     
        delete(get(info_panel_comp.info_panel,'children'));
        
        if ~isempty(info_panel)
            delete(info_panel_comp.info_panel)
        else
            info_panel = info_panel_comp.info_panel;
        end
        
    end
end

if ~isempty(info_panel)
    info_panel_comp = [];
    info_panel_comp.info_panel=info_panel;  
else
   setappdata(main_figure,'Info_panel',info_panel_comp);
   return 
end


info_panel_comp.xy_disp=uicontrol(info_panel_comp.info_panel,'Style','Text','String','','units','normalized','Position',[0 0 0.2 1],'BackgroundColor',[1 1 1]);

info_panel_comp.pos_disp=uicontrol(info_panel_comp.info_panel,'Style','Text','String','','units','normalized','Position',[0.2 0 0.1 1],'BackgroundColor',[1 1 1]);

info_panel_comp.time_disp=uicontrol(info_panel_comp.info_panel,'Style','Text','String','','units','normalized','Position',[0.3 0.5 0.15 0.5],'BackgroundColor',[1 1 1]);
info_panel_comp.value=uicontrol(info_panel_comp.info_panel,'Style','Text','String','','units','normalized','Position',[0.3 0 0.15 0.5],'BackgroundColor',[1 1 1]);

info_panel_comp.i_str=uicontrol(info_panel_comp.info_panel,'Style','Text','String','','units','normalized','Position',[0.45 0.5 0.35 0.5],'BackgroundColor',[1 1 1]);

info_panel_comp.cursor_mode=uicontrol(info_panel_comp.info_panel,'Style','Text','String','','units','normalized','Position',[0.45 0 0.1 0.5],'BackgroundColor',[1 1 1]);
info_panel_comp.percent_BP=uicontrol(info_panel_comp.info_panel,'Style','Text','String','','units','normalized','Position',[0.55 0 0.1 0.5],'BackgroundColor',[1 1 1]);
info_panel_comp.display_subsampling=uicontrol(info_panel_comp.info_panel,'Style','Text','String','','units','normalized','Position',[0.65 0 0.15 0.5],'BackgroundColor',[1 1 1]);

info_panel_comp.summary=uicontrol(info_panel_comp.info_panel,'Style','Text','String','','units','normalized','Position',[0.8 0.0 0.2 1],'BackgroundColor',[1 1 1]);

pt_int.enterFcn =  @(figHandle, currentPoint)...
replace_interaction(figHandle,'interaction','WindowButtonMotionFcn','id',1);
pt_int.exitFcn = [];
pt_int.traverseFcn = [];

iptSetPointerBehavior(info_panel_comp.info_panel,pt_int);


% info_panel.proc_axes=axes('parent',info_panel_comp.info_panel,'Units','normalized','Position',[0 0 0.05 1],'Visible','off');
% imshow(fullfile(whereisEcho(),'icons','done.png'));
setappdata(main_figure,'Info_panel',info_panel_comp);

end

