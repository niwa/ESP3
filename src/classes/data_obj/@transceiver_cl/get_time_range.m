function t = get_time_range(trans_obj,idx_ping,idx_r,idx_beam)

arguments
    trans_obj transceiver_cl
    idx_ping {mustBeNumeric}=[]
    idx_r {mustBeNumeric}=[]
    idx_beam {mustBeNumeric}=[]
end
if isempty(idx_r)
    idx_r = (1:numel(trans_obj.Range));
end

t=(idx_r(:)-1).*trans_obj.get_params_value('SampleInterval',idx_ping,idx_beam);

end