function [Sp,Sv]=convert_power(power,range,c,alpha,t_eff,t_nom,ptx,lambda,gain,eq_beam_angle,sacorr,type)

if isscalar(unique(t_nom(:)))
   t_nom  =t_nom(1);
end

[dr_sp,dr_sv]=compute_dr_corr(type,t_nom,c);
    
[TVG_Sp,TVG_Sv,range_sp,range_sv]=computeTVG(range,dr_sp,dr_sv);

tmp=10*log10(single(power))-2*gain-10*log10(ptx.*lambda.^2/(16*pi^2));

if numel(unique(alpha(:)))>1
    Sp=tmp+TVG_Sp+2*cumsum(alpha.*[zeros(1,size(range_sp,2),size(range_sp,3));diff(range_sp,1)],1,'omitnan');
    Sv=tmp-10*log10(c.*t_eff/2)-eq_beam_angle-2*sacorr+TVG_Sv+2*cumsum(alpha.*[zeros(1,size(range_sv,2),size(range_sv,3)); diff(range_sv,1)],1,'omitnan');
else
    alpha=(unique(alpha(:)));
    Sp=tmp+TVG_Sp+2*alpha.*range_sp;
    Sv=tmp-10*log10(c.*t_eff/2)-eq_beam_angle-2*sacorr+TVG_Sv+2*alpha.*range_sv;
end

end

        
        