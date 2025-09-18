function create_spatial_SQL(db_filename, table_names,lon_cols,lat_cols,srid)

sqlite_folder=fullfile(whereisEcho(),'ext_lib');

sqlite3_file=fullfile(sqlite_folder,'sqlite3');

temp_sql_file = [tempname '.sql'];
fid = fopen(temp_sql_file,'w+');

fprintf(fid,'SELECT load_extension(''mod_spatialite.dll'');\n');
fprintf(fid,'SELECT InitSpatialMetadata(1);\n\n');

for it = 1:numel(table_names)
    fprintf(fid,['SELECT AddGeometryColumn(''%s'' , ''geom_col'', %d, ''POINT'', ''XY'');\n',...
                'UPDATE %s SET geom_col = MakePoint(%s,%s,%d);\n\n'],...
        table_names{it},...
        srid,...
        table_names{it},...
        lon_cols{it},...
        lat_cols{it},...
        srid);
end

fclose(fid);   
if ~isdeployed()
    type(temp_sql_file)
end

command = sprintf('"%s" "%s" ".read ''%s''"',sqlite3_file,db_filename,temp_sql_file);

if isdeployed()
    [~,~] = system(command);
else
    [~,~] = system(command,'-echo');
end

delete(temp_sql_file);