function create_survey_options_xml(layers_obj,surv_options_obj)

[pathtofiles,~]=layers_obj.get_path_files();
pathtofile=unique(pathtofiles);

for ip=1:numel(pathtofile)
    fname=fullfile(pathtofile{ip},'survey_options.xml');
    if ~isfile(fname) && isempty(surv_options_obj)
        idx = find(strcmpi(pathtofile,pathtofiles),1);
        surv_options_obj_tmp = survey_options_cl('Options',layers_obj(idx).EnvData.env_data_to_struct());
        survey_option_to_xml_file(surv_options_obj_tmp,'xml_filename',fname,'subset',1);
    elseif ~isempty(surv_options_obj)
        surv_options_obj_tmp = surv_options_obj;
        survey_option_to_xml_file(surv_options_obj_tmp,'xml_filename',fname,'subset',1);
    end
end

end