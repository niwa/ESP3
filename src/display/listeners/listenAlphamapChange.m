function listenAlphamapChange(~,listdata,main_figure,prop)

main_menu=getappdata(main_figure,'main_menu');
set(main_menu.(prop),'checked',listdata.AffectedObject.(prop));
main_figure.Alphamap = listdata.AffectedObject.get_alphamap();

end