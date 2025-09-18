function [n_eval,delta,alpha,phi_est]=est_phicross_mat(n,amp,phase,phi_fix)

[nb_samples,~]=size(n);
alpha=sum(amp.*(n-repmat(mean(n),nb_samples,1)).*(phase-repmat(mean(phase),nb_samples,1)))./sum(amp.*(n-repmat(mean(n),nb_samples,1)).^2);
beta=repmat(mean(phase),nb_samples,1)-repmat(alpha,nb_samples,1).*repmat(mean(n),nb_samples,1);

phi_est=repmat(alpha,nb_samples,1).*n+beta;
delta=sqrt(mean((phi_est-phase).^2));
n_eval=abs((phi_fix-beta)./repmat(alpha,nb_samples,1));