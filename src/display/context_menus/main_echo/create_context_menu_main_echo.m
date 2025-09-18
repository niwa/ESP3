function create_context_menu_main_echo(main_figure)

% prep
axes_panel_comp = getappdata(main_figure,'Axes_panel');

if isempty(axes_panel_comp)
    return;
end

layer = get_current_layer();
if isempty(layer)
    return;
end

delete(findobj(ancestor(axes_panel_comp.echo_obj.echo_bt_surf,'figure'),'Type','UiContextMenu','-and','Tag','btCtxtMenu'));

% initialize context menu
context_menu = uicontextmenu(ancestor(axes_panel_comp.echo_obj.echo_bt_surf,'figure'),'Tag','btCtxtMenu');
axes_panel_comp.echo_obj.echo_bt_surf.ContextMenu = context_menu;

% Ping Analysis
analysis_menu = uimenu(context_menu,'Label','Ping Analysis');
uimenu(analysis_menu,'Label','Plot Profiles',         'Callback',{@plot_profiles_callback,main_figure});
if ~isdeployed
    uimenu(analysis_menu,'Label','Display Ping Impedance','Callback',{@display_ping_impedance_cback,main_figure,[],1});
end
uimenu(analysis_menu,'Label','Plot Ping TS Spectrum', 'Callback',{@plot_ping_spectrum_callback,main_figure});
uimenu(analysis_menu,'Label','Plot Ping Sv Spectrum', 'Callback',{@plot_ping_sv_spectrum_callback,main_figure});

% ST and Tracks
data_menu = uimenu(context_menu,'Label','ST and Tracks');
uimenu(data_menu,'Label','Remove Tracks','Callback',@remove_tracks_cback);
uimenu(data_menu,'Label','Remove ST',    'Callback',@remove_ST_cback);

% Survey Data
survey_menu = uimenu(context_menu,'Label','Survey Data');
uimenu(survey_menu,'Label','Edit Voyage Info',                      'Callback',{@edit_trip_info_callback,main_figure});
uimenu(survey_menu,'Label','Edit/Add Survey Data',                  'Callback',{@edit_survey_data_callback,main_figure,0});
uimenu(survey_menu,'Label','Edit/Add Survey Data for this file',    'Callback',{@edit_survey_data_curr_file_callback,main_figure});
uimenu(survey_menu,'Label','Edit/Add Survey Data for this transect','Callback',{@edit_survey_data_curr_transect_callback,main_figure});
uimenu(survey_menu,'Label','Remove Survey Data',                    'Callback',{@edit_survey_data_callback,main_figure,1});
uimenu(survey_menu,'Label','Split Transect Here',                   'Callback',{@split_transect_callback,main_figure});

%3D display
display_3D = uimenu(context_menu,'Label','3D display');
uimenu(display_3D,'Label','Add this transect in 3D display',                      'Callback',{@disp_layer_3D_callback,main_figure,0,false});
uimenu(display_3D,'Label','Add this transect in 3D display (selected regions only)',                      'Callback',{@disp_layer_3D_callback,main_figure,0,true});
uimenu(display_3D,'Label','Remove this transect from 3D display',                      'Callback',{@disp_layer_3D_callback,main_figure,1,false});

% Tools
tools_menu = uimenu(context_menu,'Label','Tools');
uimenu(tools_menu,'Label','Correct this transect position based on cable angle and towbody depth','Callback',{@correct_pos_angle_depth_sector_cback,main_figure});
uimenu(tools_menu,'Label','Plot Sv echogram using user chosen frequency bounds (FM transducers)','Callback',{@echogram_freq_red_FM,main_figure});

% Bad Pings
bt_menu = uimenu(context_menu,'Label','Bad Pings');
uifreq  = uimenu(bt_menu,'Label','Copy to other channels');
uimenu(uifreq,'Label','all',                  'Callback',{@copy_bt_cback,main_figure,[]});
uimenu(uifreq,'Label','choose which Channels','Callback',{@copy_bt_cback,main_figure,1});

% Configuration
config_menu = uimenu(context_menu,'Label','Transceiver configuration');
uimenu(config_menu,'Label','Display Ping Configuration','Callback',{@disp_ping_config_params_callback,main_figure});

% Copy
copy_menu = uimenu(context_menu,'Label','Copy');
uimenu(copy_menu,'Label','To clipboard','Callback',{@copy_echo_to_clipboard_callback,main_figure});
uimenu(context_menu,'Label','Copy position/Filename to clipboard (csv)','Callback',{@copy_pos_to_clipboard_callback,'csv'});
uimenu(context_menu,'Label','Copy position/Filename to clipboard','Callback',{@copy_pos_to_clipboard_callback,'--'});

end

function copy_pos_to_clipboard_callback(~,~,out)

    layer=get_current_layer();
    main_figure = get_esp3_prop('main_figure');
    axes_panel_comp=getappdata(main_figure,'Axes_panel');
    curr_disp=get_esp3_prop('curr_disp'); 

    [trans_obj,~]=layer.get_trans(curr_disp);
    
    if isempty(trans_obj)
        %pause(dpause);
        return;
    end
    
     echo_obj = axes_panel_comp.echo_obj;
    
     [~,~,idx_ping,~] = echo_obj.get_main_ax_cp(trans_obj);

     iFile=trans_obj.Data.FileId(idx_ping);
     [~,file,ext] = fileparts(layer.Filename{iFile});
     Lat=trans_obj.GPSDataPing.Lat(idx_ping);
     Long=trans_obj.GPSDataPing.Long(idx_ping);
     [lat_str,lon_str]=print_pos_str(Lat,Long);
      
     switch out
         case 'csv'
             str = sprintf('Filename,Time,Lat,Lon,LatDeg,LonDeg\n%s%s,%s, %.5f/%.5f,%s,%s\n',file,ext,datestr(trans_obj.Time(idx_ping)),Lat,Long,lat_str,lon_str);
         otherwise
             str = sprintf('%s%s, Time: %s, Lat/Lon (decimal degrees): %.5f/%.5f, Lat/Lon (degrees decimal minutes): %s/%s\n',file,ext,datestr(trans_obj.Time(idx_ping)),Lat,Long,lat_str,lon_str);
     end
     str = sprintf('%s%s, Time: %s, Lat/Lon (decimal degrees): %.5f/%.5f, Lat/Lon (degrees decimal minutes): %s/%s\n',file,ext,datestr(trans_obj.Time(idx_ping)),Lat,Long,lat_str,lon_str);
     clipboard("copy",str);

end

%%
% subfunctions
%



%%
function copy_echo_to_clipboard_callback(~,~,~)
esp3_obj=getappdata(groot,'esp3_obj');

curr_disp=esp3_obj.curr_disp;

save_echo('fileN','-clipboard','cid','main','field',curr_disp.Fieldname);

end



%%
function copy_bt_cback(~,~,main_figure,ifreq)

layer = get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[~,idx_freq] = layer.get_trans(curr_disp);


if ~isempty(ifreq)
    idx_other = setdiff(1:numel(layer.Frequencies),idx_freq);
    if isempty(idx_other)
        return;
    end
    
    list_freq_str = cellfun(@(x,y) sprintf('%.0f kHz: %s',x,y),num2cell(layer.Frequencies(idx_other)/1e3), deblank(layer.ChannelID(idx_other)),'un',0);
    
    if isempty(list_freq_str)
        return;
    end
    
    [ifreq,val] = listdlg_perso(main_figure,'',list_freq_str);
    if val==0 || isempty(ifreq)
        return;
    end
    ifreq = layer.find_cid_idx(layer.ChannelID(idx_other(ifreq)));
end

[bots,ifreq] = layer.generate_bottoms_for_other_freqs(idx_freq,ifreq);

for i = 1:numel(ifreq)
    old_bot = layer.Transceivers(ifreq(i)).Bottom;
    bots(i).Sample_idx = old_bot.Sample_idx;
    bots(i).Tag = (old_bot.Tag>0&bots(i).Tag>0);
    layer.Transceivers(ifreq(i)).Bottom = bots(i);
    add_undo_bottom_action(main_figure,layer.Transceivers(ifreq(i)),old_bot,bots(i));
end

set_alpha_map(main_figure,'main_or_mini',union({'main','mini'},layer.ChannelID(ifreq)),'update_under_bot',0,'update_cmap',0);

end

%%
function correct_pos_angle_depth_sector_cback(~,~,main_figure)


layer = get_current_layer();

if isempty(layer)
    return;
end

axes_panel_comp = getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~] = layer.get_trans(curr_disp);
trans = trans_obj;

ax_main = axes_panel_comp.echo_obj.main_ax;
x_lim = double(get(ax_main,'xlim'));

cp = ax_main.CurrentPoint;
x = cp(1,1);

x = max(x,x_lim(1));
x = min(x,x_lim(2));

xdata = trans.get_transceiver_pings();

[~,idx_ping] = min(abs(xdata-x));

time = trans.Time;
t_n = time(idx_ping);


prompt = {'Towing cable angle (in degree)','Towbody depth'};
defaultanswer = {25,500};


[answer,cancel] = input_dlg_perso(main_figure,'Correct position',prompt,...
    {'%.0f' '%.1f'},defaultanswer);
if cancel
    return;
end

if isempty(answer)
    return;
end

angle_deg = answer{1};

if isnan(angle_deg)
    warning('Invalid Angle');
    return;
end

depth_m = answer{2};

if isnan(depth_m)
    warning('Invalid Depth');
    return;
end

[surv,~] = layer.get_survdata_at_time(t_n);

[~,idx_ts] = min(abs(time-surv.StartTime));
[~,idx_te] = min(abs(time-surv.EndTime));

idx_t = idx_ts:idx_te;

curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~] = layer.get_trans(curr_disp);
gps_data = trans_obj.GPSDataPing;

LongLim = [min(gps_data.Long(idx_t)) max(gps_data.Long(idx_t))];

LatLim = [min(gps_data.Lat(idx_t)) max(gps_data.Lat(idx_t))];

ext_lat_lon_lim_v2(LatLim,LongLim,0.3);

[new_lat,new_long,hfig] = correct_pos_angle_depth(gps_data.Lat(idx_t),gps_data.Long(idx_t),angle_deg,depth_m,proj_i);

war_str = 'Would you like to use this corrected track (in red)?';
choice = question_dialog_fig(main_figure,'',war_str);
close(hfig);

switch choice
    case 'Yes'
        trans_obj.GPSDataPing.Lat(idx_t) = new_lat;
        trans_obj.GPSDataPing.Long(idx_t) = new_long;
        layer.replace_gps_data_layer(trans_obj.GPSDataPing);
        export_gps_to_csv_callback([],[],main_figure,layer.Unique_ID,'_gps');
    case 'No'
        return;
        
end

update_map_tab(main_figure);
update_grid(main_figure);
update_grid_mini_ax(main_figure);


end