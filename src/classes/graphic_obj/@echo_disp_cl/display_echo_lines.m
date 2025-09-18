
function lines_plot_tot = display_echo_lines(echo_obj,trans_obj,line_obj,varargin)
%profile on;
curr_disp_default=curr_state_disp_cl();

p = inputParser;
addRequired(p,'echo_obj',@(x) isa(x,'echo_disp_cl'));
addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addRequired(p,'line_obj');
addParameter(p,'text_size',8,@isnumeric);
addParameter(p,'linewidth',0.5,@isnumeric);
addParameter(p,'curr_disp',curr_disp_default,@(x) isa(x,'curr_state_disp_cl'));

parse(p,echo_obj,trans_obj,line_obj,varargin{:});

curr_disp = p.Results.curr_disp;

lines_plot_tot =[];

curr_time=trans_obj.Time;
curr_pings=trans_obj.get_transceiver_pings();

curr_range=trans_obj.get_samples_range();
curr_dist=trans_obj.GPSDataPing.Dist;

main_axes=echo_obj.main_ax;

delete(echo_obj.lines_h);
u=findobj(main_axes,'tag','lines');
delete(u);

echo_obj.lines_h  =[];


if isempty(line_obj)
    return;
end

vis=curr_disp.DispLines;
cmap_struct = init_cmap(curr_disp.Cmap,curr_disp.ReverseCmap);

for il=1:numel(line_obj)
    active_line=line_obj(il);
    [~,~,y_line,~] = active_line.get_time_dist_and_range_corr(curr_time,curr_dist);

    switch echo_obj.echo_usrdata.geometry_y
        case'samples'
            dyi  =1/2;
        otherwise
            dyi  =0;
    end

    if ~isempty(y_line)
        %profile on;
       
        switch echo_obj.echo_usrdata.geometry_y
            case'samples'
                y_line=ceil(y_line./mean(diff(curr_range),'omitnan'))+dyi;
            otherwise
        end
        
        if isempty(y_line)
            warning('Line time does not match the current layer.');
            continue;
        end
        
        x_line=curr_pings;

        if strcmpi(line_obj(il).Tag,'Canopy')
            if isempty(line_obj(il).LineColor)
                cmap_struct.col_tracks = [0 0.75 0];
            else
                cmap_struct.col_tracks = line_obj(il).LineColor;
            end
        end
        if strcmp(line_obj(il).File_origin,'Bottom Line')
            if isempty(line_obj(il).LineColor)
                cmap_struct.col_tracks = [0 0 0];
            else
                cmap_struct.col_tracks = line_obj(il).LineColor;
            end
        end
        if ~isempty(line_obj(il).LineWidth)
            lwidth = line_obj(il).LineWidth;
            line_plot=plot(main_axes,x_line,y_line,'color',cmap_struct.col_tracks,'linewidth',lwidth,'tag','lines','visible',vis);
        else
            line_plot=plot(main_axes,x_line,y_line,'color',cmap_struct.col_tracks,'linewidth',p.Results.linewidth,'tag','lines','visible',vis);
        end

        switch main_axes.Tag
            case 'main'
                line_plot.UserData.Annotation_h = [];
                line_plot.UserData.ID = active_line.ID;
                pointerBehavior.enterFcn    = @(src, evt) enter_line_plot_fcn(src, evt,line_plot,active_line);
                pointerBehavior.exitFcn     = @(src, evt) exit_line_plot_fcn(src, evt,line_plot);
                pointerBehavior.traverseFcn = [];
                iptSetPointerBehavior(line_plot,pointerBehavior);
                create_line_context_menu(line_plot);
        end
        lines_plot_tot = [lines_plot_tot line_plot];
    end
    echo_obj.lines_h = lines_plot_tot;
end
%profile off;
%profile viewer;

    function exit_line_plot_fcn(~,~,hplot)
        
        if ~isvalid(hplot)
            delete(hplot);
            return;
        end
        if ~isempty(active_line.LineWidth)
            set(hplot,'linewidth',active_line.LineWidth);
            if ~isempty(hplot.UserData.Annotation_h)
                delete(hplot.UserData.Annotation_h);
            end
        end
        hplot.UserData.Annotation_h = [];
    end

    function enter_line_plot_fcn(src,evt,hplot,l_obj)
        
        if ~isvalid(hplot)
            delete(hplot);
            return;
        end
        
        set(src, 'Pointer', 'hand');
        if ~isempty(l_obj.LineWidth)&&isnumeric(l_obj.LineWidth)
            set(hplot,'linewidth',l_obj.LineWidth+1.5);
        else
            l_obj.LineWidth = 0.5;
            set(hplot,'linewidth',l_obj.LineWidth+1.5);
        end
        
        switch src.Tag
            case 'ESP3'
                ax=ancestor(hplot,'axes');
                cp=ax.CurrentPoint;
                if isempty(hplot.UserData.Annotation_h)
                    hplot.UserData.Annotation_h = text(ax,cp(1,1),cp(1,2),sprintf('%s',sprintf('%s',l_obj.print())),...
                        'EdgeColor',cmap_struct.col_txt,'BackgroundColor',cmap_struct.col_ax,'VerticalAlignment','Bottom','Interpreter','none','Color',cmap_struct.col_txt);
                else
                    set(hplot.UserData.Annotation_h,'Position',[cp(1,1),cp(1,2)],'String',sprintf('%s',l_obj.print()));
                end
            otherwise
                if isempty(hplot.UserData.Annotation_h)
                    hplot.UserData.Annotation_h = annotation(src,'textbox',[0 0 0 0],'Units',src.Units,...
                        'String',sprintf('%s',sprintf('%s',l_obj.print())),'Color',cmap_struct.col_txt,'EdgeColor',cmap_struct.col_txt,'BackgroundColor',cmap_struct.col_ax,...
                        'VerticalAlignment','Bottom','Interpreter','none');
                end
                set(hplot.UserData.Annotation_h,'Position',[evt(1) evt(2) 0 0],'String',sprintf('%s',l_obj.print()),'FitBoxToText','on');
        end
    end
end
