function set_transducer_depth_from_line(trans_obj,line_obj)
trans_obj.TransceiverDepth=zeros(size(trans_obj.Time));

if ~isempty(line_obj)
    curr_dist=trans_obj.GPSDataPing.Dist;
    curr_time=trans_obj.GPSDataPing.Time;
    time_out=[];
    r_out=[];
    
    for i=1:numel(line_obj)
        idx_add=~isnan(line_obj(i).Range(:));
        time_out=[time_out line_obj(i).Time(idx_add)];
        r_out=[r_out line_obj(i).Range(idx_add)];
    end
    
    [time_tot,idx_sort]=unique(time_out);
    r_tot=r_out(idx_sort);
    
    if sum(curr_dist,'all','omitnan')>0  
        curr_dist_red=resample_data_v2(curr_dist,curr_time,time_tot);
        dist_corr=curr_dist_red-line_obj(1).Dist_diff;
        time_corr=resample_data_v2(time_tot,curr_dist_red,dist_corr);
        range_line=resample_data_v2(r_tot,time_tot,time_corr);
    else
        range_line=r_tot;
        time_corr=time_tot;
    end
    
    idx_nan=isnan(range_line);
    range_line(idx_nan)=[];
    time_corr(idx_nan)=[];
    
    range_t = nan(size(trans_obj.Time));
    block_len = get_block_len(50,'cpu',[]);
    idx_ping_tot = trans_obj.get_transceiver_pings();   
    block_size = min(ceil(block_len/numel(time_corr)),numel(trans_obj.Time));
    num_ite = ceil(numel(idx_ping_tot)/block_size);
    for ui = 1:num_ite
        idx_ping = idx_ping_tot((ui-1)*block_size+1:min(ui*block_size,numel(idx_ping_tot)));
        [dt,idx_t]=min(abs(time_corr(:)-trans_obj.Time(idx_ping)),[],1);
        idx_rem= dt>10*mode(diff(trans_obj.Time(idx_ping)));
        range_t(idx_ping)=range_line(idx_t);
        range_t(idx_ping(idx_rem))=0;
    end
    trans_obj.TransceiverDepth=range_t(:)';
    
end
  
end