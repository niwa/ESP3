function [data,sampleAcrossDist,sampleAlongDist,sampleUpDist]=get_subdatamat_AcUp_pos(trans_obj,varargin)

p = inputParser;

addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addParameter(p,'idx_r',[],@isnumeric);
addParameter(p,'idx_beam',[],@isnumeric);
addParameter(p,'idx_ping',[],@isnumeric);
addParameter(p,'field','data_wc',@ischar);

parse(p,trans_obj,varargin{:});

sampleAcrossDist = [];
sampleAlongDist = [];
sampleUpDist = [];

data = trans_obj.Data.get_subdatamat('field',p.Results.field,'idx_ping',p.Results.idx_ping,'idx_beam',p.Results.idx_beam,'idx_r',p.Results.idx_r);

if isempty(data)
    return;
end

r = trans_obj.get_samples_range(p.Results.idx_r);

beamAngle=trans_obj.get_params_value('BeamAngleAthwartship',p.Results.idx_ping,p.Results.idx_beam);
beamAngleAl=trans_obj.get_params_value('BeamAngleAlongship',p.Results.idx_ping,p.Results.idx_beam);

sampleAcrossDist = -r.*sind(beamAngle);
sampleAlongDist = -r.*sind(beamAngleAl);
sampleUpDist = r.*cosd(beamAngle);