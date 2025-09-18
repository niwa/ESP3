%% inter_region_create.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |main_figure|: TODO: write description and info on variable
% * |mode|: TODO: write description and info on variable
% * |func|: TODO: write description and info on variable
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
% * 2017-03-28: header (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function inter_region_create(main_figure,mode,func)

layer=get_current_layer();
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');
ah=axes_panel_comp.echo_obj.main_ax;

switch main_figure.SelectionType
    case 'normal'
        
    otherwise
        %         curr_disp.CursorMode='Normal';
        return;
end
axes_panel_comp.echo_obj.echo_bt_surf.UIContextMenu=[];
axes_panel_comp.echo_obj.bottom_line_plot.UIContextMenu=[];
cmap_struct = init_cmap(curr_disp.Cmap,curr_disp.ReverseCmap);

clear_lines(ah);

[trans_obj,idx_freq]=layer.get_trans(curr_disp);
xdata=trans_obj.get_transceiver_pings();
ydata=trans_obj.get_transceiver_samples();

rr=trans_obj.get_samples_range();


%xdata=double(get(axes_panel_comp.echo_obj.echo_surf,'XData'));
%ydata=double(get(axes_panel_comp.echo_obj.echo_surf,'YData'));
x_lim=get(ah,'xlim');
y_lim=get(ah,'ylim');

cp = ah.CurrentPoint;
xinit = cp(1,1);
yinit = cp(1,2);
xx = min(ceil(cp(1,2)),numel(rr));

if xinit<x_lim(1)||xinit>x_lim(end)||yinit<y_lim(1)||yinit>y_lim(end)||isempty(rr)
    return;
end

u=1;
switch mode
    case 'rectangular'
        xinit = cp(1,1);
        yinit = cp(1,2);
    case 'horizontal'
        xinit = xdata(1);
        yinit = cp(1,2);
    case 'vertical'
        xinit = cp(1,1);
        yinit = ydata(1);
end

x_box=xinit;
y_box=yinit;


hp=patch(ah,'XData',xinit,'YData',yinit,'FaceColor',cmap_struct.col_lab,'FaceAlpha',0.4,'EdgeColor',cmap_struct.col_lab,'linewidth',0.5,'Tag','reg_temp');
txt=text(ah,cp(1,1),cp(1,2),sprintf('%.2f m',rr(xx)),'color',cmap_struct.col_lab,'Tag','reg_temp');

replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb);
replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb);


    function wbmcb(~,~)
        cp = ah.CurrentPoint;
        xx = min(ceil(cp(1,2)),numel(rr));
        u=u+1;
        
        switch mode
            case 'rectangular'
                X = [xinit,cp(1,1)];
                Y = [yinit,cp(1,2)];
            case 'horizontal'
                X = [xinit,xdata(end)];
                Y = [yinit,cp(1,2)];
            case 'vertical'
                X = [xinit,cp(1,1)];
                Y = [yinit,ydata(end)];
                
        end
        
        x_min=min(X);
        x_min=max(xdata(1),x_min);
        
        x_max=max(X);
        x_max=min(xdata(end),x_max);
        
        y_min=min(Y);
        y_min=max(y_min,ydata(1));
        
        y_max=max(Y);
        y_max=min(y_max,ydata(end));
        
        x_box=([x_min x_max  x_max x_min x_min]);
        y_box=([y_max y_max y_min y_min y_max]);
        
        if cp(1,2)<0
            return;
        end
        
        str_txt=sprintf('%.2f m',rr(xx));
        
        if isvalid(hp)
            set(hp,'XData',x_box,'YData',y_box,'Tag','reg_temp');
        else
            hp=patch(ah,'XData',x_box,'YData',y_box,'FaceColor',cmap_struct.col_lab,'FaceAlpha',0.4,'EdgeColor',cmap_struct.col_lab,'linewidth',0.5,'Tag','reg_temp');
        end
        
        if isvalid(txt)
            set(txt,'position',[cp(1,1) cp(1,2) 0],'string',str_txt);
        else
            txt=text(cp(1,1),cp(1,2),str_txt,'color',cmap_struct.col_lab);
        end
        
    end

    function wbucb(main_figure,~)
        
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2);
        
        layer=get_current_layer();
        
        [trans_obj,idx_freq]=layer.get_trans(curr_disp);
        
        if isempty(y_box)||isempty(x_box)
            delete(txt);
            delete(hp);
            return;
        end
        
        x_box=round(x_box);
        y_box=round(y_box);
        
        y_min=min(y_box);
        y_max=max(y_box);
        
        y_min=max(y_min,ydata(1));
        y_max=min(y_max,ydata(end));
        
        x_min=min(x_box);
        x_min=round(max(xdata(1),x_min));
        
        x_max=max(x_box);
        x_max=round(min(xdata(end),x_max));
           
        idx_ping=find(xdata<=x_max&xdata>=x_min);
        idx_r=find(ydata<=y_max&ydata>=y_min);
        
        switch mode
            case 'horizontal'
                idx_ping=1:length(trans_obj.get_transceiver_pings());
            case 'vertical'
                idx_r=1:length(trans_obj.get_transceiver_samples());   
        end
        delete(txt);
        delete(hp);
        
        feval(func,main_figure,idx_r,idx_ping);
        
        
    end



end