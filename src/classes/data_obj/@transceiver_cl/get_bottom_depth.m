function bot_depth=get_bottom_depth(trans_obj,varargin)

idx_pings = 1:numel(trans_obj.Time);
idx_r = (1:numel(trans_obj.Range));
idx_beam = 1:max(trans_obj.Data.Nb_beams);

switch nargin
    case 1
    case 2
        idx_pings = varargin{1};
    case 3 
        idx_pings = varargin{1};
        idx_beam = varargin{2};
end

[data_struct,~] = trans_obj.get_xxx_ENH('data_to_pos',{'bottom'},...
    'idx_ping',idx_pings,...
    'idx_r',idx_r,...
    'idx_beam',idx_beam);

bot_depth = data_struct.bottom.H;