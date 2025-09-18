%% detec_bottom_algo_v4.m
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
% * 2018-08-07: fully commented (Alex Schimel)
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
function output_struct=detec_bottom_algo_v4(trans_obj,varargin)

%% Input parser
%profile on;
% initialize
p = inputParser;

% defaults and checking functions
default_idx_r_min = 0;
default_idx_r_max = Inf;
default_thr_bottom = -35;
check_thr_bottom = @(x)(x>=-120&&x<=50);
default_thr_backstep = -1;
check_thr_backstep = @(x)(x>=-12&&x<=12);
check_shift_bot = @(x) isnumeric(x);
check_thr_cum = @(x)(x>=0&&x<=100);

% adding to parser
addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addParameter(p,'denoised',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'r_min',default_idx_r_min,@isnumeric);
addParameter(p,'r_max',default_idx_r_max,@isnumeric);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'thr_bottom',default_thr_bottom,check_thr_bottom);
addParameter(p,'thr_backstep',default_thr_backstep,check_thr_backstep);
addParameter(p,'thr_echo',-35,check_thr_bottom);
addParameter(p,'thr_cum',1,check_thr_cum);
addParameter(p,'shift_bot',0,check_shift_bot);
addParameter(p,'interp_method','none');
addParameter(p,'rm_outliers_method','none');
addParameter(p,'load_bar_comp',[]);
addParameter(p,'block_len',0,@(x) x>0 || isempty(x));

% and parse
parse(p,trans_obj,varargin{:});

output_struct.done =  false;

block_len = get_block_len(50,'cpu',p.Results.block_len);

if isempty(p.Results.reg_obj)
    idx_r=1:length(trans_obj.get_samples_range());
    idx_ping_tot=1:length(trans_obj.get_transceiver_pings());
    reg_obj=region_cl('Name','Temp','Idx_r',idx_r,'Idx_ping',idx_ping_tot);
else
    reg_obj = p.Results.reg_obj;
    idx_ping_tot=reg_obj.Idx_ping;
    idx_r=reg_obj.Idx_r;
end

% pulse length
[~,Np_all] = trans_obj.get_pulse_Teff(idx_ping_tot);
[~,Np_p_all] = trans_obj.get_pulse_length(idx_ping_tot);

Np_p_max = max(Np_p_all,[],'all','omitnan');

% remove from calculation samples to close to start of record
idx_r(idx_r<2*Np_p_max) = [];

% get range corresponding to samples
range_tot = trans_obj.get_samples_range(idx_r);

if ~isempty(idx_r)
    idx_r(range_tot<p.Results.r_min|range_tot>p.Results.r_max)=[];
end

output_struct.bottom=[];
output_struct.bot_mask = [];
output_struct.bs_bottom=[];
output_struct.idx_bottom=[];
output_struct.idx_ringdown=[];
output_struct.idx_ping=[];

% bail with those empty results if not enough samples
if isempty(idx_r)
    disp_perso([],'Nothing to detect bottom from...');
    return;
end

range_tot = trans_obj.get_samples_range(idx_r);
idx_beams = trans_obj.get_idx_beams([-inf inf]);
% inititialize results
bot_idx_tot = nan(numel(idx_beams),numel(idx_ping_tot));
BS_bottom_tot = nan(numel(idx_beams),numel(idx_ping_tot));
bot_mask_tot = false(numel(range_tot),numel(idx_ping_tot),numel(idx_beams));

% processing is done in block. Calculate block size and number of
% iterations

block_size = min(ceil(block_len/numel(idx_r)),numel(idx_ping_tot));
num_ite = ceil(numel(idx_ping_tot)/block_size);

% udpate prgoress bar
if ~isempty(p.Results.load_bar_comp)
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite*numel(idx_beams), 'Value',0);
end

if isempty(idx_r)
    idx_r = (1:numel(range_tot))';
end

idx_r_ori = idx_r;

if p.Results.denoised > 0
    field = 'svdenoised';
    alt_fields = {'sv','spdenoised','sp','img_intensity'};
else
    field = 'sv';
    alt_fields = {'sp','img_intensity'};
end

% get parameters

thr_backstep = p.Results.thr_backstep;
r_max = p.Results.r_max;
thr_echo = p.Results.thr_echo;
thr_cum  = p.Results.thr_cum/100; % thr_cum in percentage

sub_p = min(numel(idx_ping_tot),5);
sub_p = min(ceil(block_size/100),sub_p);
% block processing loop
[faBW,psBW] = trans_obj.get_beamwidth_at_f_c([]);

for uib = idx_beams'
    Np = max(Np_all(:,:,uib),[],'all','omitnan');
    Np_p = max(Np_p_all(:,:,uib),[],'all','omitnan');

    switch trans_obj.Mode
        case 'FM'
            win_size=max(floor(Np/2),5);
        case 'CW'
            win_size=max(Np,5);
    end

    sub_r = Np;
    for ui = 1:num_ite

        % pings for this block
        idx_ping = idx_ping_tot(max((ui-1)*block_size+1-sub_p,1):min(ui*block_size+sub_p,numel(idx_ping_tot)));

        t_angle = trans_obj.get_beams_pointing_angles(idx_ping,uib);
        thr_bottom = p.Results.thr_bottom-pow2db(1./cosd(abs(90-t_angle)).^2);

        [data,field] = trans_obj.get_data_to_process('field',field,'alt_fields',alt_fields,...
            'idx_r',idx_r_ori(1:sub_r:end),'idx_ping',idx_ping(1:sub_p:end),'idx_beam',idx_beams(uib));

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

        % nb_comp_max = 2;
        % 
        % win_size_p = 11;
        % win_size_p = min(win_size_p,size(BS,2));
        % ip_ite  = floor(win_size_p/2):win_size_p:size(BS,2)-floor(win_size_p/2);
        % thr_bottom_new = nan(1,numel(ip_ite));
        % numComponents = nan(1,numel(ip_ite));
        % ip = 0;
        % for ipp = ip_ite
        %     ip = ip+1;
        %     ip_bs = abs((1:size(BS,2))-ipp)<win_size_p/2;
        %     BS_tmp = BS(:,ip_bs);
        %     AIC = inf(1,nb_comp_max);
        %     GMModels = cell(1,nb_comp_max);
        %     options = statset('MaxIter',50);
        %     for k = 1:nb_comp_max
        %         GMModels{k} = fitgmdist(BS_tmp(:),k,'Options',options,'CovarianceType','diagonal');
        %         if GMModels{k}.Converged
        %             AIC(k)= GMModels{k}.AIC;
        %         else
        %             AIC(k) = inf;
        %             break;
        %         end
        %     end
        % 
        %     [minAIC,numComponents(ip)] = min(AIC);
        % 
        %     xpdf = linspace(min(BS_tmp(:),[],"all"),max(BS_tmp(:),[],"all"),100)';
        %     % figure();histogram(BS_tmp(:),100,'Normalization','pdf');hold on;plot(xpdf,pdf(GMModels{numComponents(ip)},xpdf));
        %     % figure();plot(xpdf,cdf(GMModels{numComponents(ip)},xpdf));
        % 
        %     [~,idx_thr] = min(abs(cdf(GMModels{numComponents(ip)},xpdf)-0.99));
        %     thr_bottom_new(ip) = xpdf(idx_thr);
        % end
        % 
        % thr_bottom = max(prctile(thr_bottom_new,10)-pow2db(1./cosd(abs(90-t_angle)).^2),thr_bottom);

        idx_r_0 = find(BS_max>thr_bottom+thr_echo,1,'first');
        idx_r_1 = find(BS_max>thr_bottom+thr_echo,1,'last');
        
        sub_idx = idx_r_0*sub_r-2*sub_r:idx_r_1*sub_r+sub_r;
        sub_idx(sub_idx<1) = 1;
        sub_idx(sub_idx>numel(idx_r_ori)) = numel(idx_r_ori);

        sub_idx = unique(sub_idx);

        if isempty(sub_idx)
            continue;
        end

        range_new = range_tot(sub_idx);
        idx_r = idx_r_ori(sub_idx);

        %     fprintf('%.0f to %.0f instead of %.0f to %.0f\n',idx_r(1),idx_r(end),idx_r_ori(1),idx_r_ori(end))

        % mask data outside of region if processing for region/selection

        reg_temp=region_cl('Name','Temp','Idx_r',idx_r,'Idx_ping',idx_ping);

        [data,idx_r,idx_ping,~,bad_data_mask,bad_trans_vec,mask,~,~] = trans_obj.get_data_from_region(reg_temp,...
            'field',field,'alt_fields',alt_fields,...
            'idx_beam',idx_beams(uib),...
            'intersect_only',1,...
            'regs',reg_obj);

        % AlongAngle=trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'idx_beam',idx_beams(uib),'field','alongangle');
        % AcrossAngle=trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'idx_beam',idx_beams(uib),'field','acrossangle');
        % 
        % if contains(trans_obj.Config.TransceiverName,{'ES60' 'ES70''ER60'})
        %     AcrossPhi = (AcrossAngle+trans_obj.Config.AngleOffsetAthwartship)*trans_obj.Config.AngleSensitivityAthwartship*127/180;
        %     AlongPhi = (AlongAngle+trans_obj.Config.AngleOffsetAlongship)*trans_obj.Config.AngleSensitivityAlongship*127/180;
        % else
        %     AcrossPhi = (AcrossAngle+trans_obj.Config.AngleOffsetAthwartship)*trans_obj.Config.AngleSensitivityAlongship;
        %     AlongPhi = (AlongAngle+trans_obj.Config.AngleOffsetAlongship)*trans_obj.Config.AngleSensitivityAthwartship;
        % end

        % complex_across = db2pow(data).*exp(-1j*AcrossPhi/180*pi);
        % complex_along = db2pow(data).*exp(-1j*AlongPhi/180*pi);
        % 
        % M = 2048;
        % g = hann(M,"periodic");
        % L = 2000;
        % Ndft = 2048;
        % fs = 1/trans_obj.Params.SampleInterval(1);
        % 
        % [sp,fp,tp] = spectrogram(complex_along(:,1143)',g,L,Ndft,fs,"centered");
        % figure()
        % pcolor(fp,trans_obj.get_samples_range(idx_r(1))+tp*1500/2,20*log10(abs(sp')),'EdgeColor','none')
        % title("spectrogram")
        % caxis(prctile(20*log10(abs(sp(:)')),[95 100]))
        % view(2), axis tight
        % axis ij

        data(mask==0|isinf(data)|bad_data_mask|bad_trans_vec)=-999;
        % mask outside of region
        data(mask==0|isinf(data)) = nan;

        % mask the spikes too
        spikes =trans_obj.get_spikes(idx_r,idx_ping);

        if ~isempty(spikes)
            data(spikes>0) = nan;
        end
        r_min = p.Results.r_min;

        % get size of data
        [nb_samples,nb_pings] = size(data);

        % edit maximum range
        if r_max == Inf
            idx_r_max = nb_samples;
        else
            [~,idx_r_max] = min(abs(r_max-range_new),[],1,'omitnan');
            idx_r_max = min(idx_r_max,nb_samples,'omitnan');
            idx_r_max = max(idx_r_max,10,'omitnan');
        end

        % edit minimum range
        [~,idx_r_min] = min(abs(r_min-range_new),[],1,'omitnan');
        idx_r_min = max(idx_r_min,2*Np_p-idx_r(1),'omitnan');
        idx_r_min = min(idx_r_min,nb_samples,'omitnan');

        % remove data out of min and max range
        if idx_r_min>1
            data(1:idx_r_min-1,:) = nan;
        end
        if idx_r_max<numel(idx_r)
            data(idx_r_max+1:end,:) = nan;
        end


        % Turn TS into surface backscatter
        switch lower(field)
            case {'sp' 'spdenoised'}
                BS = data-10*log10(range_new);
            case {'sv' 'svdenoised'}
                BS = data+10*log10(range_new);
            otherwise
                BS = data;
        end

        % record as original before mods
        BS_ori = BS;
        BS_ori(isnan(BS)) = -999;

        % % max BS in ping
        [max_bs,idx_max] = max(BS,[],1,'omitnan');
        % figure();
        % imagesc(BS);hold on;
        % plot(idx_max,'r');
        % clim([thr_bottom+thr_echo thr_bottom]);

        % keep only samples whose BS is greater than the max minus thr_echo
        
        Bottom_region_temp = bsxfun(@gt,BS,max_bs+thr_echo);
                
        % remove pings where no sample has BS exceeding BS_thr:
        Bottom_region_temp(:,max_bs<thr_bottom) = false;

        % filter result to remove isolated bits and fill holes
        tmp = filter2_perso(ones(win_size,sub_p),single(Bottom_region_temp));
        Bottom_region_temp = tmp >= 0.2;

        idx_empty = sum(Bottom_region_temp,'omitnan')==0;
        Bottom_region_temp(:,idx_empty) = [];
        Bottom_region = false(size(BS));
        Bottom_region(:,~idx_empty) = Bottom_region_temp;

        %turn this into linear indexing
        [I_bottom,J_bottom] = find(Bottom_region);

        I_bottom(I_bottom>nb_samples) = nb_samples;

        % add to the list the samples at twice the distance, aka first multiple
        % of the bottom detect
        J_double_bottom = [J_bottom ; J_bottom];
        I_double_bottom = [2*(I_bottom+idx_r(1)-1)-idx_r(1) ; 2*(I_bottom+idx_r(1)-1)+1-idx_r(1)];
        I_double_bottom(I_double_bottom > nb_samples) = nan;

        % Index of places containing the double bottom echo
        idx_double_bottom = I_double_bottom(~isnan(I_double_bottom)) + nb_samples*(J_double_bottom(~isnan(I_double_bottom))-1);
        Double_bottom = nan(nb_samples,nb_pings);
        Double_bottom(idx_double_bottom) = 1;
        Double_bottom_region = ~isnan(Double_bottom);
        Bottom_region = Bottom_region & ~Double_bottom_region;

        % turn BS to linear
        BS_lin = 10.^(BS/10);

        BS_lin_masked_squared = BS_lin.^2;
        BS_lin_masked_squared(~Bottom_region) = nan;

        % normalized cumulative sum of this
        BS_lin_cumsum = bsxfun(@rdivide,cumsum(BS_lin_masked_squared,1,'omitnan'),sum(BS_lin_masked_squared,'omitnan'));

        % apply cumsum threshold:
        BS_lin_cumsum(BS_lin_cumsum<thr_cum) = nan;
        [~,bot_idx] = min(BS_lin_cumsum,[],1,'omitnan');
        
        %figure();plot(bot_idx_tmp);hold on;plot(bot_idx_ori);plot(bot_idx,'k');
        % 3. backstepping

        % backstep size is one pulse length, unless smaller than 2 sample
        backstep = max([4 Np]);

        for iip = 1:nb_pings
            BS_ping = BS_ori(:,iip);
            %         f=figure();ax=axes(f,'nextplot','add');plot(ax,BS_ping);
            %         vline=xline(ax,bot_idx(iip),'r');
            %         ylim(ax,[-80 -30]);
            % if bottom is not too close to start
            if bot_idx(iip) > 2*backstep

                if bot_idx(iip) > backstep
                    % find maximum BS in an interval ONE pulse length above bottom
                    [bs_val,idx_max_tmp] = max(BS_ping((bot_idx(iip)-backstep):bot_idx(iip)-1),[],'omitnan');
                else
                    % if bottom is too close to start, just exit
                    continue;
                end

                % if that BS value is valid and more than the bottom BS plus thr_backstep
                while bs_val >= (BS_ping(bot_idx(iip))+thr_backstep) && bs_val > thr_bottom(iip)+thr_echo+thr_backstep

                    if bot_idx(iip)-(backstep-idx_max_tmp+1) > 0
                        % move the bottom to that value
                        bot_idx(iip) = bot_idx(iip)-(backstep-idx_max_tmp+1);
                    end
                    %bot_idx(iip)
                    %vline.Value=bot_idx(iip);
                    if bot_idx(iip) > backstep
                        % calculate next value
                        [bs_val,idx_max_tmp] = max(BS_ping((bot_idx(iip)-backstep):bot_idx(iip)-1),[],'omitnan');
                    else
                        break;
                    end

                end
            end

            bot_idx(iip) =max(bot_idx(iip)-backstep,1,'omitnan');
        end

        % cleaning up that bottom
        bot_idx(bot_idx<idx_r_min) = idx_r_min;
        bot_idx(idx_empty) = nan;

        % filtered and masked version of BS
        echolength_theory = echo_length(max(Np),1/2*(faBW(uib)+psBW(uib)),5,bot_idx);

        win_size=ceil(mode(echolength_theory));
        win_size =  max(win_size,5);

        BS_filter = pow2db(filter2_perso(ones(win_size,1),db2pow(BS)));
        BS_filter(~Bottom_region) = nan;

        BS_bottom = max(BS_filter,[],'omitnan');
        BS_bottom(isnan(bot_idx)) = nan;

        % pings for which the max BS per ping (after filtering BS) is lower
        % than thr_bottom.
        idx_low = (BS_bottom<thr_bottom);
       
        % shift the bottom up
        bot_idx = bot_idx - ceil(p.Results.shift_bot./max(diff(range_new),[],1,'omitnan'));

        % nan the bottom for those low bottom BS pings
        bot_idx(idx_low) = nan;
        BS_bottom(idx_low) = nan;

        % save those results for this iteration
        idx_ping = idx_ping-idx_ping_tot(1)+1;
        bot_idx_tot(uib,idx_ping)                 = bot_idx+idx_r(1)-1;
        BS_bottom_tot(uib,idx_ping)              = BS_bottom;
        bot_mask_tot(idx_r,idx_ping,uib) = Bottom_region;
        

        % update progress bar
        if ~isempty(p.Results.load_bar_comp)
            set(p.Results.load_bar_comp.progress_bar, 'Value',ui+(uib-1)*num_ite);
        end

    end
end
bot_idx_tot(bot_idx_tot<=0) = 1;
output_struct.bottom=floor(bot_idx_tot+Np/2);
output_struct.bs_bottom=BS_bottom_tot;
output_struct.idx_ping=idx_ping_tot;
output_struct.bot_mask = bot_mask_tot;

old_tag = trans_obj.Bottom.Tag;
old_bot = trans_obj.Bottom.Sample_idx;
old_bot(idx_beams,output_struct.idx_ping) = output_struct.bottom;

new_bot = bottom_cl('Origin','Algo_v3',...
    'Sample_idx',old_bot,...
    'Tag',old_tag);

trans_obj.Bottom = new_bot;

trans_obj.clean_bottom('idx_ping',idx_ping_tot,'idx_beam',idx_beams,'interp_method',p.Results.interp_method,'rm_outliers_method',p.Results.rm_outliers_method);

output_struct.bottom = trans_obj.Bottom.Sample_idx;
output_struct.idx_ping = idx_ping_tot;
output_struct.done =  true;

% profile off;
% profile viewer;

