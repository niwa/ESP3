function  set_transducer_depth(trans_obj,depth,time_d)
depth_corr = [];
if isscalar(depth)
    depth_corr = depth*ones(size(trans_obj.Time));
else
    if~isempty(time_d)
        depth_corr=resample_data_v2(depth,time_d,trans_obj.Time,curr_dist,dist_corr);
        depth_corr(isnan(depth_corr))=0;
    end
end

if ~isempty(depth_corr)
    trans_obj.TransceiverDepth=depth_corr;
end



end