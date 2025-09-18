function default_val = get_default_bathy_extract_val()
default_val.win_filt = 5;
default_val.echo_len_fact = [1/8 1];
default_val.thr_echo  = -30;
default_val.field = 'sv';
default_val.fitmeth = 'poly11';%'poly1' or 'poly11'
default_val.rsq_slope_est_thr = 1;
default_val.comp_angle = [true true];
default_val.slope_max = 70;
default_val.default_slope = 5;
default_val.estimate_slope_bool = true;
default_val.full_bathy_extract = false;
default_val.robust_estimation = true;
default_val.use_full_att = false;
default_val.use_full_gps = false;
default_val.dt_att = 0;
default_val.clean_bot_bool = true;
end