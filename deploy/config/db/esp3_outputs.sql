CREATE TABLE t_transect
(
	transect_pkey    			SERIAL PRIMARY KEY, -- NOTE: can be used for ICES transect_id
	
	-- ICES basics
	transect_name				TEXT, 		-- Name of the transect (ICES transect_name)
	transect_description		TEXT,		-- Description of the transect, its purpose, and main activity (ICES transect_description). NOTE: will be the same as "transect_type" for now
	transect_related_activity	TEXT,		-- Describe related activities that may occur on the transect (ICES transect_related_activity). NOTE: should be "linked" to the transect_station
	transect_start_time			TIMESTAMP,	-- yyyy-mm-dd HH:MM:SS Start time of the transect (ICES transect_start_time)
	transect_end_time			TIMESTAMP,	-- yyyy-mm-dd HH:MM:SS End time of the transect (ICES transect_end_time)
	
	-- Formalized info attributes NIWA-MPI actually need. Not in ICES
	transect_lat_start			FLOAT,	--decimal degrees
	transect_lon_start			FLOAT,	--decimal degrees	
	transect_lat_end			FLOAT,	--decimal degrees	
	transect_lon_end			FLOAT,	--decimal degrees
	
	transect_snapshot			INT, 		-- To identify time repeats. Typically for statistical purposes, in acoustic surveys
	transect_stratum			TEXT, 		-- To identify geographically different areas. Typically for statistical purposes, in trawl surveys 
	transect_station			TEXT, 		-- To identify separate targets. Typically station numbers in trawl survey, or marks in acoustic surveys 
	transect_type				TEXT, 		-- To identify categorically different data purposes, e.g. transit/steam/trawl/junk/test/etc. 
	transect_number				INT, 		-- To identify separate transects in a same snapshot/stratum/station/type

	transect_comments			TEXT,		-- Free text field for relevant information not captured by other attributes (ICES transect_comments)	
	
	UNIQUE (transect_snapshot,transect_stratum,transect_type,transect_number,transect_start_time,transect_end_time) ON CONFLICT REPLACE,
	CHECK (transect_end_time>=transect_start_time) ON CONFLICT IGNORE
);
COMMENT ON TABLE t_transect is 'Acoustic data transects';

CREATE TABLE t_survey_options
(
	t_survey_options_pkey   SERIAL PRIMARY KEY,
	Script   				TEXT,
	Title 					TEXT
	Main_species 			TEXT,
	Areas 					TEXT,
	Voyage 					TEXT,
	SurveyName				TEXT,
	Author					TEXT,
	Created					TIMESTAMP,
	Comments				TEXT,
	Use_exclude_regions		BOOLEAN,
	Absorption				TEXT,
	Es60_correction			BOOLEAN,
	Motion_correction		BOOLEAN,
	Shadow_zone				BOOLEAN,
	Shadow_zone_height		FLOAT,
	Vertical_slice_size		FLOAT,
	Vertical_slice_units	TEXT,
	Horizontal_slice_size	FLOAT,
	IntType					TEXT,
	IntRef 					TEXT,
	Remove_tracks			BOOLEAN,
	Remove_ST				BOOLEAN,
	Export_ST				BOOLEAN,
	Export_TT				BOOLEAN,
	Denoised				FLOAT,
	Frequency				FLOAT,
	Channel 				TEXT,
	FrequenciesToLoad 		TEXT,
	ChannelsToLoad 			TEXT,
	CopyBottomFromFrequency	BOOLEAN,
	CTD_profile 			TEXT,
	SVP_profile 			TEXT,
	Temperature				FLOAT,
	Salinity				FLOAT,
	SoundSpeed				FLOAT,
	MeanDepth				FLOAT,
	BadTransThr				FLOAT,
	SaveBot					BOOLEAN,
	SaveReg					BOOLEAN,
	DepthMin				FLOAT,
	DepthMax				FLOAT,
	RangeMin				FLOAT,
	RangeMax				FLOAT,
	RefRangeMin				FLOAT,
	RefRangeMax				FLOAT,
	AngleMin				FLOAT,
	AngleMax				FLOAT,
	ExportSlicedTransects	BOOLEAN,
	ExportRegions			BOOLEAN,
	SvThr					FLOAT,
	RunInt					FLOAT
);
COMMENT ON TABLE t_echoint1D is 'Transect summary';


CREATE TABLE t_transect_summary
(
	transect_summary_pkey    SERIAL PRIMARY KEY,
	transect_key		INT,
	distance			FLOAT, -- in mn
	average_speed		FLOAT,	--in knots
	sv					FLOAT,--mean volumic acoustic backscatter
	sa				    FLOAT,--mean areal acoustic bacsckatter
	sa_deadzone			FLOAT,--mean areal acoustic backscatter coming from dead-zone
	nb_st				INT,--number of single targets
	nb_tracks			INT,--number of tracked targets
	nb_pings 			INT,--number of pings in transects
		
	FOREIGN KEY (transect_key) REFERENCES t_transect(transect_pkey)
);
COMMENT ON TABLE t_transect_summary is 'Transect summary';

CREATE TABLE t_stratum_summary
(
	t_stratum_summary_pkey    SERIAL PRIMARY KEY,
	stratum				TEXT,
	nb_transects		INT,
	sa_mean				FLOAT,--mean areal acoustic bacsckatter
	sa_std			    FLOAT,--mean areal acoustic backscatter standard_deviation
	sa_weigted_mean	    FLOAT,--mean areal acoustic bacsckatter weighted by transect length
	sa_weigthed_std     FLOAT,--mean areal acoustic bacsckatter weighted by transect length
	
	FOREIGN KEY (stratum) REFERENCES t_transect(transect_stratum)
);
COMMENT ON TABLE t_stratum_summary is 'Transect summary';


CREATE TABLE t_echoint_transect_1D
(
	echo_int_1D_pkey    SERIAL PRIMARY KEY,
	transect_key		INT,
	nb_samples			INT,
	eint				FLOAT,
	sd_Sv				FLOAT,
	Vert_Slice_Idx		INT,
	Ping_S				INT,
	Ping_E				INT,
	Nb_good_pings		INT,
	Sample_S			INT,
	Sample_E			INT,
	Range_min			FLOAT,
	Range_max			FLOAT,
	Depth_min			FLOAT,
	Depth_max			FLOAT,
	Depth_mean			FLOAT,
	Dist_to_bot_min		FLOAT,
	Dist_to_bot_max		FLOAT,
	Dist_to_bot_mean	FLOAT,
	Range_ref_min		FLOAT,
	Range_ref_max		FLOAT,
	Dist_S				FLOAT,
	Dist_E				FLOAT,
	Time_S				TIMESTAMP,
	Time_E				TIMESTAMP,
	Lat_S				FLOAT,
	Lon_S				FLOAT,
	Lat_E				FLOAT,
	Lon_E				FLOAT,
	sv					FLOAT,
	ABC					FLOAT,
	NASC				FLOAT,
	nb_st				INT,
	nb_tracks			INT,
	st_ts_mean			FLOAT,
	tracks_ts_mean		FLOAT,
	Tags				TEXT,	
	Reference			TEXT,
	
	FOREIGN KEY (transect_key) REFERENCES t_transect(transect_pkey)
	UNIQUE (transect_key,Vert_Slice_Idx) ON CONFLICT REPLACE
);
COMMENT ON TABLE t_echoint_transect_1D is 'Sliced transect vertically (1 Dimension)';

CREATE TABLE t_echoint_transect_2D
(
	echo_int_2D_pkey    SERIAL PRIMARY KEY,
	transect_key		INT,
	nb_samples			INT,
	eint				FLOAT,
	sd_Sv				FLOAT,
	Vert_Slice_Idx		INT,
	Horz_Slice_Idx		INT,
	Ping_S				INT,
	Ping_E				INT,
	Nb_good_pings		INT,
	Sample_S			INT,
	Sample_E			INT,
	Range_min			FLOT,
	Range_max			FLOAT,
	Depth_min			FLOAT,
	Depth_max			FLOAT,
	Depth_mean			FLOAT,
	Dist_to_bot_min		FLOAT,
	Dist_to_bot_max		FLOAT,
	Dist_to_bot_mean	FLOAT,
	Range_ref_min		FLOAT,
	Range_ref_max		FLOAT,
	Dist_S				FLOAT,
	Dist_E				FLOAT,
	Time_S				TIMESTAMP,
	Time_E				TIMESTAMP,
	Lat_S				FLOAT,
	Lon_S				FLOAT,
	Lat_E				FLOAT,
	Lon_E				FLOAT,
	PRC					FLOAT,
	sv					FLOAT,
	ABC					FLOAT,
	NASC				FLOAT,
	nb_st				INT,
	nb_tracks			INT,
	st_ts_mean			FLOAT,
	tracks_ts_mean		FLOAT,
	Tags				TEXT,
	Reference			TEXT,


	FOREIGN KEY (transect_key) REFERENCES t_transect(transect_pkey)
	UNIQUE (transect_key,Vert_Slice_Idx,Horz_Slice_Idx,Reference) ON CONFLICT REPLACE
);
COMMENT ON TABLE t_echoint_transect_2D is 'Echo-integrated transect (2 Dimension)';

