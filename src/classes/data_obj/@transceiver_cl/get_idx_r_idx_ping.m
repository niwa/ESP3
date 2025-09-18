function [idx_r,idx_ping,data_mask] = get_idx_r_idx_ping(trans_obj,region,varargin)

%% input parser
p = inputParser;
addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addRequired(p,'region',@(x) isa(x,'region_cl'));
addParameter(p,'timeBounds',[0 Inf],@isnumeric);
addParameter(p,'depthBounds',[-inf inf],@isnumeric);
addParameter(p,'rangeBounds',[-inf inf],@isnumeric);
addParameter(p,'refRangeBounds',[-inf inf],@isnumeric);
addParameter(p,'idx_beam',[],@isnumeric);
addParameter(p,'db',1,@isnumeric);
addParameter(p,'dr',1,@isnumeric);
addParameter(p,'dp',1,@isnumeric);
parse(p,trans_obj,region,varargin{:});

idx_ping_tot = region.Idx_ping;
idx_r = [];
idx_ping = [];
data_mask = [];

idx_ping_tot(idx_ping_tot>numel(trans_obj.get_transceiver_time())) = [];

time_tot = trans_obj.get_transceiver_time(idx_ping_tot);

idx_keep_x = ( time_tot<=p.Results.timeBounds(2) & time_tot>=p.Results.timeBounds(1) );

if ~any(idx_keep_x)
    return;
end

idx_ping = idx_ping_tot(idx_keep_x);
idx_r = region.Idx_r;
idx_r = idx_r(1:p.Results.dr:end);
idx_ping = idx_ping(1:p.Results.dp:end);

range_trans = trans_obj.get_samples_range(idx_r);

idx_r = idx_r(range_trans>min(p.Results.rangeBounds) & range_trans<=max(p.Results.rangeBounds));

if isempty(idx_r)
    return;
end

if ~isempty(p.Results.idx_beam)
    idx_beam  =  p.Results.idx_beam;
else
    nb_beams = max(trans_obj.Data.Nb_beams,[],'omitnan');
    idx_beam =  1:nb_beams;
end

data_mask = true(numel(idx_r),numel(idx_ping),numel(idx_beam));

if ~all(isinf(p.Results.depthBounds))    
    depth_samples = trans_obj.get_samples_depth(idx_r,idx_ping,idx_beam);
    data_mask(depth_samples<min(p.Results.depthBounds)|depth_samples>max(p.Results.depthBounds))=false;
end

range_samples = trans_obj.get_samples_range(idx_r);
data_mask(range_samples<min(p.Results.rangeBounds)|range_samples>max(p.Results.rangeBounds),:,:)=false;

mask_vec = any(sum(data_mask,2,'omitnan')>0,3);
mask_vec = mask_vec(1:numel(idx_r));
idx_r = idx_r(mask_vec);
data_mask = data_mask(mask_vec,:,:);