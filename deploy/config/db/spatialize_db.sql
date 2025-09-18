SELECT InitSpatialMetadata(1);
SELECT AddGeometryColumn('t_echoint_transect_1D' , 'geom_col', 4326, 'POINT', 'XY');
UPDATE t_echoint_transect_1D SET geom_col = MakePoint(Lon_S,Lat_s,4326);

SELECT AddGeometryColumn('t_echoint_transect_2D' , 'geom_col', 4326, 'POINT', 'XY');
UPDATE t_echoint_transect_1D SET geom_col = MakePoint(Lon_S,Lat_s,4326);

SELECT AddGeometryColumn('t_transect' , 'geom_col', 4326, 'POINT', 'XY');
UPDATE t_echoint_transect_1D SET geom_col = MakePoint(transect_lon_start,transect_lat_start,4326);