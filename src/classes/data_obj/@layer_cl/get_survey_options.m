function surv_options_obj = get_survey_options(layer_obj)
[pathtofile,~]=layer_obj.get_path_files();

fname=fullfile(pathtofile{1},'survey_options.xml');

if ~isfile(fname)
    surv_options_obj = survey_options_cl('Options',struct(layer_obj.EnvData));
    survey_option_to_xml_file(surv_options_obj,'xml_filename',fname,'subset',1);
end

try
    surv_options_obj=parse_survey_options_xml(fname);
    surv_options_obj.ChannelsToLoad.set_value(layer_obj.AvailableChannelIDs);
    surv_options_obj.FrequenciesToLoad.set_value(layer_obj.AvailableFrequencies);
    if ~ismember(surv_options_obj.Frequency.Value,surv_options_obj.FrequenciesToLoad.Value)
        surv_options_obj.Frequency.set_value(layer_obj.Transceivers(1).Config.Frequency);
    end
    if ~ismember(surv_options_obj.Channel.Value,surv_options_obj.ChannelsToLoad.Value)
        surv_options_obj.Channel.set_value(layer_obj.Transceivers(1).Config.ChannelID);
    end
catch
    print_errors_and_warnings([],'warning',sprintf('Could not parse survey option XML file %s',fname));
    surv_options_obj=survey_options_cl();
end
