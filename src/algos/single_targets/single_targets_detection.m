function output_struct=single_targets_detection(trans_obj,varargin)
%SINGLE_TARGET_DETECTION
%profile on;
%Parse Arguments
p = inputParser;

check_trans_cl=@(obj)isa(obj,'transceiver_cl');
defaultTsThr=-50;
checkTsThr=@(thr)(thr>=-120&&thr<=0);
defaultPLDL=6;
checkPLDL=@(PLDL)(PLDL>=1&&PLDL<=30);
defaultMinNormPL=0.7;
defaultMaxNormPL=1.5;
checkNormPL=@(NormPL)(NormPL>=0.0&&NormPL<=10);
defaultMaxBeamComp=4;
checkBeamComp=@(BeamComp)(BeamComp>=0&&BeamComp<=100);
defaultMaxStdMinAxisAngle=0.6;
checkMaxStdMinAxisAngle=@(MaxStdMinAxisAngle)(MaxStdMinAxisAngle>=0&&MaxStdMinAxisAngle<=45);
defaultMaxStdMajAxisAngle=0.6;
checkMaxStdMajAxisAngle=@(MaxStdMajAxisAngle)(MaxStdMajAxisAngle>=0&&MaxStdMajAxisAngle<=45);

check_data_type=@(datatype) ischar(datatype)&&(sum(strcmp(datatype,{'CW','FM'}))==1);


addRequired(p,'trans_obj',check_trans_cl);
addParameter(p,'denoised',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'TS_threshold',defaultTsThr,checkTsThr);
addParameter(p,'TS_threshold_max',0,checkTsThr);
addParameter(p,'PLDL',defaultPLDL,checkPLDL);
addParameter(p,'MinNormPL',defaultMinNormPL,checkNormPL);
addParameter(p,'MaxNormPL',defaultMaxNormPL,checkNormPL);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'MaxBeamComp',defaultMaxBeamComp,checkBeamComp);
addParameter(p,'MaxStdMinAxisAngle',defaultMaxStdMinAxisAngle,checkMaxStdMinAxisAngle);
addParameter(p,'MaxStdMajAxisAngle',defaultMaxStdMajAxisAngle,checkMaxStdMajAxisAngle);
addParameter(p,'DataType',trans_obj.Mode,check_data_type);
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
addParameter(p,'r_max',Inf,@isnumeric);
addParameter(p,'r_min',0,@isnumeric);
addParameter(p,'load_bar_comp',[]);

parse(p,trans_obj,varargin{:});

output_struct.done =  false;

if isempty(p.Results.reg_obj)
    idx_r_tot=1:length(trans_obj.get_samples_range());
    idx_ping_tot=1:length(trans_obj.get_transceiver_pings());
    reg_obj=region_cl('Name','Temp','Idx_r',idx_r_tot,'Idx_ping',idx_ping_tot);
else
    reg_obj=p.Results.reg_obj;
end

idx_ping_tot=reg_obj.Idx_ping;
idx_r_tot=reg_obj.Idx_r;

range_tot = trans_obj.get_samples_range(idx_r_tot);

if ~isempty(idx_r_tot)
    idx_r_tot(range_tot<p.Results.r_min|range_tot>p.Results.r_max)=[];
end

if isempty(idx_r_tot)
    disp_perso([],'Nothing to detect single targets from...');
    output_struct.single_targets=init_st_struct(0);
    output_struct.done =  false;
    return;
end


if isempty(p.Results.reg_obj)
    reg_obj=region_cl('Idx_r',idx_r_tot,'Idx_ping',idx_ping_tot);
else
    reg_obj=p.Results.reg_obj;
end

up_bar=~isempty(p.Results.load_bar_comp);
Number_tot=trans_obj.get_transceiver_pings();
Range_tot=trans_obj.get_samples_range();
nb_samples_tot=length(Range_tot);
nb_pings_tot=length(Number_tot);

Idx_samples_lin_tot=reshape(1:nb_samples_tot*nb_pings_tot,nb_samples_tot,nb_pings_tot);

max_TS=p.Results.TS_threshold_max;
min_TS=p.Results.TS_threshold;

if max_TS<=min_TS
    dlg_perso([],'Invalid params','Invalid parameters for Single Target detection (TS thresholds)');
    return;
end

trans_obj.rm_tracks();
block_len = get_block_len(50,'cpu',p.Results.block_len);

block_size=min(ceil(block_len/numel(idx_r_tot)/2),numel(idx_ping_tot));

num_ite=ceil(numel(idx_ping_tot)/block_size);

if up_bar
    p.Results.load_bar_comp.progress_bar.setText('Single Target detection');
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
end

heading=trans_obj.AttitudeNavPing.Heading(:)';
pitch=trans_obj.AttitudeNavPing.Pitch(:)';
roll=trans_obj.AttitudeNavPing.Roll(:)';
heave=trans_obj.AttitudeNavPing.Heave(:)';
yaw=trans_obj.AttitudeNavPing.Yaw(:)';
dist=trans_obj.GPSDataPing.Dist(:)';

pitch(isnan(pitch))=0;

roll(isnan(roll))=0;

heave(isnan(heave))=0;

dist(isnan(dist))= 0;


if isempty(dist)
    dist=zeros(1,nb_pings_tot);
end

if isempty(heading)||all(isnan(heading))||all(heading==-999)
    heading=zeros(1,nb_pings_tot);
end

if isempty(roll)
    roll=zeros(1,nb_pings_tot);
    pitch=zeros(1,nb_pings_tot);
    heave=zeros(1,nb_pings_tot);
end

single_targets_tot=[];

if p.Results.denoised
    field='spdenoised';
else
    field = 'sp';
end

if ~ismember(field,trans_obj.Data.Fieldname)
    field='sp';
end

[BW_athwart,BW_along]=trans_obj.get_beamwidth_at_f_c([]);

for ui=1:num_ite
    idx_ping=idx_ping_tot((ui-1)*block_size+1:min(ui*block_size,numel(idx_ping_tot)));
    
    idx_r=idx_r_tot;
    
    reg_temp=region_cl('Name','Temp','Idx_r',idx_r,'Idx_ping',idx_ping);
    
    [Sp,idx_r,idx_ping,~,bad_data_mask,bad_trans_vec,inter_mask,below_bot_mask,~]=get_data_from_region(trans_obj,reg_temp,'field',field,...
        'intersect_only',1,...
        'regs',reg_obj);
    if isempty(Sp)
        continue;
    end
    
    power= trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'field','power');
    
    mask=bad_data_mask|below_bot_mask|~inter_mask;
    
    mask(:,bad_trans_vec)=1;
    
    
    idx_r=idx_r(:);
    idx_ping=idx_ping(:)';
    
    if isempty(Sp)
        dlg_perso([],'No TS','Cannot find single targets with no TS datagram...');
        output_struct.single_targets=[];
        return;
    end
    
    [nb_samples,nb_pings]=size(Sp);
    [T,N]=trans_obj.get_pulse_Teff(idx_ping);

    
    Idx_samples_lin=Idx_samples_lin_tot(idx_r,idx_ping);
    r=trans_obj.get_samples_range(idx_r);
    r_p=trans_obj.get_samples_range(max(N));
    Range=repmat(r,1,nb_pings);
    
    
    Sp(mask>=1)=-999;
    power(mask>=1)=0;
    
    if ~any(Sp(:)>-999)
        continue;
    end
    Range(mask)=nan;
    
    [~,idx_r_max]=min(abs(r-max(Range(Sp>-999))));
    
    [~,idx_r_min]=min(abs(r-min(Range(Sp>-999))));
    idx_r_min_p=find(r>r_p,1);
    if ~isempty(idx_r_min_p)
        idx_r_min=max(idx_r_min_p,idx_r_min);
    end
    
    %idx_r_min=1;
    idx_rem=[];
    
    if idx_r_max<nb_samples
        idx_rem=union(idx_rem,idx_r_max:nb_samples);
    end
    
    if idx_r_min>1
        idx_rem=union(idx_rem,1:idx_r_min);
    end
    
    %%%%%%%Remove all unnecessary data%%%%%%%%
    
    idx_r(idx_rem)=[];
    Sp(idx_rem,:)=[];
    power(idx_rem,:)=[];
    Idx_samples_lin(idx_rem,:)=[];
    
    [nb_samples,nb_pings]=size(Sp);
    along=trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'field','AlongAngle');
    athwart=trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'field','AcrossAngle');
    
    if isempty(along)||isempty(athwart)
        disp('Computing using single beam data');
        along=zeros(size(Sp));
        athwart=zeros(size(Sp));
    end
    
    Range=repmat(trans_obj.get_samples_range(idx_r),1,nb_pings);
    
    Samples=repmat(idx_r,1,nb_pings);
    Ping=repmat(trans_obj.get_transceiver_pings(idx_ping),nb_samples,1);
    Time=repmat(trans_obj.get_transceiver_time(idx_ping),nb_samples,1);
    
    N=repmat(N,nb_samples,1);
    Np=min(N(1),numel(idx_r)-2);
    T=T(1);
    
    Pulse_length_max_sample=max(ceil(N.*p.Results.MaxNormPL),3,'omitnan');
    Pulse_length_min_sample=max(floor(N.*p.Results.MinNormPL),3,'omitnan');
    
    %Calculate simradBeamCompensation
    simradBeamComp = simradBeamCompensation(BW_along, BW_athwart, along, athwart);
    
    %method_fp = 'lm';%'fp'
    method_fp = 'fp';
    peak_mat = Sp;
    
    peak_mat(peak_mat==-999)=nan;
    peak_mat(peak_mat<min_TS-p.Results.MaxBeamComp) = min_TS-p.Results.MaxBeamComp;
    
    switch  method_fp
        case 'lm'
            idx_peaks = islocalmax(peak_mat,1, 'FlatSelection','first',...
                'MinSeparation',Np,'MinProminence',p.Results.PLDL);
            
            idx_peaks_lin = find(idx_peaks);
            idx_peaks_lin = idx_peaks_lin-Np;
            idx_peaks_lin(Sp(idx_peaks_lin)<min_TS-p.Results.MaxBeamComp|Sp(idx_peaks_lin)>max_TS|idx_peaks_lin<0)=[];
            width_peaks = Np*ones(size(idx_peaks_lin));
            
        case 'fp'
            
            f_peak_func = @(x) findpeaks(x,...
                'MinPeakHeight',min_TS-p.Results.MaxBeamComp,...
                'WidthReference','halfprom',...
                'MinPeakDistance',Np);
            
            idx_peaks_lin = [];
            width_peaks = [];

            for uip = 1:size(peak_mat,2)
                if any(peak_mat>min_TS-p.Results.MaxBeamComp,'all')
                    [~,idx_peaks_lin_tmp,width_peaks_tmp ,~] = f_peak_func(peak_mat(:,uip));
                    idx_peaks_lin  =[idx_peaks_lin;idx_peaks_lin_tmp+(uip-1)*size(peak_mat,1)];
                    width_peaks = [width_peaks;width_peaks_tmp];
                end
            end
    end
    
    
    switch p.Results.DataType
        case 'CW'
            
            
            idx_peaks = islocalmax(peak_mat,1, 'FlatSelection','center',...
                'MinSeparation',Np,'MinProminence',p.Results.PLDL);
            idx_peaks_lin = find(idx_peaks);
            
            
            idx_peaks_lin(Sp(idx_peaks_lin)<min_TS-p.Results.MaxBeamComp|Sp(idx_peaks_lin)>max_TS)=[];
            
            %figure();imagesc(idx_peaks_2)
            %             A= peak_mat(:,2);
            %             TF = islocalmax(A);
            %             x = 1:numel(A);
            %             figure();
            %             plot(x,A,x(TF),A(TF),'r*')
            %
            
            %Level of the local maxima (power dB)...
            
            
            nb_peaks=length(idx_peaks_lin);
            pulse_level=peak_mat(idx_peaks_lin)-p.Results.PLDL;
            idx_samples_lin=Idx_samples_lin(idx_peaks_lin);
            pulse_env_after_lin=ones(nb_peaks,1);
            pulse_env_before_lin=ones(nb_peaks,1);
            idx_sup_after=ones(nb_peaks,1);
            idx_sup_before=ones(nb_peaks,1);
            max_pulse_length=max(Pulse_length_max_sample(:))+1;
            
            p_mat = repmat(1:size(Sp,2),nb_samples,1);
            for ii=2:max_pulse_length
                id_m = max(idx_peaks_lin -ii,1);
                id_p = min(idx_peaks_lin +ii,numel(peak_mat));
                
                idx_sup_before=idx_sup_before.*(pulse_level<=peak_mat(id_m)&p_mat(id_m) == p_mat(idx_peaks_lin));
                idx_sup_after=idx_sup_after.*(pulse_level<=peak_mat(id_p)&p_mat(id_p) == p_mat(idx_peaks_lin));
                pulse_env_before_lin=pulse_env_before_lin+idx_sup_before;
                pulse_env_after_lin=pulse_env_after_lin+idx_sup_after;
            end
            
            temp_N = N(idx_peaks_lin);
            
            pulse_length_lin = pulse_env_before_lin+pulse_env_after_lin+1;
            
            idx_good_pulses = (pulse_length_lin<=Pulse_length_max_sample(idx_peaks_lin))&(pulse_length_lin>=Pulse_length_min_sample(idx_peaks_lin));
            
            idx_target_lin = idx_peaks_lin(idx_good_pulses);
            idx_samples_lin = idx_samples_lin(idx_good_pulses);
            
            pulse_length_trans_lin = temp_N;
            
            pulse_env_before_lin=pulse_env_before_lin(idx_good_pulses);
            pulse_env_after_lin=pulse_env_after_lin(idx_good_pulses);
            
            nb_targets=length(idx_target_lin);
            temp_N = temp_N(idx_good_pulses);

            max_pulse_length = max(pulse_length_lin,[],1,'omitnan');
            
            samples_targets_sp=nan(max_pulse_length,nb_targets);
            samples_targets_power=nan(max_pulse_length,nb_targets);
            samples_targets_comp=nan(max_pulse_length,nb_targets);
            samples_targets_range=nan(max_pulse_length,nb_targets);
            samples_targets_sample=nan(max_pulse_length,nb_targets);
            samples_targets_along=nan(max_pulse_length,nb_targets);
            samples_targets_athwart=nan(max_pulse_length,nb_targets);
            samples_pulse_length_trans_samples=nan(max_pulse_length,nb_targets);
            samples_pulse_length_samples=nan(max_pulse_length,nb_targets);
            target_ping_number=nan(1,nb_targets);
            target_time=nan(1,nb_targets);
            
            if up_bar
                set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_targets, 'Value',0);
            end
            
            for itt=1:nb_targets
                if up_bar
                    set(p.Results.load_bar_comp.progress_bar,'Value',itt);
                end

                %idx_pulse=idx_target_lin(itt)-floor(Np/2):idx_target_lin(itt)+floor(Np/2)+rem(Np,2)-1;
                idx_pulse = idx_target_lin(itt)-pulse_env_before_lin(itt):idx_target_lin(itt)+pulse_env_after_lin(itt);
%               idx_pulse = union(idx_pulse,idx_pulse_min);
                idx_pulse(idx_pulse<=0)=[];
                idx_pulse(idx_pulse>numel(Sp))=[];
                
                samples_targets_sp(1:numel(idx_pulse),itt)=Sp(idx_pulse);
                samples_targets_power(1:numel(idx_pulse),itt)=power(idx_pulse);
                samples_targets_comp(1:numel(idx_pulse),itt)=simradBeamComp(idx_pulse);
                samples_targets_range(1:numel(idx_pulse),itt)=Range(idx_pulse);
                samples_targets_sample(1:numel(idx_pulse),itt)=Samples(idx_pulse);
                samples_targets_along(1:numel(idx_pulse),itt)=along(idx_pulse);
                samples_targets_athwart(1:numel(idx_pulse),itt)=athwart(idx_pulse);
                samples_pulse_length_trans_samples(1:numel(idx_pulse),itt)=pulse_length_trans_lin(itt);
                samples_pulse_length_samples(1:numel(idx_pulse),itt)=numel(idx_pulse);
                target_ping_number(itt)=Ping(idx_target_lin(itt));
                target_time(itt)=Time(idx_target_lin(itt));
            end
            
            samples_targets_idx_r=round(sum(samples_targets_power.*samples_targets_sample,'omitnan')./sum(samples_targets_power,'omitnan'));
            
            idx_wav_power = samples_targets_idx_r - min(samples_targets_sample)+1;
            
            [max_pow,~] = max(samples_targets_power);
            
            [~,idx_max] = max(samples_targets_sp);
            
            idx_wav_power(idx_wav_power==1)=nan;
            idx_max(idx_max==1) = nan;
            pow_cumsum = cumsum(samples_targets_power,'omitnan')./sum(samples_targets_power,'omitnan')*100;
            
            [~,idx_ts] = max(diff(samples_targets_sp)<=0.2&pow_cumsum(1:end-1,:)>max(20,100./sum(~isnan(samples_targets_power))));
            idx_ts(idx_ts==1) = nan;
            
            [~,idx_ts_2] = max(diff(diff(samples_targets_sp))>=-0.05);
            idx_ts_2(idx_ts_2==1) = nan;
            
            [~,idx_cumsum] = max(pow_cumsum>max(20,100./sum(~isnan(samples_targets_power))));
            idx_cumsum(idx_cumsum==1) = nan;
            
            idx_final = min(idx_ts,idx_wav_power);
            idx_final(temp_N < 10) = idx_max(temp_N < 10);
            
            idx_final(idx_max<idx_wav_power/2|idx_max<idx_final) = idx_max(idx_max<idx_wav_power/2|idx_max<idx_final);
            
            idx_final(isnan(idx_final))  = mode(idx_final);

            disp_meth = false;
            
            if disp_meth
                
                new_echo_figure([]);
                plot(idx_max);hold on;
                plot(idx_ts,'-x');
                plot(idx_ts_2,'-o');
                plot(idx_wav_power);
                plot(idx_cumsum);
                plot(idx_final,'r','linewidth',2);
                legend('Max','Rising','Inflex','Wav','20% Cum. sum','Final');
                
                 idx_ts(isnan(idx_ts)) = 0;
                 idx_ts_2(isnan(idx_ts_2)) = 0;
                 idx_wav_power(isnan(idx_wav_power)) = 0;
                 idx_max(isnan(idx_max)) = 0;
                 idx_cumsum(isnan(idx_cumsum)) = 0;
                
                ipings = 1:min(5,numel(idx_cumsum));
                
                for iping = ipings
                    
                    data = samples_targets_sp(:,iping);
                    figure('Name',num2str(iping));
                    nexttile;plot(data);hold on;xline(idx_max(iping),'b');xline(idx_wav_power(iping),'k');xline(idx_ts(iping),'g');xline(idx_ts_2(iping),'y');xline(idx_final(iping),'r');ylabel('S_p')
                    nexttile;plot(diff(data));hold on;xline(idx_max(iping),'b');xline(idx_wav_power(iping),'k');xline(idx_ts(iping),'g');xline(idx_ts_2(iping),'y');xline(idx_final(iping),'r');ylabel('d^2S_p/dt^2')
                    nexttile;plot(diff(diff(data)));hold on;xline(idx_max(iping),'b');xline(idx_wav_power(iping),'k');xline(idx_ts(iping),'g');xline(idx_ts_2(iping),'y');xline(idx_final(iping),'r');ylabel('$\hat{S_p}$','Interpreter','latex')
                    nexttile;plot(pow_cumsum(:,iping));hold on;xline(idx_max(iping),'b');xline(idx_wav_power(iping),'k');xline(idx_ts(iping),'g');xline(idx_ts_2(iping),'y');xline(idx_final(iping),'r');ylabel('$\sum{S_p}$','Interpreter','latex')
                end
            end
            
            power_norm= sum(samples_targets_power)./max_pow;
            
            std_along=nanstd(samples_targets_along);
            std_athwart=nanstd(samples_targets_athwart);
            
            idx_rem=std_along>p.Results.MaxStdMinAxisAngle|std_athwart>p.Results.MaxStdMajAxisAngle;
            
            samples_targets_sp(:,idx_rem)=nan;
            
            samples_targets_range(:,idx_rem)=nan;
            
            target_range=samples_targets_range(idx_final+(0:nb_targets-1)*max_pulse_length);
            
            target_range_min=min(samples_targets_range);
            target_range_max=max(samples_targets_range);
            
            target_comp=samples_targets_comp(idx_final+(0:nb_targets-1)*max_pulse_length);
            target_TS_uncomp=samples_targets_sp(idx_final+(0:nb_targets-1)*max_pulse_length);
            
            phi_along=samples_targets_along(idx_final+(0:nb_targets-1)*max_pulse_length);
            phi_athwart=samples_targets_athwart(idx_final+(0:nb_targets-1)*max_pulse_length);
            
            target_TS_comp=target_TS_uncomp+target_comp;
            target_TS_comp(target_TS_comp<min_TS|target_comp>p.Results.MaxBeamComp|target_TS_comp>max_TS)=nan;
            target_TS_uncomp(target_TS_comp<min_TS|target_comp>p.Results.MaxBeamComp|target_TS_comp>max_TS)=nan;
            
            %removing all non-valid_targets again...
            idx_keep= ~isnan(target_TS_comp);
            %pulse_length_lin=pulse_length_lin(idx_keep);
            pulse_length_trans_lin=pulse_length_trans_lin(idx_keep);
            target_TS_comp=target_TS_comp(idx_keep);
            target_TS_uncomp=target_TS_uncomp(idx_keep);
            target_range=target_range(idx_keep);
            target_range_min=target_range_min(idx_keep);
            target_range_max=target_range_max(idx_keep);
            target_idx_r=samples_targets_idx_r(idx_keep);
            std_along=std_along(idx_keep);
            std_athwart=std_athwart(idx_keep);
            phi_along=phi_along(idx_keep);
            phi_athwart=phi_athwart(idx_keep);
            target_ping_number=target_ping_number(idx_keep);
            target_time=target_time(idx_keep);
            nb_valid_targets=sum(idx_keep);
            idx_target_lin=idx_target_lin(idx_keep);
            idx_samples_lin=idx_samples_lin(idx_keep);
            pulse_env_before_lin=pulse_env_before_lin(idx_keep);
            pulse_env_after_lin=pulse_env_after_lin(idx_keep);
            
            %let's remove overlapping targets just in case...
            idx_target=zeros(nb_samples,nb_pings);
            if up_bar
                set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_valid_targets, 'Value',0);
            end
            
            for itt=1:nb_valid_targets
                
                if up_bar
                    set(p.Results.load_bar_comp.progress_bar,'Value',itt);
                end
                
                idx_same_ping=find(target_ping_number==target_ping_number(itt));
                
                same_target=find((target_range_max(idx_same_ping)==target_range_max(itt)&(target_range_min(itt)==target_range_min(idx_same_ping))));
                
                if  length(same_target)>=2
                    target_TS_comp(idx_same_ping(same_target(2:end)))=nan;
                    target_range_max(idx_same_ping(same_target(2:end)))=nan;
                    target_range_min(idx_same_ping(same_target(2:end)))=nan;
                end
                
                overlapping_target=(target_range(idx_same_ping)<=target_range_max(itt)&(target_range_min(itt)<=target_range(idx_same_ping)))|...
                    (target_range_max(idx_same_ping)<=target_range_max(itt)&(target_range_min(itt)<=target_range_max(idx_same_ping)))|...
                    (target_range_min(idx_same_ping)<=target_range_max(itt)&(target_range_min(itt)<=target_range_min(idx_same_ping)));
                
                idx_target(idx_target_lin(itt)-pulse_env_before_lin(itt):idx_target_lin(itt)+pulse_env_after_lin(itt))=1;
                
                if sum(overlapping_target)>=2
                    idx_overlap=target_TS_comp(idx_same_ping(overlapping_target))<max(target_TS_comp(idx_same_ping(overlapping_target)),[],'all','omitnan');
                    target_TS_comp(idx_same_ping(idx_overlap))=nan;
                    target_range_max(idx_same_ping(idx_overlap))=nan;
                    target_range_min(idx_same_ping(idx_overlap))=nan;
                end
            end
            
            
            
            
            %removing all non-valid_targets again an storing results in single target
            %structure...
            idx_keep_final= ~isnan(target_TS_comp);
            single_targets  = init_st_struct(sum(idx_keep_final));
            single_targets.Power_norm=power_norm(idx_keep_final);
            single_targets.TS_comp=target_TS_comp(idx_keep_final);
            single_targets.TS_uncomp=target_TS_uncomp(idx_keep_final);
            single_targets.Target_range=target_range(idx_keep_final);
            single_targets.idx_r=target_idx_r(idx_keep_final);
            single_targets.Target_range_min=target_range_min(idx_keep_final);
            single_targets.Target_range_max=target_range_max(idx_keep_final);
            single_targets.StandDev_Angles_Minor_Axis=std_along(idx_keep_final);
            single_targets.StandDev_Angles_Major_Axis=std_athwart(idx_keep_final);
            single_targets.Angle_minor_axis=phi_along(idx_keep_final);
            single_targets.Angle_major_axis=phi_athwart(idx_keep_final);
            single_targets.Ping_number=target_ping_number(idx_keep_final);
            single_targets.Time=target_time(idx_keep_final);
            
            idx_target_lin=idx_target_lin(idx_keep_final)';
            single_targets.idx_target_lin=idx_samples_lin(idx_keep_final)';
            single_targets.pulse_env_before_lin=pulse_env_before_lin(idx_keep_final)';
            single_targets.pulse_env_after_lin=pulse_env_after_lin(idx_keep_final)';
            single_targets.TargetLength = (pulse_env_after_lin(idx_keep_final)'+pulse_env_before_lin(idx_keep_final)'+1);
            single_targets.PulseLength_Normalized_PLDL=(pulse_env_after_lin(idx_keep_final)'+pulse_env_before_lin(idx_keep_final)'+1)./pulse_length_trans_lin(idx_keep_final)';
            single_targets.Transmitted_pulse_length=T*ones(size(single_targets.PulseLength_Normalized_PLDL));
            
            
            heading_mat=repmat(heading(idx_ping),nb_samples,1);
            roll_mat=repmat(roll(idx_ping),nb_samples,1);
            pitch_mat=repmat(pitch(idx_ping),nb_samples,1);
            heave_mat=repmat(heave(idx_ping),nb_samples,1);
            dist_mat=repmat(dist(idx_ping),nb_samples,1);
            yaw_mat=repmat(yaw(idx_ping),nb_samples,1);
            
            single_targets.Dist=dist_mat(idx_target_lin);
            single_targets.Roll=roll_mat(idx_target_lin);
            single_targets.Pitch=pitch_mat(idx_target_lin);
            single_targets.Yaw=yaw_mat(idx_target_lin);
            single_targets.Heave=heave_mat(idx_target_lin);
            single_targets.Heading=heading_mat(idx_target_lin);
            single_targets.Track_ID=nan(size(single_targets.Heading));
            
            
            
        case 'FM'
            
            
            
            dt=trans_obj.get_params_value('SampleInterval',idx_ping(1));
            dr=dt*mean(trans_obj.get_soundspeed(idx_r))/2;
            
            [~,Neff]=trans_obj.get_pulse_comp_Teff(idx_ping(1));
            [T,~]=trans_obj.get_pulse_length(idx_ping(1));
            
            
            width_peaks = (Neff+1)*ones(size(idx_peaks_lin));
            
            
            %figure();plot(peak_mat(:));hold on;plot(idx_peaks_lin,peak_vals,'+');xlim([1 1e4])
            %             peak_mat(peak_mat<-80)=-80;
            %             figure();findpeaks(peak_mat(:,1),1:numel(peak_mat(:,1)),...
            %                 'WidthReference','halfprom',...
            %                 'Annotate','extents');
            

           
            nb_targets = numel(idx_peaks_lin);
            max_pulse_length = 2*max(width_peaks);
            
%             samples_targets_sp=nan(max_pulse_length,nb_targets);
%             samples_targets_power=nan(max_pulse_length,nb_targets);
            samples_targets_comp=nan(max_pulse_length,nb_targets);
%             samples_targets_range=nan(max_pulse_length,nb_targets);
%             samples_targets_sample=nan(max_pulse_length,nb_targets);
            samples_targets_along=nan(max_pulse_length,nb_targets);
            samples_targets_athwart=nan(max_pulse_length,nb_targets);

            
            if up_bar
                set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_targets, 'Value',0);
            end
            
            for itt=1:nb_targets
                if up_bar
                    set(p.Results.load_bar_comp.progress_bar,'Value',itt);
                end
                idx_pulse=idx_peaks_lin(itt)-width_peaks(itt):idx_peaks_lin(itt)+width_peaks(itt);

                idx_pulse(idx_pulse<=0)=[];
                idx_pulse(idx_pulse>numel(Sp))=[];
                
%                 samples_targets_sp(1:numel(idx_pulse),itt)=Sp(idx_pulse);
%                 samples_targets_power(1:numel(idx_pulse),itt)=power(idx_pulse);
                samples_targets_comp(1:numel(idx_pulse),itt)=simradBeamComp(idx_pulse);
%                 samples_targets_range(1:numel(idx_pulse),itt)=Range(idx_pulse);
%                 samples_targets_sample(1:numel(idx_pulse),itt)=Samples(idx_pulse);
                samples_targets_along(1:numel(idx_pulse),itt)=along(idx_pulse);
                samples_targets_athwart(1:numel(idx_pulse),itt)=athwart(idx_pulse);
            end
            
            comp=simradBeamComp(idx_peaks_lin);
            std_along = nanstd(samples_targets_along,0,1);
            std_athwart = nanstd(samples_targets_athwart,0,1);
            
            idx_rem=comp(:)'>p.Results.MaxBeamComp|std_along>p.Results.MaxStdMinAxisAngle|std_athwart>p.Results.MaxStdMajAxisAngle|...
                Sp(idx_peaks_lin)'+comp(:)'<min_TS|...
                Sp(idx_peaks_lin)'+comp(:)'>max_TS;
            
            idx_peaks_lin(idx_rem)=[];
            width_peaks(idx_rem)=[];
            
            
            idx_samples=rem(idx_peaks_lin,size(peak_mat,1));
            idx_samples(idx_samples==0)=nb_samples;
            
            idx_samples_lin=Idx_samples_lin(idx_peaks_lin);
            
            
            idx_ping=Ping(idx_peaks_lin);
            single_targets  = init_st_struct(numel(idx_peaks_lin));
            single_targets.TS_comp=Sp(idx_peaks_lin)'+simradBeamComp(idx_peaks_lin)';
            single_targets.TS_uncomp=Sp(idx_peaks_lin)';
            single_targets.Target_range=Range(idx_peaks_lin)';
            single_targets.idx_r= (idx_r_tot(idx_samples)+idx_r_min-1)';
            single_targets.Target_range_min=Range(idx_peaks_lin)'-width_peaks'/2*dr;
            single_targets.Target_range_max=Range(idx_peaks_lin)'-width_peaks'/2*dr;
            single_targets.StandDev_Angles_Minor_Axis=zeros(size(idx_peaks_lin))';
            single_targets.StandDev_Angles_Major_Axis=zeros(size(idx_peaks_lin))';
            single_targets.Angle_minor_axis=along(idx_peaks_lin)';
            single_targets.Angle_major_axis=athwart(idx_peaks_lin)';
            single_targets.Ping_number=idx_ping';
            single_targets.Time=Time(idx_peaks_lin)';
            
            single_targets.idx_target_lin=idx_samples_lin;
            single_targets.pulse_env_before_lin=width_peaks'/2*dt;
            single_targets.pulse_env_after_lin=width_peaks'/2*dt;
            single_targets.Transmitted_pulse_length=T*ones(size(idx_peaks_lin'));
            
            single_targets.PulseLength_Normalized_PLDL=width_peaks';
            single_targets.TargetLength=width_peaks';
            single_targets.Power_norm=zeros(size(single_targets.TargetLength));
            single_targets.Dist=dist(single_targets.Ping_number);
            single_targets.Roll=roll(single_targets.Ping_number);
            single_targets.Pitch=pitch(single_targets.Ping_number);
            single_targets.Yaw=yaw(single_targets.Ping_number);
            single_targets.Heave=heave(single_targets.Ping_number);
            single_targets.Heading=heading(single_targets.Ping_number);
            single_targets.Track_ID=nan(size(idx_peaks_lin))';
            
            
    end
    
    if ~isempty(single_targets.Ping_number)
        bot_range = trans_obj.get_bottom_range(single_targets.Ping_number);
        single_targets.Target_range_to_bottom = bot_range-single_targets.Target_range;
        single_targets.Target_depth = single_targets.Target_range+trans_obj.get_transducer_depth(single_targets.Ping_number);
    end
    
    fields_st=fieldnames(single_targets);
    for ifi=1:numel(fields_st)
        single_targets.(fields_st{ifi})=single_targets.(fields_st{ifi})(:)';
    end
    
    if ui>1&&~isempty(single_targets_tot)
        
        for ifi=1:numel(fields_st)
            single_targets_tot.(fields_st{ifi})=cat(2,single_targets_tot.(fields_st{ifi}),single_targets.(fields_st{ifi}));
        end
    else
        fields_st=fieldnames(single_targets);
        for ifi=1:numel(fields_st)
            single_targets_tot.(fields_st{ifi})= single_targets.(fields_st{ifi});
        end
    end
    if up_bar
        set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',ui);
    end
    
end


output_struct.single_targets=single_targets_tot;

if ~isempty(output_struct.single_targets)
    previous_targets = trans_obj.ST;
    idx_st_rem = ismember(previous_targets.idx_r,idx_r_tot) & ismember(previous_targets.Ping_number,idx_ping_tot);
    ffst = fieldnames(previous_targets);

    for uif  =1:numel(ffst)
        previous_targets.(ffst{uif})(idx_st_rem) = [];
        output_struct.single_targets.(ffst{uif}) = [output_struct.single_targets.(ffst{uif}) previous_targets.(ffst{uif})];
    end
    
    trans_obj.set_ST(output_struct.single_targets);
end

output_struct.done =  true;

