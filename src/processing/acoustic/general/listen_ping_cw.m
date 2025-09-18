function listen_ping_cw(sig_carrier,f_c,f_s,fs_fact)

new_f_s = fs_fact*max(f_s);

nb_trans = numel(sig_carrier);

nb_samples = cellfun(@numel,sig_carrier);

t_max = max(nb_samples/f_s);
sig = zeros(1,ceil(t_max*new_f_s)+1);
interp_sig_carrier = cell(1,nb_trans);

for idx_freq = 1 : nb_trans
    t = linspace(0,numel(sig_carrier{idx_freq})/f_s(idx_freq),numel(sig_carrier{idx_freq}));
    if isempty(t)
        continue;
    end
    F = griddedInterpolant(t,db2pow(sig_carrier{idx_freq}),"pchip");

    t_new = t(1):1/new_f_s:t(end);

    interp_sig_carrier{idx_freq} = F(t_new).* exp(1i*2*pi*f_c(idx_freq)*t_new);

    sig(1:numel(t_new)) = sig(1:numel(t_new)) + (interp_sig_carrier{idx_freq});
end

soundsc(real(sig),max(f_s));

% figure();
% plot(real(sig));hold on;
% cellfun(@(x) plot(real(x)),interp_sig_carrier);


end