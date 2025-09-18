function [path_xml,reg_file_str,bot_file_str] = create_files_str(layer_obj)

% input parser
p = inputParser;
addRequired(p,'layer_obj',@(obj) isa(obj,'layer_cl'));
parse(p,layer_obj);

[path_xml, bot_file_str, reg_file_str] = cellfun(@create_bot_reg_xml_fname,layer_obj.Filename,'UniformOutput',false);