%% region_undo_fcn.m
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
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-09-12 first version (Yoann Ladroit). TODO: complete date and comment
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function region_undo_fcn(main_figure,trans_obj,regs)
if~isdeployed()
    disp_perso(main_figure,'Undo Region')
end

map_tab_comp = getappdata(main_figure,'Map_tab');
gax = map_tab_comp.ax;
old_regs = trans_obj.Regions;
if ~isempty(old_regs)
    cellfun(@(x) rem_reg_tag_lim(gax,x),{old_regs(:).Unique_ID});
end
trans_obj.rm_all_region();
IDs=trans_obj.add_region(regs);
trans_obj.disp_reg_tag_on_map('gax',gax,'uid',IDs);
curr_disp=get_esp3_prop('curr_disp');
display_regions('all');
curr_disp.Reg_changed_flag=1;
if ~isempty(IDs)
    curr_disp.setActive_reg_ID({});   
    curr_disp.Reg_changed_flag=1;
end
end


