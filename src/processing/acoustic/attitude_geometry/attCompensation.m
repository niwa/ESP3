function compensation = attCompensation(faBW, psBW, roll_t, pitch_t,roll_r,pitch_r)
% Calculates the simard beam compensation given the beam angles and
% positions in the beam

alpha=(faBW+psBW)/2/180*pi;

[phi_t, theta_t] = simradAnglesToSpherical(pitch_t, roll_t);

[phi_r, theta_r] = simradAnglesToSpherical(pitch_r, roll_r);


cosmu=sind(phi_t).*cosd(theta_t).*sind(phi_r).*cosd(theta_r) +...
    sind(phi_t).*sind(theta_t).*sind(phi_r).*sind(theta_r) + ...
    cosd(phi_t).*cosd(phi_t);

mu = abs(acos(cosmu)) ;

x=sin(mu)/sin(alpha/2);

k = 0.17083*x.^5 - 0.39660*x.^4 + 0.53851*x.^3 + 0.13764*x.^2 + 0.039645*x + 1;

compensation=10*log10(k);
end

