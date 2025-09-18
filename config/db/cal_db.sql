CREATE TABLE t_calibration_acquisition_method_type
(
    calibration_acquisition_method_type_pkey	SERIAL PRIMARY KEY,
    calibration_acquisition_method_type			TEXT, -- Describe the method used to acquire calibration data (ICES category Calibration, attribute calibration_acquisition_method
	
	UNIQUE (calibration_acquisition_method_type) ON CONFLICT IGNORE
);
COMMENT ON TABLE t_calibration_acquisition_method_type is 'Controlled vocabulary for calibration_acquisition_method_type attribute in t_calibration.';
INSERT INTO t_calibration_acquisition_method_type (calibration_acquisition_method_type) VALUES ('Standard sphere, in-situ'),('Standard sphere, tank'),('Standard sphere, other'),('Reciprocity, Hydrophone'),('Seafloor reflection'),('Nominal'),('Intership');


CREATE TABLE t_parameters
(
	parameters_pkey				SERIAL PRIMARY KEY,
	
	parameters_pulse_mode		TEXT DEFAULT 'CW', 	-- CW/FM
	parameters_pulse_length		NUMERIC, 	-- in seconds applies to both CW/FM
	parameters_pulse_slope		NUMERIC DEFAULT 0,	-- pulse slope. applies to both CW/FM
	parameters_FM_pulse_type	TEXT DEFAULT 'linear sweep',	-- linear sweep ,  exponential sweep, etc.
	parameters_frequency_start	NUMERIC, 	
	parameters_frequency_end	NUMERIC, 	
	parameters_power			NUMERIC, 	-- in Watts
	
	parameters_comments			TEXT, 	-- Free text field for relevant information not captured by other attributes
	
	UNIQUE (parameters_pulse_mode,parameters_pulse_length,parameters_pulse_slope,parameters_FM_pulse_type,parameters_frequency_start,parameters_frequency_end,parameters_power) ON CONFLICT IGNORE
);
COMMENT ON TABLE t_parameters is 'Acquisition parameters';

CREATE TABLE t_environment
(
	environment_pkey 				SERIAL PRIMARY KEY,
	
	environment_salinity			NUMERIC, -- Salinity in PSU
	environment_temperature			NUMERIC, -- Temperature in degrees celsius
	environment_depth				NUMERIC, -- Depth in meters
	
	UNIQUE (environment_salinity,environment_temperature,environment_depth) ON CONFLICT IGNORE
	);
COMMENT ON TABLE t_environment is 'Environmental parameters';

CREATE TABLE t_sound_propagation
(
	sound_propagation_pkey 				SERIAL PRIMARY KEY,
	
	sound_propagation_absorption		NUMERIC, -- Sound absorption in dB/km
	sound_propagation_velocity			NUMERIC, -- Sound velocity in m/s
	sound_propagation_frequency			NUMERIC, -- Frequency of sound wave in hertz
	sound_propagation_depth				NUMERIC, -- Depth in meters
	
	UNIQUE (sound_propagation_absorption,sound_propagation_velocity,sound_propagation_frequency) ON CONFLICT IGNORE
	);
COMMENT ON TABLE t_sound_propagation is 'Sound propagation parameters';	



CREATE TABLE t_calibration
(
	calibration_pkey 				SERIAL PRIMARY KEY,
	
	calibration_date				TIMESTAMP,	-- Date of calibration (ICES calibration_date)
	calibration_acquisition_method_type_key	INTEGER DEFAULT 1,		
	calibration_processing_method	TEXT, 		-- Describe method of processing that was used to generate calibration offsets (ICES calibration_processing_method)
	calibration_accuracy_estimate	TEXT, 		-- Estimate of calibration accuracy. Include a description and units so that it is clear what this estimate means (ICES calibration_accuracy_estimate)
	calibration_report				TEXT, 		-- URL or references to external documents which give a full account of calibration processing and results may be appropriate (ICES calibration_report)
	calibration_operator			TEXT,		-- Person/company who did the calibration
	
	calibration_channel_ID			TEXT, 		-- channel ID to which the calibration refers to (Unique identifier of a transceiver/transceiver/combination)
	calibration_parameters_key		INTEGER,    
	calibration_frequency			NUMERIC,		-- frequency at which calibration parameters apply to for this setup (Hz)
	calibration_gain				NUMERIC,		-- on-axis gain for this setup (db)
	calibration_sacorrect			NUMERIC,		-- sa correction as applied on Simrad systems (db)
	calibration_phi_athwart			NUMERIC,		-- estimated athwart beam angle (angular degrees)
	calibration_phi_along			NUMERIC,		-- estimated along beam angle (angular degrees)
	calibration_phi_athwart_offset	NUMERIC,		-- estimated athwart beam angle offset (angular degrees)
	calibration_phi_along_offset	NUMERIC,		-- estimated along beam angle offset (angular degrees)
	calibration_psi					NUMERIC,		-- estimated equivalent bean angle (db)
	calibration_rms					NUMERIC,		-- root mean square error (db)
	calibration_fm_xml_str			TEXT,		-- XML string describing calibration if applicable
	calibration_depth				NUMERIC,	-- depth of transducer during calibration
	calibration_up_or_down_cast		TEXT DEFAULT 'static',
	calibration_sphere_range_av		NUMERIC,	-- average range of sphere echoes during calibration
	calibration_sphere_range_std	NUMERIC,	-- standard deviation of range of sphere echoes during calibration
	calibration_nb_echoes			NUMERIC,	-- total number of sphere echoes during calibration
	calibration_nb_central_echoes	NUMERIC,	-- number of central sphere echoes during calibration
	calibration_environment_key		NUMERIC,		
	calibration_sound_propagation_key		NUMERIC,
	calibration_sphere_ts			NUMERIC,
	calibration_sphere_type			TEXT,
		
	calibration_comments			TEXT,		-- Free text field for relevant information not captured by other attributes (ICES calibration_comments)
	FOREIGN KEY (calibration_acquisition_method_type_key) REFERENCES t_calibration_acquisition_method_type(calibration_acquisition_method_type_pkey),
	FOREIGN KEY (calibration_parameters_key) REFERENCES t_parameters(parameters_pkey),
	FOREIGN KEY (calibration_environment_key) REFERENCES t_environment(environment_pkey),
	FOREIGN KEY (calibration_sound_propagation_key) REFERENCES t_sound_propagation(sound_propagation_pkey),
	UNIQUE (calibration_date,calibration_channel_ID,calibration_parameters_key,calibration_depth,calibration_up_or_down_cast,calibration_sphere_type) ON CONFLICT REPLACE
);
COMMENT ON TABLE t_calibration is 'Calibration sessions';






