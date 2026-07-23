function run_urmy_layer_detector(~,~,main_figure)
layer = get_current_layer;
trans_obj = layer.Transceivers(1);
curr_disp=get_esp3_prop('curr_disp');

reg_obj = create_WC_region(trans_obj,'y_min',10,'y_max',Inf,'Ref','Transducer','Cell_w',10,'Cell_h',10);

[data,idx_r,idx_ping,~,bad_data_mask,bad_trans_vec,mask,below_bot_mask,~] =trans_obj.get_data_from_region(reg_obj,'field',curr_disp.Fieldname);
pings = trans_obj.get_transceiver_pings;

data(below_bot_mask|isinf(data))=nan;

depths = trans_obj.get_samples_depth(idx_r,idx_ping);
data(mask==0|isinf(data)|bad_data_mask|bad_trans_vec)=nan;
data(mask==0|isinf(data)) = nan;
spikes =trans_obj.get_spikes(idx_r,idx_ping);
if ~isempty(spikes)
    data(spikes>0) = nan;
end

[detected_layers,vertical_metrics] = plot_vertical_metrics_urmy(data,depths,pings,trans_obj,"Threshold",curr_disp.Caxes{1}(1),"main_figure",main_figure);

disp(vertical_metrics);
