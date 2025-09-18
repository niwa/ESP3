function add_layers_to_esp3(esp3_obj,new_layers,multi_lay_mode)

fprintf('Loading survey metadata \n');
new_layers.load_echo_logbook_db();
fprintf('Adding ping data to logbook database\n');
new_layers.add_ping_data_to_db(1,0);

all_layer=[esp3_obj.layers new_layers];
fprintf('Sorting layers by survey metadata \n');
all_layers_sorted=all_layer.sort_per_survey_data();

layers=[];
fprintf('Shuffling layers \n');
for icell=1:length(all_layers_sorted)
    layers=[layers shuffle_layers(all_layers_sorted{icell},'multi_layer',multi_lay_mode)];
end

% if any(ismember({layers(:).Filetype},{'ME70' 'MS70' 'MBS'}))
%     arrayfun(@group_channels,layers(ismember({layers(:).Filetype},{'ME70' 'MS70' 'MBS'})));
% end
    
if ~isempty(layers)
    esp3_obj.layers=layers;
end

end