function [trans_obj_out,idx_group] = group_transceivers(trans_obj_in,varargin)
trans_obj_out = [];
idx_group = {};
nb_trans = numel(trans_obj_in);

if nb_trans<=1
    return;
end

field_to_group_def = trans_obj_in(1).Data.Fieldname;

p  =  inputParser;

addRequired(p,'trans_obj_in',@(obj) all(isa(obj,'transceiver_cl')));
addParameter(p,'fields_to_group',field_to_group_def,@iscell);
addParameter(p,'groupdir','along',@(x) ismember(x,{'along' 'across'}));
addParameter(p,'filetype','',@ischar);

parse(p,trans_obj_in,varargin{:});

params_obj_in = [trans_obj_in(:).Params];
[params_obj_out,idx_group] = params_obj_in.group_params(p.Results.groupdir,p.Results.filetype);

nb_new_trans = numel(idx_group);

if isempty(nb_new_trans) 
    return;
end

for uit = 1:nb_new_trans
    idx_t = idx_group{uit};
    if isscalar(idx_t)
        continue;
    end
    config_to_groups  = [trans_obj_in(idx_t).Config];
    config_obj_tmp = config_to_groups.group_config();
    config_obj_tmp.ChannelID  = sprintf('%s_%s beams %d to %d',config_obj_tmp.TransceiverName,config_obj_tmp.SerialNumber,min(idx_t),max(idx_t));
    ac_data_to_groups = [trans_obj_in(idx_t).Data];
    ac_data_tmp = ac_data_to_groups.group_ac_data(p.Results.fields_to_group,uit);
    nb_samples_ac = arrayfun(@(x) max(x.Nb_samples),ac_data_to_groups);
    [nbs,idx_range] = max(nb_samples_ac);
    alpha = nan(nbs,numel(idx_t));
    for uita = 1:numel(idx_t)
        alpha(1:numel(trans_obj_in(idx_t(uita)).Alpha),uita) = trans_obj_in(idx_t(uita)).Alpha;
    end
    trans_tmp =transceiver_cl('Data',ac_data_tmp,...
            'Alpha',alpha,...
            'AttitudeNavPing',trans_obj_in(idx_t(idx_range)).AttitudeNavPing,...
            'GPSDataPing',trans_obj_in(idx_t(idx_range)).GPSDataPing,...
            'Range',trans_obj_in(idx_t(idx_range)).Range,...
            'Time',trans_obj_in(idx_t(idx_range)).Time,...
            'TransceiverDepth',trans_obj_in(idx_t(idx_range)).TransceiverDepth,...
            'Mode',trans_obj_in(idx_t(idx_range)).Mode,...
            'Config',config_obj_tmp,...
            'Params',params_obj_out(uit));
    trans_obj_out = [trans_obj_out trans_tmp];
end


end