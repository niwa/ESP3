function [Cp,Cv,Mbub,Kg] = get_gas_constants(gas_list,gas_frac,N,Tk)

N_Total = sum(gas_frac);      % total number of moles

% constant pressure specific heat:
Gas_Cp.O2 = 0.919;           % Cp (kJ/(kg K)
Gas_Cp.N2 = 1.04;
Gas_Cp.CH4 = 2.22;
Gas_Cp.CO2 = 0.844;
Gas_Cp.Ar = 0.520;

% constant-volume specific heat:
Gas_Cv.O2 = 0.659;           % Cv (kJ/(kg K)
Gas_Cv.N2 = 0.743;
Gas_Cv.CH4 = 1.70;
Gas_Cv.CO2 = 0.655;
Gas_Cv.Ar = 0.312;

% molar masses
Gas_M.O2 = 31.99880/1000;    % molar mass of O2 (kg/mole)
Gas_M.N2 = 28.01340/1000;    % molar mass of N2 (kg/mole)
Gas_M.CH4 = 16.04246/1000;   % molar mass of methane
Gas_M.CO2 = 44.0095/1000;    % molar mass of CO2
Gas_M.Ar = 39.948/1000;


Gas_X.O2 = 0;
Gas_X.N2 = 0;
Gas_X.CH4 = 0;
Gas_X.CO2 = 0;
Gas_X.Ar = 0;


Mbub=0;
Cp=0;
Cv=0;


for ii=1:numel(gas_list)
    Gas_X.(gas_list{ii}) = gas_frac(ii)/N_Total;
    Mbub=Mbub+N*Gas_M.(gas_list{ii})*Gas_X.(gas_list{ii});
    Cp=Cp+Gas_Cp.(gas_list{ii})*Gas_X.(gas_list{ii});
    Cv=Cv+Gas_Cv.(gas_list{ii})*Gas_X.(gas_list{ii});
end

Kg = lambda([Gas_X.N2 Gas_X.O2 Gas_X.CO2 0 0 0 0 Gas_X.CH4 0 0 0 0 0 Gas_X.Ar],Tk); % thermal conductivity of gas mixture
