function [Cax,Type,Units,AlphaDisp]=init_cax(Fieldname)

if isempty(Fieldname)
    Cax= [];
    Type='';
    Units='';
    return;
end
AlphaDisp = 'CaxBounds';
switch lower(deblank(Fieldname))
    case 'sa'
        Cax= [-65 -35];
        Type='Sa';
        Units='dB re 1(m^2 m^{-2})';
    case 'sv'
        Cax= [-75 -40];
        Type='Sv';
        Units='dB re 1 m^-1';
    case 'svdenoised'
        Cax= [-75 -40];
        Type='Denoised Sv';
        Units='dB re 1 m^-1';
    case 'sp'
        Cax= [-55 -25];
        Type='TS (uncomp.)';
        Units='dB re 1 m^2';
    case {'sp_comp' 'ts'}
        Cax= [-55 -25];
        Type='TS';
        Units='dB re 1 m^2';
    case 'spdenoised'
        Cax= [-55 -25];
        Type='Denoised Sp';
        Units='dB re 1 m^2';
    case 'svunmatched'
        Cax= [-75 -40];
        Type='Sv (non-matched)';
        Units='dB re 1 m^-1';
    case 'spunmatched'
        Cax= [-55 -25];
        Type='TS (uncomp.,non-matched)';
        Units='dB re 1 m^2';
    case 'power'
        Cax= [-150 -100];
        Type='Power';
        Units='dB';
    case 'powerunmatched'
        Cax= [-150 -100];
        Type='Power before match Filtering';
        Units='dB';
    case 'powerdenoised'
        Cax= [-150 -100];
        Type='Denoised Power';
        Units='dB';
    case 'y_filtered'
        Cax= [-50 0];
        Type='abs(Y) filtered';
        Units='dB';
    case 'y'
        Cax= [-50 0];
        Type='Abs(Y)';
        Units='dB';
    case 'y_real'
        Cax= [-150 -100];
        Type='Y_real';
        Units='dB';
    case 'y_real_filtered'
        Cax= [-150 -100];
        Type='Y_real_filtered';
        Units='dB';
    case'y_imag'
        Cax= [-150 -100];
        Type='Y_imag';
        Units='dB';
    case'y_imag_filtered'
        Cax= [-150 -100];
        Type='Y_imag_filtered';
        Units='dB';
    case 'singletarget'
        Cax= [-55 -25];
        Type='ST TS';
        Units='dB re 1 m^2';
    case 'snr'
        Cax= [0 30];
        Type='SNR';
        Units='dB';
    case 'acrossphi'
        Cax= [-180 180];
        Type='Phase Across';
        Units=char(hex2dec('00BA'));
        AlphaDisp = 'SpCaxBounds';
    case 'alongphi'
        Cax= [-180 180];
        Type='Phase Along';
        Units=char(hex2dec('00BA'));
        AlphaDisp = 'SpCaxBounds';
    case 'alongangle'
        Cax= [-10 10];
        Type='Angle Along';
        Units=char(hex2dec('00BA'));
        AlphaDisp = 'SpCaxBounds';
    case 'acrossangle'
        Cax= [-10 10];
        Type='Angle Across';
        Units=char(hex2dec('00BA'));
        AlphaDisp = 'SpCaxBounds';
    case 'fishdensity'
        Cax= [0 10];
        Type='Fish Density';
        Units='fish/m^3';
    case 'motioncompensation'
        Cax= [0 12];
        Type='Motion Compensation';
        Units='dB';
    case 'std_sv'
        Cax= [0 12];
        Type='Std Sv';
        Units='dB';
    case 'prc'
        Cax= [0 50];
        Type='PRC';
        Units='%';
    case 'img_intensity'
        Cax= [10 220];
        Type='Image Intensity';
        Units ='';
    case 'wc_data'
        Cax= [-55 -20];
        Type='WC Data';
        Units ='dB';
    case 'feature_id'
        Cax= [1 100];
        Type = 'Feature ID';
        Units ='';
    case 'feature_sv'
        Cax= [-75 -40];
        Type = 'Feature Sv';
        Units ='dB re 1 m^-1';
    case {'velocity' 'velocity_north' 'velocity_east' 'velocity_down' 'quiver_velocity'}
        Cax = [-2 2];
        Type = 'Current Velocity';
        switch lower(deblank(Fieldname))
            case 'velocity_north'
                Type = 'Current North Velocity';
            case 'velocity_east'
                Type = 'Current East Velocity';
            case 'velocity_down'
                Type = 'Current Down Velocity';
            case 'quiver_velocity'
                Type = 'Current Velocity field';
        end
        Units = 'm/s';
        AlphaDisp = 'CorrCaxBounds';
    case {'bathy'}
        Cax = [-inf inf];
        Type = 'Bathymetry';
        Units = 'm';
        AlphaDisp = 'AlphaNormed';
    case {'correlation'}
        Cax = [20 90];
        Type = 'Correlation';
        Units = '%';

    case {'comp_sig_1_real','comp_sig_2_real','comp_sig_3_real','comp_sig_4_real'}
        Cax= [-50 0];      
        Units='dB';
        switch lower(Fieldname)
            case 'comp_sig_1_real'
                 Type='Real part quadrant 1';
            case 'comp_sig_2_real'
                Type='Real part quadrant 2';
            case 'comp_sig_3_real'
                Type='Real part quadrant 3';
            case 'comp_sig_4_real'
                Type='Real part quadrant 4';
        end
    case{'comp_sig_1_imag','comp_sig_2_imag','comp_sig_3_imag','comp_sig_4_imag'}
        Cax= [-50 -0];
        switch lower(Fieldname)
            case 'comp_sig_1_imag'
                Type='Imag. part quadrant 1';
            case 'comp_sig_2_imag'
                Type='Imag. part quadrant 2';
            case 'comp_sig_3_imag'
                Type='Imag. part quadrant 3';
            case 'comp_sig_4_imag'
                Type='Imag. part quadrant 4';
        end
        Units='dB';
    case{'comp_sig_2' 'comp_sig_3' 'comp_sig_4'}
        Cax= [-50 -0];
        switch lower(Fieldname)
            case 'comp_sig_1'
                Type='Abs(s) quadrant 1';
            case 'comp_sig_2'
                Type='Abs(s) quadrant 2';
            case 'comp_sig_3'
                Type='Abs(s) quadrant 3';
            case 'comp_sig_4'
                Type='Abs(s) quadrant 4';
        end
        Units='dB';
    otherwise
        if contains(lower(Fieldname),'khz')
            Type= ['Sv-' Fieldname];
            Cax= [-10 10];
            Units='dB';
            AlphaDisp = 'InfBounds';
        else
            Cax= [-200 200];
            Type=Fieldname;
            Units='dB';
        end
end

end