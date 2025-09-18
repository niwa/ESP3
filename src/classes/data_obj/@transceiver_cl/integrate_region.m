%% integrate_region.m
%
% Integrate echogram
%
%% Help
%
% *USE*
%
% sub_output = integrate_region(trans_obj,region) integrates acoustic data
% in trans_obj according to region.
%
% *INPUT VARIABLES*
%
% * |trans_obj|: TODO: write description and info on variable
% * |region|: TODO: write description and info on variable
% * |input_variable_1|: TODO: write description and info on variable
% * |input_variable_1|: TODO: write description and info on variable
% * |input_variable_1|: TODO: write description and info on variable
% * |input_variable_1|: TODO: write description and info on variable

%
% *sub_output VARIABLES*
%
% * |sub_output|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2019-09-08 first version (Yoann Ladroit). TODO: complete date and comment
% relying on get_data_from_region to get masks and region contents
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function output = integrate_region(trans_obj,region,varargin)

%% input variables management through input parser
p = inputParser;

addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addRequired(p,'region',@(x) isa(x,'region_cl'));
addParameter(p,'line_obj',[],@(x) isa(x,'line_cl')||isempty(x));
addParameter(p,'depthBounds',[-inf inf],@isnumeric);
addParameter(p,'rangeBounds',[-inf inf],@isnumeric);
addParameter(p,'refRangeBounds',[-inf inf],@isnumeric);
addParameter(p,'BeamAngularLimit',[-inf inf],@isnumeric);
addParameter(p,'timeBounds',[0 inf],@isnumeric);
addParameter(p,'denoised',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'feature_bool',false,@(x) isnumeric(x)||islogical(x));
addParameter(p,'motion_correction',false,@(x) isnumeric(x)||islogical(x));
addParameter(p,'intersect_only',false,@(x) isnumeric(x)||islogical(x));
addParameter(p,'idx_regs',[],@isnumeric);
addParameter(p,'regs',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'select_reg','selected',@ischar);
addParameter(p,'keep_bottom',false,@(x) isnumeric(x)||islogical(x));
addParameter(p,'keep_all',false,@(x) isnumeric(x)||islogical(x));
addParameter(p,'sv_thr',-999,@isnumeric);
addParameter(p,'cal',[],@(x) isstruct(x) || isempty(x));
addParameter(p,'envdata',[],@(x) isa(x,'env_data_cl') || isempty(x));
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
addParameter(p,'load_bar_comp',[]);

parse(p,trans_obj,region,varargin{:});

use_tall = false;

block_len = get_block_len(50,'cpu',p.Results.block_len);

if any([region.Cell_h region.Cell_w]==0)
    print_errors_and_warnings([],'Warning',sprintf('Region %.0f defined with cell size =0',region.ID));
    output=[];
    return;
end

PROF = false;
PROF = PROF && ~isdeployed();

if PROF
    profile on;
end

output=[];

if p.Results.denoised>0
    field='svdenoised';
    if ~ismember('svdenoised',trans_obj.Data.Fieldname)
        field='sv';
    end
else
    field='sv';
end
[~,found]=trans_obj.Data.find_field_idx(field);

if ~found
    return;
end

idx_beam = trans_obj.get_idx_beams(p.Results.BeamAngularLimit);
% idx_r_tot = region.Idx_r;
% idx_ping_tot = region.Idx_ping;

[idx_r_tot,idx_ping_tot,~] = trans_obj.get_idx_r_idx_ping(region,...
    'idx_beam',idx_beam,...
    'timeBounds',p.Results.timeBounds,...
    'rangeBounds',p.Results.rangeBounds,...
    'refRangeBounds',p.Results.refRangeBounds,...
    'depthBounds',p.Results.depthBounds,...
    'timeBounds',p.Results.timeBounds);

if isempty(idx_ping_tot)||isempty(idx_r_tot)
    return;
end

time_tot=trans_obj.get_transceiver_time(idx_ping_tot);
pings_tot=trans_obj.get_transceiver_pings(idx_ping_tot);

if isempty(trans_obj.GPSDataPing.Dist)
    region.Cell_w_unit = 'pings';
else
    dist_tot = trans_obj.GPSDataPing.Dist(idx_ping_tot);
end

switch region.Cell_w_unit
    case 'pings'
        x = pings_tot;
    case 'meters'
        x = dist_tot;
    case 'seconds'
        x= time_tot*24*60*60;
end

idx_tot_idx = floor((x-min(x,[],'all','omitnan'))/region.Cell_w)+1;

[~,idx_start]=unique(idx_tot_idx,'first');
[~,idx_end]=unique(idx_tot_idx,'last');

N_x_tot=numel(idx_start);

nb_pings_per_slices=idx_end-idx_start+1;

if ~p.Results.keep_bottom
    idx_bot=trans_obj.get_bottom_idx(idx_ping_tot);
    if ~any(isnan(idx_bot))
        idx_r_tmp=max(idx_bot,[],'all','omitnan');
        if ~isnan(idx_r_tmp)
            idx_r_tot(idx_r_tot>idx_r_tmp)=[];
        end
    end
end

if isempty(idx_r_tot)
    return;
end

idx_r_max=idx_r_tot(end);

sample_range=trans_obj.get_samples_range(idx_r_tot);
sample_trans=trans_obj.Data.get_samples(idx_r_tot);
depth_trans=trans_obj.get_transducer_depth(idx_ping_tot);

% taking the average of distance between two samples
dr  = mean(diff(sample_range,1,1),'all','omitnan');

bot_depth=trans_obj.get_bottom_depth(idx_ping_tot,idx_beam);

switch region.Reference
    case 'Surface'
        line_ref_tot = trans_obj.get_surface_height(idx_ping_tot);
    case 'Transducer'
        line_ref_tot = depth_trans;
    case 'Bottom'
        line_ref_tot = bot_depth;
    case 'Line'
        if isempty(p.Results.line_obj)
            line_obj=line_cl('Range',zeros(1,numel(idx_ping_tot)),'Time',time_tot);
        else
            line_obj=p.Results.line_obj;
        end
        line_ref_tot = resample_data_v2(line_obj.Range,line_obj.Time,time_tot);
end

block_size=min(ceil(block_len/(numel(idx_r_tot)*numel(idx_beam))),numel(x),'omitnan');
dslice=min(ceil(block_size/mean(nb_pings_per_slices,'omitnan')),N_x_tot,'omitnan');
%dslice=10;
idx_ite_x=unique([dslice:dslice:N_x_tot N_x_tot]);

num_ite=ceil(numel(idx_ping_tot)/block_size);
N_y_ori_per_ping = nan(1,numel(idx_ping_tot));
N_y_tot = 0;


for ui = 1:num_ite
    idx_ping=idx_ping_tot((ui-1)*block_size+1:min(ui*block_size,numel(idx_ping_tot)));
    [~,sub_idx_ping]=intersect(idx_ping_tot,idx_ping);
    sample_depth=trans_obj.get_samples_depth([idx_r_tot(1) idx_r_tot(end)],sub_idx_ping,idx_beam);
    range_from_line_ref=sample_depth-line_ref_tot(:,sub_idx_ping,:);
    N_y_ori_per_ping(sub_idx_ping) = floor(min(range_from_line_ref,[],[1 3],'omitnan')/region.Cell_h);
    N_y_tot = max(N_y_tot,ceil(range(range_from_line_ref,'all')/region.Cell_h));
end

x0=min(x,[],'omitnan');

idx_x_empty=[];

if isempty(line_ref_tot(~isnan(line_ref_tot)))
    disp('No reference line, nothing to integrate...');
    return;
end

load_bar_comp=p.Results.load_bar_comp;
if ~isempty(load_bar_comp)
    load_bar_comp.progress_bar.setText(sprintf('Channel %s: Integrating %s',trans_obj.Config.ChannelID,region.print()));
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(idx_ite_x), 'Value',0);
end

ub=0;
%profile on;
%gpu_comp=get_gpu_comp_stat();
gpu_comp=0;


for ui=idx_ite_x

    is=idx_start(ui-dslice+1);
    ie=idx_end(ui);
    %field = 'snr';
    %% getting Sv
    [Sv_reg,idx_r,idx_ping,idx_beam,bad_data_mask,bad_trans_vec,intersection_mask,below_bot_mask,mask_from_st] = get_data_from_region(trans_obj,region,...
        'field',field,...
        'timeBounds',[time_tot(is) time_tot(ie)],...
        'depthBounds',p.Results.depthBounds,...
        'BeamAngularLimit',p.Results.BeamAngularLimit,...
        'rangeBounds',[min(p.Results.rangeBounds) min(max(p.Results.rangeBounds),trans_obj.get_samples_range(idx_r_max),'omitnan')],...
        'refRangeBounds',p.Results.refRangeBounds,...
        'intersect_only',p.Results.intersect_only,...
        'idx_regs',p.Results.idx_regs,...
        'regs',p.Results.regs,...
        'select_reg',p.Results.select_reg,...
        'keep_bottom',p.Results.keep_bottom);

    %     if size(Sv_reg,3) > 1
    %         Sv_reg = pow2db_perso(mean(db2pow_perso(Sv_reg),3,'omitnan'));
    %     end

    if isempty(Sv_reg)||~any(Sv_reg,'all')
        continue;
    end

    %% motion correction
    if p.Results.motion_correction>0
        motion_corr=trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'field','motioncompensation');
        if ~isempty(motion_corr)
            motion_corr(motion_corr==-999)=0;
            Sv_reg=Sv_reg+motion_corr;
        else
            disp('Cannot find motion corrected Sv, integrating normal Sv.')
        end
    end

    if p.Results.feature_bool
        feature_mask = trans_obj.get_feature_mask('idx_ping',idx_ping,'idx_r',idx_r,'idx_beam',idx_beam);
    else
        feature_mask  = true(size(Sv_reg));
    end

    %% Masking data
    % defining overall mask for the region and masking data within region
    Mask_reg = intersection_mask & ~mask_from_st & ~isnan(Sv_reg) & feature_mask;
    Mask_reg(:,bad_trans_vec,:) = false;

    Sv_reg(Sv_reg<p.Results.sv_thr) = -999;

    if numel(size(Sv_reg))>2
        Sv_reg(bad_data_mask,:) = -999;
    else
        Sv_reg(bad_data_mask) = -999;
    end

    Sv_reg(~Mask_reg) = nan;

    [~,sub_idx_ping]=intersect(idx_ping_tot,idx_ping);
    [~,sub_idx_r]=intersect(idx_r_tot,idx_r);

    %% vectors in pings and samples

    % time, range, ping counter, and sample counter vectors
    sub_time = time_tot(sub_idx_ping);
    sub_pings = pings_tot(sub_idx_ping);
    sub_samples = sample_trans(sub_idx_r);

    sub_line_ref=line_ref_tot(:,sub_idx_ping,:);

    sub_bot_depth=bot_depth(:,sub_idx_ping,:);

    sub_depth = trans_obj.get_samples_depth(idx_r,idx_ping,idx_beam);

    sub_dist_from_bot=sub_depth-sub_bot_depth;

    sub_range_from_line_ref=sub_depth-sub_line_ref;

    % distance, latitude and longitude
    if isempty(trans_obj.GPSDataPing.Dist)
        region.Cell_w_unit = 'pings';
        sub_dist = nan(size(sub_time));
        sub_lat  = nan(size(sub_time));
        sub_lon  = nan(size(sub_time));
    else
        sub_dist = trans_obj.GPSDataPing.Dist(idx_ping);
        sub_lat  = trans_obj.GPSDataPing.Lat(idx_ping);
        sub_lon  = trans_obj.GPSDataPing.Long(idx_ping);
    end

    y_mat = sub_range_from_line_ref;


    sub_x = x(sub_idx_ping);

    % meshgrid the vectors in X and Y
    [x_mat,~] = meshgrid(sub_x,sub_idx_r);


    %% cell work

    % get cell width and height
    cell_w = region.Cell_w;
    cell_h = region.Cell_h;

    % column index of cells composing the region. Note that reference is
    % beggining of echogram so that if data starts at ping #11 in the file
    % while cell width is 10 pings, then first cell of the region is cell #2
    x_mat_idx = floor((x_mat-x0)/cell_w)+1;
    x_vec=min(x_mat_idx,[],'all','omitnan'):max(x_mat_idx,[],'all','omitnan');
    idx_x_empty=union(idx_x_empty ,setdiff(x_vec,unique(x_mat_idx)));

    ix1=min(x_mat_idx,[],'all','omitnan');
    % column index of cell in the region
    slice_idx = floor((sub_x-x0)/cell_w)+1;
    x_mat_idx=x_mat_idx-ix1+1;

    % row index of cells compos
    switch region.Reference
        case {'Line' 'Bottom'}
            y_mat_idx = -ceil(y_mat/cell_h)+1;
        otherwise
            y_mat_idx = floor(y_mat/cell_h)+1;
    end

    iy1 = min(N_y_ori_per_ping(sub_idx_ping));
    y_mat_idx = y_mat_idx -iy1 + 1;

    y_mat_idx(isinf(y_mat_idx)|isnan(y_mat_idx))=N_y_tot-iy1+1;
    y_mat_idx(y_mat_idx<=0) = 1;

    iy1 = iy1 - min(N_y_ori_per_ping)+1;
    % mask region and bottom
    Mask_reg_min_bot = Mask_reg & ~below_bot_mask & ~isinf(y_mat_idx) & ~isnan(y_mat_idx) & Sv_reg>-999;

    %% INTEGRATION CALCULATIONS

    % get s_v in linear values and remove total region and bottom mask
    Sv_reg(~Mask_reg_min_bot) = nan;
    Sv_reg_lin = 10.^(Sv_reg/10);

    if size(Sv_reg ,3)>1
        vert_samp = ceil(y_mat/dr);
        vert_samp = vert_samp-min(vert_samp,[],'all')+1;
        vert_samp(vert_samp<=0) = 1;
        vert_samp(vert_samp>size(Sv_reg,1)) = size(Sv_reg,1);

        ping_number = repmat((1:size(Sv_reg,2)),size(vert_samp,1),1,size(vert_samp,3));
        
        Sv_reg_lin = accumarray([vert_samp(~isnan(vert_samp)) ping_number(~isnan(vert_samp))],Sv_reg_lin(~isnan(vert_samp)),[size(Sv_reg,1) size(Sv_reg,2)],@(x) mean(x,'all','omitnan'),0);

        sub_depth = mean(sub_depth,3,'omitnan');
        sub_dist_from_bot = mean(sub_dist_from_bot,3,'omitnan');
        y_mat = mean(y_mat,3,'omitnan');
        y_mat_idx = ceil(mean(y_mat_idx,3,'omitnan'));
        Sv_reg  = pow2db_perso(Sv_reg_lin);
        Mask_reg_min_bot = any(Mask_reg_min_bot,3);
    end

    if gpu_comp
        %Sv_reg=gpuArray(Sv_reg);
        Sv_reg_lin=gpuArray(Sv_reg_lin);
    end

    % number of cells in x and y
    N_x = max(x_mat_idx,[],'all','omitnan');
    N_y = max(y_mat_idx,[],'all','omitnan');

    if isnan(N_y)||isnan(N_x)
        return;
    end


    % total number of valid samples in each cell
    if~isempty(Mask_reg_min_bot(Mask_reg_min_bot))
        sub_output.nb_samples = accumarray( [y_mat_idx(Mask_reg_min_bot) x_mat_idx(Mask_reg_min_bot)] , Mask_reg_min_bot(Mask_reg_min_bot) , [N_y N_x] , @sum , 0 );
        % cells empty of valid samples:
        Mask_reg_sub = (sub_output.nb_samples==0);

        % s_a as the sum of the s_v of valid samples within each cell, multiplied
        % by the average between-sample range
        eint_sparse = accumarray( [y_mat_idx(Mask_reg_min_bot) x_mat_idx(Mask_reg_min_bot)] , Sv_reg_lin(Mask_reg_min_bot) , size(Mask_reg_sub) , @sum , 0 ) * dr;
        sub_output.eint = eint_sparse;
        sub_output.sd_Sv = accumarray( [y_mat_idx(Mask_reg_min_bot) x_mat_idx(Mask_reg_min_bot)] , Sv_reg(Mask_reg_min_bot) , size(Mask_reg_sub) , @std , 0 );
    else
        eint_sparse=zeros(N_y,N_x);
        sub_output.nb_samples=zeros(N_y,N_x);
        sub_output.eint=zeros(N_y,N_x);
        sub_output.sd_Sv=zeros(N_y,N_x);
        Mask_reg_sub = (sub_output.nb_samples==0);
    end


    idx_mat=repmat((1:size(y_mat_idx,1))',1,size(y_mat_idx,2));

    idx_s_min = accumarray( [y_mat_idx(:) x_mat_idx(:)] ,idx_mat(:), [N_y N_x] , @min , nan);
    idx_s_max = accumarray( [y_mat_idx(:) x_mat_idx(:)] ,idx_mat(:), [N_y N_x] , @max , nan);

    idx_mask=(isnan(idx_s_max));
    idx_s_max(idx_mask)=[];
    idx_s_min(idx_mask)=[];

    sub_output.Vert_Slice_Idx = accumarray( x_mat_idx(1,:)' , slice_idx(:) , [N_x 1] , @min , 0)';
    sub_output.Horz_Slice_Idx = accumarray( [y_mat_idx(:) x_mat_idx(:)] ,y_mat_idx(:)+iy1-1, [N_y N_x] , @(x) min(x,[],'omitnan') , 0);

    % first and last ping in each cell
    sub_output.Ping_S    = accumarray( x_mat_idx(1,:)' , sub_pings(:) , [N_x 1] , @min , nan)';
    sub_output.Ping_E    = accumarray( x_mat_idx(1,:)' , sub_pings(:) , [N_x 1] , @max , nan)';

    % number of pings not flagged as bad transmits, in each cell
    sub_output.Nb_good_pings = repmat(accumarray(x_mat_idx(1,:)',(bad_trans_vec(:))==0,[N_x 1],@sum,0),1,N_y)';

    % first and last sample in each cell
    sub_output.Sample_S=nan(N_y,N_x);
    sub_output.Sample_E=nan(N_y,N_x);

    sub_output.Sample_S(~idx_mask)=sub_samples(idx_s_min);
    sub_output.Sample_E(~idx_mask)=sub_samples(idx_s_max);

    sub_output.Range_min=nan(N_y,N_x);
    sub_output.Range_max=nan(N_y,N_x);

    sub_output.Range_min(~isnan(sub_output.Sample_S))=trans_obj.get_samples_range(sub_output.Sample_S(~isnan(sub_output.Sample_S)));
    sub_output.Range_max(~isnan(sub_output.Sample_E))=trans_obj.get_samples_range(sub_output.Sample_E(~isnan(sub_output.Sample_E)));

    % minimum and maximum depth of samples in each cell
    sub_output.Depth_min = accumarray([y_mat_idx(:) x_mat_idx(:)],sub_depth(:),size(Mask_reg_sub),@min,nan);
    sub_output.Depth_max = accumarray([y_mat_idx(:) x_mat_idx(:)],sub_depth(:),size(Mask_reg_sub),@max,nan);

    % average depth of each cell
    sub_output.Depth_mean = (sub_output.Depth_min+sub_output.Depth_max)/2;

    sub_output.Dist_to_bot_min = accumarray([y_mat_idx(:) x_mat_idx(:)],sub_dist_from_bot(:),size(Mask_reg_sub),@min,nan);
    sub_output.Dist_to_bot_max = accumarray([y_mat_idx(:) x_mat_idx(:)],sub_dist_from_bot(:),size(Mask_reg_sub),@max,nan);
    sub_output.Dist_to_bot_mean = (sub_output.Dist_to_bot_min+sub_output.Dist_to_bot_max)/2;

    % minimum and maximum range of samples in each cell (referenced to the transducer, surface, bottom or line)

    sub_output.Range_ref_min = accumarray([y_mat_idx(:) x_mat_idx(:)],y_mat(:),size(Mask_reg_sub),@min,nan);
    sub_output.Range_ref_max = accumarray([y_mat_idx(:) x_mat_idx(:)],y_mat(:),size(Mask_reg_sub),@max,nan);

    % "thickness" (height of each cell)
    sub_output.Thickness_tot = abs(sub_output.Range_ref_max-sub_output.Range_ref_min)+dr;
    sub_output.Thickness_mean = (sub_output.nb_samples)./sub_output.Nb_good_pings*dr;

    sub_output.Dist_S = accumarray(x_mat_idx(1,:)',sub_dist(:),[N_x 1],@min,nan)';
    sub_output.Dist_E = accumarray(x_mat_idx(1,:)',sub_dist(:),[N_x 1],@max,nan)';

    sub_output.Time_S = accumarray(x_mat_idx(1,:)',sub_time(:),[N_x 1],@min,nan)';
    sub_output.Time_E = accumarray(x_mat_idx(1,:)',sub_time(:),[N_x 1],@max,nan)';

    sub_output.Lat_S = accumarray(x_mat_idx(1,:)',sub_lat(:),[N_x 1],@min,nan)';
    sub_output.Lon_S = accumarray(x_mat_idx(1,:)',sub_lon(:),[N_x 1],@min,nan)';

    sub_output.Lat_E = accumarray(x_mat_idx(1,:)',sub_lat(:),[N_x 1],@max,nan)';
    sub_output.Lon_E = accumarray(x_mat_idx(1,:)',sub_lon(:),[N_x 1],@max,nan)';


    sub_output.PRC = sub_output.nb_samples*dr./((sub_output.Ping_E-sub_output.Ping_S+1).*sub_output.Thickness_tot);

    sub_output.sv  = eint_sparse./(sub_output.nb_samples*dr);
    sub_output.sv(sub_output.nb_samples==0)=0;


    sub_output.ABC = sub_output.Thickness_mean.*sub_output.sv;
    sub_output.NASC = 4*pi*1852^2*sub_output.ABC;
    sub_output.Lon_S(sub_output.Lon_S>180) = sub_output.Lon_S(sub_output.Lon_S>180)-360;
    sub_output.Lon_E(sub_output.Lon_E>180) = sub_output.Lon_E(sub_output.Lon_E>180)-360;

    if ui==idx_ite_x(1)
        output = structfun(@(x) init_fields(x,N_y_tot,N_x_tot),sub_output,'un',0);
    end


    %     [N_y,N_x]=size(sub_output.nb_samples);
    %     output = structfun(@(y,x) complete_fields(y,x,iy1,ix1,N_y,N_x),output,sub_output,'un',0);
    %
    output=complete_ouput(output,sub_output,iy1,ix1);

    if ~isempty(load_bar_comp)
        ub=ub+1;
        set(load_bar_comp.progress_bar, 'Value',ub);
    end
end

if isempty(output)
    return;
end

[N_y_tot,N_x_tot]=size(output.nb_samples);
output.nb_st=zeros(N_y_tot,N_x_tot);
output.nb_tracks=zeros(N_y_tot,N_x_tot);
output.st_ts_mean=-999*ones(N_y_tot,N_x_tot);
output.nb_tracks=zeros(N_y_tot,N_x_tot);
output.tracks_ts_mean=-999*ones(N_y_tot,N_x_tot);
tracks_struct=trans_obj.Tracks;

if ~isempty(trans_obj.ST.TS_comp)
    for ii=1:N_y_tot
        for jj=1:N_x_tot
            if output.sv(ii,jj)==0||isnan(output.sv(ii,jj)==0)
                continue;
            end

            switch region.Reference
                case 'Surface'
                    idx_st=find(trans_obj.ST.Target_depth>=output.Depth_min(ii,jj)&trans_obj.ST.Target_depth<output.Depth_max(ii,jj)&...
                        trans_obj.ST.Ping_number>=output.Ping_S(jj)&trans_obj.ST.Ping_number<output.Ping_E(jj));
                case 'Transducer'
                    idx_st=find(trans_obj.ST.Target_range>=output.Range_ref_min(ii,jj)&trans_obj.ST.Target_range<output.Range_ref_max(ii,jj)&...
                        trans_obj.ST.Ping_number>=output.Ping_S(jj)&trans_obj.ST.Ping_number<output.Ping_E(jj));
                case 'Bottom'
                    idx_st=find(trans_obj.ST.Target_range_to_bottom>=-output.Range_ref_max(ii,jj)&trans_obj.ST.Target_range_to_bottom<-output.Range_ref_min(ii,jj)&...
                        trans_obj.ST.Ping_number>=output.Ping_S(jj)&trans_obj.ST.Ping_number<output.Ping_E(jj));
                case 'Line'
                    idx_st=find(trans_obj.ST.Target_range-line_ref_tot(trans_obj.ST.Ping_number)>=output.Range_ref_min(ii,jj)&trans_obj.ST.Target_range-line_ref_tot(trans_obj.ST.Ping_number)<output.Range_ref_max(ii,jj)&...
                        trans_obj.ST.Ping_number>=output.Ping_S(jj)&trans_obj.ST.Ping_number<output.Ping_E(jj));
            end

            output.nb_st(ii,jj)=numel(idx_st);

            if ~isempty(idx_st)
                output.st_ts_mean(ii,jj) = pow2db(mean(db2pow(trans_obj.ST.TS_comp(idx_st)),'omitnan'));
                if ~isempty(tracks_struct)
                    idx_tracks=cellfun(@(var) any(ismember(var,idx_st)),tracks_struct.target_id);
                    if any(idx_tracks)
                        output.tracks_ts_mean(ii,jj) = pow2db(mean(cellfun(@(x) mean(db2pow(trans_obj.ST.TS_comp(x)),'omitnan'),tracks_struct.target_id(idx_tracks)),'omitnan'));
                        tracks_struct.target_id(idx_tracks)=[];
                        output.nb_tracks(ii,jj)=sum(idx_tracks,'omitnan');
                    end

                end
            end
        end
    end
end


%remove empty vertical slices (no data in those)
fields = fieldnames(output);
for ifi = 1:length(fields)
    output.(fields{ifi})(:,idx_x_empty) = [];
end

if p.Results.keep_all==0
    [N_y,N_x]=size(output.sv);
    idx_rem = [];

    idx_zeros_start =  find(sum(output.sv,2,'omitnan')>0,1);

    if idx_zeros_start>1
        idx_rem = union(idx_rem,1:idx_zeros_start-1);
    end

    idx_zeros_end = find(flipud(sum(output.sv,2,'omitnan')>0),1);
    if idx_zeros_end>1
        idx_rem = union(idx_rem,N_y-((1:idx_zeros_end-1)-1));
    end

    for ifi = 1:length(fields)
        if size(output.(fields{ifi}),1) == N_y
            output.(fields{ifi})(idx_rem,:) = [];
        end
    end

    idx_rem = [];
    idx_zeros_start = find(sum(output.sv,1,'omitnan')>0,1);
    if idx_zeros_start>1
        idx_rem = union(idx_rem,1:idx_zeros_start-1);
    end

    idx_zeros_end = find(fliplr(sum(output.sv,2,'omitnan')>0),1);
    if idx_zeros_end>1
        idx_rem = union(idx_rem,N_x-((1:idx_zeros_end-1)-1));
    end

    for ifi = 1:length(fields)
        output.(fields{ifi})(:,idx_rem) = [];
    end
end

switch trans_obj.Mode
    case 'FM'
        [N_y,N_x]=size(output.sv);
        cal = p.Results.cal;

        if isempty(cal)
            cal = trans_obj.get_transceiver_fm_cal();
        end
        envdata = p.Results.envdata;
        if isempty(envdata)
            envdata = env_data_cl();
        end

        win_fact = 3;
        ps = repmat(output.Ping_S,N_y,1);
        pe = repmat(output.Ping_E,N_y,1);
        ss = output.Sample_S;
        se = output.Sample_E;
        output.Sv_fm= cell(N_y,N_x);
        output.sd_Sv_fm = cell(N_y,N_x);
        output.f_fm = cell(N_y,N_x);
        output.r_fm = cell(N_y,N_x);

        if ~isempty(load_bar_comp)
            load_bar_comp.progress_bar.setText(sprintf('Channel %s: FM processing %s',trans_obj.Config.ChannelID,region.print()));
            set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',N_x, 'Value',0);
        end
        for jj = 1:N_x
            for ii = 1:N_y

                if pow2db_perso(output.sv(ii,jj))>p.Results.sv_thr&&output.sv(ii,jj)>0
                    [sv_tmp,f_tmp,r_tmp]=arrayfun(@(iP) trans_obj.processSv_f_r_2(envdata,iP,trans_obj.get_samples_range(ss(ii,jj):se(ii,jj)),win_fact,cal,'2D',0),...
                        ps(ii,jj):pe(ii,jj),...
                        'un',0);
                    output.Sv_fm{ii,jj} = pow2db_perso(mean(db2pow(cell2mat(sv_tmp')),1,'omitnan'));
                    output.sd_Sv_fm{ii,jj} = std(cell2mat(sv_tmp'),0,1,'omitnan');
                    output.f_fm{ii,jj}  = f_tmp{1};
                    output.r_fm{ii,jj} = r_tmp{1};
                end

            end
            if ~isempty(load_bar_comp)
                set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',N_x, 'Value',jj);
            end
        end
end

output.Sample_S(output.Sample_S == 0) = nan;
output.Sample_E(output.Sample_E == 0) = nan;


if use_tall
    output.Tags=tall(strings(size(output.eint)));

    for ifi = 1:length(fields)
        if all(size(output.(fields{ifi}))>1)
            output.(fields{ifi}) = tall(output.(fields{ifi}));
        end
    end
else
    output.Tags=strings(size(output.eint));
end
output.Tag_str = unique(output.Tags);
output.Tag_cmap = randi(64,[numel(output.Tag_str),3])/64;
output.Tag_descr = string(size(output.Tag_str));

if PROF
    profile off;
    profile viewer;
end

if ~isempty(load_bar_comp)
    load_bar_comp.progress_bar.setText('');
end
end


function y=init_fields(x,N_y_tot,N_x_tot)
if all(size(x)>1)
    y=nan(N_y_tot,N_x_tot);
elseif size(x,1)==1
    y=nan(1,N_x_tot);
elseif size(x,2)==1
    y=nan(N_y_tot,1);
end
end
%
%
% function y=complete_fields(y,x,y1,x1,N_y,N_x)
%
%     if isa(x,'gpuArray')
%         x=gather(x);
%     end
%
%     if all(size(x)>1)&& ~isnan(x1) && ~isnan(y1)
%         y(y1:(y1+N_y-1),x1:(x1+N_x-1))=x;
%     elseif size(x,1)==1&&size(x,2)==N_x && ~isnan(x1)
%         y(x1:(x1+N_x-1))=x;
%     elseif size(x,2)==1&&size(x,1)==N_y && ~isnan(y1)
%         y(y1:(y1+N_y-1))=x;
%     end
%
% end

function output=complete_ouput(output,sub_output,y1,x1)
[N_y,N_x]=size(sub_output.nb_samples);

fields = fieldnames(sub_output);

for ifi=1:numel(fields)
    if isa(sub_output.(fields{ifi}),'gpuArray')
        sub_output.(fields{ifi})=gather(sub_output.(fields{ifi}));
    end

    if all(size(sub_output.(fields{ifi}))==[N_y,N_x])&& ~isnan(x1) && ~isnan(y1)
        output.(fields{ifi})(y1:(y1+N_y-1),x1:(x1+N_x-1))=sub_output.(fields{ifi});
    elseif size(sub_output.(fields{ifi}),1)==1&&size(sub_output.(fields{ifi}),2)==N_x && ~isnan(x1)
        output.(fields{ifi})(x1:(x1+N_x-1))=sub_output.(fields{ifi});
    elseif size(sub_output.(fields{ifi}),2)==1&&size(sub_output.(fields{ifi}),1)==N_y && ~isnan(y1)
        output.(fields{ifi})(y1:(y1+N_y-1))=sub_output.(fields{ifi});
    end
end
end
