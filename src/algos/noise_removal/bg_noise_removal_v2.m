function output_struct=bg_noise_removal_v2(trans_obj,varargin)

range_t=trans_obj.get_samples_range();

p = inputParser;

defaultv_filt=5;
checkv_filt=@(v_filt)(v_filt>0&&v_filt<=1000);
defaulth_filt=10;
checkh_filt=@(h_filt)(h_filt>0&&h_filt<=1000);
defaultNoiseThr=-125;
checkNoiseThr=@(NoiseThr)(NoiseThr<=-10&&NoiseThr>=-200);
defaultSNRThr=10;
checkSNRThr=@(SNRThr)(SNRThr>=-10&&SNRThr<=50);


addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addParameter(p,'v_filt',defaultv_filt,checkv_filt);
addParameter(p,'h_filt',defaulth_filt,checkh_filt);
addParameter(p,'NoiseThr',defaultNoiseThr,checkNoiseThr);
addParameter(p,'snr_filt',true,@islogical);
addParameter(p,'SNRThr',defaultSNRThr,checkSNRThr);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
addParameter(p,'load_bar_comp',[]);

parse(p,trans_obj,varargin{:});
output_struct.done=false;

c=trans_obj.get_soundspeed([]);

FreqStart=trans_obj.get_params_value('FrequencyStart',1);
FreqEnd=trans_obj.get_params_value('FrequencyEnd',1);
Freq=trans_obj.Config.Frequency;
ptx=trans_obj.get_params_value('TransmitPower');

eq_beam_angle=trans_obj.Config.EquivalentBeamAngle;
gain=trans_obj.get_current_gain();

FreqCenter=(FreqStart+FreqEnd)/2;

eq_beam_angle=eq_beam_angle+20*log10(Freq./(FreqCenter));
alpha=trans_obj.get_absorption();
cal=trans_obj.get_transceiver_cw_cal();
sacorr=2*cal.SACORRECT;
nb_beams = numel(gain);

pings_tot=trans_obj.get_transceiver_pings();

if strcmp(trans_obj.Mode,'FM')
    [t_eff,~]=trans_obj.get_pulse_comp_Teff();
else
    [t_eff,~]=trans_obj.get_pulse_Teff();
end

[t_nom,~]=trans_obj.get_pulse_length();

nb_pings_tot=numel(pings_tot);
block_len = get_block_len(50,'cpu',p.Results.block_len);

block_size=ceil(block_len/numel(range_t));

num_ite=ceil(nb_pings_tot/block_size);

if ~isempty(p.Results.load_bar_comp)
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite*nb_beams, 'Value',0);
end
output_struct.done=false;
idx_ping_tot=1:nb_pings_tot;
idx_r=1:numel(range_t);

disp =false;

noise_avg = nan(nb_beams,nb_pings_tot);

for ui=1:num_ite
    idx_ping=idx_ping_tot((ui-1)*block_size+1:min(ui*block_size,numel(idx_ping_tot),'omitnan'));
    %sub_bot=trans_obj.get_bottom_range(idx_ping);

    lambda=c./FreqCenter;
    [~,Np] = trans_obj.get_pulse_length(idx_ping);
    Np = max(Np,[],2);
    reg_temp=region_cl('Name','Temp','Idx_r',idx_r,'Idx_ping',idx_ping);

    idx_beam = 1:nb_beams;
    for uib = idx_beam

        [temp_pow,idx_r,idx_ping,~,bad_data_mask,~,~,~,~] = ...
            get_data_from_region(trans_obj,reg_temp,'field','power','idx_beam',uib);

        if isempty(temp_pow)
            continue;
        end
        temp_pow(temp_pow==0)=nan;

        temp_pow(bad_data_mask)=nan;

        temp_pow(1:min(2*Np(1,1,uib),numel(range_t)),:)=nan;

        if all(isnan(temp_pow),'all')
            [sv,~,~,~,~,~,~,~,~]=get_data_from_region(trans_obj,reg_temp,'field','sv','idx_beam',uib);
            [sp,~,~,~,~,~,~,~,~]=get_data_from_region(trans_obj,reg_temp,'field','sp','idx_beam',uib);
            trans_obj.Data.replace_sub_data_v2(sp,'spdenoised','idx_ping',idx_ping,'idx_beam',uib);
            trans_obj.Data.replace_sub_data_v2(sv,'svdenoised','idx_ping',idx_ping,'idx_beam',uib);
            continue;
        end

        [nb_samples,nb_pings]=size(temp_pow);

        [I,J]=find(~isnan(temp_pow));

        J_d=[J ; J ];
        I_d=[I ; ceil(0.8*I)];

        idx_d=I_d+nb_samples*(J_d-1);
        reg_n=false(nb_samples,nb_pings);
        reg_n(idx_d)=true;

        v_filt_m=max(p.Results.v_filt,3*max(diff(range_t),[],1,'omitnan'),'omitnan');

        v_filt=ceil(min(v_filt_m,size(temp_pow,1))/max(diff(range_t),[],1,'omitnan'));

        h_filt=ceil(min(p.Results.h_filt,size(temp_pow,2)/20,'omitnan'));
        noise_thr=p.Results.NoiseThr;
        SNR_thr=p.Results.SNRThr;

        pow_filt=filter2_perso(ones(v_filt,h_filt),temp_pow);
        %reg_n_filt=filter2_perso(ones(v_filt,h_filt),reg_n);

        pow_filt(pow_filt==0|~(reg_n))=nan;
        [noise_db,~]=min(10*log10(pow_filt),[],1,'omitnan');

        pow_noise_db=bsxfun(@times,noise_db,ones(size(temp_pow,1),1));
        pow_noise_db(temp_pow<0)=nan;
        pow_noise_db(pow_noise_db>noise_thr)=noise_thr;

        pow_noise=10.^(pow_noise_db/10);
        %     pow_unoised=pow-pow_noise;
        %     pow_unoised(pow_unoised<=0)=nan;
        %
        [sv,~,~,~,~,~,~,~,~]=get_data_from_region(trans_obj,reg_temp,'field','sv','idx_beam',uib);
        [sp,~,~,~,~,~,~,~,~]=get_data_from_region(trans_obj,reg_temp,'field','sp','idx_beam',uib);

        sp=db2pow_perso(sp);
        sv=db2pow_perso(sv);

        [sp_noise,sv_noise]=convert_power(pow_noise,range_t,c,alpha(:,:,uib),t_eff(1,idx_ping,uib),t_nom(1,idx_ping,uib),double(ptx(1,idx_ping,uib)),lambda(:,1,uib),gain(uib),eq_beam_angle(uib),sacorr(uib),trans_obj.Config.TransceiverType);
        
        sp_noise=db2pow_perso(sp_noise);
        sv_noise=db2pow_perso(sv_noise);
        
        noise_avg(uib,idx_ping) = pow2db(mean(pow_noise,1));

        Sp_unoised_lin=sp-sp_noise;
        Sp_unoised_lin(Sp_unoised_lin<=0)=nan;
        Sp_unoised=10*log10(Sp_unoised_lin);


        Sv_unoised_lin=sv-sv_noise;
        Sv_unoised_lin(Sv_unoised_lin<=0)=nan;
        Sv_unoised=10*log10(Sv_unoised_lin);

        SNR=Sv_unoised-pow2db_perso(sv_noise);

        if p.Results.snr_filt
            bot_s = trans_obj.get_bottom_idx(idx_ping,uib);
            bot_reg = (idx_r>=bot_s&idx_r<bot_s*(1+tand(trans_obj.Config.BeamWidthAlongship(uib)/2)));
            SNR_tmp = SNR;
            SNR_tmp (bot_reg) = nan;
            SNR_tmp = filter2_perso(ones(v_filt,h_filt),SNR_tmp);
            SNR (~bot_reg) = SNR_tmp(~bot_reg);
            %SNR = filter2_perso(gausswin(v_filt,1)*gausswin(h_filt,1)',SNR);
        end

        %SNR_2=pow2db_perso(pow_unoised./pow_noise);
        %pow_unoised(SNR<SNR_thr)=0;
        %SNR_thr= 1.7;
        Sp_unoised(SNR<SNR_thr)=-999;
        Sv_unoised(SNR<SNR_thr)=-999;

        %pow_unoised(isnan(pow_unoised))=0;
        Sp_unoised(isnan(Sp_unoised))=-999;
        Sv_unoised(isnan(Sv_unoised))=-999;
        SNR(isnan(SNR))=-999;


        trans_obj.Data.replace_sub_data_v2(Sp_unoised,'spdenoised','idx_ping',idx_ping,'idx_beam',uib);
        trans_obj.Data.replace_sub_data_v2(Sv_unoised,'svdenoised','idx_ping',idx_ping,'idx_beam',uib);
        trans_obj.Data.replace_sub_data_v2(SNR,'snr','idx_ping',idx_ping,'idx_beam',uib);
        clear Sp_unoised Sv_unoised snr temp_pow;

        if ~isempty(p.Results.load_bar_comp)
            set(p.Results.load_bar_comp.progress_bar, 'Value',(ui-1)*nb_beams+uib);
        end
    end


end

if disp
    esp3_obj = getappdata(groot,'esp3_obj');
    noise_fig =  new_echo_figure(esp3_obj.main_figure,...
        'Name','noise_level',...
        'tag','noise_fig',...
        'Position',[0 0 800 400],...
        'UiFigureBool',true);

    uigl_ax = uigridlayout(noise_fig,[2 1]);
    noise_axes=uiaxes(uigl_ax,'Box','on','Nextplot','add');
    grid(noise_axes,'on');
    ylabel(noise_axes,'Noise level (dB)')
    noise_axes.XTickLabels={''};
    plot(noise_axes,noise_avg,'k');

    ax_speed=uiaxes(uigl_ax,'Box','on','Nextplot','add');
    grid(ax_speed,'on');
    ylabel(ax_speed,'Vessel speed (knots)');
    plot(ax_speed,trans_obj.GPSDataPing.Speed,'r');
    ylabel(noise_axes,'Ping number');
 
end

output_struct.done=true;
output_struct.noise_avg = noise_avg;

end



