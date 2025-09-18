function [ Pb,rho_seawater ] = INTbubPRESSURE( y,T,S,a,tau )
R = 8.3145;           % universal gas law constant J/(mol K)
Tk = T + 273.15;        % temperature in degrees Kelvin

Pa = 1.01325e5;         % atmospheric pressure
g = 9.81;
Ph = 1.01325e5*(1+0.1*(y));     % hydrostatic pressure (see White, Fluid Mechanics)
rho_seawater= 1027 - 0.15*(T-10) + 0.78*(S-35) + 4.5e-3*1e-4*Ph;  % density in kg/m^3 (see Knauss, Introduction to Physical Oceanography)
Pb = Pa + rho_seawater*g.*(y) + 2*tau./a;        % internal bubble pressure

end

