function remove_tracks_cback(~,~)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);
trans_obj.rm_tracks();
curr_disp.ChannelID=layer.ChannelID{idx_freq};

end