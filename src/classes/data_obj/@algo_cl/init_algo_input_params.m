
%% Function
function init_algo_input_params(obj)

switch obj.Name
    case 'school_detect_3D'
        obj.Input_params = init_input_params({'r_min' 'r_max' 'beamAngle_min' 'beamAngle_max' 'thr_sv' 'filt_3D' 'DT' 'NBeams' 'NSamps' 'Gx' 'Gy' 'Gz'...
            'N_3D' 'Zext_min' 'Hext_min' 'numPing_min' 'geo_ref' 'rm_specular' 'denoised' });
    case 'Bad_pings_from_attitude'
        obj.Input_params = init_input_params({'thr_motion_angular_speed' 'thr_sv_correction' 'thr_angular_motion_diff'});
    case 'CFARdetection'
        obj.Input_params = init_input_params({'r_min' 'r_max' 'beamAngle_min' 'beamAngle_max' 'thr_sv' 'median_filter_bool' 'L' 'GC' 'DT' 'NBeams' 'NSamps' 'N_2D' 'Gx' 'Gy' 'Gz'...
            'N_3D' 'AR_min' 'Rext_min' 'stdR_min' 'numPing_min' 'rm_specular'  });
    case 'CanopyHeight'
        obj.Input_params = init_input_params({'r_min' 'nb_min_sples' 'thr_sv'});
    case 'Classification'
        obj.Input_params = init_input_params({'classification_file' 'ref' 'nb_min_cells' 'cluster_tags' 'thr_cluster'...
            'max_iter' 'distance' 'replicates' 'create_regions' 'reslice'});
    case 'BottomDetection'
        obj.Input_params = init_input_params({'r_min' 'r_max' 'thr_bottom' 'thr_backstep' ...
            'h_filt' 'v_filt' 'shift_bot' 'rm_outliers_method' 'interp_method' 'denoised'});
    case 'BottomDetectionV2'
        obj.Input_params = init_input_params({'r_min' 'r_max' 'thr_bottom' 'thr_backstep'...
            'thr_echo' 'thr_cum' 'shift_bot' 'rm_outliers_method' 'interp_method' 'denoised'});
    case 'DropOuts'
        obj.Input_params = init_input_params({'r_min' 'r_max' 'thr_sv' 'thr_sv_max' 'gate_dB'});
    case 'MBecho'
        obj.Input_params = init_input_params({'p_int_offset' 'copy_other_f' 'singleMBE_region' 'WC_lgth'});
    case 'BadPingsV2'
        obj.Input_params = init_input_params({ 'Ringdown_std_bool' 'Ringdown_std' 'BS_std_bool' 'BS_std'...
            'Above' 'thr_spikes_Above' 'Below' 'thr_spikes_Below' 'Additive' 'thr_add_noise' 'denoised' 'enhance'});
    case 'SpikesRemoval'
        obj.Input_params = init_input_params({'r_min' 'r_max' 'thr_sp' 'v_filt' 'v_buffer' 'flag_bad_pings' 'denoised'});
    case 'SchoolDetection'
        obj.Input_params = init_input_params({'r_min' 'r_max' 'thr_sv' 'thr_sv_max' 'l_min_can' 'h_min_can'...
            'l_min_tot' 'h_min_tot' 'horz_link_max' 'vert_link_max' 'nb_min_sples' 'denoised'});
    case 'Denoise'
        obj.Input_params = init_input_params({'h_filt' 'v_filt' 'NoiseThr' 'SNRThr' 'snr_filt'});
    case 'SingleTarget'
        obj.Input_params = init_input_params({'r_min' 'r_max' 'TS_threshold' 'TS_threshold_max' 'PLDL'...
            'MaxBeamComp' 'MinNormPL' 'MaxNormPL' 'MaxStdMajAxisAngle' 'MaxStdMinAxisAngle' 'denoised'});
    case 'TrackTarget'
        obj.Input_params = init_input_params({'AlphaMajAxis' 'AlphaMinAxis' 'AlphaRange' ...
            'BetaMajAxis' 'BetaMinAxis' 'BetaRange' ...
            'ExcluDistMajAxis' 'ExcluDistMinAxis' 'ExcluDistRange' ...
            'MaxStdMajAxisAngle' 'MaxStdMinAxisAngle' ...
            'MissedPingExpMajAxis' 'MissedPingExpMinAxis' 'MissedPingExpRange' ...
            'WeightMajAxis' 'WeightMinAxis' 'WeightRange' 'WeightTS' 'WeightPingGap' ...
            'Min_ST_Track' 'Min_Pings_Track' 'Max_Gap_Track' 'Min_max_TS_track' 'IgnoreAttitude'});
    case 'BottomFeatures'
        obj.Input_params = init_input_params({'bot_feat_comp_method' 'thr_cum' 'thr_cum_max' 'estimated_slope' 'thr_sv' 'bot_ref_depth' 'denoised'});
    otherwise
        obj.Input_params=[];

end

end