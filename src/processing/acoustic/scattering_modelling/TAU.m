function tau = TAU(~,~,~,~,T)

Tk = T+273;
% tau = 1e-3 * (75.64 - (Tk - 273.15) * 0.1445);  % surface tension of the air-sea interface (NOTE: NEED THIS FOR METHANE AND SEAWATER)
tau = 1e-3 * (30 - (Tk - 273.15) * 0.1445);  %METHANE


end

