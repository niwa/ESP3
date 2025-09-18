function bot_r_trans = get_bottom_range(trans_obj,varargin)


r_trans = trans_obj.get_samples_range();


if nargin == 1 || isempty(varargin{1})
    idx_p = 1:numel(trans_obj.Time);
else
    idx_p = varargin{1};
end

Bottom_idx = trans_obj.get_bottom_idx(varargin{:});

if isempty(trans_obj.Bottom.Sample_idx)
    bot_r_trans = ones(size(Bottom_idx))*r_trans(end);
else
    bot_r_trans = nan(size(Bottom_idx()));
    bot_r_trans(~isnan(Bottom_idx)) = r_trans(Bottom_idx(~isnan(Bottom_idx)));
    bot_r_trans(Bottom_idx>=trans_obj.Data.Nb_samples(trans_obj.Data.BlockId(idx_p)')) = nan;
    bot_r_trans(Bottom_idx==1) = nan;
end

