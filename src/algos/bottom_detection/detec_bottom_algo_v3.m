%% detec_bottom_algo_v3.m
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
% TODO
%
% *OUTPUT VARIABLES*
%
% TODO
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-04-02: header (Alex Schimel).
% * YYYY-MM-DD: first version (Yoann Ladroit). TODO: complete date and comment
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function output_struct=detec_bottom_algo_v3(trans_obj,varargin)

%profile on;
%Parse Arguments

p = inputParser;

default_idx_r_min=0;

default_idx_r_max=Inf;

default_thr_bottom=-35;
check_thr_bottom=@(x)(x>=-120&&x<=-3);

default_thr_backstep=-1;
check_thr_backstep=@(x)(x>=-12&&x<=12);

check_shift_bot=@(x) isnumeric(x);
check_filt=@(x)(x>=0)||isempty(x);

addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addParameter(p,'denoised',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'r_min',default_idx_r_min,@isnumeric);
addParameter(p,'r_max',default_idx_r_max,@isnumeric);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'thr_bottom',default_thr_bottom,check_thr_bottom);
addParameter(p,'thr_backstep',default_thr_backstep,check_thr_backstep);
addParameter(p,'v_filt',10,check_filt);
addParameter(p,'h_filt',10,check_filt);
addParameter(p,'shift_bot',0,check_shift_bot);
addParameter(p,'interp_method','none');
addParameter(p,'rm_outliers_method','none');
addParameter(p,'load_bar_comp',[]);
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
parse(p,trans_obj,varargin{:});

output_struct.done =  false;



if isempty(p.Results.reg_obj)
    idx_r=1:length(trans_obj.get_samples_range());
    idx_ping_tot=1:length(trans_obj.get_transceiver_pings());
    reg_obj=region_cl('Name','Temp','Idx_r',idx_r,'Idx_ping',idx_ping_tot);
else
    reg_obj = p.Results.reg_obj;
    idx_ping_tot=reg_obj.Idx_ping;
    idx_r=reg_obj.Idx_r;
end

[~,Np]=trans_obj.get_pulse_Teff(1);
[~,Np_p]=trans_obj.get_pulse_length(1);

idx_r(idx_r<2*max(Np_p))=[];


range_tot = trans_obj.get_samples_range(idx_r);

if ~isempty(idx_r)
    idx_r(range_tot<p.Results.r_min|range_tot>p.Results.r_max)=[];
end

output_struct.bottom=[];
output_struct.bot_mask = [];
output_struct.bs_bottom=[];
output_struct.idx_bottom=[];
output_struct.idx_ping=[];

if isempty(idx_r)
    disp_perso([],'Nothing to detect bottom from...');

    return;
end

bot_idx_tot=nan(1,numel(idx_ping_tot));
BS_bottom_tot=nan(1,numel(idx_ping_tot));

block_len = get_block_len(50,'cpu',p.Results.block_len);


block_size=min(ceil(block_len/numel(idx_r)),numel(idx_ping_tot));
num_ite=ceil(numel(idx_ping_tot)/block_size);


range_tot= trans_obj.get_samples_range(idx_r);
dr=mean(diff(range_tot));

thr_bottom=p.Results.thr_bottom;
thr_backstep=p.Results.thr_backstep;
r_min = max(p.Results.r_min,(0.05*range(range_tot)+range_tot(1)));
r_max=p.Results.r_max;

thr_echo=-35;
thr_cum=1;
load_bar_comp=p.Results.load_bar_comp;

if p.Results.denoised > 0
    field = 'svdenoised';
    alt_fields = {'sv','spdenoised','sp','img_intensity'};
else
    field = 'sv';
    alt_fields = {'sp','img_intensity'};
end

if ~isempty(p.Results.load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
end
idx_r_ori = idx_r;
sub_r = 10*Np;
sub_p = ceil(block_size/50);

for ui=1:num_ite
    idx_ping=idx_ping_tot((ui-1)*block_size+1:min(ui*block_size,numel(idx_ping_tot)));

    [data,field] = trans_obj.get_data_to_process('field',field,'alt_fields',alt_fields,'idx_r',idx_r_ori(1:sub_r:end),'idx_ping',idx_ping(1:sub_p:end));

    if isempty(data)
        return;
    end

    switch lower(field)
        case {'sp' 'spdenoised'}
            BS = data-10*log10(range_tot(1:sub_r:end));
        case {'sv' 'svdenoised'}
            BS = data+10*log10(range_tot(1:sub_r:end));
        otherwise
            BS = data;
    end

    BS_max = max(BS,[],2,'omitnan');

    idx_r_0 = find(BS_max>max(BS_max,[],'omitnan')+thr_echo,1,'first');
    idx_r_1 = find(BS_max>max(BS_max,[],'omitnan')+thr_echo,1,'last');
    sub_idx = idx_r_0*sub_r-2*sub_r:idx_r_1*sub_r;
    sub_idx(sub_idx<1) = 1;
    sub_idx(sub_idx>numel(idx_r_ori)) = numel(idx_r_ori);

    sub_idx = unique(sub_idx);

    if isempty(sub_idx)
        continue;
    end

    range_new = range_tot(sub_idx);
    idx_r = idx_r_ori(sub_idx);


    reg_temp=region_cl('Name','Temp','Idx_r',idx_r,'Idx_ping',idx_ping);

    [data,idx_r,idx_ping,idx_beam,bad_data_mask,bad_trans_vec,mask,~,~]=get_data_from_region(trans_obj,reg_temp,...
        'field',field,'alt_fields',alt_fields,...
        'intersect_only',1,...
        'regs',reg_obj);

    data(mask==0|isinf(data)|bad_data_mask|bad_trans_vec)=-999;

    [nb_samples,nb_pings]=size(data);

    if r_max==Inf
        idx_r_max=nb_samples;
    else
        [~,idx_r_max]=min(abs(r_max+p.Results.v_filt-range_new));
        idx_r_max=min(idx_r_max,nb_samples);
        idx_r_max=max(idx_r_max,10);
    end

    [~,idx_r_min]=min(abs(r_min-p.Results.v_filt-range_new));
    idx_r_min=max(idx_r_min,10);
    idx_r_min=min(idx_r_min,nb_samples);

    ringdown=trans_obj.Data.get_subdatamat('idx_r',ceil(Np/3),'idx_ping',idx_ping,'field','power');
    if isempty(ringdown)
        ringdown = trans_obj.Data.get_subdatamat('idx_r',ceil(Np/3),'idx_ping',idx_ping,'field','sv');
    end
    RingDown=pow2db_perso(ringdown);

    data(1:idx_r_min,:)=nan;
    data(idx_r_max:end,:)=nan;

    %First let's find the bottom...

    heigh_b_filter=floor(p.Results.v_filt/dr)+1;

    b_filter=ceil(min(10,nb_pings/10));


    field = strrep(field,'denoised','');

    switch lower(field)
        case {'sp' 'spdenoised'}
            BS = data-10*log10(range_new);
        case {'sv' 'svdenoised'}
            BS = data+10*log10(range_new);
        otherwise
            BS = data;
    end

    BS(isnan(BS))=-999;
    BS_ori=BS;


 
    BS_lin=10.^(BS/10);
    BS_lin(isnan(BS_lin))=0;

    BS_lin_red=BS_lin(idx_r_min:idx_r_max,:);


    filter_fun = @(block_struct) max(block_struct.data(:));
    BS_filtered_bot_lin=blockproc(BS_lin_red,[heigh_b_filter b_filter],filter_fun);
    [nb_samples_red,~]=size(BS_filtered_bot_lin);

    BS_filtered_bot=10*log10(BS_filtered_bot_lin);
    BS_filtered_bot_lin(isnan(BS_filtered_bot_lin))=0;

    cumsum_BS=cumsum((BS_filtered_bot_lin),1,'omitnan');
    cumsum_BS(cumsum_BS<=eps)=nan;

    if size(cumsum_BS,1)>1
        diff_cum_BS=diff(10*log10(cumsum_BS),1,1);
    else
        diff_cum_BS=zeros(size(cumsum_BS));
    end
    diff_cum_BS(isnan(diff_cum_BS))=0;

    [~,idx_max_diff_cum_BS]=max(diff_cum_BS,[],1);

    idx_start=idx_max_diff_cum_BS-1;
    idx_end=idx_max_diff_cum_BS+3;

    bot_idx_region=(bsxfun(@ge,(1:nb_samples_red)',idx_start)&bsxfun(@le,(1:nb_samples_red)',idx_end));

    max_bs=max(BS_filtered_bot);
    Max_BS_reg=(bsxfun(@gt,BS_filtered_bot,max_bs+thr_echo));
    Max_BS_reg(:,max_bs<thr_bottom)=0;
    bot_idx_region=ceil(filter(ones(1,3)/3,1,bot_idx_region));

    bot_idx_region=find_cluster((bot_idx_region>0&BS_filtered_bot>=thr_bottom&Max_BS_reg),1);


    bot_idx_region_red=imresize(bot_idx_region,size(BS_lin_red),'nearest');
    bot_idx_region=zeros(size(BS_lin));
    bot_idx_region(idx_r_min:idx_r_max,:)=bot_idx_region_red;

    n_permut=min(floor((heigh_b_filter+1)/4),nb_samples);
    Permut=[nb_samples-n_permut+1:nb_samples 1:nb_samples-n_permut];

    bot_idx_region=bot_idx_region(Permut,:);
    bot_idx_region(1:n_permut,:)=0;

    idx_bottom=bsxfun(@times,bot_idx_region,(1:nb_samples)');
    idx_bottom(~bot_idx_region)=nan;
    idx_bottom(end,(sum(idx_bottom,'omitnan')==0))=nb_samples;


    %     [I_bottom,J_bottom]=find(~isnan(idx_bottom));
    %
    %     I_bottom(I_bottom>nb_samples)=nb_samples;
    %
    %     J_double_bottom=[J_bottom ; J_bottom ; J_bottom];
    %     I_double_bottom=[I_bottom ; 2*I_bottom ; 2*I_bottom+1];
    %     I_double_bottom(I_double_bottom > nb_samples)=nan;
    %     idx_double_bottom=I_double_bottom(~isnan(I_double_bottom))+nb_samples*(J_double_bottom(~isnan(I_double_bottom))-1);
    %     Double_bottom=nan(nb_samples,nb_pings);
    %     Double_bottom(idx_double_bottom)=1;
    %     Double_bot_idx_region=~isnan(Double_bottom);

    %%%%%%%%%%%%%%%%%%%%%Bottom detection and BS analysis%%%%%%%%%%%%%%%%%%%%%%


    BS_lin_norm=bsxfun(@rdivide,bot_idx_region.*BS_lin,sum(bot_idx_region.*BS_lin,'omitnan'));


    BS_lin_norm_bis=BS_lin_norm;
    BS_lin_norm_bis(isnan(BS_lin_norm))=0;
    BS_lin_cumsum=(cumsum(BS_lin_norm_bis,1,'omitnan')./repmat(sum(BS_lin_norm_bis,'omitnan'),size(bot_idx_region,1),1));
    BS_lin_cumsum(BS_lin_cumsum<thr_cum/100)=Inf;
    [~,bot_idx_temp]=min((abs(BS_lin_cumsum-thr_cum/100)));
    bot_idx_temp_2=min(idx_bottom);
    bot_idx=max(bot_idx_temp,bot_idx_temp_2);

    backstep=max([1 Np]);

    for iuu=1:nb_pings

        BS_ping=BS_ori(:,iuu);
        if bot_idx(iuu)>2*backstep
            bot_idx(iuu)=bot_idx(iuu)-backstep;
            if bot_idx(iuu)>backstep
                [bs_val,idx_max_tmp]=max(BS_ping((bot_idx(iuu)-backstep):bot_idx(iuu)-1));
            else
                continue;
            end

            while bs_val>=BS_ping(bot_idx(iuu))+thr_backstep &&bs_val>-999
                if bot_idx(iuu)-(backstep-idx_max_tmp+1)>0
                    bot_idx(iuu)=bot_idx(iuu)-(backstep-idx_max_tmp+1);
                end
                if bot_idx(iuu)>backstep
                    [bs_val,idx_max_tmp]=max(BS_ping((bot_idx(iuu)-backstep):bot_idx(iuu)-1));
                else
                    break;
                end
            end
        end
    end

    % figure();plot(bot_idx_temp)
    % hold on;plot(bot_idx_temp_2)
    % plot(bot_idx);

    bot_idx(bot_idx==1)=nan;
    bot_idx(min(idx_bottom)>=max(1,nb_samples-round(heigh_b_filter)/2))=nan;

    BS_filter=(20*log10(filter(ones(4*Np,1)/(4*Np),1,10.^(BS/20)))).*bot_idx_region;
    BS_filter(bot_idx_region==0)=nan;

    BS_bottom=max(BS_filter);
    BS_bottom(isnan(bot_idx))=nan;

    bot_idx=bot_idx- ceil(p.Results.shift_bot./max(diff(range_new)));
    bot_idx(bot_idx<=0)=1;

    idx_ping=idx_ping-idx_ping_tot(1)+1;
    % profile off;
    % profile viewer;


    bot_idx_tot(idx_ping)=bot_idx+idx_r(1)-1;
    BS_bottom_tot(idx_ping)=BS_bottom;

    if ~isempty(p.Results.load_bar_comp)
        set(p.Results.load_bar_comp.progress_bar, 'Value',ui);
    end
end

output_struct.bottom=floor(bot_idx_tot+Np/2);
output_struct.bs_bottom=BS_bottom_tot;
output_struct.idx_ping=idx_ping_tot;

old_tag = trans_obj.Bottom.Tag;
old_bot = trans_obj.Bottom.Sample_idx;
old_bot(idx_beam,output_struct.idx_ping) = output_struct.bottom;

new_bot = bottom_cl('Origin','Algo_v3',...
    'Sample_idx',old_bot,...
    'Tag',old_tag);

trans_obj.Bottom = new_bot;

trans_obj.clean_bottom('idx_ping',idx_ping_tot,'idx_beam',[],'interp_method',p.Results.interp_method,'rm_outliers_method',p.Results.rm_outliers_method);

output_struct.bottom = trans_obj.Bottom.Sample_idx;
output_struct.idx_ping = idx_ping_tot;
output_struct.done =  true;

% profile off;
% profile viewer;
output_struct.done =  true;
end


