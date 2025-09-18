function listenDispReg(~,listdata,main_figure)
main_menu=getappdata(main_figure,'main_menu');
set(main_menu.DispReg,'checked',listdata.AffectedObject.DispReg);
toggle_disp_regions(main_figure);
end