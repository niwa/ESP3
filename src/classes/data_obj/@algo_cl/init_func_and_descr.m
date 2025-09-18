function init_func_and_descr(obj)

name=obj.Name;

switch name
    case 'school_detect_3D'
        obj.Function=@school_3d_features_detection;
        obj.Description = '3D school detection for MBES';
        obj.Display_name = '3D School Detection';
    case 'Bad_pings_from_attitude'
        obj.Function=@bad_pings_from_attitude;
        obj.Description = 'Detection of bad pings from motion data (pitch and roll)';
        obj.Display_name = '"Bad pings" Detection from motion data';
    case 'CFARdetection'
        obj.Function=@CFAR_wc_features_detection;
        obj.Description = 'CFAR Feature detection for MBES';
        obj.Display_name = 'Feature Detection (CFAR)';
    case 'CanopyHeight'
        obj.Function=@canopy_height_estimation;
        obj.Description = 'Detection of the canopy height for submerged plants';
        obj.Display_name = 'Canopy Detection';
    case 'BottomDetection'
        obj.Function=@detec_bottom_algo_v3;
        obj.Description = 'Detection of the bottom echo';
        obj.Display_name = 'Bottom Detection (V1)';
    case 'BottomDetectionV2'
        obj.Function=@detec_bottom_algo_v4;
        obj.Description = 'Detection of the bottom echo';
        obj.Display_name = 'Bottom Detection (V2)';
    case 'BadPingsV2'
        obj.Function=@bad_pings_removal_3;
        obj.Description = 'Automated detection of pings deemed unusable for further analysis and based on multiple criteria.';
        obj.Display_name = '"Bad pings" Detection';
    case 'DropOuts'
        obj.Function=@dropouts_detection;
        obj.Description = 'Detection of drops in signal level from consecutive pings, flagging them as “bad”.';
        obj.Display_name = 'Dropouts Detection';
    case 'MBecho'
        obj.Function=@detect_multiple_bottom_echo;
        obj.Description = 'Detection of multiple bottom echoes in the WC and creation of a “bad data” region where they appear.';
        obj.Display_name = 'Multiple Bottom echo Detection';
    case 'Denoise'
        obj.Function=@bg_noise_removal_v2;
        obj.Description = 'Removal of background noise and estimation of signal to noise ratio.';
        obj.Display_name = 'Background Noise Removal';
    case 'SchoolDetection'
        obj.Function=@school_detect;
        obj.Description = 'Implementation of the shoal analysis and patch estimation system algorithm (SHAPES).';
        obj.Display_name = '2D School Detection';
    case 'SingleTarget'
        obj.Function=@single_targets_detection;
        obj.Description = 'Detection of isolated targets based on signal characteristics.';
        obj.Display_name = 'Single Targets Detection';
    case 'TrackTarget'
        obj.Function=@track_targets_angular;
        obj.Description = 'Tracking of single targets in 4 dimensions.';
        obj.Display_name = 'Single-Targets Tracking';
    case 'SpikesRemoval'
        obj.Function=@spike_removal;
        obj.Description = 'Automated detection of short bursts of noise attributed to external interferences and removed from further analysis.';
        obj.Display_name = 'Noise-Spike removal';
    case 'BottomFeatures'
        obj.Function=@compute_bottom_features;
        obj.Description = 'Calculation of RoxAnn bottom features “roughness (E1)” and “hardness (E2)”. Three approaches available.';
        obj.Display_name = 'RoxAnn Bottom Features';
    case 'Classification'
        obj.Function=@apply_classification;
        obj.Description = 'Classification of regions or integration cells based on a user-defined classification tree.';
        obj.Display_name = 'Region/WC classification';
    otherwise
        obj.Function=[];
        obj.Description = '';
        
end

end