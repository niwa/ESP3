function load_layers_from_future_obj(esp3_obj,f_obj)
esp3_obj.w_h.update_waitbar([]);
str = 'Finished reading files... Fetching results.';
esp3_obj.w_h.general_label.Text = str;drawnow;
idx_fetch = cellfun(@isempty,{f_obj(:).Error});
%f_obj.Diary
[new_layers,multi_lay_mode] = fetchOutputs(f_obj(idx_fetch),'UniformOutput',false);
str = 'Finished fetching  results files... Loading results in ESP3.';
esp3_obj.w_h.general_label.Text = str;drawnow;
up_echo  = false;
new_layers_tot = [];
algo_vec_init=init_algos();
[~,~,algo_vec,~]=load_config_from_xml(0,0,1);
for uil = 1:numel(new_layers)
    if ~isempty(new_layers{uil})
        up_echo  = true;
        new_layers{uil}.add_algo(algo_vec_init,'reset_range',true);
        new_layers{uil}.add_algo(algo_vec,'reset_range',true);
        new_layers{uil}.load_bot_regs('bot_ver',-1,'reg_ver',-1);
        new_layers_tot = [new_layers_tot new_layers{uil}];
    end
end
show_status_bar(esp3_obj.main_figure);

if up_echo
     esp3_obj.add_layers_to_esp3(new_layers_tot,multi_lay_mode{1});
%     pause(1);
    loadEcho(esp3_obj.main_figure,1);
end

hide_status_bar(esp3_obj.main_figure);
disp(esp3_obj.future_op_obj);
%close(ff);
delete(esp3_obj.w_h);
esp3_obj.w_h = files_open_waitbar_cl.empty();

end