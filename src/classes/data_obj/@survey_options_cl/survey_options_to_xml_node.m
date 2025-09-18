function xml_node=survey_options_to_xml_node(survey_opt_obj,docNode,subset)

if subset==1   
    fields_opts={'SoundSpeed' 'Temperature' 'Salinity' 'DepthMin','DepthMax','RangeMin','RangeMax','RefRangeMin','RefRangeMax','AngleMin','AngleMax',...
        'Vertical_slice_size','Vertical_slice_units','Horizontal_slice_size','SvThr','Denoised','Shadow_zone','Shadow_zone_height','Motion_correction',...
        'IntType','IntRef'};
else
    fields_opts=fields(survey_opt_obj);
end

xml_node = docNode.createElement('options');

for iprop=1:length(fields_opts)
%try
    if isnumeric(survey_opt_obj.(fields_opts{iprop}).Value)||islogical(survey_opt_obj.(fields_opts{iprop}).Value)
        xml_node.setAttribute(fields_opts{iprop}, vec2delem_str(double(survey_opt_obj.(fields_opts{iprop}).Value),';','%.2f '));
    elseif iscell(survey_opt_obj.(fields_opts{iprop}).Value)
         xml_node.setAttribute(fields_opts{iprop}, strjoin(survey_opt_obj.(fields_opts{iprop}).Value,';'));
    else
        xml_node.setAttribute(fields_opts{iprop},survey_opt_obj.(fields_opts{iprop}).Value);
    end
    
% catch err
%     disp('Error')
% end
end
