function [Sv_f,f_vec,r_slice]=processSv_f_r_2(trans_obj,EnvData,iPings,r,win_fact,cal,output_size,cell_h)

att_model = EnvData.AttModel;

if isempty(att_model)
    att_model='doonan';
end


if strcmp(trans_obj.Mode,'FM')
    
    if isempty(cal)
        cal=trans_obj.get_transceiver_fm_cal();
    end
    
    Rwt_rx=trans_obj.Config.Impedance;
    Ztrd=trans_obj.Config.Ztrd;
    nb_chan = trans_obj.Config.NbQuadrants;
    iPing = iPings(1);
    f_s_sig=round((1./(trans_obj.get_params_value('SampleInterval',iPing))));
    c=(EnvData.SoundSpeed);
    FreqStart=(trans_obj.get_params_value('FrequencyStart',iPing));
    FreqEnd=(trans_obj.get_params_value('FrequencyEnd',iPing));

    if FreqEnd>=120000||FreqStart>=120000
        att_model='fandg';
    end  
    
    ptx=(trans_obj.get_params_value('TransmitPower',iPing));
    [~,Np]=trans_obj.get_pulse_length(iPing);

    %eq_beam_angle=trans_obj.Config.EquivalentBeamAngle;

    
    range=trans_obj.get_samples_range();
    nb_samples=length(range);
    
    n_sig_sub=win_fact*Np;

    
    [~,idx_r1]=min(abs(range-(r(1))));
    [~,idx_r2]=min(abs(range-(r(end))));
    
    idx_r1=max(idx_r1,1);
    idx_r2=min(idx_r2,nb_samples);

    if (idx_r2-idx_r1)<n_sig_sub
        idx_r=round((idx_r1+idx_r2)/2);
        idx_r1=max(idx_r-ceil(n_sig_sub/2),1);
        idx_r2=min(idx_r+ceil(n_sig_sub/2)-1,nb_samples);
    end


    y_c = double_to_complex_single(trans_obj.Data.get_subdatamat('idx_r',idx_r1:idx_r2,'idx_ping',iPings,'field','y_filtered'));

    if isempty(y_c)
        y_c = double_to_complex_single(trans_obj.Data.get_subdatamat('idx_r',idx_r1:idx_r2,'idx_ping',iPings,'field','y'));
    end
    
    y_c = double(y_c);
    y_c = mean(y_c,2,'omitnan');
    n_sig = numel(y_c);
    n_sig_sub=min(n_sig_sub,n_sig);

    nfft_proc = 2^(nextpow2(n_sig_sub)+2);

    switch output_size
        case '2D'
            n_overlap=ceil(n_sig_sub/2);
        case'3D'
            if cell_h==0
                n_overlap=n_sig_sub-1;
            else
                dr = mean(diff(range));
                n_cell=min(max(floor(cell_h/dr),1),n_sig_sub);
                n_overlap=min(n_sig_sub-ceil(n_cell/2),n_sig_sub-1);
            end
    end

    n_rep=ceil(max(FreqEnd,FreqStart)/f_s_sig);
    f_vec_rep=f_s_sig*(0:nfft_proc*n_rep-1)/nfft_proc;
    
%     if FreqStart>FreqEnd
%         f_vec_rep=fliplr(f_vec_rep);
%     end
    
    idx_vec=f_vec_rep>=min(FreqStart,FreqEnd)&f_vec_rep<=max(FreqStart,FreqEnd);

    if isempty(find(idx_vec~=0,1))
        id1 = find(f_vec_rep>=min(FreqStart,FreqEnd),1);
        id2 = find(f_vec_rep<=max(FreqStart,FreqEnd));
        id2 = id2(end);
        Freq = mean(FreqEnd,FreqStart);
        if abs(f_vec_rep(id1)-Freq)<=abs(f_vec_rep(id2)-Freq)
            idx_vec = id1;
        else
            idx_vec = id2;
        end
    end
        
    f_vec=f_vec_rep(idx_vec);

    r=range(idx_r1:idx_r2);

    y_spread=y_c.*r;
    ddd = false;
    if ~isdeployed()&&ddd
        fprintf('%s\n%.0fkHz: FFT win: %.0f, Sig length: %.0f, Overlap; %d\n' ,output_size,(FreqStart+FreqEnd)/2/1e3,nfft_proc,numel(y_spread),n_overlap);
    end
    
    w_h=hann(n_sig_sub);
%     w_h=ones(n_sig_sub,1);
%     w_h = tukeywin(n_sig_sub,0.5);
%     w_h=hamming(n_sig_sub);
    
    w_h=w_h/(sqrt(sum(w_h.^2,'omitnan')/n_sig_sub));
    
    fft_vol = spectrogram(y_spread,w_h,n_overlap,nfft_proc)/nfft_proc/2;
    
    [~,y_tx_matched,~]=trans_obj.get_pulse();
    
    y_tx_auto=xcorr(y_tx_matched)/sum(abs(y_tx_matched).^2,'omitnan');
    
    if n_sig<length(y_tx_auto)
        y_tx_auto_red=y_tx_auto(ceil(length(y_tx_auto)/2)-floor(n_sig/2)+1:ceil(length(y_tx_auto)/2)-floor(n_sig/2)+n_sig);
    else
        y_tx_auto_red=y_tx_auto;
    end
    
    fft_pulse=(fft(y_tx_auto_red,nfft_proc))/nfft_proc;
    
    fft_vol_norm=bsxfun(@rdivide,fft_vol,(fft_pulse));
    
    fft_vol_norm_rep=repmat(fft_vol_norm,n_rep,1);
    
    fft_vol_norm=fft_vol_norm_rep(idx_vec,:)';
      
    if size(fft_vol_norm,1)==1
        r_slice=mean(r);
    else
        idx_val=ceil(n_sig_sub/2)+(0:size(fft_vol_norm,1)-1)*(n_sig_sub-n_overlap);
        r_slice=r(idx_val);
    end

    switch trans_obj.Config.TransceiverName
        case 'TOPAS'            
            Sv_f=20*log10(abs(fft_vol_norm));
        otherwise
            
            alpha_f = arrayfun(@(x) seawater_absorption(x, EnvData.Salinity, EnvData.Temperature, r_slice,att_model),f_vec/1e3,'un',0);
            alpha_f=cell2mat(alpha_f);
            alpha_f=alpha_f/1e3;
            
            lambda=c./(f_vec);
                        
            eq_beam_angle=interp1(cal.Frequency,cal.eq_beam_angle,f_vec,'linear','extrap');

            Gf=interp1(cal.Frequency,cal.Gain,f_vec,'linear','extrap');

            Prx_fft_vol=nb_chan*(abs(fft_vol_norm)/(2*sqrt(2))).^2*((Rwt_rx+Ztrd)/Rwt_rx)^2/Ztrd;
            
            tw=round(sum(abs(w_h).^2,'omitnan')/...
            (max(abs(w_h).^2,[],'omitnan')))/f_s_sig;


            Sv_f=bsxfun(@minus,10*log10(Prx_fft_vol)+bsxfun(@times,2*alpha_f,r_slice),10*log10(c*tw/2)+10*log10(ptx*lambda.^2/(16*pi^2))+2*Gf+eq_beam_angle);
    end
    
%     df=mean(abs(diff(f_vec)));
%     ds=round(2e3/df);
%     if rem(ds,2)==1
%         ds=ds+1;
%     end
        
%     if ds<size(Sv_f,2)
%         tmp=smoothdata(Sv_f,2,'rlowess',ds);
%         
%         tmp(isnan(Sv_f))=nan;
%         
%         Sv_f=tmp;
%     end
    
else
    Sv_f=[];
    f_vec=[];
    r_slice=[];
    fprintf('%s not in  FM mode\n',trans_obj.Config.ChannelID);
end
r_slice=r_slice(:);

end
