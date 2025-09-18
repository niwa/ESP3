function [data,idx_r,idx_ping,idx_beam,bad_data_mask,bad_trans_vec,intersection_mask,below_bot_mask,mask_from_st] = get_data_from_region(trans_obj,region,varargin)

%% input parser
p = inputParser;
addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addRequired(p,'region',@(x) isa(x,'region_cl'));
addParameter(p,'timeBounds',[0 Inf],@isnumeric);
addParameter(p,'depthBounds',[-inf inf],@isnumeric);
addParameter(p,'rangeBounds',[-inf inf],@isnumeric);
addParameter(p,'refRangeBounds',[-inf inf],@isnumeric);
addParameter(p,'BeamAngularLimit',[-inf inf],@isnumeric);
addParameter(p,'idx_beam',[],@isnumeric);
addParameter(p,'db',1,@isnumeric);
addParameter(p,'dr',1,@isnumeric);
addParameter(p,'dp',1,@isnumeric);
addParameter(p,'field','sv',@ischar);
addParameter(p,'alt_fields',{},@iscell);
addParameter(p,'intersect_only',false,@(x) isnumeric(x)||islogical(x));
addParameter(p,'idx_regs',[],@isnumeric);
addParameter(p,'line_obj',[],@(x) isa(x,'line_cl')||isempty(x));
addParameter(p,'regs',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'select_reg','all',@ischar);
addParameter(p,'keep_bottom',false,@(x) isnumeric(x)||islogical(x));
parse(p,trans_obj,region,varargin{:});

%% init
data = [];
bad_data_mask = [];
intersection_mask = [];
bad_trans_vec = [];
below_bot_mask = [];
mask_from_st = [];


if isempty(p.Results.idx_beam)
    idx_beam = trans_obj.get_idx_beams(p.Results.BeamAngularLimit);
else
   idx_beam = p.Results.idx_beam;
end

[idx_r,idx_ping,data_mask] = trans_obj.get_idx_r_idx_ping(region,...
    'depthBounds',p.Results.depthBounds,...
    'timeBounds',p.Results.timeBounds,...
    'rangeBounds',p.Results.rangeBounds,...
    'refRangeBounds',p.Results.refRangeBounds,...
    'timeBounds',p.Results.timeBounds,...
    'idx_beam',idx_beam,...
    'dr',p.Results.dr,'dp',p.Results.dp,'db',p.Results.db);


if isempty(idx_r)||isempty(idx_ping)
    idx_beam = [];
    return;
end

if isempty(idx_beam)
    idx_beam = (1:trans_obj.Data.Nb_beams);
end

depth_transd = trans_obj.get_transducer_depth(idx_ping);
range_trans = trans_obj.get_samples_range(idx_r);
time_tot = trans_obj.get_transceiver_time(idx_ping);

[data,~] = trans_obj.get_data_to_process('field',p.Results.field,'alt_fields',p.Results.alt_fields,'idx_r',idx_r,'idx_ping',idx_ping,'idx_beam',idx_beam);

bot_sple = trans_obj.get_bottom_idx(idx_ping,idx_beam);
bot_sple(isnan(bot_sple)) = inf;

[~,~,idx_keep_r] = intersect(idx_r,region.Idx_r);
[~,~,idx_keep_p] = intersect(idx_ping,region.Idx_ping);

if isempty(data)
    warning('No such data');
    return;
end

region.Idx_ping = idx_ping;
region.Idx_r = idx_r;


switch region.Shape
    case 'Polygon'
        region.MaskReg = region.get_sub_mask(idx_keep_r,idx_keep_p);
        data(region.get_mask==0) = NaN;
end

if isempty(idx_r)||isempty(idx_ping)
    warning('Cannot integrate this region, no data...');
    trans_obj.rm_region_id(region.Unique_ID);
    return;
end
intersection_mask = true(size(data,[1,2]));

if p.Results.intersect_only==1
    
    switch p.Results.select_reg
        case 'all'
            idx = trans_obj.find_regions_type('Data');
        otherwise
            idx = p.Results.idx_regs;
    end
    
    intersection_mask = region.get_mask_from_intersection(trans_obj.Regions(idx));
    
    if ~isempty(p.Results.regs)
        intersection_mask_2 = region.get_mask_from_intersection(p.Results.regs);
        intersection_mask   = intersection_mask_2|intersection_mask;
    end
   
   
end

idx = trans_obj.find_regions_type('Bad Data');
bad_data_mask = region.get_mask_from_intersection(trans_obj.Regions(idx));

mask_spikes = trans_obj.get_spikes(idx_r,idx_ping);

if ~isempty(mask_spikes)
    bad_data_mask = bad_data_mask|mask_spikes;
end

if region.Remove_ST
    mask_from_st = trans_obj.mask_from_st();
    mask_from_st = mask_from_st(idx_r,idx_ping);
else
    mask_from_st = false(size(data,[1,2]));
end

bad_trans_vec = (trans_obj.Bottom.Tag(idx_ping)==0);

if p.Results.keep_bottom==0
   below_bot_mask = bsxfun(@ge,idx_r,bot_sple);
else
    below_bot_mask = false(size(data));
end

data(~data_mask)=nan;

switch region.Reference
    case 'Surface'
        line_ref = -repmat(depth_transd,1,1,numel(idx_beam));
    case 'Transducer'
        line_ref = zeros(1,size(data,2),size(data,3));
    case 'Bottom'
        line_ref = trans_obj.get_bottom_range(idx_ping,idx_beam);
    case 'Line'
        if isempty(p.Results.line_obj)
            line_obj=line_cl('Range',-depth_transd,'Time',time_tot);
        else
            line_obj=p.Results.line_obj;
        end
        line_ref = resample_data_v2(line_obj.Range,line_obj.Time,time_tot);
        line_ref = repmat(line_ref,1,1,numel(idx_beam));
end

if any(~isinf(p.Results.refRangeBounds))
        range_from_line_ref=(range_trans-line_ref);
        data(range_from_line_ref<min(p.Results.refRangeBounds)|range_from_line_ref>max(p.Results.refRangeBounds))=nan;
end


