%% edit_line.m
%
% function allowing user to ineractively edit the currently active line
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |src|: TODO: write description and info on variable
% * |cbackdata|: TODO: write description and info on variable
% * |main_figure|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2022-01-19: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function edit_line(src,~,main_figure)


if check_axes_tab(main_figure)==0
    return;
end

layer=get_current_layer();
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');

mouse_state=1;

ah=axes_panel_comp.echo_obj.main_ax;

clear_lines(ah);


layer=get_current_layer();
lines_tab_comp=getappdata(main_figure,'Lines_tab');
nb_lines=numel(layer.Lines);

if ~isempty(layer.Lines)
    active_line=layer.Lines(min(nb_lines,get(lines_tab_comp.tog_line,'value')));
else
    return
end
%disp(active_line)
% old_l = line_cl;
% old_l.Prop = active_line;
old_line=active_line.copy_line; %copy(old_l);

cmap_struct = init_cmap(curr_disp.Cmap,curr_disp.ReverseCmap);

[trans_obj,~]=layer.get_trans(curr_disp);

xdata=trans_obj.get_transceiver_pings();
ydata=trans_obj.get_transceiver_samples();

t_range = trans_obj.get_samples_range();
t_time = trans_obj.get_transceiver_time();
t_dist = trans_obj.GPSDataPing.Dist;  

[time_line,~,range_line] = active_line.get_time_dist_and_range_corr(t_time,t_dist);

x_lim=get(ah,'xlim');
y_lim=get(ah,'ylim');

nb_pings=length(trans_obj.Time);

xinit=nan(1,nb_pings);
yinit=nan(1,nb_pings);
idx_ping=[];
cp = ah.CurrentPoint;
xinit(1) =cp(1,1);
yinit(1)=cp(1,2);
% x0=xinit(1);
% y0=yinit(1);
u=1;
if xinit(1)<x_lim(1)||xinit(1)>x_lim(end)||yinit(1)<y_lim(1)||yinit(1)>y_lim(end)
    return;
end



switch src.SelectionType
    case {'normal','alt','extend'}
        hp=plot(ah,xinit,yinit,'color',cmap_struct.col_bot,'linewidth',1,'Tag','bottom_temp');

        switch src.SelectionType
            case 'normal'
                replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb_ext);
                replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',1,'interaction_fcn',@wbucb);
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',@wbdcb_ext);
            case 'alt'
                return;
        end
    otherwise
        [~, idx_t]=min(abs(xinit(1)-xdata),[],'omitnan');
        [~,idx_r]=min(abs(yinit(1)-ydata),[],'omitnan');

        range_line(idx_t)=t_range(idx_r);

        end_line_edit(1);
end


    function wbmcb_ext(~,~)
        cp=ah.CurrentPoint;

        switch mouse_state
            case 1
                u=sum(~isnan(xinit),"omitnan")+1;
        end
        xinit(u)=cp(1,1);
        yinit(u)=cp(1,2);
        if isvalid(hp)
            set(hp,'XData',xinit,'YData',yinit);
        else
            hp=plot(ah,xinit,yinit,'color',cmap_struct.col_bot,'linewidth',1,'Tag','bottom_temp');
        end


    end

    function wbdcb_ext(~,~)
        mouse_state=1;
        [x_f,y_f]=check_xy();
        update_line(x_f,y_f);
        switch src.SelectionType
            case {'open' 'alt'}
                delete(hp);
                replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
                replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',1);
                end_line_edit(1);
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@edit_line,main_figure});
                return;
        end

        u=sum(~isnan(xinit),'omitnan')+1;
    end

    function [x_f, y_f]=check_xy()
        xinit(isnan(xinit))=[];
        yinit(isnan(yinit))=[];
        x_rem=xinit>xdata(end)|xinit<xdata(1);
        y_rem=yinit>ydata(end)|yinit<ydata(1);

        xinit(x_rem|y_rem)=[];
        yinit(x_rem|y_rem)=[];

        [x_f,IA,~] = unique(xinit);
        y_f=yinit(IA);
    end

    function wbucb(~,~)
        mouse_state=0;
        if u==1
            xinit(u)=cp(1,1);
            yinit(u)=cp(1,2);
            u=2;
        end

    end

    function update_line(x_f,y_f)

        if length(x_f)>1
            for i=1:length(x_f)-1
                [~, idx_t]=min(abs(x_f(i)-xdata),[],'omitnan');
                [~, idx_t_1]=min(abs(x_f(i+1)-xdata),[],'omitnan');

                [~,idx_r]=min(abs(y_f(i)-ydata),[],'omitnan');
                [~,idx_r1]=min(abs(y_f(i+1)-ydata),[],'omitnan');

                idx_t=(idx_t:idx_t_1);

                range_line(idx_t)=t_range(round(linspace(idx_r,idx_r1,length(idx_t))));
                idx_ping=union(idx_ping,idx_t);
            end
        elseif isscalar(x_f)
            [~, idx_t]=min(abs(x_f-xdata),[],'omitnan');
            [~,idx_r]=min(abs(y_f-ydata),[],'omitnan');
            range_line(idx_t)=t_range(idx_r);
            idx_ping=union(idx_ping,idx_t);
        end

    end

    function end_line_edit(val)
    
        active_line.Data = resample_data_v2(active_line.Data ,active_line.Time,time_line);
        active_line.Range = range_line;
        active_line.Time = time_line;
        active_line.UTC_diff = 0;
        active_line.Dist_diff  = 0;
        active_line.Dr = 0;

        layer.add_lines(active_line);

        if strcmpi(active_line.Tag,'Offset')
            for idx=1:numel(layer.Transceivers)
                trans_obj=layer.Transceivers(idx);
                trans_obj.set_transducer_depth_from_line(active_line);
            end
            curr_disp.DispSecFreqs=curr_disp.DispSecFreqs;
        end        
        
        new_line = active_line;

        if val>0 
            add_undo_line_action(main_figure,trans_obj,old_line,new_line)
        end
        
        update_lines_tab(main_figure);
        display_lines();

    end



end
