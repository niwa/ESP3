function [row_h,col_w]=get_top_panel_height(nb)
gui_fmt=init_gui_fmt_struct('pixels');

switch gui_fmt.txtStyle.units
    case {'char','characters'}
        def_str='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz 0123456789()';
        tmp= uicontrol('Style','text','units','pixels','String',def_str,'visible','off','FontSize',gui_fmt.txtStyle.fontsize);
        h=get(tmp,'Extent');
        
        mw = max(h(3)/numel(def_str),7);
        mh = max(h(4),18);
        delete(tmp);
    otherwise
        mw = 1;
        mh = 1;
end

col_w = (2*gui_fmt.x_sep+gui_fmt.txt_w+gui_fmt.box_w)*mw;
row_h=(gui_fmt.y_sep*(nb+3)+gui_fmt.box_h*(nb+1))*mh;

end