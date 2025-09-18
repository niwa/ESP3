function computeSpSv(trans_obj,env_data_obj,varargin)

p = inputParser;

addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addRequired(p,'env_data_obj',@(obj) isa(obj,'env_data_cl'));
addParameter(p,'cal_fm',[]);
addParameter(p,'load_bar_comp',[]);
addParameter(p,'FieldNames',{},@iscell);
addParameter(p,'Type','uncomp',@ischar);
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));

if ~isdeployed()
    tic;
    %profile on;
end

parse(p,trans_obj,env_data_obj,varargin{:});

[~,found_pow]=trans_obj.Data.find_field_idx('power');

if ~found_pow
    return;
end

[c,range_t_ori]=trans_obj.compute_soundspeed_and_range(env_data_obj);
trans_obj.set_transceiver_range(range_t_ori);
trans_obj.recompute_angles(c);

trans_obj.rm_ST();

trans_obj.set_absorption(env_data_obj);

alpha=trans_obj.get_absorption();

cal_cw=trans_obj.get_transceiver_cw_cal();

fprintf('Computing Sp and Sv values:\n');
trans_obj.disp_calibration_env_params(env_data_obj);

if ~isempty(p.Results.cal_fm)
    cal_fm = p.Results.cal_fm;
else
    if strcmpi(trans_obj.Mode,'FM')
        cal_fm = trans_obj.get_transceiver_fm_cal() ;
    else
       cal_fm=[]; 
    end
end

f_c=trans_obj.get_center_frequency([]);

if ~isempty(cal_fm)
    idx_not_nan = find(~isnan(cal_fm.Gain));
    [~,idx_f] = min(abs(f_c-cal_fm.Frequency(idx_not_nan)'),[],1,'omitnan');
    eq_beam_angle_c=cal_fm.eq_beam_angle(idx_not_nan(idx_f));
    G=cal_fm.Gain(idx_not_nan(idx_f));
else
    eq_beam_angle = shiftdim(trans_obj.Config.EquivalentBeamAngle,-1);
    f_nom = shiftdim(trans_obj.Config.Frequency,-1);
    G=shiftdim(cal_cw.G0,-1)+10*log10(f_c./f_nom);
    eq_beam_angle_c=eq_beam_angle-20*log10(f_c./f_nom);
end

ptx = trans_obj.get_params_value('TransmitPower');
[t_eff,~]=trans_obj.get_pulse_Teff();
[t_eff_comp,~]=trans_obj.get_pulse_comp_Teff();
[t_nom,~]=trans_obj.get_pulse_length();

sacorr = shiftdim(cal_cw.SACORRECT,-1);

pings=trans_obj.get_transceiver_pings();

nb_samples=numel(range_t_ori);
nb_pings=numel(pings);

%[gpu_comp,g]=get_gpu_comp_stat();
gpu_comp=0;

% if gpu_comp%use of gpuArray results in about 20% speed increase here
%     gpuDevice(1);
% end
block_len = get_block_len(50,'cpu',p.Results.block_len);
bsize=ceil(block_len/nb_samples);
u=0;

if ~isempty(p.Results.load_bar_comp)
    p.Results.load_bar_comp.progress_bar.set('Minimum',0,'Maximum',ceil(nb_pings/bsize),'Value',0);
end


while u<ceil(nb_pings/bsize)
    idx_ping=(u*bsize+1):min(((u+1)*bsize),nb_pings);
    u=u+1;
    
    pow=trans_obj.Data.get_subdatamat('idx_r',1:nb_samples,'idx_ping',idx_ping,'field','power');
    powunmatched=trans_obj.Data.get_subdatamat('idx_r',1:nb_samples,'idx_ping',idx_ping,'field','powerunmatched');
    
    if gpu_comp%use of gpuArray results in about 20% speed increase here
        if g.AvailableMemory/(8*4*5)<=bsize*nb_samples
            gpuDevice(1);
        end
        pow=gpuArray(pow);
        range_t=gpuArray(range_t_ori);
        powunmatched=gpuArray(powunmatched);
        ptx_idx_ping=gpuArray(ptx(idx_ping));
    else
        ptx_idx_ping=ptx(idx_ping);
        range_t=range_t_ori;
    end
   
    
    switch trans_obj.Mode
                
        case 'FM'
            sacorr = 0;
            [Sp,Sv]=convert_power(pow,range_t,c,alpha,t_eff_comp(idx_ping),t_nom(idx_ping),ptx_idx_ping,c./f_c(idx_ping),G(idx_ping),eq_beam_angle_c(idx_ping),sacorr,trans_obj.Config.TransceiverType);
            
            if any(strcmpi(p.Results.FieldNames,'sp'))||isempty(p.Results.FieldNames)&&~isempty(powunmatched)
                [Sp_un,Sv_un]=convert_power(powunmatched,range_t,c,alpha,t_eff(idx_ping),t_nom(idx_ping),ptx_idx_ping,c./f_c(idx_ping),G(idx_ping),eq_beam_angle_c(idx_ping),sacorr,trans_obj.Config.TransceiverType);
                
                if  isa(Sp_un,'gpuArray')
                    Sp_un=gather(Sp_un);
                    Sv_un=gather(Sv_un);
                end
                trans_obj.Data.replace_sub_data_v2(Sp_un,'spunmatched','idx_ping',idx_ping);
                trans_obj.Data.replace_sub_data_v2(Sv_un,'svunmatched','idx_ping',idx_ping);
            end
            
        case 'CW'
            
            switch trans_obj.Config.TransceiverType
                case [list_WBTs() 'FCV-38']
                    
                otherwise
                    t_eff=t_nom;
            end
            
            [Sp,Sv]=convert_power(pow,range_t,c,alpha,t_eff(idx_ping),t_nom(idx_ping),ptx_idx_ping,c./f_c(idx_ping),G(idx_ping),eq_beam_angle_c(idx_ping),sacorr,trans_obj.Config.TransceiverType);
            
    end
 
    if any(strcmpi(p.Results.FieldNames,'sv'))||isempty(p.Results.FieldNames)
        if isa(Sv,'gpuArray')
            Sv=gather(Sv);
        end
        trans_obj.Data.replace_sub_data_v2(Sv,'sv','idx_ping',idx_ping);
        clear Sv;
    end
    if any(strcmpi(p.Results.FieldNames,'sp'))||isempty(p.Results.FieldNames)
        if  isa(Sp,'gpuArray')
            Sp=gather(Sp);
        end
        trans_obj.Data.replace_sub_data_v2(Sp,'sp','idx_ping',idx_ping);
        clear Sp;
    end
    if ~isempty(p.Results.load_bar_comp)
        p.Results.load_bar_comp.progress_bar.set('Value',u);
    end
end
trans_obj.Data.remove_sub_data('svdenoised');
trans_obj.Data.remove_sub_data('spdenoised');

if ~isdeployed()
    t=toc;
    fprintf('Sp and Sv values computed in %.2f seconds\n',t);
    %    profile off
    %    profile viewer;
end

end