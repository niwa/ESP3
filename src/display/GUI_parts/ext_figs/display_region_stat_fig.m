%% display_region_stat_fig.m
%
% Display figure with table summarizing region stats.
%
%% Help
%
% *USE*
%
% TODO
%
% *INPUT VARIABLES*
%
% * |main_figure|: Handle to main ESP3 window
% * |regIntStruct|: Output from integrate_region
%
% *OUTPUT VARIABLES*
%
% * |hfig|: Handle to created figure
%
% *RESEARCH NOTES*
%
% TODO
%
% *NEW FEATURES*
%
% * 2017-03-22: header and comments updated according to new format (Alex Schimel)
% * 2017-03-07: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function hfig = display_region_stat_fig(main_figure,regIntStruct,id)

hfig=new_echo_figure(main_figure,'Tag',sprintf('reg_stat_%s',id),'Resize','off','Units','pixels','Position',[200 200 250 250],'UiFigureBool',true);

layout = uigridlayout(hfig);
layout.RowHeight = {'1x'};
layout.ColumnWidth = {'1x'};
Sa_lin = sum(regIntStruct.eint,'all','omitnan')./sum(max(regIntStruct.Nb_good_pings),'omitnan');
rownames = {'Sv Mean' 'Sv std' 'Sa' 'Number of Samples' 'NASC' 'ABC' 'Region Length' 'Region Height' 'Nb Cells'};

units = {'%.2f dB' '%.2f dB' '%.2f dB' '%.0f' '%.6f m2/nmi2' '%.9f m2/m2' '%.0f m' '%.0f m' '%.0f'};
regIntStruct.sv(pow2db_perso(regIntStruct.sv)<-900) = 0;
vars = {pow2db_perso(mean(regIntStruct.sv(:)))...
    std(pow2db_perso(regIntStruct.sv(:)),'omitnan')...
    pow2db_perso(Sa_lin)...
    sum(regIntStruct.nb_samples,'all','omitnan')...
    mean(sum(regIntStruct.NASC,'omitnan'))...
    mean(sum(regIntStruct.ABC,'omitnan'))...
    max(regIntStruct.Dist_E(:))-min(regIntStruct.Dist_S(:))...
    max(regIntStruct.Depth_max(:))-min(regIntStruct.Depth_min(:))...
    nnz(regIntStruct.sv(:)>0)};

vvv = cellfun(@(x,y) sprintf(y,x),vars,units,'un',0);
    
t = table(vvv','RowNames',rownames);

tt = uitable(layout,'Data',t);
tt.ColumnEditable = false;
tt.ColumnName = {};



