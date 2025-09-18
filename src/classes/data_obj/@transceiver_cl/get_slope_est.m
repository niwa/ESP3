%% get_slope_est.m
%
% Gives a slope estimation of the bottom measured on the associated
% transducer using the depth line as reference
%
%% Help
%
% *USE*
%
% TODO
%
% *INPUT VARIABLES*
%
% * |trans_obj|: Object of class |transceiver_cl| (Required)
% * |FilterWidth|: Filter width (in meters) for smoothing bottom and vessel
% distance (Optional. Num. Default: |100|).
%
% *OUTPUT VARIABLES*
%
% * |shadow_zone_height_est|: Shadow zone height estimation
% * |slope_est|: TODO

% * |slope_est|: estimated slope
% * |bot_depth|: bottom range corrected from transducer depth
%
% *RESEARCH NOTES*
%
% TODO: complete header and in-code commenting
%
% *NEW FEATURES*
%
% * 2017-03-22: header and comments updated according to new format (alex)
% % 2017-03-15: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function [slope_est,bot_depth,range_bathy] = get_slope_est(trans_obj,varargin)

% input parser
p = inputParser;
addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addParameter(p,'FiltWidth',100,@isnumeric);
addParameter(p,'SlopeMax',30,@isnumeric);
parse(p,trans_obj,varargin{:});
results = p.Results;

% get bottom depth
%bot_range = trans_obj.get_bottom_range();
bot_idx = trans_obj.get_bottom_idx();

[~,Np] = trans_obj.get_pulse_length();
 
dist_vessel = trans_obj.get_dist();

[counts,hist_diff] = histcounts(diff(dist_vessel));
[~,idx] = max(counts,[],'omitnan');
s_width = results.FiltWidth/(hist_diff(idx));

idx_ping_tot = trans_obj.get_transceiver_pings();
rr = trans_obj.get_samples_range();

block_size = 50;

num_ite = ceil(numel(idx_ping_tot)/block_size);

idx_est = ones(size(bot_idx));
% block processing loop
for ui = 1:num_ite

    % pings for this block
    idx_ping = idx_ping_tot((ui-1)*block_size+1:min(ui*block_size,numel(idx_ping_tot)));

    %idx_r = min(bot_idx(idx_ping),[],'omitnan')-10*max(Np(idx_ping),[],'omitnan'):max(bot_idx(idx_ping),[],'omitnan')+100*max(Np(idx_ping),[],'omitnan');

   idx_r =  min(bot_idx(idx_ping),[],'omitnan')-10*max(Np(idx_ping),[],'omitnan'): ceil(max(bot_idx(idx_ping),[],'omitnan')/cosd(results.SlopeMax));
   idx_r(idx_r<0)=[];
   idx_r(idx_r>numel(rr))=[];

    if numel(idx_r)<2
        continue;
    end

    %[alongphi, acrossphi] = trans_obj.get_phase('idx_r',idx_r,'idx_ping',idx_ping);
    reg_obj=region_cl('Name','Temp','Idx_r',idx_r,'Idx_ping',idx_ping);
    [sv,idx_r,idx_ping,~,bad_data_mask,~,~,~,~]=trans_obj.get_data_from_region(reg_obj,...
                    'field','sv');
    sv_lin = db2pow_perso(sv);
    sv_lin(bad_data_mask) = 0;

    idx_est_tmp = ceil(sum(sv_lin.*idx_r,'omitnan')./sum(sv_lin,'omitnan'));
    idx_est_tmp(sum(sv_lin,'omitnan')==0) = bot_idx(idx_ping(sum(sv_lin,'omitnan')==0));
    idx_est(idx_ping) = idx_est_tmp;
end

t_angle = trans_obj.get_beams_pointing_angles();
idx_est(isinf(idx_est)|isnan(idx_est)|idx_est<0|idx_est>numel(rr))=1;
range_bathy =  rr(idx_est)';
range_bathy(bot_idx == 1 | isnan(bot_idx)) = nan;
bot_depth = rr(idx_est)'.*sind(t_angle) + trans_obj.get_transducer_depth();
bot_depth(idx_est==1) = nan;

bot_depth = smooth(bot_depth',s_width)';
dist_vessel_filt = smooth(dist_vessel',s_width)';
%dist_vessel_filt(diff(dist_vessel_filt)<hist_diff(idx)/4)=nan;

% estimate slope
slope_est = nan(size(bot_depth));
slope_est(1:end-1) = atand(diff(bot_depth)./diff(dist_vessel_filt));

