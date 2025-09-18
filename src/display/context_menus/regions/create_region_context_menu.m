%% create_region_context_menu.m
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
% * |reg_plot|: TODO: write description and info on variable
% * |main_figure|: TODO: write description and info on variable
% * |ID|: TODO: write description and info on variable
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
function context_menu = create_region_context_menu(reg_plot,main_figure,ID)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~]=layer.get_trans(curr_disp);

switch class(ID)
    case 'matlab.graphics.primitive.Patch'
        isreg=0;
        select_plot = ID;
        ID='select_area';
    case 'char'
        isreg=1;
        select_plot = trans_obj.get_region_from_Unique_ID(ID);
    otherwise
        return;
end

curr_fig = ancestor(reg_plot(1),'figure');
context_menu=uicontextmenu(curr_fig,'Tag','RegionContextMenu','UserData',ID);

for ii=1:length(reg_plot)
    reg_plot(ii).UIContextMenu=context_menu;
end

if isreg>0
    region_menu=uimenu(context_menu,'Label','Region');
    uidisp=uimenu(region_menu,'Label','Display');
    uimenu(uidisp,'Label','Region SV','MenuSelectedFcn',{@display_region_callback,main_figure,'2D',false});
    uimenu(uidisp,'Label','Region Fish Density','MenuSelectedFcn',{@display_region_fishdensity_callback,main_figure});
    uimenu(uidisp,'Label','Frequency differences (with other channels)','MenuSelectedFcn',{@freq_diff_callback,main_figure});
    uimenu(uidisp,'Label','Region 3D echoes (TS)','MenuSelectedFcn',{@display_region_callback,main_figure,'3D',false});
    uimenu(uidisp,'Label','Region bathy','MenuSelectedFcn',{@display_region_callback,main_figure,'3D_bathy',false});
    uimenu(uidisp,'Label','Region 3D Sv','MenuSelectedFcn',{@display_region_callback,main_figure,'3D_sv',false});
    uimenu(uidisp,'Label','Region 3D (current field)','MenuSelectedFcn',{@display_region_callback,main_figure,'3D_curr_field',false});
    uimenu(uidisp,'Label','Region 3D Single targets','MenuSelectedFcn',{@display_region_callback,main_figure,'3D_ST',false});
    uimenu(uidisp,'Label','Region 3D Tracked targets','MenuSelectedFcn',{@display_region_callback,main_figure,'3D_tracks',false});
    uimenu(uidisp,'Label','Region 3D Single targets (animated)','MenuSelectedFcn',{@display_region_callback,main_figure,'3D_ST',true});
    uimenu(uidisp,'Label','Region 3D Tracked targets (animated)','MenuSelectedFcn',{@display_region_callback,main_figure,'3D_tracks',true});
    
    if any(contains(trans_obj.Data.Fieldname,'velocity'))
        uimenu(uidisp,'Label','Region 3D Velocity Quiver','MenuSelectedFcn',{@display_region_callback,main_figure,'3D_quiver',false});
    end
    uifreq=uimenu(region_menu,'Label','Copy to other channels');
    uimenu(uifreq,'Label','all','MenuSelectedFcn',{@copy_region_callback,main_figure,[]});
    uimenu(uifreq,'Label','choose which Channel(s)','MenuSelectedFcn',{@copy_region_callback,main_figure,1});
    uimerge=uimenu(region_menu,'Label','Merge/Combine/Split regions');
    uimenu(uimerge,'Label','Merge Overlapping Regions (union)','MenuSelectedFcn',{@merge_overlapping_regions_callback,main_figure});
    uimenu(uimerge,'Label','Merge Overlapping Regions (union per Tag)','MenuSelectedFcn',{@merge_overlapping_regions_per_tag_callback,main_figure});
    uimenu(uimerge,'Label','Combine Selected Regions (union)','MenuSelectedFcn',{@merge_selected_regions_callback,main_figure,0});
    uimenu(uimerge,'Label','Combine Selected Regions (intersection)','MenuSelectedFcn',{@merge_selected_regions_callback,main_figure,1});
    uimenu(uimerge,'Label','Split Selected non-continous regions','MenuSelectedFcn',{@merge_selected_regions_callback,main_figure,-1});
end



analysis_menu=uimenu(context_menu,'Label','Analysis');
uimenu(analysis_menu,'Label','Display Pdf of values','MenuSelectedFcn',{@disp_hist_region_callback,select_plot,main_figure});
uimenu(analysis_menu,'Label','Display region(s) statistics','MenuSelectedFcn',{@reg_integrated_callback,select_plot,main_figure});
if isreg>0
      
    uimenu(analysis_menu,'Label','Classify region(s)','MenuSelectedFcn',{@classify_reg_callback,main_figure});
    uimenu(analysis_menu,'Label','Display Mean Depth of current region','MenuSelectedFcn',{@plot_mean_aggregation_depth_callback,main_figure});

    export_menu=uimenu(context_menu,'Label','Export');
    uimenu(export_menu,'Label','Export integrated region(s) to .xlsx','MenuSelectedFcn',{@export_regions_callback,main_figure});
    uimenu(export_menu,'Label','Export Sv values to .xlsx','MenuSelectedFcn',{@export_regions_values_callback,main_figure,'selected','sv'});
    uimenu(export_menu,'Label','Export currently displayed values to .xlsx','MenuSelectedFcn',{@export_regions_values_callback,main_figure,'selected','curr_data'});
    sub_export_menu=uimenu(export_menu,'Label','XYZ/VRML');
    uimenu(sub_export_menu,'Label','Export region(s) TS Echoes to XYZ or VRML file (current frequency)','MenuSelectedFcn',{@export_regions_xyz_callback,main_figure,'TS'},'Tag','current_freq');
    uimenu(sub_export_menu,'Label','Export region(s) TS Echoes to XYZ or VRML file (all frequencies)','MenuSelectedFcn',{@export_regions_xyz_callback,main_figure,'TS'},'Tag','all');
    uimenu(sub_export_menu,'Label','Export region(s) current data to XYZ or VRML file (current frequency)','MenuSelectedFcn',{@export_regions_xyz_callback,main_figure,'curr_data'},'Tag','current_freq');
    uimenu(sub_export_menu,'Label','Export region(s) current data to XYZ or VRML file (all frequencies)','MenuSelectedFcn',{@export_regions_xyz_callback,main_figure,'curr_data'},'Tag','all');
    
    if trans_obj.ismb()
        mbes_menu=uimenu(export_menu,'Label','MBES/Imaging sonar');
        uimenu(mbes_menu,'Label','Export region WC data to image','MenuSelectedFcn',@export_mbes_reg_to_img_cback);
        uimenu(mbes_menu,'Label','Export region WC data to MPEG-4','MenuSelectedFcn',{@export_mb_wc_to_mp4_cback,'current','MPEG-4',select_plot});
    end
end

uimenu(analysis_menu,'Label','Spectral Analysis (noise)','MenuSelectedFcn',{@noise_analysis_callback,select_plot,main_figure});

freq_analysis_menu=uimenu(context_menu,'Label','Frequency Analysis');
uimenu(freq_analysis_menu,'Label','Display TS Frequency response','MenuSelectedFcn',{@freq_response_reg_callback,select_plot,main_figure,'sp',false});
uimenu(freq_analysis_menu,'Label','Display Sv Frequency response','MenuSelectedFcn',{@freq_response_reg_callback,select_plot,main_figure,'sv',false});
uimenu(freq_analysis_menu,'Label','Display Sliced Sv Frequency response','MenuSelectedFcn',{@freq_response_reg_callback,select_plot,main_figure,'sv',true});
uimenu(freq_analysis_menu,'Label','Plot Sv echogram using user chosen frequency bounds (FM transducers)','MenuSelectedFcn',{@echogram_freq_red_FM_reg,main_figure});

if strcmp(trans_obj.Mode,'FM')
    uimenu(freq_analysis_menu,'Label','Create Frequency Matrix Sv','MenuSelectedFcn',{@freq_response_mat_callback,select_plot,main_figure});
    uimenu(freq_analysis_menu,'Label','Create Frequency Matrix TS','MenuSelectedFcn',{@freq_response_sp_mat_callback,select_plot,main_figure});
end

algo_menu=uimenu(context_menu,'Label','Apply Algorithm');
al = list_algos(true);

for uil  = 1:numel(al)
    algo_obj  = algo_cl('Name',al{uil});
    uimenu(algo_menu,'Label',algo_obj.Display_name,'MenuSelectedFcn',{@apply_algo_cback,main_figure,algo_obj.Name,select_plot});
end


uimenu(context_menu,'Label','Shift Bottom ...','MenuSelectedFcn',{@shift_bottom_callback,select_plot});
% uimenu(context_menu,'Label','Apply bottom detection V2 and display 3D bathy ...','MenuSelectedFcn',{@apply_bottom_and_disp_bathy_cback,select_plot});


if isreg==0 
    uimenu(context_menu,'Label','Clear Spikes','MenuSelectedFcn',{@clear_spikes_cback,select_plot,main_figure});
end

%
% if isreg==0&&~isdeployed()
%     algo_menu=uimenu(context_menu,'Label','"Sliding" Algorithms');
%     uimenu(algo_menu,'Label','Bottom Detection V1','MenuSelectedFcn',{@change_userdata_cback,select_plot,'bot_detec_v1'});
%     uimenu(algo_menu,'Label','Bottom Detection V2','MenuSelectedFcn',{@change_userdata_cback,select_plot,'bot_detec_v2'});
%     %uimenu(algo_menu,'Label','Bad transmits','MenuSelectedFcn',{@change_userdata_cback,select_plot,'bad_transmits'});
%     uimenu(algo_menu,'Label','Disable "Sliding" Algorithm','MenuSelectedFcn',{@change_userdata_cback,select_plot,''});
% end


end



function clear_spikes_cback(~,~,select_plot,main_figure)
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~]=layer.get_trans(curr_disp);

switch class(select_plot)
    case 'region_cl'
        reg_obj=trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
    otherwise
        idx_ping=round(min(select_plot.XData)):round(max(select_plot.XData));
        idx_r=round(min(select_plot.YData)):round(max(select_plot.YData));
        reg_obj=region_cl('Name','Select Area','Idx_r',idx_r,'Idx_ping',idx_ping,'Unique_ID','select_area');
end
idx_r = reg_obj.Idx_r;
idx_ping = reg_obj.Idx_ping;

trans_obj.set_spikes(idx_r,idx_ping,0);
set_alpha_map(main_figure,'update_under_bot',0,'update_cmap',0);

end

function freq_diff_callback(~,~,main_figure)
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);
IDs=curr_disp.Active_reg_ID;

reg_curr=trans_obj.get_region_from_Unique_ID(IDs);
layer.copy_region_across(idx_freq,reg_curr,[]);

frequencies=layer.Frequencies;
nb_trans=length(layer.Frequencies);

output_reg=cell(numel(IDs),nb_trans);
CIDs=layer.ChannelID;
for irtans=1:nb_trans
    trans=layer.Transceivers(irtans);
    
    for jids=1:numel(IDs)
        reg=trans.get_region_from_Unique_ID(reg_curr(jids).Unique_ID);
        output_reg{jids,irtans}=trans.integrate_region(reg,'keep_bottom',1,'keep_all',1);
    end
end


for jids=1:numel(IDs)
    output_reg_1=output_reg{jids,idx_freq};
    for irtans=1:nb_trans       
        if irtans==idx_freq
            continue;
        end
        
        output_reg_2=output_reg{jids,irtans};
        output_diff  = substract_reg_outputs( output_reg_1,output_reg_2);
        CID=layer.Transceivers(irtans).Config.ChannelID;
        freq=frequencies(strcmpi(CIDs,CID));
        
        if ~isempty(output_diff)
            sv=pow2db_perso(output_diff.sv(:));
            cax_min=prctile(sv,5);
            cax_max=prctile(sv,95);
            cax=curr_disp.getCaxField('sv');
            
            switch reg_curr.Reference
                case 'Line'
                    line_obj=layer.get_first_line();
                otherwise
                    line_obj=[];
            end
            
            reg_curr(jids).display_region(output_diff,'main_figure',main_figure,...
                'alphadata',double(pow2db_perso(output_reg_1.sv)>cax(1)),...
                'Cax',[cax_min cax_max],...
                'Name',sprintf('%s, %dkHz-%dkHz',reg_curr(jids).print,curr_disp.Freq/1e3,freq/1e3),...
                'line_obj',line_obj);
        else
            fprintf('Cannot compute differences %dkHz-%dkHz\n',curr_disp.Freq/1e3,freq/1e3);
        end
    end
end


end


function reg_integrated_callback(~,~,select_plot,main_figure)
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~]=layer.get_trans(curr_disp);

switch class(select_plot)
    case 'region_cl'
        [trans_obj,~]=layer.get_trans(curr_disp);
        reg_obj=trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
    otherwise
        idx_ping=round(min(select_plot.XData)):round(max(select_plot.XData));
        idx_r=round(min(select_plot.YData)):round(max(select_plot.YData));
        reg_obj=region_cl('Name','Select Area','Idx_r',idx_r,'Idx_ping',idx_ping,'Unique_ID','select_area');
end


for i=1:numel(reg_obj)
    regCellInt=trans_obj.integrate_region(reg_obj(i));
    if isempty(regCellInt)
        return;
    end
    
    hfig = display_region_stat_fig(main_figure,regCellInt,reg_obj(i).Unique_ID);
    set(hfig,'Name',reg_obj(i).print());
end
end



function disp_hist_region_callback(~,~,select_plot,main_figure)
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');


switch class(select_plot)
    case 'region_cl'
        [trans_obj,~]=layer.get_trans(curr_disp);
        reg_obj=trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
    otherwise
        idx_ping=round(min(select_plot.XData)):round(max(select_plot.XData));
        idx_r=round(min(select_plot.YData)):round(max(select_plot.YData));
        reg_obj=region_cl('Name','Select Area','Idx_r',idx_r,'Idx_ping',idx_ping,'Unique_ID','select_area');
end

trans=layer.get_trans(curr_disp);
[~,Type,Units]=init_cax(curr_disp.Fieldname);
for i=1:length(reg_obj)
    reg_curr=reg_obj(i);
    [data,~,~,~,bad_data_mask,bad_trans_vec,~,below_bot_mask,~]=trans.get_data_from_region(reg_curr,...
        'field',curr_disp.Fieldname);
        
    data(bad_data_mask|below_bot_mask|isinf(data))=nan;
    data(:,bad_trans_vec)=nan;
    
    if ~any(~isnan(data))
        return;
    end
    
    
    tt=reg_curr.print();
    if ~isempty(Units)
        xlab = sprintf('%s',Type);
    else
        xlab = sprintf('%s (%s)',Type,Units);
    end
    [pdf,x]=pdf_perso(data,'bin',50);
    md = median(data,'all','omitmissing');
    mm = mean(data,'all','omitmissing');
    %sd = std(data,0,'all','omitmissing');
    prc_d  =prctile(data,[5 95],'all');
    ff = new_echo_figure(main_figure,'Name',sprintf('Region %d Histogram: %s',reg_curr.ID,curr_disp.Type),'Tag',sprintf('histo%s',reg_curr.Unique_ID));
    ax = axes(ff,'nextplot','add');
    title(ax,tt);
    bar(ax,x,pdf);
    xline(ax,mm,'-',sprintf('Mean: %.1f %s',mm,Units),'Color',[0.7 0 0]);
    %xline(ax,md-sd,'--',sprintf('Mean-\\delta: %.1f %s',md-sd,Units),'Color',[0.7 0 0]);
    %xline(ax,md+sd,'--',sprintf('Mean-\\delta: %.1f %s',md+sd,Units),'Color',[0.7 0 0]);
    xline(ax,prc_d(1),'--',sprintf('5th percentile: %.1f %s',prc_d(1),Units),'Color',[0.7 0 0]);
    xline(ax,prc_d(2),'--',sprintf('95th percentile: %.1f %s',prc_d(2),Units),'Color',[0.7 0 0]);
    xline(ax,md,'-',sprintf('Median: %.1f %s',md,Units),'Color',[0 0.7 0]);
    grid(ax,'on');box(ax,'on');
    ylabel(ax,'Pdf');
    xlabel(ax,xlab);
    
end

end

