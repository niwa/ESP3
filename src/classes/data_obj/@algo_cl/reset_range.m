
function reset_range(algo_vec,range)
if ~isempty(range)
    for ial=1:length(algo_vec)
        switch algo_vec(ial).Name
            case {'BottomDetection'}
                algo_param_obj = algo_vec(ial).get_algo_param('r_min');
                if algo_param_obj.Value> range(end)
                    algo_vec(ial).set_input_param_value('r_min',range(1));
                end
                algo_vec(ial).set_input_param_value('r_max',range(end));
                algo_vec(ial).set_input_param_value('vert_filt',range(end)/50);
            case {'SchoolDetection' 'SingleTarget' 'SpikeRemoval' 'BottomDetectionV2' 'DropOuts'}

                algo_param_obj = algo_vec(ial).get_algo_param('r_min');
                if algo_param_obj.Value> range(end)
                    algo_vec(ial).set_input_param_value('r_min',range(1));
                end
                algo_vec(ial).set_input_param_value('r_max',range(end));

        end
    end
end