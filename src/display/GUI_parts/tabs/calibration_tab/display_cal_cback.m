function display_cal_cback(~,~,main_figure)

layer=get_current_layer();

cal_fig=new_echo_figure(main_figure,'Tag','calibration');
layer.display_cal(cal_fig);


end