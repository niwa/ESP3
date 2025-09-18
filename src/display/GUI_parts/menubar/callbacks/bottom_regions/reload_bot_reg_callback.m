%% reload_bot_reg_callback.m
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
% * |main_figure|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% NA
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
function reload_bot_reg_callback(~,~,main_figure,tag)

layers=get_esp3_prop('layers');
app_path=get_esp3_prop('app_path');
layer = get_current_layer();
if isempty(layers)
    return;
end

choice=question_dialog_fig(main_figure,'','WARNING: This will replace all Currently opened layers Bottom and Regions?');


switch choice
    case 'Yes'
    otherwise
        return;
end

for ilay=1:length(layers)
    switch tag
        case 'CVS'
            for uui=1:length(layers(ilay).Frequencies)
                layers(ilay).Transceivers(uui).rm_region_origin('esp2');
            end
            layers(ilay).CVS_BottomRegions(app_path.cvs_root.Path_to_folder)
        otherwise
            layers(ilay).load_bot_regs();
    end

end

set_esp3_prop('layers',layers);
clear_regions(main_figure,{},{});

curr_disp=get_esp3_prop('curr_disp');
display_regions('all');

curr_disp.setActive_reg_ID({});

display_bottom(main_figure);

set_alpha_map(main_figure,'main_or_mini',union({'main','mini'},layer.ChannelID));


end