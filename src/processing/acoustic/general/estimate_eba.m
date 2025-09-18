function eba = estimate_eba(bw_at,bw_al)
    eba = 10*log10(2.578*sind(bw_at/4+bw_al/4).^2);
end