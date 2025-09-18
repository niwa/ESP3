function bot_reg_folder = get_bot_reg_folder(path_f,create_folder_bool)
bot_reg_folder = fullfile(path_f,'bot_reg');

if create_folder_bool && ~isfolder(bot_reg_folder)
    [status, msg, msgID] = mkdir(bot_reg_folder);
    if ~status
        print_errors_and_warnings([],'Warning',sprintf('Could not create bot_reg folder %s\n',bot_reg_folder));
        print_errors_and_warnings([],'Warning',msgID);
        print_errors_and_warnings([],'Warning',msg);
    end
end