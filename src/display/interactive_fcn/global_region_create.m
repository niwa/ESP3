%% global_region_create.m
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
% * 2017-03-24: header (Alex Schimel)
% * 2017-03-24: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function global_region_create(main_figure,shape,mode)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');

[echo_obj,trans_obj,~,~]=get_axis_from_cids(main_figure,{'main'});
ah=echo_obj.main_ax;

switch main_figure.SelectionType
    case 'normal'

    otherwise
        %         curr_disp.CursorMode='Normal';
        return;
end

echo_obj.echo_bt_surf.UIContextMenu=[];
echo_obj.bottom_line_plot.UIContextMenu=[];

clear_lines(ah);

cmap_struct = init_cmap(curr_disp.Cmap,curr_disp.ReverseCmap);

[trans_obj,~]=layer.get_trans(curr_disp);


[x,y,idx_p,idx_r] = echo_obj.get_main_ax_cp(trans_obj);
if isempty(idx_p)||isempty(idx_r)
    return;
end

xinit(1) = idx_p;
yinit(1)= idx_r;

u=2;

xdata=trans_obj.get_transceiver_pings();
ydata=trans_obj.get_transceiver_samples();

x_lim=get(ah,'xlim');
y_lim=get(ah,'ylim');

if xinit(1)<x_lim(1)||xinit(1)>xdata(end)||yinit(1)<y_lim(1)||yinit(1)>y_lim(end)
    return;
end

rr=trans_obj.get_samples_range();
hp=patch(ah,'XData', xinit,'YData',yinit,'FaceColor',cmap_struct.col_lab,'FaceAlpha',0.4,'EdgeColor',cmap_struct.col_lab,'linewidth',0.5,'Tag','reg_temp');
txt=text(ah,x,y,sprintf('%.2f m',rr(min(ceil(idx_r),numel(rr)))),'color',cmap_struct.col_lab,'Tag','reg_temp');

switch shape
    case 'Polygon'
        func = @create_poly_region_func;
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb_ext);
        replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',@wbdcb_ext);
    case 'Hand Drawn'
        func = @create_poly_region_func;
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb);
    case 'Rectangular'
        func = @create_region_func;
        switch mode
            case 'rectangular'

            case 'horizontal'
                xinit = xdata(1);
            case 'vertical'
                yinit = ydata(1);
        end
        xbox=([xinit xinit  xinit xinit xinit]);
        ybox=([yinit yinit yinit yinit yinit]);
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb_box);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb);
end

    function wbmcb(~,~)

        [x,y,idx_p,idx_r] = echo_obj.get_main_ax_cp(trans_obj);

        if isempty(idx_p)||isempty(idx_r)
            return;
        end


        xinit(u) = idx_p;
        yinit(u) = idx_r;

        if isvalid(hp)
            set(hp,'XData',xinit,'YData',yinit);
        else
            hp=patch(ah,'XData',xinit,'YData',yinit,'FaceColor',cmap_struct.col_lab,'FaceAlpha',0.4,'EdgeColor',cmap_struct.col_lab,'linewidth',0.5,'Tag','reg_temp');
        end

        if isvalid(txt)
            set(txt,'position',[x y 0],'string',sprintf('%.2f m',rr(yinit(u))));
        else
            txt=text(ah,x,y,sprintf('%.2f m',rr(yinit(u))),'color',cmap_struct.col_lab,'Tag','reg_temp');
        end
        u=u+1;

    end

    function wbmcb_box(~,~)
        [x,y,idx_p,idx_r] = echo_obj.get_main_ax_cp(trans_obj);

        if isempty(idx_p)||isempty(idx_r)
            return;
        end

        X = [xinit,idx_p];
        Y = [yinit,idx_r];

        switch mode
            case 'rectangular'

            case 'horizontal'
                X = [xinit,xdata(end)];
            case 'vertical'
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

        xbox=([x_min x_max  x_max x_min x_min]);
        ybox=([y_max y_max y_min y_min y_max]);


        str_txt=sprintf('%.2f m',rr(idx_r));

        if isvalid(hp)
            set(hp,'XData',xbox,'YData',ybox,'Tag','reg_temp');
        else
            hp=patch(ah,'XData',xbox,'YData',ybox,'FaceColor',cmap_struct.col_lab,'FaceAlpha',0.4,'EdgeColor',cmap_struct.col_lab,'linewidth',0.5,'Tag','reg_temp');
        end

        if isvalid(txt)
            set(txt,'position',[x y 0],'string',str_txt);
        else
            txt=text(x,y,str_txt,'color',cmap_struct.col_lab);
        end

    end

    function wbmcb_ext(~,~)

        [x,y,idx_p,idx_r] = echo_obj.get_main_ax_cp(trans_obj);

        if isempty(idx_p)||isempty(idx_r)
            return;
        end

        xinit(u) = idx_p;
        yinit(u) = idx_r;

        if isvalid(hp)
            set(hp,'XData',xinit,'YData',yinit);
        else
            hp=patch(ah,'XData',xinit,'YData',yinit,'FaceColor',cmap_struct.col_lab,'FaceAlpha',0.4,'EdgeColor',cmap_struct.col_lab,'linewidth',0.5,'Tag','reg_temp');
        end

        if isvalid(txt)
            set(txt,'position',[x y 0],'string',sprintf('%.2f m',rr(yinit(u))));
        else
            txt=text(ah,x,y,sprintf('%.2f m',rr(yinit(u))),'color',cmap_struct.col_lab,'Tag','reg_temp');
        end
    end

    function wbdcb_ext(~,~)

        switch main_figure.SelectionType
            case {'open' 'alt'}

                wbucb(main_figure,[]);
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@create_region,main_figure,'Polygon',''});

                %                 set(enabled_obj,'Enable','on');
                return;
        end

        check_xy();
        u=length(xinit)+1;

        if isvalid(hp)
            set(hp,'XData',xinit,'YData',yinit);
        else
            hp=plot(ah,xinit,yinit,'color',cmap_struct.col_lab,'linewidth',1,'Tag','reg_temp');
        end


    end

    function check_xy()
        xinit(isnan(xinit))=[];
        yinit(isnan(yinit))=[];
        x_rem=xinit>xdata(end)|xinit<xdata(1);
        y_rem=yinit>ydata(end)|yinit<ydata(1);

        xinit(x_rem|y_rem)=[];
        yinit(x_rem|y_rem)=[];


    end

    function wbucb(main_figure,~)

        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2);
        x_data_disp=linspace(xdata(1),xdata(end),length(xdata));
        clear_lines(ah)
        delete(txt);
        delete(hp);
        
        switch shape
            case {'Hand Drawn' 'Polygon'}
                check_xy()

                [~,poly_pings]=min(abs(xinit-double(x_data_disp')));
                [~,poly_r]=min(abs(yinit-double(ydata)));

                if length(poly_pings)<=2
                    return;
                end
                poly_pings=([poly_pings poly_pings(1)]);
                poly_r=([poly_r poly_r(1)]);
            case 'Rectangular'

                y_min=min(ybox);
                y_max=max(ybox);

                y_min=max(y_min,ydata(1));
                y_max=min(y_max,ydata(end));

                x_min=min(xbox);
                x_min=round(max(xdata(1),x_min));

                x_max=max(xbox);
                x_max=round(min(xdata(end),x_max));

                poly_pings=find(xdata<=x_max&xdata>=x_min);
                poly_r=find(ydata<=y_max&ydata>=y_min);

                switch mode
                    case 'horizontal'
                        poly_pings=1:length(trans_obj.get_transceiver_pings());
                    case 'vertical'
                        poly_r=1:length(trans_obj.get_transceiver_samples());
                end
        end
       
        feval(func,main_figure,poly_r,poly_pings);


    end


end
