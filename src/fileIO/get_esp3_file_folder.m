function echo_folder = get_esp3_file_folder(path_f,create_folder_bool)
echo_folder = fullfile(path_f,'echoanalysisfiles');
if create_folder_bool && ~isfolder(echo_folder)
    [status, msg, msgID] = mkdir(echo_folder);
    if ~status
        print_errors_and_warnings([],'Warning',sprintf('Could not create ESP3 folder %s\n',echo_folder));
        print_errors_and_warnings([],'Warning',msgID);
        print_errors_and_warnings([],'Warning',msg);
    end
end