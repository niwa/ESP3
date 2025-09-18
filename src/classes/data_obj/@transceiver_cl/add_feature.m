function add_feature(trans_obj,features,varargin)

p = inputParser;

addRequired(p,'trans_obj',@(trans_obj) isa(trans_obj,'transceiver_cl'));
addRequired(p,'features',@(obj) isa(obj,'feature_3D_cl')||isempty(obj));

parse(p,trans_obj,features,varargin{:});

for ifi = 1:numel(features)
    trans_obj.rm_feature_id(features(ifi).Unique_ID);
    trans_obj.Features = [trans_obj.Features features(ifi)];
end

end