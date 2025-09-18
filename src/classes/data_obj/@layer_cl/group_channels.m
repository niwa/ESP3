function layer_obj = group_channels(layer_obj,varargin)

if numel(layer_obj.Transceivers)<2
    return;
end

field_to_group_def = layer_obj.Transceivers(1).Data.Fieldname;

p  =  inputParser;

addRequired(p,'layer_obj',@(obj) isa(obj,'layer_cl'));
addParameter(p,'fields_to_group',field_to_group_def,@iscell);
addParameter(p,'idx_channel',[],@isnumeric);
addParameter(p,'load_bar_comp',[]);
addParameter(p,'ChannelIDs',layer_obj.ChannelID,@iscell);

parse(p,layer_obj,varargin{:});

ismb_trans = find(layer_obj.Transceivers.ismb);
if all(layer_obj.Transceivers.ismb)
    return;
end
if ~isempty(ismb_trans)
    layer_obj.remove_transceiver('channel',layer_obj.ChannelID(ismb_trans));
end

idx_chan = union(p.Results.idx_channel,find(~contains(layer_obj.ChannelID,'Reference') & ismember(layer_obj.ChannelID,p.Results.ChannelIDs)));

trans_to_merge = layer_obj.Transceivers(idx_chan);
gdir = 'along';
switch layer_obj.Filetype
    case 'ME70'
        gdir = 'along';
    case 'MS70'
        gdir = 'across';
end

new_trans = trans_to_merge.group_transceivers('fields_to_group',p.Results.fields_to_group,'groupdir',gdir,'filetype',layer_obj.Filetype);

layer_obj.add_trans(new_trans);
[layer_obj.AvailableFrequencies,idx_sort] = sort([layer_obj.AvailableFrequencies mean(new_trans.Config.Frequency)]);
layer_obj.AvailableChannelIDs = ([layer_obj.AvailableChannelIDs {new_trans.Config.ChannelID}]);
layer_obj.AvailableChannelIDs = layer_obj.AvailableChannelIDs(idx_sort);

end