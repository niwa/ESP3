function rho = SW_Density(T,uT,S,uS)
    % SW_Density    Density of seawater
    %=========================================================================
    % USAGE:  rho = SW_Density(T,uT,S,uS)
    %
    % DESCRIPTION:
    %   Density of seawater at atmospheric pressure (0.1 MPa) using Eq. (8)
    %   given by [1] which best fit the data of [2] and [3]. The pure water
    %   density equation is a best fit to the data of [4]. 
    %   Values at temperature higher than the normal boiling temperature are
    %   calculated at the saturation pressure.
    %
    % INPUT:
    %   T  = temperature 
    %   uT = temperature unit
    %        'C'  : [degree Celsius] (ITS-90)
    %        'K'  : [Kelvin]
    %        'F'  : [degree Fahrenheit] 
    %        'R'  : [Rankine]
    %   S  = salinity
    %   uS = salinity unit
    %        'ppt': [g/kg]  (reference-composition salinity)
    %        'ppm': [mg/kg] (in parts per million)
    %        'w'  : [kg/kg] (mass fraction)
    %        '%'  : [kg/kg] (in parts per hundred)
    %   
    %   Note: T and S must have the same dimensions
    %
    % OUTPUT:
    %   rho = density [kg/m^3]
    %
    %   Note: rho will have the same dimensions as T and S
    %
    % VALIDITY: 0 < T < 180 C; 0 < S < 160 g/kg;
    % 
    % ACCURACY: 0.1%
    % 
    % REVISION HISTORY:
    %   2009-12-18: Mostafa H. Sharqawy (mhamed@mit.edu), MIT
    %               - Initial version
    %   2012-06-06: Karan H. Mistry (mistry@mit.edu), MIT
    %               - Allow T,S input in various units
    %               - Allow T,S to be matrices of any size
    %
    % DISCLAIMER:
    %   This software is provided "as is" without warranty of any kind.
    %   See the file sw_copy.m for conditions of use and license.
    % 
    % REFERENCES:
    %   [1] M. H. Sharqawy, J. H. Lienhard V, and S. M. Zubair, Desalination
    %       and Water Treatment, 16, 354-380, 2010. (http://web.mit.edu/seawater/)
    %   [2] Isdale, and Morris, Desalination, 10(4), 329, 1972.
    %   [3] Millero and Poisson, Deep-Sea Research, 28A (6), 625, 1981
    %   [4]	IAPWS release on the Thermodynamic properties of ordinary water substance, 1996. 
    %=========================================================================

    %% CHECK INPUT ARGUMENTS

    % CHECK THAT S&T HAVE SAME SHAPE
    if ~isequal(size(S),size(T))
        error('check_stp: S & T must have same dimensions');
    end

    % CONVERT TEMPERATURE INPUT TO °C
    switch lower(uT)
        case 'c'
        case 'k'
            T = T - 273.15;
        case 'f'
            T = 5/9*(T-32);
        case 'r'
            T = 5/9*(T-491.67);
        otherwise
            error('Not a recognized temperature unit. Please use ''C'', ''K'', ''F'', or ''R''');
    end

    % CONVERT SALINITY TO PPT
    switch lower(uS)
        case 'ppt'
        case 'ppm'
            S = S/1000;
        case 'w'
            S = S*1000;
        case '%'
            S = S*10;
        otherwise
            error('Not a recognized salinity unit. Please use ''ppt'', ''ppm'', ''w'', or ''%''');
    end

    % CHECK THAT S & T ARE WITHIN THE FUNCTION RANGE
    if ~isequal((T<0)+(T>180),zeros(size(T)))
        warning('Temperature is out of range for density function 0 < T < 180 C');
    end

    if ~isequal((S<0)+(S>160),zeros(size(S)))
        warning('Salinity is out of range for density function 0 < S < 160 g/kg');
    end

    %% BEGIN

    s = S/1000;

    a = [
         9.9992293295E+02    
         2.0341179217E-02    
        -6.1624591598E-03    
         2.2614664708E-05    
        -4.6570659168E-08    
    ];

    b = [
         8.0200240891E+02    
        -2.0005183488E+00    
         1.6771024982E-02    
        -3.0600536746E-05    
        -1.6132224742E-05    
    ];

    rho_w = a(1) + a(2)*T + a(3)*T.^2 + a(4)*T.^3 + a(5)*T.^4;
    D_rho = b(1)*s + b(2)*s.*T + b(3)*s.*T.^2 + b(4)*s.*T.^3 + b(5)*s^2.*T.^2;
    rho   = rho_w + D_rho;

end
