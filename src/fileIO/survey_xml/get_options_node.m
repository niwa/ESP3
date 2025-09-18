function  Options = get_options_node(xml_node)
Options = get_node_att(xml_node);
nb = 0;
if isfield(Options,'FrequenciesToLoad')
    if ischar(Options.FrequenciesToLoad)
        Options.FrequenciesToLoad = str2double(strsplit(Options.FrequenciesToLoad,';'));
        if isnan(Options.FrequenciesToLoad)
            Options.FrequenciesToLoad = Options.Frequency;
        end
    end
    nb = numel(Options.FrequenciesToLoad);
end

if isfield(Options,'FrequenciesMinToEI_FMmode')
    if ischar(Options.FrequenciesMinToEI_FMmode)
        Options.FrequenciesMinToEI_FMmode = str2double(strsplit(Options.FrequenciesMinToEI_FMmode,';'));
    end
end

if isfield(Options,'FrequenciesMaxToEI_FMmode')
    if ischar(Options.FrequenciesMaxToEI_FMmode)
        Options.FrequenciesMaxToEI_FMmode = str2double(strsplit(Options.FrequenciesMaxToEI_FMmode,';'));
    end
end

if isfield(Options,'ChannelsToLoad')
    Options.ChannelsToLoad = strsplit(Options.ChannelsToLoad,';');
    nb = max(nb,numel(Options.ChannelsToLoad));
end

if nb>0
    if isfield(Options,'Absorption')
        abs_ori = Options.Absorption;
        Options.Absorption = nan(1,nb);
        if ischar(abs_ori)
            abs_temp = str2double(strsplit(abs_ori,';'));
            if length(abs_temp) == nb
                Options.Absorption = abs_temp;
            end
        else
            Options.Absorption=abs_ori;
        end
    end
end
end

