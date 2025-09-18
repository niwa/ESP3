
function update_wc_fig(layer,idx_ping)

esp3_obj = getappdata(groot,'esp3_obj');
wc_fan  = getappdata(esp3_obj.main_figure,'wc_fan');

if isempty(wc_fan)||~isvalid(wc_fan.wc_axes)
    return;
end

curr_disp = esp3_obj.curr_disp;
[trans_obj,~]=layer.get_trans(curr_disp);

if ~trans_obj.ismb
    trans_obj = [];
    ismb_trans = find(arrayfun(@ismb,layer.Transceivers),1);
    if ~isempty(ismb_trans)
        trans_obj = layer.Transceivers(ismb_trans);
    end
end

if ~isempty(trans_obj)
    fname = list_layers(layer,'valid_filename',false);
    [~,fnamet,~] = fileparts(fname{1});
    tt = sprintf('File: %s. Ping: %.0f/%.0f. Time: %s.\nChannel %s',fnamet,idx_ping,numel(trans_obj.Time),datetime(trans_obj.get_transceiver_time(idx_ping),"ConvertFrom",'datenum'),trans_obj.Config.ChannelID);

    switch layer.Filetype
        case 'MS70'
            fdir = 'across';
        otherwise
            fdir = 'across';
    end
    % profile on;
    disp_ping_wc_fan(wc_fan,trans_obj,'idx_ping',idx_ping,'curr_disp',esp3_obj.curr_disp,'tt',tt,'fandir',fdir);
    
    % profile off
    % profile viewer
else
    clean_echo_figures(esp3_obj.main_figure,'Tag','wc_fan');
    rmappdata(esp3_obj.main_figure,'wc_fan');
end

end

