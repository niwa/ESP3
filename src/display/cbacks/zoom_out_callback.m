%% zoom_out_callback.m
%
% TODO
%
%% Help
%
% *USE*
%
% TODO
%
% *INPUT VARIABLES*
%
% * |src|: TODO
% * |main_figure|: TODO
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO: complete header and in-code commenting
%
% *NEW FEATURES*
%
% * 2017-03-22: header and comments (Alex Schimel)
% * 2017-03-21: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function zoom_out_callback(src,~,main_figure)

if check_axes_tab(main_figure)==0
    return;
end

layer=get_current_layer();
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');

trans=layer.get_trans(curr_disp);


xdata_tot=trans.get_transceiver_pings();
ydata_tot=trans.get_transceiver_samples();

ah=axes_panel_comp.echo_obj.main_ax;

cp = ah.CurrentPoint;
xx=ah.XLim;
yy=ah.YLim;

xinit = cp(1,1);
yinit = cp(1,2);

if xinit<xx(1)||xinit>xx(end)||yinit<yy(1)||yinit>yy(end)
    return;
end

switch src.SelectionType
    case 'normal'
        
        x_lim_ori=get(ah,'XLim');
        y_lim=get(ah,'YLim');
        
        dx=abs(diff(x_lim_ori));
        dy=diff(y_lim);
        
        x_lim(1)=x_lim_ori(1)-dx/2;
        y_lim(1)=y_lim(1)-dy/2;
        x_lim(2)=x_lim_ori(2)+dx/2;
        y_lim(2)=y_lim(2)+dy/2;
        
        x_lim(x_lim>max(xdata_tot))=max(xdata_tot);
        x_lim(x_lim<min(xdata_tot))=min(xdata_tot);
        
        
        y_lim(y_lim>max(ydata_tot))=max(ydata_tot);
        y_lim(y_lim<min(ydata_tot))=min(ydata_tot);
    case {'alt','open'}
        x_lim=[min(xdata_tot) max(xdata_tot)];
        y_lim=[min(ydata_tot) max(ydata_tot)];
    otherwise
        return;
        
end
set(ah,'XLim',x_lim,'YLim',y_lim);

end
