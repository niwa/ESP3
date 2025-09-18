function listen_ping_cback(idx_ping,r_lim,a_lim)
layer=get_current_layer();

nb_trans = numel(layer.Transceivers);
signal = cell(1,nb_trans);
f_c = nan(1,nb_trans);
f_s = nan(1,nb_trans);



for idx_freq = 1:nb_trans
    trans_obj=layer.Transceivers(idx_freq);
    rr = trans_obj.get_samples_range();
    idx_r = find(rr >= r_lim(1) & rr <= r_lim(2));
    idx_beam = trans_obj.get_idx_beams(a_lim);
    if isempty(idx_r)
        continue;
    end
    signal{idx_freq}=trans_obj.Data.get_subdatamat('idx_ping',idx_ping,'field','svdenoised','idx_r',idx_r,'idx_beam',idx_beam);

    if isempty(signal{idx_freq})
        signal{idx_freq}=trans_obj.Data.get_subdatamat('idx_ping',idx_ping,'field','sv','idx_r',idx_r,'idx_beam',idx_beam);
    end
    if  size(signal{idx_freq},3) > 1 
        signal{idx_freq} = pow2db_perso(squeeze(mean(db2pow_perso(signal{idx_freq}),3,'omitnan')));
    end

    f_c(idx_freq) = mean(squeeze(trans_obj.get_center_frequency(idx_ping)));
    f_s(idx_freq) = 1./mean(squeeze(trans_obj.get_params_value('SampleInterval',idx_ping)));
end

%fs_factor = ceil(mean(f_c)/(1e3));
fs_factor = 200;
listen_ping_cw(signal,f_c,f_s,fs_factor)





