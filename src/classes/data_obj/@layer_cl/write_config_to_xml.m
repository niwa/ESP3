function write_config_to_xml(lay_obj)

for ilay = 1:numel(lay_obj)
    files = lay_obj(ilay).list_files_layers();

    [path_f,fileN,~] = cellfun(@fileparts,files,'UniformOutput',false);

    config_files = cellfun(@(x,y) fullfile(x,[y '_config.xml']),path_f,fileN,'UniformOutput',false);

    config_obj = [lay_obj(ilay).Transceivers(:).Config];

    config_obj.config_obj_to_xml(config_files);
end

