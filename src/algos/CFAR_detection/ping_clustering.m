function ClusterID= ping_clustering(detection_mask,varargin)

p = inputParser;
addRequired(p,'detection_mask',@islogical);
addParameter(p,'NBeams',1,@(x) x>0);
addParameter(p,'NSamps',2,@(x) x>0);
addParameter(p,'N_2D',10,@(x) x>0);
addParameter(p,'conn',8,@isnumeric);
addParameter(p,'load_bar_comp',[]);

parse(p,detection_mask,varargin{:});

if ~isempty(p.Results.load_bar_comp)
    p.Results.load_bar_comp.progress_bar.setText('Ping clustering...');
end

NBeams = p.Results.NBeams;
NSamps = p.Results.NSamps;

detection_mask = permute(detection_mask,[1 3 2]);

[nb_samples,nb_beams,~] = size(detection_mask);

ii = find(detection_mask);

iPing = ceil(ii/(nb_samples*nb_beams));
iBeam = ceil((ii-(iPing-1)*nb_samples*nb_beams)/nb_samples);
iSample  = ii-(iPing-1)*nb_samples*nb_beams-(iBeam-1)*nb_samples;
 
loc1 = [iSample(:)/NSamps,iBeam(:)/NBeams,2*iPing(:)];
ptCloud = pointCloud(loc1);
[ccid,~] = pcsegdist(ptCloud,1,"NumClusterPoints",[p.Results.N_2D inf]) ;

ClusterID = zeros(size(detection_mask));
ClusterID(ii) = ccid';

ClusterID = permute(ClusterID,[1 3 2]);

end

