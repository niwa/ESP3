function set_absorption(trans_obj,envdata)

if isempty(trans_obj.Alpha)
    trans_obj.Alpha = nan(numel(trans_obj.Range),numel(trans_obj.Params.BeamNumber));
end

if isnumeric(envdata)       
    if all(isnan(envdata))
        f_c = trans_obj.get_center_frequency([]);
        f_c = squeeze(mean(f_c,2));
        d_trans=mean(trans_obj.get_samples_depth([],1),3);

        envdata=arrayfun(@(x) seawater_absorption(x,35, 10, d_trans,'fandg')/1e3,f_c'/1e3,'un',0);  
        envdata=cell2mat(envdata);
    end
    
    if all(size(envdata)==[numel(trans_obj.Range),numel(trans_obj.Params.BeamNumber)])
        trans_obj.Alpha=envdata;
        
        if isscalar(unique(envdata))
            trans_obj.Alpha_ori='constant';
        else
            trans_obj.Alpha_ori='profile';
        end
        
    else
        trans_obj.Alpha=mean(envdata,'all','omitnan')*ones(size(trans_obj.Alpha));
        trans_obj.Alpha_ori='constant';
    end    
    
elseif isa(envdata,'env_data_cl')
    [alpha,ori]=trans_obj.compute_absorption(envdata);
    trans_obj.Alpha=alpha;
    trans_obj.Alpha_ori=ori;
else
    [alpha,ori]=trans_obj.compute_absorption();
    trans_obj.Alpha=alpha;
    trans_obj.Alpha_ori=ori;
end

end