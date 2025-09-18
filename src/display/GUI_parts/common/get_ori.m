function [idx_r_ori,idx_ping_ori]=get_ori(layer,curr_disp,main_echo)

xdata=double(get(main_echo,'XData'));
ydata=double(get(main_echo,'YData'));


switch main_echo.Type
    case 'surface'
        xdata=xdata+1/2;
end

[trans_obj,~]=layer.get_trans(curr_disp);
trans=trans_obj;
Number=trans.get_transceiver_pings();
Samples=trans.get_transceiver_samples();
[~,idx_ping_ori]=min(abs(xdata(1)-Number));

[~,idx_r_ori]=min(abs(ydata(1)-Samples));
end