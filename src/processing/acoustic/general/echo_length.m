% length of the bottom echo along the axis (in m), given:
%   r_p: range of pulse (c*tau/2) (in m)
%   theta_b: beam aperture (in degrees)
%   beta: incident angle at bottom (combining seafloor slope and transducer tilt) (in degrees)
%   r: range of the start of the echo (bottom range) (in m)
%
% example use:
% r_p=1e-3*1500/2; theta_b=7; beta=0:0.1:5; r=100;
% figure();plot(beta,echo_length(r_p,theta_b,beta,r));grid on;
% xlabel('angle(deg.)');ylabel('Echo length (m)');

function el = echo_length(r_p,theta_b,beta,r)

el = nan(size(r_p));

beta = abs(beta);

idx_beta =  beta < theta_b/2;
% when incident angle is smaller than half aperture, the reflection
% starts within the footprint of the aperture on the seafloor, and so
% the echo starts here and finishes at the far edge of the aperture.

el(idx_beta) = r_p(idx_beta) + r(idx_beta).*( 1./cosd(beta(idx_beta)+theta_b/2) - 1);

idx_beta_2  = (beta >= theta_b/2) & (beta < (180/2 - theta_b/2));

% when incident angle is larger than half aperture, the bottom
% reflection starts outside of the footprint of the aperture on the
% seafloor, so that the echo starts at one edge of the aperture and
% finishes at the other edge.
el(idx_beta_2) = r_p(idx_beta_2) + r(idx_beta_2).*( cosd(beta(idx_beta_2)-theta_b/2)./cosd(beta(idx_beta_2)+theta_b/2) - 1);


end


