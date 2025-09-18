function al_from_xml = get_al_from_al_xml_struct(al_xml_struct)

[~,~,algo_files]=get_config_files(al_xml_struct.Name);

try
    [al_def,algo_alt,al_names]=read_config_algo_xml(algo_files{1});
catch
    algo=init_algos(aa);
    write_config_algo_to_xml(algo,{'--'},0);
    [al_def,algo_alt,al_names]=read_config_algo_xml(algo_files{1});
end

idx_al = find(strcmpi(al_xml_struct.Varargin.savename,al_names));

if isempty(idx_al)
    al_from_xml = al_def;
else
    al_from_xml = algo_alt(idx_al);
end

fields_in=al_from_xml.Input_params.get_name();

for ialxml=1:length(fields_in)
    if isfield(al_xml_struct.Varargin,fields_in{ialxml})
        al_from_xml.set_input_param_value(fields_in{ialxml},al_xml_struct.Varargin.(fields_in{ialxml}));
    end
end