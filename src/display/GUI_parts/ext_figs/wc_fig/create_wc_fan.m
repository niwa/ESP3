function wc_fan = create_wc_fan(varargin)

p = inputParser;
addParameter(p,'wc_fig',[]);
addParameter(p,'curr_disp',[]);

parse(p,varargin{:});

curr_disp = p.Results.curr_disp;
wc_fan.wc_fan_fig = p.Results.wc_fig;

if isempty(curr_disp)
    curr_disp  = curr_state_disp_cl();
end

cmap_struct = init_cmap(curr_disp.Cmap,curr_disp.ReverseCmap);

if isempty(wc_fan.wc_fan_fig)
    wc_fan.wc_fan_fig = new_echo_figure([],...
        'Name','WC fan',...
        'tag','wc_fan',...
        'UiFigureBool',true);
    wc_fan.wc_fan_fig.Color = cmap_struct.col_ax;
end


if isa(wc_fan.wc_fan_fig,'matlab.ui.container.GridLayout')
    wc_fan.gl_ax = wc_fan.wc_fan_fig;
    wc_fan.wc_fan_fig = ancestor(wc_fan.wc_fan_fig,'Figure');
else
    wc_fan.gl_ax  = uigridlayout(wc_fan.wc_fan_fig,[1 1]);
end

wc_fan.gl_ax.BackgroundColor = cmap_struct.col_ax;

usrdata.geometry = 'fan';
usrdata.current_ping = nan;
usrdata.CID = '';


wc_fan.wc_axes = uiaxes(wc_fan.gl_ax,...
    'Units','normalized',...
    'Color',cmap_struct.col_ax,...
    'GridColor',cmap_struct.col_grid,...
    'MinorGridColor',cmap_struct.col_grid,...
    'XColor',cmap_struct.col_lab,...
    'YColor',cmap_struct.col_lab,...
    'GridColor',cmap_struct.col_grid,...
    'MinorGridColor',cmap_struct.col_grid,...
    'XGrid','on',...
    'YGrid','on',...
    'FontSize',8,...
    'XLimMode','manual',...
    'YLimMode','manual',...
    'Box','on',...
    'SortMethod','childorder',...
    'GridLineStyle','--',...
    'MinorGridLineStyle',':',...
    'NextPlot','add',...
    'YDir','reverse',...
    'visible','on',...
    'ClippingStyle','rectangle',...
    'Interactions',[],...
    'DataAspectRatio',[1 1 1],...
    'Toolbar',[],...
    'YDir',curr_disp.YDir,...
    'CLim',curr_disp.Cax,...
    'Colormap',cmap_struct.cmap,...
    'Tag','wc',...
    'UserData',usrdata);


wc_fan.light_h = light(wc_fan.wc_axes,'Visible','off','Style','infinite','Position',[0 1 0]);

wc_fan.wc_axes.XAxisLocation='top';
wc_fan.wc_axes.XAxis.TickLabelFormat='%.0fm';
wc_fan.wc_axes.YAxis.TickLabelFormat='%.0fm';


wc_fan.wc_axes_tt = title(wc_fan.wc_axes,' ','Color',cmap_struct.col_lab,'Interpreter','none');

wc_fan.wc_gh = pcolor(wc_fan.wc_axes,ones(2,2));
wc_fan.bot_gh = plot(wc_fan.wc_axes,ones(1,2),'Color',cmap_struct.col_bot,'LineStyle','-','Marker','.');
wc_fan.beam_limit_plot_h = [plot(wc_fan.wc_axes,ones(1,2),'Color',cmap_struct.col_bot,'LineStyle','--')...
    plot(wc_fan.wc_axes,ones(1,2),'Color',cmap_struct.col_bot,'LineStyle','--')];

ctxt_menu =uicontextmenu(wc_fan.wc_fan_fig);

uih = uimenu(ctxt_menu,'Label','Geometry');
uimenu(uih,'Label','Fan display (Depth/across-distance)','Checked','on','tag','fan','MenuSelectedFcn',{@set_geometry,wc_fan.wc_axes});
uimenu(uih,'Label','Range/beam display','Checked','off','tag','rangebeam','MenuSelectedFcn',{@set_geometry,wc_fan.wc_axes});
uimenu(uih,'Label','Range/freq display','Checked','off','tag','rangefreq','MenuSelectedFcn',{@set_geometry,wc_fan.wc_axes});


uih1 = uimenu(ctxt_menu,'Label','Axes ratio');
uimenu(uih1,'Label','"Filled" view','Checked','off','tag','filled','MenuSelectedFcn',{@changed_axes_ratio_cback,wc_fan.wc_axes});
uimenu(uih1,'Label','"Equal" view','Checked','on','tag','equal','MenuSelectedFcn',{@changed_axes_ratio_cback,wc_fan.wc_axes});


uih2 = uimenu(ctxt_menu,'Label','Rendering');
uimenu(uih2,'Label','"Interpolated','Checked','off','tag','interp','MenuSelectedFcn',{@set_interp,wc_fan.wc_gh});
uimenu(uih2,'Label','"Flat" view','Checked','on','tag','flat','MenuSelectedFcn',{@set_interp,wc_fan.wc_gh});

if ~isdeployed()
    uih3 = uimenu(ctxt_menu,'Label','Analysis');
    uimenu(uih3,'Label','Noise analysis','tag','interp','MenuSelectedFcn',{@disp_noise_estimation_cback,wc_fan.wc_axes});


end

set(wc_fan.wc_gh,...
    'Facealpha','flat',...
    'FaceColor','flat',...
    'FaceLighting','none',...
    'LineStyle','none',...
    'AlphaDataMapping','direct',...
    'ContextMenu',ctxt_menu);

wc_fan.wc_axes.ContextMenu = ctxt_menu;

material(wc_fan.wc_gh,'shiny');
wc_fan.wc_cbar = [];pause(0.1);
wc_fan.wc_cbar = colorbar(wc_fan.wc_axes,'southoutside','Color',cmap_struct.col_lab);
end

function set_interp(src,~,gh)

interp_h = findobj(src.Parent,'Tag','interp');
flat_h = findobj(src.Parent,'Tag','flat');
switch src.Tag
    case 'interp'
        interp_h.Checked = 'on';
        flat_h.Checked = 'off';

        set(gh,...
            'Facealpha','interp',...
            'FaceColor','interp',...
            'FaceLighting','gouraud');
    case 'flat'
        flat_h.Checked = 'on';
        interp_h.Checked = 'off';

        set(gh,...
            'Facealpha','flat',...
            'FaceColor','flat');

end

end

function set_geometry(src,~,gax)

fan_h = findobj(src.Parent,'Tag','fan');
range_h = findobj(src.Parent,'Tag','rangebeam');
range_f_h = findobj(src.Parent,'Tag','rangefreq');

switch src.Tag
    case 'fan'
        fan_h.Checked = 'on';
        range_h.Checked = 'off';
        range_f_h.Checked = 'off';
        gax.UserData.geometry = 'fan';
    case 'rangebeam'
        fan_h.Checked = 'off';
        range_h.Checked = 'on';
        range_f_h.Checked = 'off';
        gax.UserData.geometry = 'rangebeam';
    case 'rangefreq'
        fan_h.Checked = 'off';
        range_h.Checked = 'off';
        range_f_h.Checked = 'on';
        gax.UserData.geometry = 'rangefreq';
end

update_info_panel([],[],1);

end

function disp_noise_estimation_cback(~,~,ax)

if isempty(ax.UserData.current_ping)||isnan(ax.UserData.current_ping)
    return;
end
esp3_obj = getappdata(groot,'esp3_obj');
main_figure = esp3_obj.main_figure;
prompt={'Number of pings to average'};
defaultanswer={11};
[answer,cancel]=input_dlg_perso(main_figure,'Number of pings to average',prompt,...
    {'%d'},defaultanswer);
if cancel
    return;
end

lay_obj = get_current_layer(); 

mb_trans_idx = find(arrayfun(@ismb,lay_obj.Transceivers));

nb_mb = numel(mb_trans_idx);

if nb_mb == 0
    return;
end

hfig=new_echo_figure(main_figure,'UiFigureBool',true,'Name','Noise power analysis','Tag','noise_power');
uigl_ax = uigridlayout(hfig,[nb_mb,2]);
idx_pings = ax.UserData.current_ping-floor(answer{1}/2):ax.UserData.current_ping+floor(answer{1}/2);

idx_pings(idx_pings<1) = [];


for uib = 1:nb_mb
    idx_pings_t = idx_pings;
    trans_obj = lay_obj.Transceivers(mb_trans_idx(uib));
    tt = trans_obj.get_transceiver_time();
    idx_pings_t(idx_pings_t>numel(tt)) = [];
    rr = trans_obj.get_samples_range();
    % [~,Np] = trans_obj.get_pulse_length(idx_pings_t);
    % Np = max(Np);
    idx_r = 1:numel(rr);
    %rr = rr(idx_r);
    pow = trans_obj.Data.get_subdatamat('idx_ping',idx_pings_t,'idx_r',idx_r,'field','power');
    ff = trans_obj.Config.Frequency/1e3;
    [ff,idx_f] = sort(ff);

    ax_av = uiaxes(uigl_ax,'Box','on','Nextplot','add','YGrid','on','XGrid','on');
    ax_av.Layout.Row = uib;
    ax_av.Layout.Column = 1;
    hhp = plot(ax_av,ff,pow2db(squeeze(mean(pow(:,:,idx_f),[1 2]))));
    ax_av.XLim = [min(ff) max(ff)];
    ax_av.XAxis.TickLabelFormat = '%d kHz';
    ax_av.YAxis.TickLabelFormat = '%d dB';

    
    ax_im = uiaxes(uigl_ax,'Box','on','Nextplot','add','YGrid','on','XGrid','on');
    ax_im.Layout.Row = uib;
    ax_im.Layout.Column = 2;
    imd = pow2db(squeeze(mean(pow(:,:,idx_f),2)));
    
    hhi = imagesc(ax_im,ff,rr,pow2db(squeeze(mean(pow(:,:,idx_f),2))));
    hhi.AlphaData = imd> -140;
     ax_im.CLim = [-140 -100];
     ax_im.XLim = [min(ff) max(ff)];
     ax_im.YLim = [min(rr) max(rr)];
     ax_im.YDir = 'reverse';
     ax_im.YAxis.TickLabelFormat = '%d m';
     ax_im.XAxis.TickLabelFormat = '%d kHz';
     colorbar(ax_im);
end

end

function changed_axes_ratio_cback(src,~,ax)

eq_h = findobj(src.Parent,'Tag','equal');
fill_h = findobj(src.Parent,'Tag','filled');

switch src.Tag
    case 'equal'
        eq_h.Checked = 'on';
        fill_h.Checked = 'off';
        ax.DataAspectRatio = [1 1 1];
    case 'filled'
        ax.DataAspectRatioMode = 'auto';
        ax.OuterPosition = [0 0 1 0.95];
        eq_h.Checked = 'off';
        fill_h.Checked = 'on';
end
end


