function  choose_freq(src,~,~)
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();
if isempty(layer)
    return;
end
curr_disp.ChannelID=layer.ChannelID{get(src,'value')};
end