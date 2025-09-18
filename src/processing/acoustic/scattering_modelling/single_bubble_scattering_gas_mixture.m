function [sigmaBS,wo,Bo] = single_bubble_scattering_gas_mixture(a,varargin)

% calculates the target strength for a bubble comprised of oxygen, carbon
% dioxide, nitrogen, and methane


p = inputParser;

addRequired(p,'a',@isnumeric);

addParameter(p,'f',(1:200)*1e3,@isnumeric);%frequency
addParameter(p,'z',200,@isnumeric);%depth
addParameter(p,'tau',0.075,@isnumeric);
addParameter(p,'T',10,@isnumeric);
addParameter(p,'S',35,@isnumeric);
addParameter(p,'gas_list',{'O2' 'N2' 'CH4' 'CO2' 'Ar'});%
addParameter(p,'gas_frac',[20.95 78.09 0 0.04 0.93]);%[3.54 13.2 9.9 72.1 1.26]]
addParameter(p,'theta',0,@(x) x>=0);
addParameter(p,'e_fact',1,@(x) x>0);
addParameter(p,'Nb_bins',500,@(x) x>0);
addParameter(p,'rmin',1e-4,@(x) x>0);
addParameter(p,'rmax',500,@(x) x>0);
addParameter(p,'gamma',[],@isnumeric);
% ratio of specific heats

parse(p,a,varargin{:});

a(a<0) = 0;

f=p.Results.f;
z=p.Results.z;
tau=p.Results.tau;
T=p.Results.T;
S=p.Results.S;


%% definition of parameters

w = 2*pi*f;                                 % angular frequency
R = 8.3144598;                              % universal gas law constant J/(mol K)
Tk = T + 273.15;                            % temperature in kelvin


%% liquid parameters
[Pb,rhow] = INTbubPRESSURE(z,T,S,a,tau);   % density of seawater 

Pa = 1.01325e5 + rhow*9.81*z;

% pressure at bubble location
%c = sndspd(S,T,z,'chen');                   % sound speed
c = seawater_svel_un95(S,T,z);

%% compute bubble parameters

Vbub = 4/3*pi*a.^3;

N=Pb*Vbub/(R *Tk);

[Cp,Cv,Mbub,Kg] = get_gas_constants(p.Results.gas_list,p.Results.gas_frac,N,Tk);

if isempty(p.Results.gamma)
    gamma = Cp/Cv;
else
    gamma=p.Results.gamma;% ratio of specific heats
    Cp=gamma*Cv;
end

rhog = Mbub./Vbub;   % density of gas

mu = 10^-6 * (1793 - T * 39.55);

%% compute sigma bs

X = a.*sqrt(4*pi*f*rhog*Cp/Kg);

d_b = 3*(gamma-1)*(X.*(sinh(X)+sin(X))-2*(cosh(X)-cos(X)))./(X.^2.*(cosh(X)-cos(X))+3*(gamma-1)*X.*(sinh(X)-sin(X)));
b = 1./(1+d_b.^2).*(1 + (3*gamma-1).*(sinh(X)-sin(X))./(X.*(cosh(X)-cos(X)))).^(-1);

for ii = 1:length(d_b)
    if isnan(d_b(ii))
        d_b(ii) = 3*(gamma-1)/X(ii);
        b(ii) = 1./(1+d_b(ii).^2)./(1+(3*gamma-1)/X(ii));
    end
end

d = d_b.*b;
GAMMA = gamma*(b+1i*d);
Vo = 4/3*pi*a.^3;                                   % unperturbed bubble volume
SIGMAsquared = 4*pi*GAMMA.*Pa.*a./(rhow.*Vo);
wo = sqrt(real(SIGMAsquared));                      % natural frequency, Ainslie and Leighton equation 23

Bth = imag(SIGMAsquared)/2./w;
Bo = Bth + 2*mu/rhow./a.^2;
eps = w*a/c;

deltaAW = 2*Bo./w + wo.^2./w.^2.*eps;

e_fact = p.Results.e_fact;

L = a*(8*e_fact^2)^(1/3);

D = sinc(sin(deg2rad(p.Results.theta))*2*pi*w/c*L).^2;

sigmaBS = (a.^2./(((wo.^2./w.^2) - 1 - 2*Bo./w.*eps).^2 + deltaAW.^2)).*D;



