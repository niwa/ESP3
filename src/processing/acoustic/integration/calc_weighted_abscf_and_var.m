function [abscf_wmean,abscf_var]=calc_weighted_abscf_and_var(trans_abscf,dist)
abscf_wmean= sum(dist.*trans_abscf)/ sum(dist);
nb_trans=length(trans_abscf);

if nb_trans>1
    abscf_var = (sum(dist.^2.*trans_abscf.^2,'omitnan')...
        -2*abscf_wmean*sum(dist.^2.*trans_abscf,'omitnan')+...
        abscf_wmean^2*sum(dist.^2,'omitnan'))*...
        nb_trans/((nb_trans-1)*sum(dist,'omitnan')^2); 
else
    abscf_var=0;
end

end