function [alpha,ori]=get_absorption(trans_obj,idx_r)

arguments
    trans_obj transceiver_cl
    idx_r {mustBeNumeric}=[]
end

if isempty(idx_r)
    alpha=trans_obj.Alpha;
else
    alpha=trans_obj.Alpha(idx_r,:);
end


ori=trans_obj.Alpha_ori;

if isempty(alpha)||all(alpha==0,'all')||all(isnan(alpha),'all')
    trans_obj.set_absorption([]);
    if isempty(idx_r)
        alpha=trans_obj.Alpha;
    else
        alpha=trans_obj.Alpha(idx_r,:);
    end
    ori=trans_obj.Alpha_ori;
end

alpha = permute(alpha,[1 3 2]);

end