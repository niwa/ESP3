function replace_gps_data_layer(layer_obj,gps_data)

for itrans=1:length(layer_obj.Transceivers) 
    gps_data_new=layer_obj.Transceivers(itrans).replace_gps_data_trans(gps_data);
end
if ~isempty(layer_obj.Transceivers)
    layer_obj.GPSData=gps_data_new;
else
    layer_obj.GPSData=gps_data;
end
end