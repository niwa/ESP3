function cal_struct = get_cw_cal(layer_obj)
nb_trans = numel(layer_obj.Frequencies);

cal_struct = init_cal_struct(nb_trans);
ff = fieldnames(cal_struct);

for ic=1:nb_trans
    cal = layer_obj.Transceivers(ic).get_transceiver_cw_cal();
    
    for ifi = 1:numel(ff)
        if iscell(cal_struct.(ff{ifi}))
            cal_struct.(ff{ifi}){ic} = cal.(ff{ifi});
        else
            cal_struct.(ff{ifi})(ic) = mean(cal.(ff{ifi}),'all');
        end
    end
    
end


end