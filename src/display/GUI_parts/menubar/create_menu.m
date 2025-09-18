%% create_menu.m
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
% * |main_figure|: Handle to main ESP3 window
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
% * 2015-06-25: first version (Yoann Ladroit)
%
% *EXAMPLE
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function create_menu(main_figure)

if isempty(main_figure)
    main_figure = get_esp3_prop('main_figure');
end

if isappdata(main_figure,'main_menu')
    menu=getappdata(main_figure,'main_menu');
    menu_f=fieldnames(menu);
    for ifif=1:numel(menu_f)
        if isvalid(menu.(menu_f{ifif}))
            delete(menu.(menu_f{ifif}));
        end
    end
    rmappdata(main_figure,'main_menu');
end

curr_disp=get_esp3_prop('curr_disp');

main_menu.files = uimenu(main_figure,'Label','File(s)');
uimenu(main_menu.files,'Label','Open file','MenuSelectedFcn',{@open_file_cback,0,false});
uimenu(main_menu.files,'Label','Open next file','MenuSelectedFcn',{@open_file_cback,1,false});
uimenu(main_menu.files,'Label','Open previous file','MenuSelectedFcn',{@open_file_cback,2,false});
uimenu(main_menu.files,'Label','Open files in the background','MenuSelectedFcn',{@open_file_cback,0,true});
%uimenu(main_menu.files,'Label','Reload Current file(s)','MenuSelectedFcn',{@reload_file,main_figure});
uimenu(main_menu.files,'Label','Index Files','MenuSelectedFcn',{@index_files_callback,main_figure});
uimenu(main_menu.files,'Label','Clean temp. files','MenuSelectedFcn',@clean_temp_files_callback);
uimenu(main_menu.files,'Label','Open log file','MenuSelectedFcn',{@open_logfile_cback,main_figure},'separator','on');

main_menu.bottom_menu = uimenu(main_figure,'Label','Bottom/Regions');


main_menu.bottom_menu_xml = uimenu(main_menu.bottom_menu,'Label','XML');
uimenu(main_menu.bottom_menu_xml,'Label','Save Bottom/Regions to xml','MenuSelectedFcn',{@save_bot_reg_xml_to_db_callback,main_figure,0,0});
uimenu(main_menu.bottom_menu_xml,'Label','Save Bottom to xml','MenuSelectedFcn',{@save_bot_reg_xml_to_db_callback,main_figure,0,[]});
uimenu(main_menu.bottom_menu_xml,'Label','Save Regions to xml','MenuSelectedFcn',{@save_bot_reg_xml_to_db_callback,main_figure,[],0});
uimenu(main_menu.bottom_menu_xml,'Label','Load Bottom/Regions from xml','MenuSelectedFcn',{@import_bot_regs_from_xml_callback,main_figure,-1,-1},'separator','on');
uimenu(main_menu.bottom_menu_xml,'Label','Load Bottom from xml','MenuSelectedFcn',{@import_bot_regs_from_xml_callback,main_figure,-1,[]});
uimenu(main_menu.bottom_menu_xml,'Label','Load Regions from xml','MenuSelectedFcn',{@import_bot_regs_from_xml_callback,main_figure,[],-1});
uimenu(main_menu.bottom_menu_xml,'Label','Reload Bottom/Regions from xml for all openned layers','MenuSelectedFcn',{@reload_bot_reg_callback,main_figure,'XML'});


main_menu.bottom_menu_db = uimenu(main_menu.bottom_menu,'Label','DB','separator','on');
uimenu(main_menu.bottom_menu_db,'Label','Save Bottom/Regions to db','MenuSelectedFcn',{@save_bot_reg_xml_to_db_callback,main_figure,1,1});
uimenu(main_menu.bottom_menu_db,'Label','Save Bottom to db','MenuSelectedFcn',{@save_bot_reg_xml_to_db_callback,main_figure,1,[]});
uimenu(main_menu.bottom_menu_db,'Label','Save Regions to db','MenuSelectedFcn',{@save_bot_reg_xml_to_db_callback,main_figure,[],1});
uimenu(main_menu.bottom_menu_db,'Label','Load Bottom and/or Regions from db','MenuSelectedFcn',{@manage_version_calllback,main_figure},'separator','on');


app_path=get_esp3_prop('app_path');
cvsroot = app_path.cvs_root.Path_to_folder;

cmd = sprintf('cvs -N -d %s',cvsroot);
[~,output] = system(cmd);
no_mbs = true;
if ~contains(output,'not recognized')
    mcvs = uimenu(main_menu.bottom_menu,'Label','CVS','separator','on');
    uimenu(mcvs,'Label','Load Bottom and Regions (if linked to dfile...)','MenuSelectedFcn',{@load_bot_reg_callback,main_figure});
    uimenu(mcvs,'Label','Load Bottom (if linked to dfile...)','MenuSelectedFcn',{@load_bot_callback,main_figure});
    uimenu(mcvs,'Label','Load Regions (if linked to dfile...)','MenuSelectedFcn',{@load_reg_callback,main_figure});
    uimenu(mcvs,'Label','Reload opened Layers CVS Bottom/Regions','MenuSelectedFcn',{@reload_bot_reg_callback,main_figure,'CVS'});
    uimenu(mcvs,'Label','Remove opened Layers CVS Bottom/Regions','MenuSelectedFcn',{@remove_cvs_callback,main_figure});
    no_mbs = false;
end


%% Export tab
main_menu.export = uimenu(main_figure,'Label','Export','Tag','menuexport');

uimenu(main_menu.export,'Label','Save Echogram','MenuSelectedFcn',@save_echo_callback);

exp_values_menu = uimenu(main_menu.export,'Label','Export Echogram Data to .xlsx');
uimenu(exp_values_menu,'Label','Sv values ','MenuSelectedFcn',{@export_regions_values_callback,main_figure,'wc','sv'});
uimenu(exp_values_menu,'Label','Currently displayed data values','MenuSelectedFcn',{@export_regions_values_callback,main_figure,'wc','curr_data'});

att_exp_menu = uimenu(main_menu.export,'Label','Attitude','Tag','menuexportatt');
uimenu(att_exp_menu,'Label','Export to _att_data.csv file','MenuSelectedFcn',{@export_attitude_to_csv_callback,main_figure,[],'_att_data'});

bot_exp_menu = uimenu(main_menu.export,'Label','Bottom (depth, E1/E2)','Tag','menuexportbot');
uimenu(bot_exp_menu,'Label','Export to shapefile','MenuSelectedFcn',{@export_bottom_to_shapefile_callback,main_figure,[]});

gps_exp_menu = uimenu(main_menu.export,'Label','Position (GPS)','Tag','menuexportgps');
uimenu(gps_exp_menu,'Label','Export to _gps_data.csv file','MenuSelectedFcn',{@export_gps_to_csv_callback,main_figure,[],'_gps_data'});
uimenu(gps_exp_menu,'Label','Export to shapefile','MenuSelectedFcn',{@export_gps_to_shapefile_callback,main_figure,[]});
uimenu(gps_exp_menu,'Label','Export to .csv or shapefile from raw files','MenuSelectedFcn',{@export_nav_to_csv_from_raw_dlbox,main_figure});
uimenu(gps_exp_menu,'Label','Force update of GPS data in database','MenuSelectedFcn',@force_ping_db_update_cback);

NMEA_exp_menu = uimenu(main_menu.export,'Label','NMEA messages','Tag','menuexportnmea');
uimenu(NMEA_exp_menu,'Label','Export to _NMEA.csv file','MenuSelectedFcn',{@export_NMEA_to_csv_callback,main_figure,[],'_NMEA'});

st_exp_menu = uimenu(main_menu.export,'Label','Single Targets/Tracks','Tag','menuexportst');
uimenu(st_exp_menu,'Label','Export Single Targets to .xlsx file','MenuSelectedFcn',{@save_st_to_xls_callback,main_figure,0});
uimenu(st_exp_menu,'Label','Export Single Targets including signal to .xlsx file','MenuSelectedFcn',{@save_st_to_xls_callback,main_figure,1});
uimenu(st_exp_menu,'Label','Export Tracked Targets to .xlsx file','MenuSelectedFcn',{@save_tt_to_xls_callback,main_figure});

mb_export_menu = uimenu(main_menu.export,'Label','MBES/Imaging Sonar','Tag','menuexportmbes');
uimenu(mb_export_menu,'Label','Export full WC to MPEG-4 file (current layer)','MenuSelectedFcn',{@export_mb_wc_to_mp4_cback,'current','MPEG-4',[]});
uimenu(mb_export_menu,'Label','Export full WC to MPEG-4 (all layer)','MenuSelectedFcn',{@export_mb_wc_to_mp4_cback,'all','MPEG-4',[]});
uimenu(mb_export_menu,'Label','Export full WC to .avi file (current layer)','MenuSelectedFcn',{@export_mb_wc_to_mp4_cback,'current','Motion JPEG AVI',[]});
uimenu(mb_export_menu,'Label','Export full WC to .avi (all layer)','MenuSelectedFcn',{@export_mb_wc_to_mp4_cback,'all','Motion JPEG AVI',[]});
% uimenu(mb_export_menu,'Label','Export full WC to .avi file (current layer)','MenuSelectedFcn',{@export_mb_wc_to_mp4_cback,'current','Uncompressed AVI'});
% uimenu(mb_export_menu,'Label','Export full WC to .avi (all layer)','MenuSelectedFcn',{@export_mb_wc_to_mp4_cback,'all','Uncompressed AVI'});

features_exp_menu = uimenu(main_menu.export,'Label','Features','Tag','menuexportfeatures');
uimenu(features_exp_menu,'Label','Export features to .mat file','MenuSelectedFcn',{@export_features_cback,'.mat'});



%% Import tab
main_menu.import = uimenu(main_figure,'Label','Import','Tag','menuimport');

ext_imp_menu= uimenu(main_menu.import,'Label','Attitude and position','Tag','menuimportatt');
uimenu(ext_imp_menu,'Label','Import GPS from .mat or .csv','MenuSelectedFcn',{@import_gps_from_csv_callback,main_figure});
uimenu(ext_imp_menu,'Label','Import Attitude from .csv or 3DM*.log file','MenuSelectedFcn',{@import_att_from_csv_callback,main_figure});

bot_reg_imp_menu= uimenu(main_menu.import,'Label','Bottom/Region','Tag','menuimportbotreg');
uimenu(bot_reg_imp_menu,'Label','Import Bottom from .evl','MenuSelectedFcn',{@import_bot_from_evl_callback,main_figure});
uimenu(bot_reg_imp_menu,'Label','Import Regions from .evr','MenuSelectedFcn',{@import_regs_from_evr_callback,main_figure});
uimenu(bot_reg_imp_menu,'Label','Import Regions from LSSS .snap','MenuSelectedFcn',{@import_from_lsss_snap_callback,main_figure});

features_imp_menu= uimenu(main_menu.import,'Label','Features','Tag','mnuimportfeatures');
uimenu(features_imp_menu,'Label','Import features from .mat file','MenuSelectedFcn',{@import_features_cback,'.mat'});

%% Survey data tab
main_menu.survey = uimenu(main_figure,'Label','Survey Data','Tag','menu_survey');
uimenu(main_menu.survey,'Label','Reload Survey Data','MenuSelectedFcn',{@import_survey_data_callback,main_figure});
uimenu(main_menu.survey,'Label','Edit Voyage Informations','MenuSelectedFcn',{@edit_trip_info_callback,main_figure});

if ~isdeployed()
    uimenu(main_menu.survey,'Label','Set Time Zone for this trip','MenuSelectedFcn',{@edit_timezone_callback,main_figure});
end

uimenu(main_menu.survey,'Label','Edit/Display logbook','MenuSelectedFcn',{@logbook_dispedit_callback,main_figure});
uimenu(main_menu.survey,'Label','Look for new files in current folder','MenuSelectedFcn',{@look_for_new_files_callback,main_figure})
uimenu(main_menu.survey,'Label','Acoustic DB tool','MenuSelectedFcn',{@acoustic_db_tool_cback,main_figure});
uimenu(main_menu.survey,'Label','Dataset Partitionning Tool (DéPité)','MenuSelectedFcn',@DPT_cback);

main_menu.map=uimenu(main_figure,'Label','Mapping Tools','Tag','mapping');
uimenu(main_menu.map,'Label','Open/Undock Map','MenuSelectedFcn',{@display_map_callback,main_figure});
uimenu(main_menu.map,'Label','Display navigation from files','MenuSelectedFcn',{@plot_gps_track_from_files_callback,main_figure});
uimenu(main_menu.map,'Label','Map from current layers (integrated)','MenuSelectedFcn',{@load_map_fig_callback,main_figure},'separator','on');
uimenu(main_menu.map,'Label','Map survey result files','MenuSelectedFcn',{@map_survey_callback,main_figure});

main_menu.display = uimenu(main_figure,'Label','Display','Tag','menutags');

m_gpu=uimenu(main_menu.display,'Label','GPU Computation');
main_menu.gpu_enabled=uimenu(m_gpu,'Label','Enabled','MenuSelectedFcn',{@change_gpu_comp_callback,main_figure},'checked',curr_disp.GPU_computation>0,'tag','enabled');
main_menu.gpu_disabled=uimenu(m_gpu,'Label','Disabled','MenuSelectedFcn',{@change_gpu_comp_callback,main_figure},'checked',curr_disp.GPU_computation==0,'tag','disabled');


m_graphics=uimenu(main_menu.display,'Label','Graphics Quality');
main_menu.disp_high_quality=uimenu(m_graphics,'Label','High (slower)','MenuSelectedFcn',{@change_echoquality_callback,main_figure},'checked',strcmpi(curr_disp.EchoQuality,'high'),'tag','high');
main_menu.disp_medium_quality=uimenu(m_graphics,'Label','Medium','MenuSelectedFcn',{@change_echoquality_callback,main_figure},'checked',strcmpi(curr_disp.EchoQuality,'medium'),'tag','medium');
main_menu.disp_low_quality=uimenu(m_graphics,'Label','Low','MenuSelectedFcn',{@change_echoquality_callback,main_figure},'checked',strcmpi(curr_disp.EchoQuality,'low'),'tag','low');
main_menu.disp_very_low_quality=uimenu(m_graphics,'Label','Very Low','MenuSelectedFcn',{@change_echoquality_callback,main_figure},'checked',strcmpi(curr_disp.EchoQuality,'very_low'),'tag','very_low');

m_font=uimenu(main_menu.display,'Label','Font');
uimenu(m_font,'Label','Change Font','MenuSelectedFcn',{@change_font_callback,main_figure});


m_colormap=uimenu(main_menu.display,'Label','Colormap');

cmap_list=list_cmaps();

for imap=1:numel(cmap_list)
    uimenu(m_colormap,'Label',cmap_list{imap},'MenuSelectedFcn',{@change_cmap_callback,main_figure},'Tag',cmap_list{imap});
end
uimenu(m_colormap,'Label','Add new Cmap(s) from cpt file','MenuSelectedFcn',{@import_new_cmap_callback,main_figure},'separator','on');


[AlphaMapDispStr,AlphaMapDispStrMenu] = curr_disp.getAlphamapDispProp();
for ui = 1:numel(AlphaMapDispStrMenu)
    main_menu.(AlphaMapDispStr{ui})=uimenu(main_menu.display,'Label',AlphaMapDispStrMenu{ui},'checked',curr_disp.(AlphaMapDispStr{ui}),'Tag',AlphaMapDispStr{ui},'MenuSelectedFcn',@set_curr_disp);
end

[HandleDispStr,HandleDispStrMenu] = curr_disp.getHandleDispProp();

for ui = 1:numel(HandleDispStrMenu)
    main_menu.(HandleDispStr{ui})=uimenu(main_menu.display,'Label',HandleDispStrMenu{ui},'checked',curr_disp.(HandleDispStr{ui}),'Tag',HandleDispStr{ui},'MenuSelectedFcn',@set_curr_disp);
end



main_menu.display_file_lines=uimenu(main_menu.display,'checked','off','Label','Display File Limits','MenuSelectedFcn',{@checkbox_callback,main_figure,@toggle_display_file_lines});
main_menu.YDir=uimenu(main_menu.display,'checked','off','Label','Reverse Y-Axis','Tag','YDir');
main_menu.ReverseCmap=uimenu(main_menu.display,'checked','off','Label','Reverse Colormap','Tag','ReverseCmap');


set([main_menu.YDir ...
    main_menu.ReverseCmap],....
    'MenuSelectedFcn',@set_curr_disp);


main_menu.close_all_fig=uimenu(main_menu.display,'Label','Close All External Figures','MenuSelectedFcn',{@close_figures_callback,main_figure});

main_menu.tools = uimenu(main_figure,'Label','Tools','Tag','menutools');

uimenu(main_menu.tools,'Label','Scattering tool','MenuSelectedFcn',@load_scattering_obj_cback);
uimenu(main_menu.tools,'Label','Update Transceiver Configuration Parameters','MenuSelectedFcn',@update_transceivers_configuration);

mbes_tools=uimenu(main_menu.tools,'Label','MBES/Imaging sonar tools');
uimenu(mbes_tools,'Label','Show WC Fan Display','MenuSelectedFcn',@init_wc_fan_plot_cback);

reg_tools=uimenu(main_menu.tools,'Label','Regions tools');
uimenu(reg_tools,'Label','Create WC Region','MenuSelectedFcn',{@create_reg_dlbox,main_figure});
uimenu(reg_tools,'Label','Display Mean Depth of current region','MenuSelectedFcn',{@plot_mean_aggregation_depth_callback,main_figure});
uimenu(reg_tools,'Label','Run unsupervised classification of the WC','MenuSelectedFcn',{@create_unsclassif_dlbox,main_figure});

towbody_tools=uimenu(main_menu.tools,'Label','Towbody tools');
uimenu(towbody_tools,'Label','Correct position based on cable angle and towbody depth','MenuSelectedFcn',{@correct_pos_angle_depth_cback,main_figure});
uimenu(towbody_tools,'Label','Set constant transducer depth','MenuSelectedFcn',@set_constant_transducer_depth_cback);

if ~isdeployed
    bs_tools=uimenu(main_menu.tools,'Label','Backscatter Analysis');
    uimenu(bs_tools,'Label','Execute BS analysis','MenuSelectedFcn',{@bs_analysis_callback,main_figure});
end

env_tools=uimenu(main_menu.tools,'Label','Environment tools');
uimenu(env_tools,'Label','Load CTD (ESP3 format)','MenuSelectedFcn',{@load_ctd_esp3_callback,main_figure});
uimenu(env_tools,'Label','Load SVP (ESP3 Format)','MenuSelectedFcn',{@load_svp_esp3_callback,main_figure});
uimenu(env_tools,'Label','Compute SVP from CTD profile','MenuSelectedFcn',{@compute_svp_esp3_callback,main_figure});
env_tools_imp=uimenu(env_tools,'Label','External imports');
uimenu(env_tools_imp,'Label','Load CTD data from Seabird file','MenuSelectedFcn',{@load_ctd_callback,main_figure});
uimenu(env_tools_imp,'Label','Load SVP data from file','MenuSelectedFcn',{@load_svp_callback,main_figure});

noise_tools=uimenu(main_menu.tools,'Label','Noise analysis');
uimenu(noise_tools,'Label','Analysis of additive noise','MenuSelectedFcn',@noise_analysis_cback);


data_tools=uimenu(main_menu.tools,'Label','Data tools');
if ~isdeployed
    uimenu(data_tools,'Label','Import angles from other frequency','MenuSelectedFcn',{@import_angles_cback,main_figure});
end

uimenu(data_tools,'Label','Create Motion Compensation echogram','MenuSelectedFcn',{@create_motion_compensation_echogramm_cback,main_figure});
uimenu(data_tools,'Label','Convert Sv to fish Density','MenuSelectedFcn',{@create_fish_density_echogramm_cback,main_figure});
rm_tools=uimenu(data_tools,'Label','Remove Data');
uimenu(rm_tools,'Label','Denoised data','MenuSelectedFcn',{@rm_subdata_cback,main_figure,'denoised'});
uimenu(rm_tools,'Label','Single Targets','MenuSelectedFcn',{@rm_subdata_cback,main_figure,'st'});
uimenu(rm_tools,'Label','Features','MenuSelectedFcn',{@rm_subdata_cback,main_figure,'features'});

canopy_tools=uimenu(main_menu.tools,'Label','Canopy height estimation');
uimenu(canopy_tools,'Label','Display/export Canopy Height (all layers)','MenuSelectedFcn',@disp_canopy_height_cback);

track_tools=uimenu(main_menu.tools,'Label','Track');
uimenu(track_tools,'Label','Create Exclude Regions from Tracked targets','MenuSelectedFcn',{@create_regs_from_tracks_callback,'Bad Data',main_figure,{}});
uimenu(track_tools,'Label','Create Regions from Tracked targets','MenuSelectedFcn',{@create_regs_from_tracks_callback,'Data',main_figure,{}});

survey_results_tools=uimenu(main_menu.tools,'Label','Survey results Tools');
uimenu(survey_results_tools,'Label','Display survey results','MenuSelectedFcn',{@display_survey_results_cback,main_figure});

main_menu.scripts = uimenu(main_figure,'Label','Scripting');
uimenu(main_menu.scripts ,'Label','Script Manager','MenuSelectedFcn',{@load_xml_scripts_callback,main_figure});
uimenu(main_menu.scripts ,'Label','Script Builder','MenuSelectedFcn',{@load_script_builder_callback,main_figure});

if ~no_mbs
    uimenu(main_menu.scripts ,'Label','MBS Scripts','MenuSelectedFcn',{@load_mbs_scripts_callback,main_figure},'separator','on');
end

main_menu.options = uimenu(main_figure,'Label','Config','Tag','main_menu.options');
uimenu(main_menu.options,'Label','Path','MenuSelectedFcn',{@load_path_fig,main_figure});
uimenu(main_menu.options,'Label','Save Current Display Configuration (Survey)','MenuSelectedFcn',{@save_disp_config_survey_cback,main_figure});
uimenu(main_menu.options,'Label','Save Current Display Configuration (Default)','MenuSelectedFcn',{@save_disp_config_cback,main_figure});


main_menu.help_shortcuts=uimenu(main_figure,'Label','Help');
uimenu(main_menu.help_shortcuts,'Label','Shortcuts','MenuSelectedFcn',{@shortcut_menu,main_figure});
uimenu(main_menu.help_shortcuts,'Label','Documentation','MenuSelectedFcn',{@load_doc_fig_cback,main_figure});
uimenu(main_menu.help_shortcuts,'Label','About','MenuSelectedFcn',{@info_menu,main_figure});
uimenu(main_menu.help_shortcuts,'Label','Release notes','MenuSelectedFcn',{@load_rn_fig_cback,main_figure});
uimenu(main_menu.help_shortcuts,'Label','Display Last Warning',...
    'MenuSelectedFcn',{@disp_last_warn_err_cback,'warn'});
setappdata(main_figure,'main_menu',main_menu);

end

function clean_temp_files_callback(~,~)
obj= getappdata(groot,'esp3_obj');
obj.clean_temp_files();
end

function disp_last_warn_err_cback(~,~,str)
switch str
    case 'warn'
        [war_str,war_id] =lastwarn;
end

str_out = sprintf('%s\n%s\n',war_str,war_id);
clipboard('copy',str_out);
dlg_perso([],'Last Warning',str_out);
fprintf(str_out);

end

function load_scattering_obj_cback(~,~)

scm_obj = get_esp3_prop('scm_obj');

if isempty(scm_obj)||~isvalid(scm_obj.UIFigure)
    esp3_obj=getappdata(groot,'esp3_obj');
    esp3_obj.load_scm_obj();
else
    figure(scm_obj.UIFigure);
end

end

function init_wc_fan_plot_cback(~,~)
init_wc_fan_plot();
update_wc_fig(get_current_layer(),1);
end

function force_ping_db_update_cback(~,~)
layers_obj = get_esp3_prop('layers');
for uil = 1:numel(layers_obj)
    layers_obj(uil).add_ping_data_to_db([],1);
end
update_map_tab(get_esp3_prop('main_figure'));
end

function open_file_cback(~,~,id,parallel_process)
esp3_obj = getappdata(groot,'esp3_obj');

if ~isempty(esp3_obj)
    esp3_obj.open_file('file_id',id,'parallel_process',parallel_process);
end

end

function display_survey_results_cback(~,~,main_figure)
app_path=get_esp3_prop('app_path');

[Filenames,PathToFile]=uigetfile({fullfile(app_path.results.Path_to_folder,'*_output.txt;*_output.mat')}, 'Pick a survey_ouptput file','MultiSelect','on');

if ~isequal(Filenames, 0)

    if ~iscell(Filenames)
        Filenames={Filenames};
    end

    Filenames_tot=fullfile(PathToFile,Filenames);

    obj_vec=load_surv_obj_frome_result_files(Filenames_tot);

    if ~isempty(obj_vec)
        hfig=new_echo_figure(main_figure,'Name','Survey Results','Tag','Survey Results');
        obj_vec.plot_survey_strat_result(hfig);
        for ii=1:length(obj_vec)
            hfig_2=new_echo_figure(main_figure,'Name',sprintf('Survey Results %s: Transect',Filenames{ii}),'Tag',sprintf('results_trans%s',Filenames{ii}));
            obj_vec(ii).plot_survey_trans_result(hfig_2);
        end
    end


else
    return;
end
end

function load_rn_fig_cback(~,~,main_figure)

pos_fig=[0.2 0.1 0.6 0.8];

uibool = will_it_work([],'',true);
%uibool = false;

doc_fig=new_echo_figure(main_figure,...
    'Units','normalized',...
    'Position',pos_fig,...
    'Name','Release Notes',...
    'Resize','on',...
    'Tag','esp3_rn',...
    'UiFigureBool',uibool,...
    'visible','on');
adress=sprintf('%s/docs/index.html',whereisEcho());

if ~uibool
    jObject = com.mathworks.mlwidgets.html.HTMLBrowserPanel;
    [doc_fig_comp.browser,doc_fig_comp.browser_container] = javacomponent(jObject, [], doc_fig);
    set(doc_fig_comp.browser_container, 'Units','norm', 'Pos',[0,0,1,1]);

    doc_fig_comp.browser.setCurrentLocation(adress);
    doc_fig.Visible='on';
else
    g = uigridlayout(doc_fig);
    g.BackgroundColor = doc_fig.Color;
    g.RowHeight={'1x'};
    g.ColumnWidth={'1x'};
    uihtml_h=uihtml(g);

    %uihtml_h.Scrollable = true;
    uihtml_h.HTMLSource = adress;
end


end

function load_doc_fig_cback(~,~,main_figure)
load_documentation_figure(main_figure);
end

function load_script_builder_callback(~,~,~)

layer=get_current_layer();

if isempty(layer)
    app_path=get_esp3_prop('app_path');
    path_f=app_path.data_root.Path_to_folder;
else
    [path_f,~,~]=fileparts(layer.Filename{1});
end

create_xml_script_gui('logbook_file',path_f);

end

function change_echoquality_callback(src,~,~)
curr_disp=get_esp3_prop('curr_disp');

if ~strcmpi(curr_disp.EchoQuality,src.Tag)
    curr_disp.EchoQuality=src.Tag;
end
end

function  change_gpu_comp_callback(src,~,main_figure)
curr_disp=get_esp3_prop('curr_disp');
main_menu=getappdata(main_figure,'main_menu');

switch src.Tag
    case 'enabled'
        set(main_menu.gpu_enabled,'checked',~strcmpi(main_menu.gpu_enabled.Checked,'on'));
        set(main_menu.gpu_disabled,'checked',strcmpi(main_menu.gpu_enabled.Checked,'off'));
    case 'disabled'
        set(main_menu.gpu_disabled,'checked',~strcmpi(main_menu.gpu_disabled.Checked,'on'));
        set(main_menu.gpu_enabled,'checked',strcmpi(main_menu.gpu_disabled.Checked,'off'));
end

curr_disp.GPU_computation=strcmpi(main_menu.gpu_enabled.Checked,'on');

if curr_disp.GPU_computation>0
    disp_perso(main_figure,'GPU Computation enabled');
else
    disp_perso(main_figure,'GPU Computation disabled');
end

end


function display_map_callback(~,~,main_figure)

undock_tab_callback([],[],main_figure,'map','new_fig');
end
function acoustic_db_tool_cback(~,~,main_figure)
enter_new_trip_in_database(main_figure,[]);
end

function DPT_cback(~,~)
layers = get_esp3_prop('layers');
if ~isempty(layers)
    [ff,~]=layers.list_files_layers;
    [fff,~,~] = cellfun(@fileparts,ff,'UniformOutput',false);
    ffl = unique(fullfile(fff,'echo_logbook.db'));
else
    ffl = {};
end
DPT('logbook_file',ffl);
end


function save_disp_config_cback(~,~,~)
curr_disp=get_esp3_prop('curr_disp');

write_config_display_to_xml(curr_disp);

end


function save_disp_config_survey_cback(~,~,~)
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();

if isempty(layer)
    return;
end

filepath=fileparts(layer.Filename{1});
write_config_display_to_xml(curr_disp,'file_path',filepath,'limited',1);

end

function edit_timezone_callback(~,~,main_figure)

layer=get_current_layer();
if isempty(layer)
    return;
end
[path_to_db,~,~]=fileparts(layer.Filename{1});
if isfolder(path_to_db)
    set_folder_time_zone(main_figure,path_to_db);
end

end

function set_constant_transducer_depth_cback(~,~)

lay_obj = get_current_layer();

curr_disp=get_esp3_prop('curr_disp');
main_figure = get_esp3_prop('main_figure');

prompt={'Transducer depth in meters'};
defaultanswer = {100};

[answer,cancel]=input_dlg_perso(main_figure,'Set Transducer depth',prompt,...
    {'%.1f'},defaultanswer);

if cancel
    return;
end

for uit= 1 :numel(lay_obj.Transceivers)
    lay_obj.Transceivers(uit).set_transducer_depth(answer{1},[]);
    if uit == 1
        line_obj = line_cl('Tag','offset','Range',answer{1}*ones(size(lay_obj.Transceivers(uit).Time)),'Time',lay_obj.Transceivers(uit).Time);
    end
end
lay_obj.add_lines(line_obj);

update_lines_tab(main_figure);
display_lines();
curr_disp.DispSecFreqs=curr_disp.DispSecFreqs;

end

function correct_pos_angle_depth_cback(~,~,main_figure)

layer=get_current_layer();

if isempty(layer)
    return;
end

prompt={'Towing cable angle (in degree)','Towbody depth'};
defaultanswer={25,500};


[answer,cancel]=input_dlg_perso(main_figure,'Correct position',prompt,...
    {'%.0f' '%.1f'},defaultanswer);
if cancel
    return;
end

angle_deg=answer{1};

if isnan(angle_deg)
    warning('Invalid Angle');
    return;
end

depth_m=answer{2};

if isnan(depth_m)
    warning('Invalid Depth');
    return;
end

curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~]=layer.get_trans(curr_disp);


gps_data=trans_obj.GPSDataPing;

[new_lat,new_long,hfig]=correct_pos_angle_depth(gps_data.Lat,gps_data.Long,angle_deg,depth_m);


war_str='Would you like to use this corrected track (in red)?';

choice=question_dialog_fig(main_figure,'',war_str);

close(hfig);

switch choice
    case 'Yes'
        trans_obj.GPSDataPing.Lat=new_lat;
        trans_obj.GPSDataPing.Long=new_long;
        layer.replace_gps_data_layer(trans_obj.GPSDataPing);
        export_gps_to_csv_callback([],[],main_figure,layer.Unique_ID,'_gps');
    case 'No'
        return;

end


update_map_tab(main_figure);


set_alpha_map(main_figure);

end


function manage_version_calllback(~,~,main_figure)

load_bot_reg_data_fig_from_db(main_figure);


end



function change_cmap_callback(src,~,~)
curr_disp=get_esp3_prop('curr_disp');
curr_disp.Cmap=src.Tag;
set_esp3_prop('curr_disp',curr_disp);
end

function change_font_callback(~,~,main_fig)
curr_disp=get_esp3_prop('curr_disp');
fonts=listfonts(main_fig);
fonts = [{'default'}; fonts];
font = curr_disp.Font;
if isempty(font) ||~ismember(font,fonts)
    font = fonts{1};
end

list_font_figure= new_echo_figure(main_fig,'Units','Pixels','Position',[100 100 200 600],...
    'Resize','off',...
    'Name','Choose Font',...
    'Tag','font_choice',....
    'UiFigureBool',true);

uigl = uigridlayout(list_font_figure,[1 1]);

uilistbox(uigl,'Multiselect','off','Value',{font},'Items',fonts,'ValueChangedFcn',{@list_font_cback,main_fig});

end

function list_font_cback(src,~,~)
curr_disp=get_esp3_prop('curr_disp');

curr_disp.Font = src.Value;
set_esp3_prop('curr_disp',curr_disp);
end



function load_map_fig_callback(~,~,main_fig)
load_map_fig(main_fig,[]);
end


function look_for_new_files_callback(~,~,main_figure)
layer=get_current_layer();
if isempty(layer)
    return;
end
layer.update_echo_logbook_dbfile('main_figure',main_figure);
load_logbook_fig(main_figure,false);

end

function open_logfile_cback(~,~,main_figure)
open_txt_file(main_figure.UserData.logFile);
end


function set_curr_disp(src,~)

curr_disp=get_esp3_prop('curr_disp');
switch src.Tag
    case 'YDir'
        switch  src.Checked
            case 'on'
                curr_disp.(src.Tag)='reverse';
                src.Checked  = 'off';
            case 'off'
                curr_disp.(src.Tag)='normal';
                src.Checked  = 'on';
        end
    otherwise

        switch src.Checked
            case {'off',0,false}
                curr_disp.(src.Tag)='on';
                src.Checked  = 'on';
            case {'on',1,true}
                curr_disp.(src.Tag)='off';
                src.Checked  = 'off';
        end
end
end


function update_transceivers_configuration(~,~)
layer = get_current_layer();
layers = get_esp3_prop('layers');

[filenames_lays,~]=list_files_layers(layers);

[path_f_lays,~,~] =  cellfun(@fileparts,filenames_lays,'UniformOutput',false);

[file_path,~,~] = fileparts(layer.Filename{1});

filenames = get_compatible_ac_files(file_path);

if isempty(filenames) || isnumeric(filenames)
    return;
end

[path_f,fileN,~] =  cellfun(@fileparts,filenames,'UniformOutput',false);

fileN(~ismember(path_f,path_f_lays)) = [];
path_f(~ismember(path_f,path_f_lays)) = [];

if isempty(path_f)
    dlg_perso([],'Nope, not doing that.',...
        'You cannot update configuration from files in a folder that has no files open... Sorry.','Timeout',30,'Type','Warning');
    return;
end

path_f_unique = unique(path_f);
config_files = cellfun(@(x,y) fullfile(x,[y '_config.xml']),path_f,fileN,'UniformOutput',false);

for uip = 1:numel(path_f_unique)
    idx_p = strcmpi(path_f,path_f_unique{uip});
    f_obj  = config_update_fig_cl('config_obj',[layer.Transceivers(:).Config],'config_filenames',config_files(idx_p));
    waitfor(f_obj.config_edit_fig);
end

layers.add_config_from_config_xml();

update_display(get_esp3_prop('main_figure'),0,1);

end





