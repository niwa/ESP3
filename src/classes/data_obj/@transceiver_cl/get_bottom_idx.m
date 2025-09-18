function bot_idx = get_bottom_idx(trans_obj,varargin)

nb_pings = length(trans_obj.get_transceiver_pings());
%nb_samples = length(trans_obj.get_samples_range());
nb_beams = numel(trans_obj.Params.BeamNumber);

Bottom_idx = round(trans_obj.Bottom.Sample_idx);

if isempty(Bottom_idx)
    bot_idx = ones(nb_beams,nb_pings);
else
    bot_idx = nan(nb_beams,nb_pings);
    bot_idx(~isnan(Bottom_idx)) = Bottom_idx(~isnan(Bottom_idx));
    bot_idx(Bottom_idx>=trans_obj.Data.Nb_samples(trans_obj.Data.BlockId)) = nan;
end

bot_idx(bot_idx==0) = 1;

if nargin>=2
    if ~isempty(varargin{1})
        idx = varargin{1};
        idx(idx<=0|idx>size(bot_idx,2)) = [];
        bot_idx = bot_idx(:,idx);
    end

    if nargin ==3
        if ~isempty(varargin{2})    
            idx = varargin{2};
            idx(idx<=0|idx>size(bot_idx,1)) = [];
            bot_idx = bot_idx(idx,:);
        end
    end
end
    
if nb_beams>1
    bot_idx =shiftdim(bot_idx',-1);
end