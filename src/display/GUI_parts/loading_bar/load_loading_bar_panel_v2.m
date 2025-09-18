function load_loading_bar_panel_v2(main_figure)

if isappdata(main_figure,'Loading_bar')
    load_bar_comp=getappdata(main_figure,'Loading_bar');
    delete(load_bar_comp.panel);
    delete(load_bar_comp.progress_bar);
    rmappdata(main_figure,'Loading_bar');
end

pix_pos=getpixelposition(main_figure);

load_bar_comp.panel=uipanel(main_figure,'Units','pixels','Position',...
    [0 0 pix_pos(3) 25],'BackgroundColor',[1 1 1],'tag','load_panel','visible','on','BorderType','line');

load_bar_comp.progress_bar=progress_bar_panel_cl(load_bar_comp.panel);

setappdata(main_figure,'Loading_bar',load_bar_comp);

end

