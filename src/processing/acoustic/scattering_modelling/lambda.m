function [out] = lambda(X,T)
%
%% Description
%
% Function for thermal conductivity calculation
% of gas with composition X and temperature T.
%
% lambda = (a.10^(-3) + b.10^(-4).T + c.10^(-8).T^2 + d.10^(-11).T^3).X
%
%% Inputs
%
% X - vector of volume fractions for next componemt of gas mixture:
%   X(1)  - volume fraction of N2                              [m^3.m^-3]
%   X(2)  - volume fraction of O2                              [m^3.m^-3]
%   X(3)  - volume fraction of CO2                             [m^3.m^-3]
%   X(4)  - volume fraction of H2O                             [m^3.m^-3]
%   X(5)  - volume fraction of SO2                             [m^3.m^-3]
%   X(6)  - volume fraction of CO                              [m^3.m^-3]
%   X(7)  - volume fraction of H2                              [m^3.m^-3]
%   X(8)  - volume fraction of CH4                             [m^3.m^-3]
%   X(9)  - volume fraction of C2H4                            [m^3.m^-3]
%   X(10) - volume fraction of C2H6                            [m^3.m^-3]
%   X(11) - volume fraction of C3H8                            [m^3.m^-3]
%   X(12) - volume fraction of C4H10                           [m^3.m^-3]
%   X(13) - volume fraction of H2S                             [m^3.m^-3]
%
% T - Temperature of mixture                                   [K]
%
%% Used coeficients and functions
%
% a, b, c, d - parameters for thermal conductivity calculation
%
%% Output
%
% lambda - thermal conductivity of gas mixture                [W.m^-1.K^-1]
%          defined for temperature T =<273,15;2500>.
%
%% Copyright (C) 2011
% Authors     : Kukurugya Jan, Terpak Jan
% Organization: Technical University of Kosice
% e-mail      : jan.kukurugya@tuke.sk, jan.terpak@tuke.sk
% Revision    : 28.12.2011
%
%   1      2        3        4       5       6       7     8        9        10       11       12       13
%   N2     O2       CO2      H2O     SO2     CO      H2    CH4      C2H4     C2H6     C3H8     C4H10    H2S
%a=[0.3918 -0.32720 -7.21390 17.5000 -8.0847 0.50660 168.0 -1.86860 -17.6013 -31.6103 1.858000 1.858000 17.5];
%b=[0.9814 0.996500 0.801400 0.65864 0.63430 0.91230 5.680 0.872500 1.199500 2.201400 0.047000 0.047000 0.65864];
%c=[-5.066 -3.74260 0.547600 -3.4412 -1.3816 -3.5236 2.354 11.78570 3.333900 -19.2300 21.76300 21.76300 -3.4412];
%d=[1.5034 0.973012 -1.05256 100.910 0.23027 0.83560 0.000 -3.61362 -1.36573 16.63834 -8.40709 -8.40709 100.91];
a=[0.3918 -0.32720 -7.21390 17.5000 -8.0847 0.50660 168.0 -1.86860 -17.6013 -31.6103 1.858000 1.858000 17.5];
b=[0.9814 0.996500 0.801400 0.65864 0.63430 0.91230 5.680 0.872500 1.199500 2.201400 0.047000 0.047000 0.65864];
c=[-5.066 -3.74260 0.547600 -3.4412 -1.3816 -3.5236 2.354 11.78570 3.333900 -19.2300 21.76300 21.76300 -3.4412];
d=[1.5034 0.973012 -1.05256 100.910 0.23027 0.83560 0.000 -3.61362 -1.36573 16.63834 -8.40709 -8.40709 100.91];

%   if T < TK
%     T=TK;
%   end
%   if T > 2500
%     T=2500;
%   end
%% EFW: Added constant for Argon thermal conductivity based on KMR
la = zeros(1,14);
for ig=1:1:14
    if ig<14
        la(ig)=(a(ig)*10^(-3) + b(ig)*10^(-4)*T + c(ig)*10^(-8)*T^2 + d(ig)*10^(-11)*T^3)*X(ig);
    else
        if numel(X)>13
            la(ig)=0.016*X(ig);
        end
    end
end
out=sum(la);
end