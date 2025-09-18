
function load_echo_int_tab(main_figure,parent_tab_group)
% import javax.swing.*
% import java.awt.*

switch parent_tab_group.Type
    case 'uitabgroup'
        echo_int_tab_comp.echo_int_tab=new_echo_tab(main_figure,parent_tab_group,'Title','Echo Integration','UiContextMenuName','echoint_tab');
        pos_tab=getpixelposition(echo_int_tab_comp.echo_int_tab);
        pos_tab(4)=pos_tab(4);
    case 'figure'
        echo_int_tab_comp.echo_int_tab=parent_tab_group;
        pos_tab=getpixelposition(echo_int_tab_comp.echo_int_tab);
end
%drawnow;
curr_disp=get_esp3_prop('curr_disp');
layer_obj=get_current_layer();
trans_obj = layer_obj.get_trans(curr_disp);

opt_panel_size=[0 pos_tab(4)-500+1 300 500];
ax_panel_size=[opt_panel_size(3) 0 pos_tab(3)-opt_panel_size(3) pos_tab(4)];

echo_int_tab_comp.opt_panel=uipanel(echo_int_tab_comp.echo_int_tab,'units','pixels','BackgroundColor','white','position',opt_panel_size);
echo_int_tab_comp.axes_panel=uipanel(echo_int_tab_comp.echo_int_tab,'units','pixels','BackgroundColor','white','position',ax_panel_size);

echo_int_tab_comp.echo_obj = echo_disp_cl(echo_int_tab_comp.axes_panel,...
    'tag','echoint',...
    'ax_tag','main',...
    'YDir',curr_disp.YDir,...
    'cmap',curr_disp.Cmap,...
    'disp_colorbar',true,...
    'H_axes_ratio',0.1,...
    'link_ax',true,...
    'V_axes_ratio',0.05,...
    'AlphaDataMapping','none');

create_context_menu_int_plot(echo_int_tab_comp.echo_obj.echo_surf);

%%%%%%Option Panel on the left side%%%%
%integration parameters
nb_rows=20;
gui_fmt=init_gui_fmt_struct();
gui_fmt.txt_w=gui_fmt.txt_w*0.8;
pos=create_pos_3(nb_rows,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtTitleStyle,'String','Parameters','Position',pos{1,1}{1}+[0 0 gui_fmt.txt_w 0]);
ref=list_echo_int_ref();
echo_int_tab_comp.ref=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.popumenuStyle,'String',ref,'Value',1,'Position',pos{2,2}{1}+[gui_fmt.box_w 0 0 0]);
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'String','Main Chan.','Position',pos{2,1}{1});
echo_int_tab_comp.tog_freq=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.popumenuStyle,'String','--','Value',1,'Position',pos{2,1}{2}+[0 0 gui_fmt.box_w 0]);

curr_disp.init_grid_val(trans_obj);

[dx,dy]=curr_disp.get_dx_dy();
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'String','Cell Width','Position',pos{3,1}{1});
echo_int_tab_comp.cell_w=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.edtStyle,'position',pos{3,1}{2},'string',dx,'Tag','w');

uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'String','Cell Height','Position',pos{4,1}{1});
echo_int_tab_comp.cell_h=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.edtStyle,'position',pos{4,1}{2},'string',dy,'Tag','h');

% if isempty(layer_obj.GPSData.Lat)
%     units_w= {'pings','seconds'};
%     xaxis_opt={'Ping Number' 'Time'};
% else
units_w= {'meters','pings','seconds'};
xaxis_opt={'Distance' 'Ping Number' 'Time' 'Lat' 'Long'};
%end

w_unit_idx=find(strcmp(curr_disp.Xaxes_current,units_w));

echo_int_tab_comp.cell_w_unit=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.popumenuStyle,'String',units_w,'Value',w_unit_idx,'Position',pos{3,2}{1},'Tag','w');
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'String','Range min(m)','Position',pos{4,2}{1},'TooltipString','Min range from the ref used for EI');
echo_int_tab_comp.r_min=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.edtStyle,'position',pos{4,2}{2},'string',0,'Tag','rmin','callback',{@check_fmt_box,0,Inf,Inf,'%.1f'});
echo_int_tab_comp.cell_w_unit_curr=get(echo_int_tab_comp.cell_w_unit,'value');

uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'String','Depth min(m)','Position',pos{5,1}{1});
echo_int_tab_comp.d_min=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.edtStyle,'position',pos{5,1}{2},'string',0,'Tag','dmin','callback',{@check_fmt_box,0,Inf,Inf,'%.1f'});

uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'String','Depth max(m)','Position',pos{5,2}{1});
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'String','Range max(m)','Position',pos{6,2}{1},'TooltipString','Max range from the ref used for EI');
echo_int_tab_comp.r_max=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.edtStyle,'position',pos{6,2}{2},'string',Inf,'Tag','rmax','callback',{@check_fmt_box,0,Inf,Inf,'%.1f'});
echo_int_tab_comp.d_max=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.edtStyle,'position',pos{5,2}{2},'string',Inf,'Tag','dmax','callback',{@check_fmt_box,0,Inf,Inf,'%.1f'});

echo_int_tab_comp.sv_thr_bool=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.chckboxStyle,'String','Sv Thr(dB)','Position',pos{6,1}{1},'Value',0);
echo_int_tab_comp.sv_thr=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.edtStyle,'position',pos{6,1}{2},'string',-999,'Tag','sv_thr','callback',{@check_fmt_box,-999,0,-80,'%.0f'});

set([echo_int_tab_comp.cell_w echo_int_tab_comp.cell_h],'callback',{@check_cell,main_figure,echo_int_tab_comp})
set(echo_int_tab_comp.cell_w_unit ,'callback',{@tog_units,main_figure,echo_int_tab_comp});


gui_fmt=init_gui_fmt_struct();
gui_fmt.txt_w=gui_fmt.txt_w*1.4;
pos=create_pos_3(nb_rows,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.txt_w,gui_fmt.box_h);

echo_int_tab_comp.denoised=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.chckboxStyle,'Value',0,'String','Denoised data','Position',pos{7,1}{1});
echo_int_tab_comp.motion_corr=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.chckboxStyle,'Value',0,'String','Motion Correction','Position',pos{7,1}{2});
echo_int_tab_comp.shadow_zone=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.chckboxStyle,'Value',0,'String','Shadow zone Est. (m)','Position',pos{7,1}{1},'visible','off');
echo_int_tab_comp.shadow_zone_h=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.edtStyle,'position',pos{7,1}{2}+[0 0 gui_fmt.box_w-gui_fmt.txt_w 0],'string','10','callback',{@ check_fmt_box,0,inf,10,'%.1f'},'visible','off');
echo_int_tab_comp.rm_st=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.chckboxStyle,'Value',0,'String','Rm.Single Targets','Position',pos{8,1}{1});
echo_int_tab_comp.all_freq=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.chckboxStyle,'Value',0,'String','All Frequencies','Position',pos{8,1}{2});

echo_int_tab_comp.reg_only=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.chckboxStyle,'Value',1,'String','Integrate by','Position',pos{9,1}{1},'Tooltipstring','unchecked: integrate all WC within bounds');
int_opt={'Tag' 'ID' 'Name' 'All Data Regions'};
echo_int_tab_comp.tog_int=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.popumenuStyle,'String',int_opt,'Value',1,'Position',pos{9,1}{2}-[0 0 gui_fmt.txt_w/3 0]);
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'position',pos{10,1}{1},'string','Region specs: ');
echo_int_tab_comp.reg_id_box=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.edtStyle,'position',pos{10,1}{2}-[0 0 gui_fmt.txt_w/3 0],'string','');

p_button=pos{11,1}{1};
p_button(3)=gui_fmt.button_w;
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.pushbtnStyle,'String','Compute','pos',p_button,'callback',{@slice_transect_cback,main_figure})
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.pushbtnStyle,'String','Export','pos',p_button+[gui_fmt.button_w 0 0 0],'callback',{@export_cback,main_figure})
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.pushbtnStyle,'String','Import','pos',p_button+[2*gui_fmt.button_w 0 0 0],'callback',@load_echoint_results_cback)
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.pushbtnStyle,'String','Outliers','pos',p_button+[0 -gui_fmt.button_h 0 0],'callback',{@rearrange_data,main_figure})%

set(echo_int_tab_comp.echo_int_tab,'ResizeFcn',{@resize_echo_int_cback,main_figure});

%display part
init_disp=13;
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtTitleStyle,'String','Display','Position',pos{init_disp,1}{1});

ref_idx=find(strcmp(ref,'Surface'));
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'String','Reference ','Position',pos{init_disp+1,1}{1}-[0 0 gui_fmt.txt_w/2 0]);
echo_int_tab_comp.tog_ref=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.popumenuStyle,...
    'String',ref,'Value',ref_idx,'Position',pos{init_disp+1,1}{1}+[gui_fmt.txt_w/2 0 -gui_fmt.txt_w/2 0],'callback',{@update_cback,main_figure});
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'String','Data ','Position',pos{init_disp+2,1}{1}-[0 0 gui_fmt.txt_w/2 0]);
echo_int_tab_comp.tog_type=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.popumenuStyle,...
    'String',{'Sv' 'PRC' 'Std Sv' 'Nb Samples' 'Nb Tracks' 'Nb Single Targets' 'Tag'},'Value',1,'Position',pos{init_disp+2,1}{1}+[gui_fmt.txt_w/2 0 -gui_fmt.txt_w/2 0],'callback',{@update_cback,main_figure});
echo_int_tab_comp.tog_tfreq=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.popumenuStyle,...
    'String',{'--'},'Value',1,'Position',pos{init_disp+2,1}{2}-[0 0 gui_fmt.txt_w/2 0],'callback',{@update_cback,main_figure});
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'String','X-Axis ','Position',pos{init_disp+3,1}{1}-[0 0 gui_fmt.txt_w/2 0]);

echo_int_tab_comp.tog_xaxis=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.popumenuStyle,'String',xaxis_opt,...
    'Value',2,'Position',pos{init_disp+3,1}{1}+[ gui_fmt.txt_w/2 0 0 0],'callback',{@update_cback,main_figure});

setappdata(main_figure,'EchoInt_tab',echo_int_tab_comp);

if ~isempty(layer_obj)
    update_echo_int_tab(main_figure,1);
end

resize_echo_int_cback([],[],main_figure);

end

function update_cback(~,~,main_figure)
update_echo_int_tab(main_figure,0);
end

function slice_transect_cback(~,~,main_figure)

load_bar_comp=show_status_bar(main_figure);
load_bar_comp.progress_bar.setText('Slicing transect...');

update_survey_opts(main_figure);
echo_int_tab_comp=getappdata(main_figure,'EchoInt_tab');

layer_obj=get_current_layer();
if isempty(layer_obj)
    return;
end

survey_options_obj=layer_obj.get_survey_options();

idx_main=get(echo_int_tab_comp.tog_freq,'value');

[trans_obj,idx_freq]=layer_obj.get_trans(layer_obj.ChannelID{idx_main});
reg_type=echo_int_tab_comp.reg_id_box.String;
reg_types=strsplit(reg_type,';');

switch echo_int_tab_comp.tog_int.String{echo_int_tab_comp.tog_int.Value}
    case 'All Data Regions'
        idx_reg=trans_obj.find_regions_type('Data');
    case 'ID'
        reg_types=str2double(reg_types);
        idx_reg=trans_obj.find_regions_ID(reg_types);
    case 'Tag'
        idx_reg=trans_obj.find_regions_tag(reg_types);
    case 'Name'
        idx_reg=trans_obj.find_regions_name(reg_types);
end

show_status_bar(main_figure);
try

    if echo_int_tab_comp.all_freq.Value>0
        idx_sec=1:numel(layer_obj.Frequencies);
    else
        idx_sec=idx_main;
    end

    layer_obj.multi_freq_slice_transect2D(...
        'idx_main_freq',idx_main,...
        'idx_sec_freq',idx_sec,...
        'idx_regs',idx_reg,...
        'regs',region_cl.empty(),...
        'survey_options',survey_options_obj,...
        'load_bar_comp',getappdata(main_figure,'Loading_bar'));


catch err
    print_errors_and_warnings(1,'error',err);
    return;
end

hide_status_bar(main_figure);
freqs_out=layer_obj.Frequencies(layer_obj.EchoIntStruct.idx_freq_out);
idx_main=find(layer_obj.Frequencies(idx_freq)==freqs_out);
set(echo_int_tab_comp.tog_tfreq,'String',num2str(freqs_out'/1e3,'%.0f kHz'),'Value',idx_main);
setappdata(main_figure,'EchoInt_tab',echo_int_tab_comp);

ref={'Surface','Bottom','Transducer'};

idx=find(ismember(ref,layer_obj.EchoIntStruct.output_2D_type{1}));
if ~isempty(idx)
    set(echo_int_tab_comp.tog_ref,'String',ref(idx));
    set(echo_int_tab_comp.tog_ref,'Value',1);
end

update_echo_int_tab(main_figure,0);

hide_status_bar(main_figure);
end

function export_cback(~,~,main_figure)

layer_obj=get_current_layer();

if isempty(layer_obj.EchoIntStruct)
    return;
end

layer=get_current_layer();
if isempty(layer)
    return;
end

idx_main=layer_obj.EchoIntStruct.idx_freq_out;

if isempty(idx_main)||isempty(layer_obj.EchoIntStruct.output_2D)
    dlg_perso(main_figure,'Nothing to export','No echo-integration results to export. Re-run the echo-integration...');
    return;
end

[path_tmp,fileN,~]=fileparts(layer.Filename{1});

path_tmp = uigetdir(path_tmp,...
    'Save Sliced transect to folder');
if isequal(path_tmp,0)
    return;
end

load_bar_comp=show_status_bar(main_figure);
load_bar_comp.progress_bar.setText('Exporting Sliced transect...');
layer_obj.export_slice_transect_to_xls('use_int',1,'idx_main_freq',idx_main,'output_f',fullfile(path_tmp,fileN));

dlg_perso(main_figure,'Done','Echo-integration finished and exported... Done');
hide_status_bar(main_figure);
end

function curves_processed_files(file_processed,matlabFigProcessedData,titleFigProcessed,refFreq)
TTP=readtable(file_processed);
f_names = fieldnames(TTP);
mask_fieldnames = contains(f_names,'_fm');
TTP=removevars(TTP,f_names(mask_fieldnames));
val=TTP.Properties.VariableNames;

svind=find(startsWith(string(val),'Sv_')==1);
freqpos=val(startsWith(string(val),'Sv_')==1);
freq=cell(1,size(svind,2));

for f=1:size(svind,2)
    if f==1
        freq{f} = refFreq;
    else
        freq{f}=sscanf(freqpos{1,f},'Sv_%d');
    end
    my_field_sv_fig = strcat('Sv_',num2str(freq{1,f}),'kHz');
    variable_sv_fig.(my_field_sv_fig) = TTP{:,svind(f)};
end
Sv=struct2table(variable_sv_fig);

%Mean Depth
Depth_mean=TTP.Depth_mean;
Sv=table2array(Sv);
fig = new_echo_figure([]);
ax  = axes(fig,'nextplot','add');
freqs=cell(1,size(svind,2));
markercolor=[0.9290 0.6940 0.1250;0 0.4470 0.7410;0.8500 0.3250 0.0980;0.4660 0.6740 0.1880;0.6350 0.0780 0.1840;0.4940 0.1840 0.5560];

for f=1:size(svind,2)
    scatter(ax,Sv(:,f),Depth_mean,'MarkerEdgeColor',[markercolor(f,1:3)],...
        'MarkerFaceColor',[markercolor(f,1:3)],...
        'LineWidth',1.5);
    xlabel(ax,'MVBS');
    ylabel(ax,'Mean Depth');
    freqs{f}=append(num2str(freq{1,f}),'kHz');
    title(ax,titleFigProcessed,'Interpreter','none');
end
legend(freqs);
saveas(fig,matlabFigProcessedData,'png');
delete(fig);
end

function rearrange_data(~,~,main_figure)
% takes the echointegration files and creates new analysed echointegration
% the user choses the echointegration files from a voyage he wants to process
% the function retrieves the frequencies and the number of frequencies in the files
% it creates new analysed echointegration files with all the Sv_diff combinations for all the existing frequencies and
% it excludes the values with a low PRC
% for each echointegration file and each freq it creates plots (Sv values depending on the depth + charts for each freq with (lat,lon,depth,number of the row and corresponding Sv value if >-60dB) allowing the user to identify potential suspicious values that were forgotten during the processing (outliers)
% for a voyage the user can chose to concatenate all the echointegration files into a single one and plot the charts mentionned above for this file
TTF_entire_trip=[];
[files_surf,path_tmp] = uigetfile({'*Surface_sliced.csv';'*Transducer_sliced.csv';'*Surface.csv';'*Transducer.csv';'*Bottom.csv';'*Bottom_sliced.csv'},'Select echo integration files to rearrange for modelling','MultiSelect', 'on');
if isa(files_surf,'char')
    S=1;
else
    S=size(files_surf,2);
end
[refFreq,~]=input_dlg_perso(main_figure,'What is the reference frequency ?',{'Frequency (in kHz)'},...
    {'%.0f'},{38});
refFreq = refFreq{1};
for surf=1:S
    if S==1
        file_table_to_process=files_surf;
    else
        file_table_to_process=files_surf{surf};
    end
    opts = detectImportOptions(append(path_tmp,'\',file_table_to_process));
    opts=setvaropts(opts,'Time_S','InputFormat','dd/MM/yyyy HH:mm:ss.SSS');
    TTP=readtable(append(path_tmp,'\',file_table_to_process),opts);
    f_names = fieldnames(TTP);
    mask_fieldnames = contains(f_names,'_fm');
    TTP=removevars(TTP,f_names(mask_fieldnames));
    val=TTP.Properties.VariableNames;
    if ~ismember('eint',val)
        continue;
    end
    nbfreq=size(find(startsWith(string(val),'sv')==1),2);
    freqpos=val(startsWith(string(val),'sv')==1);
    % retrieving the frequencies and the number of frequencies in the files
    freq = cell(1,nbfreq);
    freq{1} = refFreq;
    for iif=2:nbfreq
        freq{iif} = sscanf(freqpos{1,iif},'sv_%d');
    end

    if ~isempty(TTP)
        nb_samples=TTP.nb_samples;
        eint=TTP.eint;
        Vert_Slice_Idx=TTP.Vert_Slice_Idx;
        Horz_Slice_Idx=TTP.Horz_Slice_Idx;
        Ping_S=TTP.Ping_S;
        Ping_E=TTP.Ping_E;
        Sample_S=TTP.Sample_S;
        Sample_E=TTP.Sample_E;
    
        Depth_min=TTP.Depth_min;
        Depth_max=TTP.Depth_max;
        Depth_mean=TTP.Depth_mean;
        Dist_to_bot_min=TTP.Dist_to_bot_min;
        Dist_to_bot_max=TTP.Dist_to_bot_max;
        Dist_to_bot_mean=TTP.Dist_to_bot_mean;
        Bottom_mean_depth=Depth_mean+Dist_to_bot_max;
        Time_S=TTP.Time_S;
        Lat_S=TTP.Lat_S;
        Lon_S=TTP.Lon_S;
        sv_mean=TTP.sv;
        ABC=TTP.ABC;
        Tags=TTP.Tags;
    
        svind=find(startsWith(string(val),'sv')==1);
        sdind=find(startsWith(string(val),'sd')==1);
        abcind=find(startsWith(string(val),'ABC')==1);
        
        if nbfreq >1
            for iif=2:nbfreq
                my_field_sv = strcat('sv_',num2str(freq{1,iif}),'kHz');
                my_field_sd = strcat('sd_Sv_',num2str(freq{1,iif}),'kHz');
                my_field_abc = strcat('ABC_',num2str(freq{1,iif}),'kHz');
                variable_sv_sd_abc.(my_field_sv) = TTP{:,svind(iif)};
                variable_sv_sd_abc.(my_field_sd) = TTP{:,sdind(iif)};
                variable_sv_sd_abc.(my_field_abc) = TTP{:,abcind(iif)};
            end
        else
            my_field_sv = strcat('sv_',num2str(freq{1,1}),'kHz');
            my_field_sd = strcat('sd_Sv_',num2str(freq{1,1}),'kHz');
            my_field_abc = strcat('ABC_',num2str(freq{1,1}),'kHz');
            variable_sv_sd_abc.(my_field_sv) = TTP{:,svind(1)};
            variable_sv_sd_abc.(my_field_sd) = TTP{:,sdind(1)};
            variable_sv_sd_abc.(my_field_abc) = TTP{:,abcind(1)};
        end
    
        indnum1=strfind(file_table_to_process,'_trans_')+7;
        indnum2=strfind(file_table_to_process,'_Transducer')-1;
        indnum3=strfind(file_table_to_process,'strat_')+6;
        numTransect=file_table_to_process(indnum1:indnum2);
        numStrat = file_table_to_process(indnum3:indnum1-8);
        indnum4 = strfind(file_table_to_process,'type_');
        dataType = file_table_to_process(indnum4+5:indnum3-8);
        indnumSnap = strfind(file_table_to_process,'snap_')+5;
        numSnap = file_table_to_process(indnumSnap);

        s=size(TTP);
        C = append(dataType,'_snap',numSnap,'_strat',numStrat,'_trans',numTransect);
        code=repelem(C,s(1,1),1);
        time=Time_S;
        time.Format='hh:mm:ss';
        date=Time_S;
        date.Format='dd/MM/yyyy';
    
        for iif=1:nbfreq
            my_field_Sv = strcat('Sv_',num2str(freq{iif}),'kHz');
            variable_Sv.(my_field_Sv) = log10(TTP{:,svind(iif)})*10;
        end
    
        % constructing all the Sv diff combinations for all existing freq
        variable_Sv=struct2table(variable_Sv);
        variable_Svarray=table2array(variable_Sv);
        if size(variable_Svarray, 2) >1
            svcombinations = nchoosek(1:size(variable_Svarray, 2), 2);
        else
            svcombinations = 1;
        end
        Sv_diff = zeros(size(variable_Svarray, 1), size(svcombinations, 1));
        my_field_Sv_diff=cell(2, size(svcombinations, 1));
        for combi = 1:size(svcombinations, 1)
            if combi>1
                [comb1,comb2] = freq{:, svcombinations(combi, :)};
                my_field_Sv_diff{1,combi} = comb1;
                my_field_Sv_diff{2,combi} = comb2;
                Sv_diff(:, combi) = diff(variable_Svarray(:, svcombinations(combi, :)), 1, 2);
            else
                comb1 = freq{:, svcombinations(combi, :)};
                my_field_Sv_diff{1,combi} = comb1;
            end
        end
    
        for ii=1:size(my_field_Sv_diff,2)
            if ischar(my_field_Sv_diff{1,ii})
                my_field_sv_diff=strcat('Sv',my_field_Sv_diff{1,ii},'_',num2str(my_field_Sv_diff{2,ii}));
            else
                my_field_sv_diff=strcat('Sv',num2str(my_field_Sv_diff{1,ii}),'_',num2str(my_field_Sv_diff{2,ii}));
            end
            variable_Svdiff.(my_field_sv_diff)=Sv_diff(:,ii);
        end

        time.Format='HH:mm:ss.SSS';
        TTF0=table(nb_samples,eint,Vert_Slice_Idx,Horz_Slice_Idx,Ping_S,Ping_E,Sample_S,Sample_E,time);
        date.Format='dd/MM/yyyy';
        TTF1=table(date,Depth_min,Depth_max,Depth_mean,Dist_to_bot_min,Dist_to_bot_max,Dist_to_bot_mean,Lat_S,Lon_S,sv_mean,ABC,Tags);
        TTF2=struct2table(variable_sv_sd_abc);
        TTF3 = table(code,Bottom_mean_depth);
        TTF4=variable_Sv;
        TTF5=struct2table(variable_Svdiff);
        TTF=[TTF0 TTF1 TTF2 TTF3 TTF4 TTF5];
    
        [~,fttp_name,~] = fileparts(file_table_to_process);
        processedFileName=append(path_tmp,'\','analysed_',fttp_name,'.csv');
        writetable(TTF, processedFileName);
        titleFigProcessed=append('analysed_',fttp_name);
        matlabFigProcessedData=append(path_tmp,'\','analysed_',fttp_name);

        % plotting Sv values for each freq depending on the depth
        curves_processed_files(processedFileName,matlabFigProcessedData,titleFigProcessed,refFreq);
    
        % plotting the charts (lat,lon,depth,number of the row and corresponding Sv value if >thr) allowing the user to identify potential suspicious values that were forgotten during the processing (outliers)
        step=50; 
        depth_min=min(TTF.Depth_min);
        depth_max=max(TTF.Depth_max);
        a = depth_min:step:depth_max+step;
        DepthCat=cell(size(TTF,1),1);
        strd={};
        t=TTF.Depth_mean;
        for ii=1:size(a,2)-1
            strd{ii}=append(string(a(ii)),'-',string(a(ii)+step));
        end
        strd{size(a,2)}=append('>',string(a(end)));
        strd=strd';
        for ii=1:size(t,1)
            if isnan(t(ii))
                DepthCat{ii}='NaN';
            else
                valf=find((t(ii)<a)==1);
                DepthCat{ii}=strd(valf(1));
            end
        end
    
        % create categorical tablePlot after removing low sv values;
        for iif=1:nbfreq            
            temp=table2array(variable_Sv);
            % define threshold thanks to normal distribution of sv values for the transect
            thr_high_values = quantile(temp(:,iif),0.9);
            ind_high=find(temp(:,iif)>=thr_high_values==1);
            very_high_Svlevel = -30;
            if isnumeric(freq{iif})
                if freq{iif}<=38
                    thr_depth = 800;
                elseif freq{iif}<=70
                    thr_depth = 600;
                elseif freq{iif}<=120
                    thr_depth = 400;
                else
                    thr_depth = 250;
                end
            else
                thr_depth = 1000;
            end
            ind_deep=find(Depth_mean>=thr_depth==1);
            ind_deep_highSv = intersect(ind_high,ind_deep);  
            ind_very_high=find(temp(:,iif)>=very_high_Svlevel==1);
            ind_deep_highSv2 = union(ind_deep_highSv,ind_very_high);
    
            if ~isempty(ind_deep_highSv2)
                highSv = variable_Sv(ind_deep_highSv2,iif);
                highSvValues = table2array(highSv);
                Lat = Lat_S(ind_deep_highSv2,1);
                Lon = Lon_S(ind_deep_highSv2,1);
                tempDepthcat=cell2table(DepthCat);
                varDepthCat=tempDepthcat(ind_deep_highSv2,1);
                varDepthCat=table2cell(varDepthCat);
                CategoricalDepth=categorical(cellstr(varDepthCat));
                tablePlotSvLatLonDepth=table(CategoricalDepth,Lat,Lon,highSvValues);
                figgeo=new_echo_figure(main_figure,'Name','Mean MVBS (high values only)');
                gb = geobubble(figgeo,tablePlotSvLatLonDepth,'Lat','Lon','SizeVariable','highSvValues','ColorVariable','CategoricalDepth');
                gb.Title = 'Mean MVBS (high values only)';
                gb.SizeLegendTitle = 'Mean MVBS';
                geobasemap colorterrain
                nameGeoBubbleFig=append(path_tmp,'\','analysed_',fttp_name,'_LatLon_Depth_HighSv_',num2str(freq{iif}),'kHzValues');
                savefig(figgeo,nameGeoBubbleFig);
                delete(figgeo);
            end
        end
    clearvars -except path_tmp files_surf pwddir_surf pwddir_bot S B NameFileOrderedByDate create_TTF_entire_trip TTF_entire_trip mission nbfreq freqs main_figure refFreq;
    end
end
% concatenate all the echointegration files into a single one and plot the charts mentionned above for this file

app_path_main=whereisEcho();
esp3_icon = fullfile(app_path_main,'icons','echoanalysis.png');
f = uifigure;
f.ToolBar='none';
f.MenuBar='none';
f.Icon = esp3_icon;
f.Position = [680 580 700 100];
bg = uibuttongroup(f,'Position',[10 10 650 300], 'BorderType', 'none');
answer1 = uiradiobutton(bg,'Position',[10 55 700 15]);
answer2 = uiradiobutton(bg,'Position',[10 35 700 15]);
answer1.Text = 'Concatenate analysed EI files and plot Lat/Lon/Depth charts with high MVBS values for the resulting file';
answer2.Text = 'Do not concatenate analysed EI files and plot Lat/Lon/Depth charts with high MVBS values for the resulting file';
uiwait(f,5)
answer = answer1.Value;
close(f)

if answer == 1
    create_TTF_entire_trip=1;
else
    create_TTF_entire_trip=0;
    dlg_perso(main_figure,'Done','Processing of EI files complete, check the charts for possible outliers');
end

if create_TTF_entire_trip==1
    try
        [files_processed,path_tmp] = uigetfile('analysed*.csv','Select the echointegration files you want to concatenate','MultiSelect', 'on');
        if isa(files_processed,'char')
            S=1;
        else
            S=size(files_processed,2);
        end
    
        temps_proc=cell(S);
        namefile_proc=cell(S);
    
        for surf=1:S
            if S==1
                file_table_to_process=files_processed;
            else
                file_table_to_process=files_processed{surf};
            end
            opts = detectImportOptions(append(path_tmp,'\',file_table_to_process));
            opts = setvartype(opts,'date','datetime');
            opts=setvaropts(opts,'date','InputFormat','dd/MM/yyyy');
            T=readtable(append(path_tmp,'\',file_table_to_process),opts);
            temps_proc{surf}={append(string(T.date(1,:)),' ',string(T.time(1,:)))};
            namefile_proc{surf}={file_table_to_process};
        end
    
        temps_proc=cell2table(temps_proc);
        testproc=table2array(temps_proc);
        tempsbisproc=[testproc{1:surf}];
        [~,ind_tps_proc]=sort(datetime(tempsbisproc));
        NameFileOrderedByDateProc=namefile_proc(ind_tps_proc);
        TTF_entire_trip=[];
        mission=NameFileOrderedByDateProc{1}{1};
        indmission = strfind(mission,'_transect_');
        for surf=1:S
            file_table_to_process=NameFileOrderedByDateProc{surf}{1};
            T=readtable(append(path_tmp,'\',file_table_to_process));
            TTF_entire_trip=[TTF_entire_trip;T];
            fname=append(path_tmp,'\',mission(1:indmission-1),'.txt');
            writetable(TTF_entire_trip,fname);
        end
        step=50; 
        depth_min=min(TTF_entire_trip.Depth_min);
        depth_max=max(TTF_entire_trip.Depth_max);
        a = depth_min:step:depth_max+step;
        DepthCat=cell(size(TTF_entire_trip,1),1);
        strd=cell(1,size(a,2)-1);
        t=TTF_entire_trip.Depth_mean;
    
        for ii=1:size(a,2)-1
            strd{ii}=append(string(a(ii)),'-',string(a(ii)+step));
        end
    
        strd{size(a,2)}=append('>',string(a(end)));
        strd=strd';
        for ii=1:size(t,1)
            if isnan(t(ii))
                DepthCat{ii}='NaN';
            else
                valf=find((t(ii)<a)==1);
                DepthCat{ii}=strd(valf(1));
            end
        end
    
        val_entire_trip=TTF_entire_trip.Properties.VariableNames;
        Sv_ind_entire_trip=find(startsWith(string(val_entire_trip),'Sv_')==1);
        Lat_S = TTF_entire_trip.Lat_S;
        Lon_S = TTF_entire_trip.Lon_S;
    
        for iif=1:nbfreq
            variable_Sv_entire_trip=TTF_entire_trip{:,Sv_ind_entire_trip(iif)};
            thr_high_values = quantile(variable_Sv_entire_trip,0.9);
            ind_high=find(variable_Sv_entire_trip>=thr_high_values==1);
            very_high_Svlevel = -25;
            if isnumeric(freq{iif})
                if freq{iif}<=38
                    thr_depth = 1000;
                elseif freq{iif}<=70
                    thr_depth = 600;
                elseif freq{iif}<=120
                    thr_depth = 400;
                else
                    thr_depth = 250;
                end
            else
                thr_depth = 1000;
            end
            ind_deep=find(TTF_entire_trip.Depth_mean>=thr_depth==1);
            ind_deep_highSv = intersect(ind_high,ind_deep);  
            ind_very_high=find(variable_Sv_entire_trip>=very_high_Svlevel==1);
            ind_deep_highSv2 = union(ind_deep_highSv,ind_very_high);
    
            if ~isempty(ind_deep_highSv2)
                highSv = variable_Sv_entire_trip(ind_deep_highSv2);
                highSvValues = highSv;
                Lat = Lat_S(ind_deep_highSv2,1);
                Lon = Lon_S(ind_deep_highSv2,1);
                tempDepthcat=cell2table(DepthCat);
                varDepthCat=tempDepthcat(ind_deep_highSv2,1);
                varDepthCat=table2cell(varDepthCat);
                CategoricalDepth=categorical(cellstr(varDepthCat));
                tablePlotSvLatLonDepth=table(CategoricalDepth,Lat,Lon,highSvValues);
                figgeo=new_echo_figure(main_figure,'Name','Mean MVBS (high values only)');
                gb = geobubble(figgeo,tablePlotSvLatLonDepth,'Lat','Lon','SizeVariable','highSvValues','ColorVariable','CategoricalDepth');
                gb.Title = 'Mean MVBS (high values only)';
                gb.SizeLegendTitle = 'Mean MVBS';
                geobasemap colorterrain
                nameGeoBubbleFig=append(path_tmp,'\','analysed_',mission,'LatLon_Depth_HighSv_',num2str(freq{iif}),'kHzValues');
                savefig(figgeo,nameGeoBubbleFig);
                delete(figgeo);
            end
        end
        dlg_perso(main_figure,'Done','Processing of EI files complete, check the charts for possible outliers');
    catch
        dlg_perso(main_figure,'Done','Processing of EI files complete, check the charts for possible outliers');
    end
end
end

function resize_echo_int_cback(~,~,main_figure)
echo_int_tab_comp=getappdata(main_figure,'EchoInt_tab');
drawnow;
switch echo_int_tab_comp.echo_int_tab.Type
    case 'uitab'
        pos_tab=getpixelposition(echo_int_tab_comp.echo_int_tab);
        pos_tab(4)=pos_tab(4);
    case 'figure'
        pos_tab=getpixelposition(echo_int_tab_comp.echo_int_tab);
end

opt_panel_size=[0 pos_tab(4)-500+1 300 500];
ax_panel_size=[opt_panel_size(3) 0 pos_tab(3)-opt_panel_size(3) pos_tab(4)];

set(echo_int_tab_comp.opt_panel,'position',opt_panel_size);
set(echo_int_tab_comp.axes_panel,'position',ax_panel_size);
end