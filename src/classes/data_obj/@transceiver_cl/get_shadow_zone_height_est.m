%% get_shadow_zone_height_est.m
%
% Gives a shadow zone height estimation
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
%
% *OUTPUT VARIABLES*
%
% * |shadow_zone_height_est|: Shadow zone height estimation
% * |slope_est|: TODO
%
% *RESEARCH NOTES*
%
% TODO: complete header and in-code commenting
%
% *NEW FEATURES*
%
% * 2017-03-22: header and comments updated according to new format (Alex Schimel)
% * 2017-03-15: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function [shadow_zone_height_est,slope_est,range_bathy] = get_shadow_zone_height_est(trans_obj ,varargin)

% input parser
p = inputParser;
addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addParameter(p,'comp_meth',2,@isnumeric);
parse(p,trans_obj,varargin{:});

% get beam angle
[faBW,psBW] = trans_obj.get_beamwidth_at_f_c([]);
[~,Np] = trans_obj.get_pulse_length();
rr = trans_obj.get_samples_range(Np)/2;

beam_angle = mean(faBW+psBW)/4;

% get slope
[slope_est,bot_depth_bathy,range_bathy] = trans_obj.get_slope_est();

bot_depth = trans_obj.get_bottom_depth();

bot_range = trans_obj.get_bottom_range();

shadow_zone_height_est_meth1 = bot_range.*abs(cosd(beam_angle-abs(slope_est))./cosd(slope_est)-1);

id = abs(slope_est)>=beam_angle;

shadow_zone_height_est_meth1(id) = bot_range(id).*abs(1./cosd(slope_est(id))-1);

shadow_zone_height_est_meth1 = shadow_zone_height_est_meth1 + rr';

shadow_zone_height_est_meth2 = bot_depth_bathy-bot_depth;
shadow_zone_height_est_meth2(shadow_zone_height_est_meth2<rr') = rr(shadow_zone_height_est_meth2<rr')';

switch p.Results.comp_meth
    case 1
        shadow_zone_height_est = shadow_zone_height_est_meth1;
    case 2
        shadow_zone_height_est = shadow_zone_height_est_meth2;
end

% figure();
% plot(shadow_zone_height_est_meth2,'r');
% hold on;
% plot(shadow_zone_height_est_meth1,'k');
% ylim([0 100]);

