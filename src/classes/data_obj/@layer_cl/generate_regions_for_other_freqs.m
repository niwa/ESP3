function [regs,idx_freq_end,r_factor,t_factor]=generate_regions_for_other_freqs(layer,idx_freq,active_reg,idx_freq_end)

if isempty(idx_freq_end)
    idx_freq_end=1:length(layer.Transceivers);
end

idx_freq_end=setdiff(idx_freq_end,idx_freq);
r_factor=ones(1,numel(idx_freq_end));
t_factor=ones(1,numel(idx_freq_end));
trans_obj=layer.Transceivers(idx_freq);

range_ori=trans_obj.get_samples_range();
time_ori=trans_obj.Time;

dr_ori=mean(diff(range_ori));
dt_ori=mean(diff(time_ori));

mask_reg_ori=active_reg.get_mask();

[nb_samples_ori,nb_pings_ori]=size(mask_reg_ori);
regs=[];
u=0;
idx_f_rem = [];
for itr=1:length(layer.Transceivers)

    if itr==idx_freq||~any(itr==idx_freq_end)
        continue;
    end

    u=u+1;
    trans_obj_sec=layer.Transceivers(itr);
    new_range=trans_obj_sec.get_samples_range();
    new_time=trans_obj_sec.Time;

    r_factor(u)=dr_ori/mean(diff(new_range));
    t_factor(u)=dt_ori/mean(diff(new_time));

    if new_range(end)<range_ori(active_reg.Idx_r(1)) || new_range(1)>range_ori(active_reg.Idx_r(end))
        idx_f_rem = union(idx_f_rem,find(idx_freq_end==itr));
        continue;
    end

    [~,idx_ping_start]=min(abs(new_time-time_ori(active_reg.Idx_ping(1))));
    [~,sample_start]=min(abs(new_range-range_ori(active_reg.Idx_r(1))));
    [~,idx_ping_end]=min(abs(new_time-time_ori(active_reg.Idx_ping(end))));
    [~,sample_end]=min(abs(new_range-range_ori(active_reg.Idx_r(end))));

    idx_ping=idx_ping_start:idx_ping_end;
    idx_r=(sample_start:sample_end)';

    if isscalar(idx_r) || isscalar(idx_ping)
        continue;
    end

    switch active_reg.Cell_w_unit
        case 'pings'
            cell_w=active_reg.Cell_w*t_factor(u);
        case 'time'
            cell_w=max(round(active_reg.Cell_w*t_factor(u)),1);
        case 'meters'
            cell_w=active_reg.Cell_w;
    end

    cell_h=active_reg.Cell_h;

    switch lower(active_reg.Shape)
        case 'polygon'
            nb_samples=length(idx_r);
            nb_pings=length(idx_ping);
            if nb_samples~=nb_samples_ori||nb_pings~=nb_pings_ori
                MaskReg=imresize(mask_reg_ori,[nb_samples nb_pings],'nearest');
            else
                MaskReg=mask_reg_ori;
            end
        otherwise
            MaskReg=ones(length(idx_r),length(idx_ping));
    end


    %     poly=active_reg.Poly;
    %     poly.Vertices(:,1)=floor(poly.Vertices(:,1)*t_factor);
    %     poly.Vertices(:,2)=floor(poly.Vertices(:,2)*r_factor);
    try
        regs=[regs region_cl(...
            'ID',active_reg.ID,...
            'Unique_ID',active_reg.Unique_ID,...
            'Name',active_reg.Name,...
            'Type',active_reg.Type,...
            'Tag',active_reg.Tag,...
            'Idx_ping',idx_ping,...
            'Idx_r',idx_r,...
            'Shape',active_reg.Shape,...
            'MaskReg',MaskReg,...
            'Reference',active_reg.Reference,...
            'Cell_w',cell_w,...
            'Cell_w_unit',active_reg.Cell_w_unit,...
            'Cell_h',cell_h,...
            'Cell_h_unit',active_reg.Cell_h_unit)];
    catch
        warning('Could not copy region %d to channel %s',active_reg.ID,layer.Transceivers(itr).Config.ChannelID);
        idx_f_rem = union(idx_f_rem,find(idx_freq_end==itr));
    end
end

idx_freq_end(idx_f_rem) = [];
r_factor(idx_f_rem) = [];
t_factor(idx_f_rem) = [];

end