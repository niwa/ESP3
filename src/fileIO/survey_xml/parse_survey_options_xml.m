function surv_options_obj = parse_survey_options_xml(xml_file)

surv_options_obj = survey_options_cl();

if ~isfile(xml_file)
    return;
end

xml_struct = parseXML(xml_file);

if ~strcmpi(xml_struct.Name,'survey_options')
    warning('XML file not describing a survey options');
    return;
end

nb_child = length(xml_struct.Children);

idx_child=1:nb_child;

for iui = idx_child
    switch xml_struct.Children(iui).Name
        case 'options'
            opt_struct = get_options_node(xml_struct.Children(iui));
            surv_options_obj.update_options(opt_struct);
        case '#comment'
            continue;
        otherwise
            warning('Unidentified Child in XML');
    end
end


end