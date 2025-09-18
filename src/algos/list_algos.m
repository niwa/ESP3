function alg_names = list_algos(varargin)
alg_names_all={'Denoise' 'BottomDetection','BottomDetectionV2',...
    'BottomFeatures','MBecho','CanopyHeight'...
    'BadPingsV2','DropOuts',...
    'SpikesRemoval','SchoolDetection','school_detect_3D',...
    'SingleTarget','TrackTarget',...
    'CFARdetection','Bad_pings_from_attitude','Classification'};

alg_names_reg_bool= [false true true false false false true true true true true true true true true false];

if nargin == 0 || ~varargin{1}
    alg_names = alg_names_all;
else
    alg_names = alg_names_all(alg_names_reg_bool);
end


