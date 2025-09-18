function update_echo_int_tab(main_figure,new)

if ~isappdata(main_figure,'EchoInt_tab')
    echo_tab_panel=getappdata(main_figure,'echo_tab_panel');
    load_echo_int_tab(main_figure,echo_tab_panel);
    return;
end

echo_int_tab_comp=getappdata(main_figure,'EchoInt_tab');
layer_obj=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
cmap_struct = init_cmap(curr_disp.Cmap,curr_disp.ReverseCmap);
cmap = cmap_struct.cmap;

surv_options_obj=layer_obj.get_survey_options();

if isempty(surv_options_obj)
    surv_options_obj=survey_options_cl();
end

if new>0||isempty(layer_obj.EchoIntStruct)||numel(layer_obj.EchoIntStruct.idx_freq_out)<echo_int_tab_comp.tog_tfreq.Value
    [~,idx_freq]=layer_obj.get_trans(curr_disp);
else
    [~,idx_freq] = layer_obj.get_trans(layer_obj.Frequencies(layer_obj.EchoIntStruct.idx_freq_out(echo_int_tab_comp.tog_tfreq.Value)));
end

if isempty(layer_obj.GPSData.Lat)
    units_w= {'pings','seconds'};
    xaxis_opt={'Ping Number' 'Time'};
else
    units_w= {'meters','pings','seconds'};
    xaxis_opt={'Distance' 'Ping Number' 'Time' 'Lat' 'Long'};
end

set(echo_int_tab_comp.cell_w_unit,'String',units_w);

idx_w=find(strcmpi(echo_int_tab_comp.cell_w_unit.String,surv_options_obj.Vertical_slice_units.Value));

if isempty(idx_w)
    idx_w=1;
end

if ~isempty(echo_int_tab_comp.cell_w_unit.Value)
    echo_int_tab_comp.cell_w_unit.Value=idx_w;
end

echo_int_tab_comp.cell_w.String=num2str(surv_options_obj.Vertical_slice_size.Value);
echo_int_tab_comp.cell_h.String=num2str(surv_options_obj.Horizontal_slice_size.Value);

echo_int_tab_comp.denoised.Value=surv_options_obj.Denoised.Value;
echo_int_tab_comp.sv_thr_bool.Value=surv_options_obj.SvThr.Value>-999;
echo_int_tab_comp.sv_thr.String=num2str(surv_options_obj.SvThr.Value);

echo_int_tab_comp.shadow_zone.Value=surv_options_obj.Shadow_zone.Value;
echo_int_tab_comp.shadow_zone_h.String=num2str(surv_options_obj.Shadow_zone_height.Value);

echo_int_tab_comp.d_min.String=num2str(surv_options_obj.DepthMin.Value);
echo_int_tab_comp.d_max.String=num2str(surv_options_obj.DepthMax.Value);

echo_int_tab_comp.motion_correction.Value=surv_options_obj.Motion_correction.Value;

set(echo_int_tab_comp.tog_xaxis,'String',xaxis_opt);

if echo_int_tab_comp.tog_xaxis.Value>numel(xaxis_opt)
    echo_int_tab_comp.tog_xaxis.Value=1;
end

if new>0
    set(echo_int_tab_comp.tog_freq,'String',layer_obj.Transceivers.get_CID_freq_str(),'Value',idx_freq);
    reset_plot(echo_int_tab_comp);
end

if ~isempty(layer_obj.EchoIntStruct.idx_freq_out)
    ChannelIDs=layer_obj.ChannelID(min(layer_obj.EchoIntStruct.idx_freq_out,numel(layer_obj.Frequencies)));
    idx_main=find(strcmpi(ChannelIDs,layer_obj.ChannelID(idx_freq)));
    if isempty(idx_main)
        idx_main=1;
    end
    [~,idx_c] = intersect(layer_obj.ChannelID,ChannelIDs);
    sss = layer_obj.Transceivers.get_CID_freq_str();
    set(echo_int_tab_comp.tog_tfreq,'String',sss(idx_c),'Value',idx_main);
else
    set(echo_int_tab_comp.tog_tfreq,'String','--','Value',1);
    idx_main=[];
end


if isempty(layer_obj.EchoIntStruct.idx_freq_out)
    setappdata(main_figure,'EchoInt_tab',echo_int_tab_comp);
    return;
end

if echo_int_tab_comp.tog_ref.Value > numel(echo_int_tab_comp.tog_ref.String)
    echo_int_tab_comp.tog_ref.Value  = 1;
end

if ~isempty(idx_main)&&~isempty(layer_obj.EchoIntStruct.output_2D{idx_main})
    echo_int_tab_comp.tog_ref.String =layer_obj.EchoIntStruct.output_2D_type{idx_main};
    id_val = min(echo_int_tab_comp.tog_ref.Value,numel(echo_int_tab_comp.tog_ref.String));
    idx_ref=find(strcmpi(echo_int_tab_comp.tog_ref.String{id_val},layer_obj.EchoIntStruct.output_2D_type{idx_main}));

    if isempty(idx_ref)
        idx_ref=1;
    end

    echo_int_tab_comp.tog_ref.Value = idx_ref;
    ref=layer_obj.EchoIntStruct.output_2D_type{idx_main}{idx_ref};

    out=layer_obj.EchoIntStruct.output_2D{idx_main}{idx_ref};

    s_eint=gather(size(out.ABC));

    if all(s_eint==1)
        return;
    end

    %{'Ping Number' 'Distance' 'Time' 'Lat' 'Long'}
    x_disp_t=echo_int_tab_comp.tog_xaxis.String{echo_int_tab_comp.tog_xaxis.Value};

    switch x_disp_t
        case 'Ping Number'
            x_disp=out.Ping_S;
        case 'Distance'
            x_disp=out.Dist_S;
        case  'Time'
            x_disp=out.Time_S;
        case 'Lat'
            x_disp=out.Lat_S;
        case 'Long'
            x_disp=out.Lon_S;
    end
    
    if  ~any(~isnan(x_disp))
        x_disp=out.Time_S;
        x_disp_t='Time';
    end

    x_ticks=unique(mean(x_disp,1));

    nb_x=numel(x_ticks);
    dx=floor(nb_x/20);

    if dx>1
        x_ticks=x_ticks(1:dx:end);
    end
    nb_x=numel(x_ticks);

    if ~isfield(layer_obj.EchoIntStruct,'survey_option') || isempty(layer_obj.EchoIntStruct.survey_option)
        s_opt = layer_obj.get_survey_options();
    else
        s_opt = layer_obj.EchoIntStruct.survey_option;
    end

    if (strcmpi(x_disp_t,'Distance')&&strcmpi(s_opt.Vertical_slice_units,'meters'))||...
            (strcmpi(x_disp_t,'Ping Number')&&strcmpi(s_opt.Vertical_slice_units,'pings'))...
            ||(strcmpi(x_disp_t,'Time')&&strcmpi(s_opt.Vertical_slice_units,'seconds'))
        xl=num2cell(floor(x_ticks/s_opt.Vertical_slice_size)*s_opt.Vertical_slice_size);
    else
        xl=num2cell(x_ticks);
    end


    switch x_disp_t
        case 'Ping Number'
            x_labels=cellfun(@(x) sprintf('%d',x),xl,'UniformOutput',0);
        case 'Distance'
            if range(x_ticks)/numel(x_ticks)>=1e3
                 x_labels=cellfun(@(x) sprintf('%.1fnm',x/1852),xl,'UniformOutput',0);
            else
                x_labels=cellfun(@(x) sprintf('%.0fm',x),xl,'UniformOutput',0);
            end
        case  'Time'
            if range(x_ticks)/numel(x_ticks)>= (24*60*60)/2
                h_fmt = 'dd-mmm';
            elseif range(x_ticks)/numel(x_ticks)>= (60*60)/2
                h_fmt='HH:MM';
            else
                h_fmt='HH:MM:SS';
            end
            x_labels=cellfun(@(x) datestr(x,h_fmt),xl,'UniformOutput',0);
        case 'Lat'
            [x_labels,~]=cellfun(@(x) print_pos_str(x,zeros(size(x))),xl,'UniformOutput',0);
        case 'Long'
            [~,x_labels]=cellfun(@(x) print_pos_str(zeros(size(x)),x),xl,'UniformOutput',0);
    end


    switch lower(ref)
        case 'surface'
            y_disp=out.Depth_min;
        case {'bottom' 'transducer' 'shadow'}
            y_disp=out.Range_ref_min;
    end


    y_disp = gather(y_disp);

    y_disp_tmp=y_disp;
    y_disp_tmp(isnan(y_disp_tmp)|isinf(y_disp_tmp))=[];
    y_min = min(y_disp_tmp,[],'all','omitnan');
    y_max = max(y_disp_tmp,[],'all','omitnan');
    y_ticks=linspace(y_min,y_max,size(y_disp,1));

    nb_y = numel(y_ticks);
    dy = floor(nb_y/10);

    if dy>1
        y_ticks=y_ticks(1:dy:end);
    end
    nb_y = numel(y_ticks);

    if s_opt.Horizontal_slice_size>1
        yl=num2cell(floor(abs(y_ticks)/s_opt.Horizontal_slice_size)*s_opt.Horizontal_slice_size);
        y_labels=cellfun(@(x) sprintf('%.0fm',x),yl,'UniformOutput',0);
    else
        yl=num2cell(abs(y_ticks));
        y_labels=cellfun(@(x) sprintf('%.0fm',x),yl,'UniformOutput',0);
    end
    legend_str={};
    echo_int_tab_comp.echo_obj.echo_surf.CDataMapping = 'scaled';
    switch echo_int_tab_comp.tog_type.String{echo_int_tab_comp.tog_type.Value}
        case 'Sv'
            out.sv(pow2db_perso(out.sv)<-200) = nan;
            c_disp=pow2db_perso(out.sv);
            v_disp=pow2db_perso(mean(out.sv,2,'omitnan'));
            h_disp=pow2db_perso(mean(out.sv,1,'omitnan'));
            ty='sv';
            c_disp(isnan(c_disp))=-999;
        case 'PRC'
            c_disp=(out.PRC)*100;
            v_disp=(mean(out.PRC,2,'omitnan'))*100;
            h_disp=(mean(out.PRC,1,'omitnan'))*100;
            ty='prc';
        case 'Std Sv'
            c_disp=(out.sd_Sv);
            v_disp=(mean(out.sd_Sv,2,'omitnan'));
            h_disp=(mean(out.sd_Sv,1,'omitnan'));
            ty='std_sv';
        case 'Nb Samples'
            c_disp=(out.nb_samples);
            v_disp=(mean(c_disp,2,'omitnan'));
            h_disp=(mean(c_disp,1,'omitnan'));
            ty='nb_samples';
        case 'Nb Tracks'
            c_disp=(out.nb_tracks);
            v_disp=(mean(c_disp,2,'omitnan'));
            h_disp=(mean(c_disp,1,'omitnan'));
            ty='nb_st_tracks';
        case'Nb Single Targets'
            c_disp=(out.nb_st);
            v_disp=(mean(c_disp,2,'omitnan'));
            h_disp=(mean(c_disp,1,'omitnan'));
            ty='nb_st_tracks';
        case 'Tag'
            [legend_str,~,ib]=unique(out.Tags);
            c_disp=reshape(ib,s_eint);
            v_disp=(mean(c_disp,2,'omitnan'));
            h_disp=(mean(c_disp,1,'omitnan'));
            ty='tag';
            cmap = ones(numel(legend_str),3);

            for uic = 1:numel(legend_str)
                id_cmap = find(strcmpi(out.Tag_str,legend_str{uic}),1);
                if ~isempty(id_cmap) && ~isempty(legend_str{uic})
                    cmap(uic,:) = out.Tag_cmap(id_cmap,:);
                else
                    cmap(uic,:) = cmap_struct.col_ax;
                end
            end

            echo_int_tab_comp.echo_surf.CDataMapping = 'direct';
    end

    c_disp=gather(c_disp);
    v_disp=gather(v_disp);
    h_disp=gather(h_disp);

    if any(out.sv(:)>0)
        ylim=[min(y_disp(out.sv>0),[],'omitnan') max(y_disp(out.sv>0),[],'omitnan')];
        xlim=[min(x_disp(1,sum(out.sv,'omitnan')>0),[],'omitnan') max(x_disp(1,sum(out.sv,'omitnan')>0),[],'omitnan')];
    else
        ylim=[y_min y_max];
        xlim=[min(x_disp(:),[],'omitnan') max(x_disp(:),[],'omitnan')];
    end
else
    out=[];
    ylim=[nan nan];
    xlim=[nan nan];
end

if ~isempty(out)

    %figure();pcolor(x_disp,y_disp,c_disp);axis ij ;y_ticks=get(gca,'ytick');y_labels=get(gca,'YTickLabel');
    x_labels{1}='';
    y_labels{1}='';
    echo_int_tab_comp.echo_obj.main_ax.Colormap = cmap;

    set(echo_int_tab_comp.echo_obj.echo_surf,'Xdata',x_disp,'YData',y_disp,'Zdata',c_disp,'Cdata',c_disp,'alphadata',ones(size(c_disp)),'userdata',ty);
    set(echo_int_tab_comp.echo_obj.v_plot,'xdata',v_disp,'ydata',mean(y_disp,2,'omitnan'));
    set(echo_int_tab_comp.echo_obj.h_plot_low,'ydata',h_disp,'xdata',mean(x_disp,1,'omitnan'));
    
    if nb_y>1 && nb_x>1 && issorted(x_ticks) && issorted(y_ticks)
        try
            set(echo_int_tab_comp.echo_obj.main_ax,'xtick',x_ticks,'ytick',y_ticks);
        end
    end

    yl=[prctile(h_disp,10) max(h_disp,[],'omitnan')*(1+sign(max(h_disp,[],'omitnan'))*0.1)];

    if diff(yl)>0
        set(echo_int_tab_comp.echo_obj.hori_ax,'ylim',yl);
    end

    xl=[prctile(v_disp,10) max(v_disp,[],'omitnan')*(1+sign(max(v_disp,[],'omitnan'))*0.1)];

    if diff(xl)>0
        set(echo_int_tab_comp.echo_obj.vert_ax,'xlim',xl);
    end

    set(echo_int_tab_comp.echo_obj.hori_ax,'XTickLabel',x_labels);
    set(echo_int_tab_comp.echo_obj.vert_ax,'YTickLabel',y_labels);

    if diff(xlim)>0&&diff(ylim)>0
        set(echo_int_tab_comp.echo_obj.main_ax,'xlim',xlim,'ylim',ylim);
    end

    update_echo_int_alphamap(main_figure);
    if ~isempty(legend_str)
        echo_int_tab_comp.echo_obj.colorbar_h.YTick=unique(ib);
        echo_int_tab_comp.echo_obj.colorbar_h.YTickLabel=cellstr(legend_str);
    else
        echo_int_tab_comp.echo_obj.colorbar_h.TicksMode='auto';
        echo_int_tab_comp.echo_obj.colorbar_h.TickLabelsMode='auto';
    end

else
    reset_plot(echo_int_tab_comp);
end

setappdata(main_figure,'EchoInt_tab',echo_int_tab_comp);
end

function reset_plot(echo_int_tab_comp)
set(echo_int_tab_comp.echo_obj.echo_surf,'Xdata',[0 0;0 0],'YData',[0 0;0 0],'CData',[0 0;0 0],'Zdata',[0 0;0 0],'alphadata',ones(size([0 0;0 0])));
set(echo_int_tab_comp.echo_obj.h_plot_low,'Xdata',0,'YData',0);
set(echo_int_tab_comp.echo_obj.v_plot,'Xdata',0,'YData',0);
set(echo_int_tab_comp.echo_obj.hori_ax,'XTickLabel',{});
set(echo_int_tab_comp.echo_obj.vert_ax,'YTickLabel',{});
end