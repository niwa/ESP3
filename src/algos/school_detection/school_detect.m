%% school_detect.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |trans_obj|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |linked_candidates|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-03-28: header (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function output_struct = school_detect(trans_obj,varargin)

p = inputParser;

check_trans_class=@(obj) isa(obj,'transceiver_cl');

default_thr_sv=-70;
check_thr_sv=@(thr)(thr>=-999&&thr<=0);

default_thr_sv_max=Inf;
check_thr_sv_max=@(thr)(thr>=-999&&thr<=Inf);

default_l_min_can=15;
check_l_min_can=@(l)(l>=0&&l<=500);

default_h_min_can=5;
check_h_min_can=@(l)(l>=0&&l<=100);

default_l_min_tot=25;
check_l_min_tot=@(l)(l>=0);

default_h_min_tot=10;
check_h_min_tot=@(l)(l>=0);

default_horz_link_max=55;
check_horz_link_max=@(l)(l>=0&&l<=1000);

default_vert_link_max=5;
check_vert_link_max=@(l)(l>=0&&l<=500);

default_nb_min_sples=100;
check_nb_min_sples=@(l)(l>0);


addRequired(p,'trans_obj',check_trans_class);
addParameter(p,'denoised',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'thr_sv',default_thr_sv,check_thr_sv);
addParameter(p,'thr_sv_max',default_thr_sv_max,check_thr_sv_max);
addParameter(p,'l_min_can',default_l_min_can,check_l_min_can);
addParameter(p,'h_min_can',default_h_min_can,check_h_min_can);
addParameter(p,'l_min_tot',default_l_min_tot,check_l_min_tot);
addParameter(p,'h_min_tot',default_h_min_tot,check_h_min_tot);
addParameter(p,'horz_link_max',default_horz_link_max,check_horz_link_max);
addParameter(p,'vert_link_max',default_vert_link_max,check_vert_link_max);
addParameter(p,'nb_min_sples',default_nb_min_sples,check_nb_min_sples);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'nb_bad_pings',3,@(x) isnumeric(x) && x>0 );
addParameter(p,'r_max',Inf,@isnumeric);
addParameter(p,'r_min',0,@isnumeric);
addParameter(p,'load_bar_comp',[]);
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));

parse(p,trans_obj,varargin{:});

output_struct.linked_candidates=[];
output_struct.done =  false;

[~,Np_p]=trans_obj.get_pulse_length();


if isempty(p.Results.reg_obj)
    idx_r=(1:length(trans_obj.get_samples_range()))';
    idx_ping_tot=1:length(trans_obj.get_transceiver_pings());
    idx_r(idx_r<=max(Np_p)+1)=[];
    reg_obj=region_cl('Idx_r',idx_r,'Idx_ping',idx_ping_tot);
else
    reg_obj=p.Results.reg_obj;
    idx_r=reg_obj.Idx_r;
    idx_ping_tot =reg_obj.Idx_ping;
end

if p.Results.denoised > 0
    field = 'svdenoised';
    alt_fields = {'sv','img_intensity'};
else
    field = 'sv';
    alt_fields = {'img_intensity'};
end


range_tot = trans_obj.get_samples_range(idx_r);

if ~isempty(idx_r)
    idx_r(range_tot<p.Results.r_min|range_tot>p.Results.r_max)=[];
end

if isempty(idx_r)
    disp_perso([],'Nothing to detect school from...');
    return;
end

reg_schools=trans_obj.get_region_from_name('School');

for i=1:length(reg_schools)
    mask_inter=reg_obj.get_mask_from_intersection(reg_schools(i));
    if any(mask_inter(:))
        %id_rem=union(id_rem,reg_schools(i).Unique_ID);
        trans_obj.rm_region_id(reg_schools(i).Unique_ID);
    end
end

thr_sv=p.Results.thr_sv;
thr_sv_max=p.Results.thr_sv_max;
l_min_can=p.Results.l_min_can;
h_min_can=p.Results.h_min_can;
l_min_tot=p.Results.l_min_tot;
h_min_tot=p.Results.h_min_tot;
horz_link_max=p.Results.horz_link_max;
vert_link_max=p.Results.vert_link_max;
nb_min_sples=p.Results.nb_min_sples;

dd=mean(diff(trans_obj.GPSDataPing.Dist(idx_ping_tot)),"all",'omitnan');

if isnan(dd) || dd == 0
    dd = 1;
    warning('No Distance was computed, using ping instead of distance for school detection');
end

%dt=mean(diff(trans_obj.GPSDataPing.Time(idx_ping_tot)),"all",'omitnan');
dr=max(diff(trans_obj.get_samples_range(idx_r)),[],'omitnan');

if dd>0
    w_unit='meters';
    cell_w=max(l_min_can/2,2*dd,'omitnan');
else
    w_unit='pings';
    cell_w=round(max(l_min_can/2,2*dd),'omitnan');
end

nb_ping_can = ceil(l_min_can/(dd));
nb_ping_tot = ceil(l_min_tot/(dd));
block_len = get_block_len(50,'cpu',p.Results.block_len);

block_size=max(min(2*ceil(block_len/numel(idx_r)),numel(idx_ping_tot)),min(10*nb_ping_tot,numel(idx_ping_tot)));

num_ite=ceil(numel(idx_ping_tot)/block_size);
up_bar = ~isempty(p.Results.load_bar_comp);
if up_bar
    p.Results.load_bar_comp.progress_bar.setText('School detection');
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
end
reg_out = [];

for ui=1:num_ite

    idx_ping=idx_ping_tot((ui-1)*block_size+1:min(ui*block_size,numel(idx_ping_tot)));
    idx_ping = idx_ping(1)-nb_ping_can:idx_ping(end)+nb_ping_can;
    idx_ping(idx_ping<1) = [];
    idx_ping(idx_ping>numel(trans_obj.get_transceiver_pings())) = [];
    reg_temp=region_cl('Name','Temp','Idx_r',idx_r,'Idx_ping',idx_ping);
    
    [Sv_mat,idx_r,idx_ping,~,bad_data_mask,bad_trans_vec,~,below_bot_mask,~]=get_data_from_region(trans_obj,reg_temp,...
        'field',field,'alt_fields',alt_fields,...
        'intersect_only',1,...
        'regs',reg_obj);

    if strcmpi(field,'img_intensity')
        tt = max(Sv_mat,[],'all','omitnan');
        dyn = 80;
        Sv_mat = (Sv_mat/tt)*dyn-dyn;
    end

    Sv_mat(:,bad_trans_vec)=nan;
    Sv_mat(bad_data_mask|below_bot_mask)=nan;

    range=trans_obj.get_samples_range(idx_r);
    dist=trans_obj.GPSDataPing.Dist;

    if mean(diff(dist))>0
        dist_pings=dist(idx_ping);
    else
        dist_pings=trans_obj.get_transceiver_pings(idx_ping)';
    end

    switch trans_obj.Mode
        case 'CW'
            [~,Np]=trans_obj.get_pulse_Teff(idx_ping);
        case 'FM'
            [~,Np]=trans_obj.get_pulse_comp_Teff(idx_ping);
            Np = 2*Np;
    end

    bad_ping_bool = false(1,numel(idx_ping));
    bad_ping_bool(bad_trans_vec) = true;

    idx_rem=(idx_r<=max(Np_p,[],'omitnan')+1);

    Sv_mask_ori=(Sv_mat>=thr_sv)&(Sv_mat<=thr_sv_max);

    Sv_mask_ori(range>=p.Results.r_max|range<=p.Results.r_min,:)=0;

    Sv_mask_int=filter2(ones(3*ceil(mean(Np,'omitnan')),1),Sv_mask_ori,'same')>=2;
    Sv_mask_int(idx_rem(:),:)=false;
    nb_bad_pings = p.Results.nb_bad_pings;

    if nb_bad_pings >= 0
        Sv_mask=filter2(ones(1,nb_bad_pings+2),Sv_mask_int,'same')>=2;
        Sv_mask(~Sv_mask_int & ~bad_ping_bool) = false;
    else
        Sv_mask = Sv_mask_int;
    end

    candidates=find_candidates_v3(Sv_mask,range,dist_pings,l_min_can,h_min_can,nb_min_sples,'mat',p.Results.load_bar_comp);

    linked_candidates_mini=link_candidates_v2(candidates,dist_pings,range,horz_link_max,vert_link_max,l_min_tot,h_min_tot,p.Results.load_bar_comp);

    output_struct.linked_candidates=sparse(linked_candidates_mini);


    if ~isempty(p.Results.load_bar_comp)
        p.Results.load_bar_comp.progress_bar.setText('Creating regions');
    end

    reg_out_tmp = trans_obj.create_regions_from_linked_candidates(output_struct.linked_candidates,'w_unit',w_unit,'h_unit','meters','idx_r',idx_r,'idx_ping',idx_ping,...
        'cell_w',cell_w,'cell_h',max(dr*2,h_min_can/10),'reg_names','School','add_regions',false);
    reg_out = [reg_out reg_out_tmp];

    if up_bar
        p.Results.load_bar_comp.progress_bar.setText('School detection');
        set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',ui);
    end
end

if ~isempty(reg_out)
    new_regions = reg_out.merge_regions('overlap_only',2);
    trans_obj.add_region(new_regions,'IDs',1:length(new_regions));
end


output_struct.done =  true;

end