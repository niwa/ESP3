function export_features_cback(src,evt,type)

lay_obj=get_current_layer();
esp3_obj = getappdata(groot,'esp3_obj');
if isempty(lay_obj)
    return;
end

if all(arrayfun(@(x) isempty(x.Features),lay_obj.Transceivers))
    return;
end

layers_Str=list_layers(lay_obj,'nb_char',80,'valid_filename',true);
path_f = fileparts(lay_obj.Filename{1});
fname = fullfile(path_f,[layers_Str{1} '_features.mat']);

[fname,path_f] = uiputfile( {fname}, 'Save Features');

if isequal(fname,0)
    return;
end
fname = fullfile(path_f,fname);

load_bar_comp = show_status_bar(esp3_obj.main_figure);

if ~isempty(load_bar_comp)
    load_bar_comp.progress_bar.setText(sprintf('Exporting features from %s',layers_Str{1}));
end

features_struct = [];
for uit = 1:numel(lay_obj.Transceivers)
    if isempty(lay_obj.Transceivers(uit).Features)
        continue;
    end
    features_struct.(matlab.lang.makeValidName(lay_obj.ChannelID{uit})) = lay_obj.Transceivers(uit).Features;
end

if ~isempty(features_struct)
  
    if isfile(fname)
        delete(fname);
    end
    save(fname,'features_struct',"-v7.3");
end

hide_status_bar(esp3_obj.main_figure)