function export_mb_wc_to_mp4_cback(~,~,tag,codec,reg_curr)

init_wc_fan_plot();
esp3_obj = getappdata(groot,'esp3_obj');
wc_fan  = getappdata(esp3_obj.main_figure,'wc_fan');

if isempty(wc_fan)
    return;
end

curr_disp = esp3_obj.curr_disp;

path_f = esp3_obj.app_path.data.Path_to_folder;

path_f = uigetdir(path_f,...
    'Select destination folder');

if isequal(path_f,0)
    return;
end

remove_interactions(esp3_obj.main_figure);
switch tag
    case 'all'
        lay_obj=esp3_obj.layers;
    case 'current'
        lay_obj=get_current_layer();
end

 layers_Str=list_layers(lay_obj,'nb_char',80,'valid_filename',true);
 load_bar_comp = show_status_bar(esp3_obj.main_figure);
 
for ilay = 1:numel(lay_obj)
   
    f_name = fullfile(path_f,layers_Str{ilay});
    
    [trans_obj,~]=lay_obj(ilay).get_trans(curr_disp);
    
    if ~trans_obj.ismb
        continue;
    end

    if isempty(reg_curr)
        idx_pings = trans_obj.get_transceiver_pings();
    else
        idx_pings  = reg_curr.Idx_ping;
    end
    
    if ~isempty(load_bar_comp)
        load_bar_comp.progress_bar.setText(sprintf('Exporting %s to %s',layers_Str{ilay},codec));
        set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(idx_pings), 'Value',0);
    end
    t = trans_obj.get_transceiver_time();
    fps = ceil(1./mean(diff(t*60*60*24)));
    vidfile = VideoWriter(f_name,codec);
    vidfile.FrameRate=fps;
    open(vidfile);
    %idx_pings = 1:150;
    uipp = 0;
    
    for uip = idx_pings
        uipp = uipp+1;
        if ~isempty(load_bar_comp)  
            set(load_bar_comp.progress_bar,'Value',uipp);
        end
        update_wc_fig(lay_obj(ilay),uip);
        drawnow;
        fr_tmp = getframe(wc_fan.wc_fan_fig);
        writeVideo(vidfile,fr_tmp); 
    end

    close(vidfile)
end

initialize_interactions_v2(esp3_obj.main_figure);
 hide_status_bar(esp3_obj.main_figure);
end