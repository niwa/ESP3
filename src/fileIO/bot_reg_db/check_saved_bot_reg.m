function can = check_saved_bot_reg(main_figure)
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();
can = false;
if isempty(layer)
    return;
end
tt_str=('Unsaved changes');
if curr_disp.Bot_changed_flag==1
    
    war_str=sprintf('Bottom has been modified without being saved.\nDo you want save it?');
    choice=question_dialog_fig(main_figure,tt_str,war_str,'opt',{'Yes' 'No' 'Cancel'});
    % Handle response
    switch choice
        case 'Yes'
            layer.write_bot_to_bot_xml();
            %layer.save_bot_reg_to_db('bot',1,'reg',0);
            curr_disp.Bot_changed_flag = 0;
        case 'Cancel'
            can = true;
    end
    
end

if curr_disp.Reg_changed_flag==1
    
    war_str=sprintf('Regions have been modified without being saved.\nDo you want save them?');
    choice=question_dialog_fig(main_figure,tt_str,war_str,'opt',{'Yes' 'No' 'Cancel'});
    % Handle response
    switch choice
        case 'Yes'
            layer.write_reg_to_reg_xml();
            %layer.save_bot_reg_to_db('bot',0,'reg',1);
            curr_disp.Reg_changed_flag = 0;
        case 'Cancel'
            can = true;
    end
end


end