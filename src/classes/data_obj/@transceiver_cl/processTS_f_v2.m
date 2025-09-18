function [Sp_f,compensation_f,f_vec,r_tot,f_corr] = processTS_f_v2(trans_obj,EnvData,iPing,r,win_fact,cal,comp_angle)

range_tr=trans_obj.get_samples_range();
[~,idx_r1]=min(abs(range_tr-min(r)));
[~,idx_r2]=min(abs(range_tr-max(r)));
nb_samples = numel(range_tr);

switch numel(r)
    case 1
        output = '2D';
    otherwise
        output = '3D';
end

if strcmp(trans_obj.Mode,'FM')
    
    if isempty(cal)
        cal=trans_obj.get_transceiver_fm_cal();
    end
    
    Rwt_rx=trans_obj.Config.Impedance;
    Ztrd=trans_obj.Config.Ztrd;

    nb_chan = trans_obj.Config.NbQuadrants;
    
    %f_c = trans_obj.get_center_frequency(iPing)
    f_s_sig=round(1/(trans_obj.get_params_value('SampleInterval',iPing)));
    c=(EnvData.SoundSpeed);
    FreqStart=(trans_obj.get_params_value('FrequencyStart',iPing));
    FreqEnd=(trans_obj.get_params_value('FrequencyEnd',iPing));
    att_model = EnvData.AttModel;
    
    if isempty(att_model)
        att_model = 'doonan';
    end
    
    if FreqEnd>=120000||FreqStart>=120000
        att_model='fandg';
    end
     
    ptx=(trans_obj.get_params_value('TransmitPower',iPing));
    
    [~,Np]=trans_obj.get_pulse_length(iPing);
    
    n_sig_sub=win_fact*Np;

    idx_r1=max(idx_r1,1);
    idx_r2=min(idx_r2,nb_samples);
    
    if (idx_r2-idx_r1)<Np*win_fact
        idx_r=round((idx_r1+idx_r2)/2);
        idx_r1=max(idx_r-ceil(Np*win_fact/2),1);
        idx_r2=min(idx_r+ceil(Np*win_fact/2)-1,nb_samples);
    end
   
    idx_ts=idx_r1:idx_r2;

    y_c = double_to_complex_single(trans_obj.Data.get_subdatamat('idx_r',idx_ts,'idx_ping',iPing,'field','y_filtered'));

    if isempty(y_c)
        y_c = double_to_complex_single(trans_obj.Data.get_subdatamat('idx_r',idx_ts,'idx_ping',iPing,'field','y'));
    end
    y_c = double(y_c);
    n_sig = numel(y_c);

    n_sig_sub=min(n_sig_sub,n_sig);

    if comp_angle(1)
        AlongAngle_val=trans_obj.Data.get_subdatamat('idx_r',idx_ts,'idx_ping',iPing,'field','AlongAngle');
    else
        AlongAngle_val = zeros(size(y_c));
    end

    if comp_angle(2)
        AcrossAngle_val=trans_obj.Data.get_subdatamat('idx_r',idx_ts,'idx_ping',iPing,'field','AcrossAngle');
    else
        AcrossAngle_val = zeros(size(y_c));
    end

    if isempty(AlongAngle_val)
        AlongAngle_val = zeros(size(y_c));
    end

    if isempty(AcrossAngle_val)
        AcrossAngle_val = zeros(size(y_c));
    end

    r_ts=range_tr(idx_ts);
    
    [~,y_tx_matched,~]=trans_obj.get_pulse();
        
    y_tx_auto=xcorr(y_tx_matched)/sum(abs(y_tx_matched).^2,'omitnan');
    
    if n_sig_sub<length(y_tx_auto)
        y_tx_auto_red=y_tx_auto(ceil(length(y_tx_auto)/2)-floor(n_sig_sub/2)+1:ceil(length(y_tx_auto)/2)-floor(n_sig_sub/2)+n_sig_sub);
    else
        y_tx_auto_red=y_tx_auto;
    end
    
    w_h=hann(n_sig_sub);

    nfft_proc = 2^(nextpow2(n_sig_sub)+2);
    
    w_h=w_h/(sqrt(sum(w_h.^2,'omitnan')/n_sig_sub));
    
    fft_pulse=(fft(y_tx_auto_red,nfft_proc))/nfft_proc;

    switch output
        case '2D'
            n_overlap = 1;
        case '3D'
            n_overlap = n_sig_sub-1;
    end
    
    s = spectrogram(y_c,w_h,n_overlap,nfft_proc)/nfft_proc/2;
    
    s_norm=bsxfun(@rdivide,s,fft_pulse);
    
    n_rep=ceil(max(FreqEnd,FreqStart)/f_s_sig);
    
    f_vec_rep=f_s_sig*(0:nfft_proc*n_rep-1)/nfft_proc;
    
    s_norm_rep=repmat(s_norm,n_rep,1);
    
    idx_vec=f_vec_rep>=min(FreqStart,FreqEnd)&f_vec_rep<=max(FreqStart,FreqEnd);
    f_vec=f_vec_rep(idx_vec);
    
    s_norm=s_norm_rep(idx_vec,:)';
    
    if size(s_norm,1)>1
        idx_val=ceil(n_sig_sub/2)+(0:size(s_norm,1)-1)*(n_sig_sub-n_overlap);
    else
        [~,idx_val]=max(abs(y_c));
    end


    r_tot=r_ts(idx_val);
    
    if ~isempty(AlongAngle_val)
        AlongAngle_val=AlongAngle_val(idx_val);
        AcrossAngle_val=AcrossAngle_val(idx_val);
    end
    
    
    BeamWidthAlongship=interp1(cal.Frequency,cal.BeamWidthAlongship,f_vec,'linear','extrap');
    BeamWidthAthwartship=interp1(cal.Frequency,cal.BeamWidthAthwartship,f_vec,'linear','extrap');
    
    Gf=interp1(cal.Frequency,cal.Gain,f_vec,'linear','extrap');
      
    alpha_f = arrayfun(@(x) seawater_absorption(x, EnvData.Salinity, EnvData.Temperature, r_tot,att_model),f_vec/1e3,'un',0);
    alpha_f=cell2mat(alpha_f);
    alpha_f=alpha_f/1e3;
    
    Prx_fft=nb_chan*(abs(s_norm)/(2*sqrt(2))).^2*((Rwt_rx+Ztrd)/Rwt_rx)^2/Ztrd;
    
    %correction factor based on frequency response of targets to account for
    %positionning "error"... Not too sure though but seems to work.
    f_nom = trans_obj.Config.Frequency;
    [faBW,psBW] = trans_obj.get_beamwidth_at_f_c([]);
    f_corr=sum((1+(f_nom-f_vec)/f_nom).*Prx_fft.^2,[],'omitnan')/sum(Prx_fft.^2,[],'omitnan');
    
    %f_corr = ones(size(f_corr));
    if ~isempty(AlongAngle_val)
        AlongAngle_val_corr = AlongAngle_val*f_corr*trans_obj.Config.BeamWidthAlongship/faBW;
        AcrossAngle_val_corr = AcrossAngle_val*f_corr*trans_obj.Config.BeamWidthAthwartship/psBW;
        compensation_f =arrayfun(@(x,y)  simradBeamCompensation(x,y, AlongAngle_val_corr,AcrossAngle_val_corr),BeamWidthAlongship,BeamWidthAthwartship,'un',0);
        compensation_f = cell2mat(compensation_f);
    else
        compensation_f = zeros(size(f_vec));
    end

    lambda=c./(f_vec);

    Sp_f=bsxfun(@minus,bsxfun(@plus,10*log10(Prx_fft)+bsxfun(@times,2*alpha_f,r_tot),40*log10(r_tot)),10*log10(ptx*lambda.^2/(16*pi^2))+2*(Gf));
       
else

    idx_r=idx_r1:idx_r2;
    r_tot=range_tr(idx_r);
    f_corr=ones(size(idx_r));

    [faBW,psBW] = trans_obj.get_beamwidth_at_f_c([]);

    f_vec=trans_obj.get_params_value('Frequency',iPing);
    Sp_f=trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',iPing,'field','spdenoised');
    if isempty(Sp_f)
        Sp_f=trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',iPing,'field','sp');
    end

    idx_beam = 1;

    if comp_angle(1)
        al_angle = trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',iPing,'idx_beam',idx_beam,'field','AlongAngle');
    else
        al_angle=zeros(numel(idx_r),numel(iPing),numel(idx_beam));
    end

    if comp_angle(2)
        ac_angle = trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',iPing,'idx_beam',1,'field','AcrossAngle');
    else
        ac_angle=zeros(numel(idx_r),numel(iPing),numel(idx_beam));
    end

    if isempty(al_angle)
        al_angle = zeros(size(Sp_f));
    end

    if isempty(ac_angle)
        ac_angle = zeros(size(Sp_f));
    end

    compensation_f=simradBeamCompensation(faBW,psBW , ac_angle, al_angle);

    

    
end

end
