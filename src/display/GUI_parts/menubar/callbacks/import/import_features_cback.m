function import_features_cback(src,evt,type)

lay_obj=get_current_layer();
esp3_obj = getappdata(groot,'esp3_obj');

if isempty(lay_obj)
    return;
end

if all(arrayfun(@(x) isempty(x.Features),lay_obj.Transceivers))
    return;
end


path_f = fileparts(lay_obj.Filename{1});


[ff,path_f] = uigetfile( {fullfile(path_f,'*features.mat')}, sprintf('Select .mat features file'),'MultiSelect','off');

if isequal(ff,0)
    return;
end

tmp = load(fullfile(path_f,ff));

if ~isfield(tmp,'features_struct')
    dlg_perso(esp3_obj.main_figure,'No features','.mat file does not seem to contain features.');
    return;
end

features_struct = tmp.features_struct;

fff = fieldnames(features_struct);

cids_val = cellfun(@matlab.lang.makeValidName,lay_obj.ChannelID,'UniformOutput',false);

if isempty(intersect(fff,cids_val))
        dlg_perso(esp3_obj.main_figure,'No features','.mat file does not seem to contain features for this layer.');
    return;
end

for uif = 1:numel(fff)
    idx_trans = find(strcmpi(fff{uif},cids_val));
    if ~isempty(idx_trans)
        lay_obj.Transceivers(idx_trans).Features = features_struct.(fff{uif});
    end
end

set_alpha_map(esp3_obj.main_figure,'update_bt',0);