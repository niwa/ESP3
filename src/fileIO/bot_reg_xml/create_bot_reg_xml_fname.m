function [path_to_files,bot_file,reg_file]=create_bot_reg_xml_fname(data_filename)
[path_to_files,~,~]=fileparts(data_filename);
path_to_files = get_bot_reg_folder(path_to_files,true);
[~,fileTemp,~]=fileparts(data_filename);
reg_file=['r_' fileTemp '.xml'];
bot_file=['b_' fileTemp '.xml'];
end