function  choose_Xaxes(obj,~,main_figure)

layer=get_current_layer();
if isempty(layer)
    return;
end
curr_disp=get_esp3_prop('curr_disp');

idx=get(obj,'value');
str=get(obj,'String');

curr_disp.Xaxes_current=str{idx};

% [echo_obj,trans_obj_tot,~,cids]=get_axis_from_cids(main_figure,curr_disp.SecChannelIDs);
% 
% for iax=1:length(echo_obj)
%     echo_im=echo_obj.get_echo_surf(iax);
%     echo_im.UserData.geometry_x = curr_disp.Xaxes_current;
% end
% 
% update_axis(main_figure,0,'main_or_mini',curr_disp.SecChannelIDs,'force_update',1);

update_grid(main_figure);
update_grid_mini_ax(main_figure);
update_display_tab(main_figure);

end