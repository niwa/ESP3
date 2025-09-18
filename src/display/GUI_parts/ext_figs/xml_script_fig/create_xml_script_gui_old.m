function xml_scrip_fig=create_xml_script_gui_old(varargin)

p = inputParser;
default_absorption=[2.7 9.8 22.8 37.4 52.7];
default_absorption_f=[18000 38000 70000 120000 200000];

addParameter(p,'main_figure',[],@(x)isempty(x)||ishandle(x));
addParameter(p,'survey_input_obj',survey_input_cl(),@(x) isa(x,'survey_input_cl'));
addParameter(p,'existing_scripts',0,@isnumeric);
addParameter(p,'logbook_file','',@(x) isfile(x)||isfolder(x));

parse(p,varargin{:});


size_max = get(0,'ScreenSize');
use_defaults=1;

survey_input_obj=p.Results.survey_input_obj;
surv_options_obj=survey_input_obj.Options;

cal=[];

if isfile(p.Results.logbook_file)
    log_f=p.Results.logbook_file;
else
    log_f=fullfile(p.Results.logbook_file,'echo_logbook.db');
end

if ~isempty(p.Results.main_figure)
    layers=get_esp3_prop('layers');
    if ~isempty(layers)
        [files_open,lay_IDs]=layers.list_files_layers();
        [folds,~,~]=cellfun(@fileparts,files_open,'un',0);

        if isfile(p.Results.logbook_file)
            path_f=fileparts(p.Results.logbook_file);
        else
            path_f=p.Results.logbook_file;
        end

        idx_f=find(strcmpi(folds,path_f));
        if ~isempty(idx_f)
            lay_id=lay_IDs{idx_f(1)};
            idx_lay=find(strcmpi({layers(:).Unique_ID},lay_id));
            if~ isempty(idx_f)
                use_defaults=0;
                cal=layers(idx_lay).get_cw_cal();
                
            end
        end
    end
end


if use_defaults
    if p.Results.existing_scripts==0
        cal.FREQ=default_absorption_f;
        cal.CID=cell(size(default_absorption_f));
        cal.alpha=default_absorption;
        cal.G0=25*ones(size(cal.FREQ));
        cal.EQA=-20.7*ones(size(cal.FREQ));
        cal.SACORRECT=zeros(size(cal.FREQ));
        str_box='No layers from the trip you are trying to build a script on are currently open, it will not know which Frequencies and calibration parameters to initialize.';
        dlg_perso(p.Results.main_figure,'No layers',str_box)
    end

end

if isempty(cal)
    cal.FREQ=union(surv_options_obj.Frequency.Value,surv_options_obj.FrequenciesToLoad.Value);
    for ifreq=1:numel(cal.FREQ)
        if cal.FREQ<120000
            att_model='doonan';
        else
            att_model='fandg';
        end
        cal.alpha(ifreq)=seawater_absorption(cal.FREQ(ifreq)/1e3,35,18, 20,att_model);
        cal.G0(ifreq)=25;
        cal.SACORRECT(ifreq)=0;
        cal.EQA(ifreq)=-20.7;
        cal.CID{ifreq}='';
    end
end

if p.Results.existing_scripts==0
    surv_options_obj.FrequenciesToLoad.Value=cal.FREQ;
    if ismember(surv_options_obj.Frequency.Value,surv_options_obj.FrequenciesToLoad.Value)
        surv_options_obj.Frequency.set_value(cal.FREQ(surv_options_obj.Frequency.Value==surv_options_obj.FrequenciesToLoad.Value));
    else
        surv_options_obj.Frequency.set_value(cal.FREQ(1));
    end
end

if p.Results.existing_scripts==0
    if ~isempty(survey_input_obj.Cal)
        [idx_f,idx_c]=ismember(cal.FREQ,[survey_input_obj.Cal(:).FREQ]);
        idx_c(idx_c==0)=[];
        if any(idx_f)
            cal.FREQ(idx_f)=[survey_input_obj.Cal(idx_c).FREQ];
            cal.G0(idx_f)=[survey_input_obj.Cal(idx_c).G0];
            cal.SACORRECT(idx_f)=[survey_input_obj.Cal(idx_c).SACORRECT];
            cal.EQA(idx_f)=[survey_input_obj.Cal(idx_c).EQA];
            cal.CID(idx_f)=[survey_input_obj.Cal(idx_c).CID];
        end
    end
end

surv_options_obj.Absorption.set_value(cal.alpha);


ws='normal';

xml_scrip_fig=new_echo_figure(p.Results.main_figure,'WindowStyle',ws,'Resize','on','Position',[0 0 size_max(3)*0.8 size_max(4)*0.8],...
    'Name','Script Builder','visible','off','Tag','XMLScriptCreationTool');

%pos_main=getpixelposition(xml_scrip_fig);

xml_script_h.infos_panel=uipanel(xml_scrip_fig,'units','normalized','Position',[0 3/5 1/3 2/5],'title','(1) Information','BackgroundColor','white','fontweight','bold');
xml_script_h.options_panel=uipanel(xml_scrip_fig,'units','normalized','Position',[0 0 1/3 3/5],'title','(2) Echo-Integrations settings','BackgroundColor','white','fontweight','bold');
xml_script_h.cal_f_panel=uipanel(xml_scrip_fig,'units','normalized','Position',[1/3 3/4 1/3 1/4],'title','(3) Frequencies/Calibration/Absorption','BackgroundColor','white','fontweight','bold');
xml_script_h.regions_panel=uipanel(xml_scrip_fig,'units','normalized','Position',[1/3 3/4-1/3 1/3 1/3],'title','(4) Regions','BackgroundColor','white','fontweight','bold');
xml_script_h.algos_panel=uipanel(xml_scrip_fig,'units','normalized','Position',[1/3 1/6 1/3 1/4],'title','(5) Algorithms','BackgroundColor','white','fontweight','bold');
xml_script_h.validation_panel=uipanel(xml_scrip_fig,'units','normalized','Position',[1/3 0 1/3 1/6],'title','(7) Create Script','BackgroundColor','white','fontweight','bold');
xml_script_h.transect_panel=uipanel(xml_scrip_fig,'units','normalized','Position',[2/3 0 1/3 1],'title','(6) Select transects','BackgroundColor','white','fontweight','bold');

% default_info=struct('Script','','XmlId','','Title','','Main_species','','Areas','','Voyage','','SurveyName','',...
%     'Author','','Created','','Comments','');
gui_fmt=init_gui_fmt_struct('norm',11,1);
tmp=gui_fmt.box_w;
gui_fmt.box_w=gui_fmt.txt_w*0.9;
gui_fmt.txt_w=tmp;

pos=create_pos_3(11,1,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);

uicontrol(xml_script_h.infos_panel,gui_fmt.txtStyle,'Position',pos{1,1}{1},'String','Title:');
xml_script_h.Infos.Title=uicontrol(xml_script_h.infos_panel,gui_fmt.edtStyle,'Position',pos{1,1}{2},'String',survey_input_obj.Infos.Title,'Tag','Title');

uicontrol(xml_script_h.infos_panel,gui_fmt.txtStyle,'Position',pos{2,1}{1},'String','Voyage:');
xml_script_h.Infos.Voyage=uicontrol(xml_script_h.infos_panel,gui_fmt.edtStyle,'Position',pos{2,1}{2},'String',survey_input_obj.Infos.Voyage,'Tag','Voyage');

uicontrol(xml_script_h.infos_panel,gui_fmt.txtStyle,'Position',pos{3,1}{1},'String','Survey Name:');
xml_script_h.Infos.SurveyName=uicontrol(xml_script_h.infos_panel,gui_fmt.edtStyle,'Position',pos{3,1}{2},'String',survey_input_obj.Infos.SurveyName,'Tag','SurveyName');

uicontrol(xml_script_h.infos_panel,gui_fmt.txtStyle,'Position',pos{4,1}{1},'String','Areas:');
xml_script_h.Infos.Areas=uicontrol(xml_script_h.infos_panel,gui_fmt.edtStyle,'Position',pos{4,1}{2},'String',survey_input_obj.Infos.Areas,'Tag','Areas');

uicontrol(xml_script_h.infos_panel,gui_fmt.txtStyle,'Position',pos{5,1}{1},'String','Main Species:');
xml_script_h.Infos.Main_species=uicontrol(xml_script_h.infos_panel,gui_fmt.edtStyle,'Position',pos{5,1}{2},'String',survey_input_obj.Infos.Main_species,'Tag','Main_species');

uicontrol(xml_script_h.infos_panel,gui_fmt.txtStyle,'Position',pos{6,1}{1},'String','Author:');
xml_script_h.Infos.Author=uicontrol(xml_script_h.infos_panel,gui_fmt.edtStyle,'Position',pos{6,1}{2},'String',survey_input_obj.Infos.Author,'Tag','Author');

uicontrol(xml_script_h.infos_panel,gui_fmt.txtStyle,'Position',pos{7,1}{1},'String','Comments:');
xml_script_h.Infos.Comments=uicontrol(xml_script_h.infos_panel,gui_fmt.edtStyle,'Position',pos{11,1}{2}+[-pos{1,1}{1}(3)  0 pos{1,1}{1}(3) 4*pos{1,1}{1}(4)],...
    'String',survey_input_obj.Infos.Comments,'Tag','Comments','Min',0,'Max',10);

fields=fieldnames(xml_script_h.Infos);

for ifi=1:numel(fields)
    set(xml_script_h.Infos.(fields{ifi}),'Callback',{@update_survey_input_infos,fields{ifi}});
    switch xml_script_h.Infos.(fields{ifi}).Style
        case 'edit'
               set(xml_script_h.Infos.(fields{ifi}),'HorizontalAlignment','left');
    end
end



%surv_options_obj
%'callback',{@ check_fmt_box,-80,-15,varin.thr_bottom,'%.0f'}

panel1=uipanel(xml_script_h.options_panel,'units','normalized','Position',[0 2/3 1 1/3],'title','Channel, Integration Grid, bounds','BackgroundColor','white','fontweight','normal');
panel2=uipanel(xml_script_h.options_panel,'units','normalized','Position',[0 1/6 1 1/2],'title','Options','BackgroundColor','white','fontweight','normal');
panel3=uipanel(xml_script_h.options_panel,'units','normalized','Position',[0 0 1 1/6],'title','Exports','BackgroundColor','white','fontweight','normal');

gui_fmt=init_gui_fmt_struct('norm',5,2);
pos=create_pos_3(5,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);

uicontrol(panel1,gui_fmt.txtTitleStyle,'String','Main Channel','Position',pos{1,1}{1});
xml_script_h.Options.Frequency=uicontrol(panel1,gui_fmt.popumenuStyle,'String',num2cell(surv_options_obj.FrequenciesToLoad.Value),...
    'Value',find(surv_options_obj.Frequency.Value==surv_options_obj.FrequenciesToLoad.Value),'Position',pos{1,1}{2}+[0 0 gui_fmt.box_w 0],'Tag','Frequency');

curr_disp=get_esp3_prop('curr_disp');

if ~isempty(curr_disp)
    [dx,dy]=curr_disp.get_dx_dy();
else
    dx=5;
    dy=5;
end

uicontrol(panel1,gui_fmt.txtStyle,'String','Vertical slice size','Position',pos{2,1}{1});
xml_script_h.Options.Vertical_slice_size=uicontrol(panel1,gui_fmt.edtStyle,'position',pos{2,1}{2},'string',dx,'Tag','Vertical_slice_size','callback',{@check_fmt_box,0,Inf,surv_options_obj.Vertical_slice_size.Value,'%.2f'});
uicontrol(panel1,gui_fmt.txtStyle,'String','Horizontal slice size','Position',pos{3,1}{1});
xml_script_h.Options.Horizontal_slice_size=uicontrol(panel1,gui_fmt.edtStyle,'position',pos{3,1}{2},'string',dy,'Tag','Horizontal_slice_size','callback',{@check_fmt_box,0,Inf,surv_options_obj.Horizontal_slice_size.Value,'%.2'});

units_w= {'meters','pings','seconds'};
w_unit_idx=find(strcmp(surv_options_obj.Vertical_slice_units.Value,units_w));
xml_script_h.Options.Vertical_slice_units=uicontrol(panel1,gui_fmt.popumenuStyle,'String',units_w,'Value',w_unit_idx,'Position',pos{2,2}{1}-[0 0 gui_fmt.txt_w/2 0],'Tag','Vertical_slice_units');

uicontrol(panel1,gui_fmt.txtStyle,'String','Min Depth (m)','Position',pos{4,1}{1});
xml_script_h.Options.DepthMin=uicontrol(panel1,gui_fmt.edtStyle,'position',pos{4,1}{2},'string',surv_options_obj.DepthMin.Value,'Tag','DepthMin','callback',{@check_fmt_box,0,Inf,surv_options_obj.DepthMin.Value,'%.1f'});

uicontrol(panel1,gui_fmt.txtStyle,'String','Max Depth(m)','Position',pos{4,2}{1});
xml_script_h.Options.DepthMax=uicontrol(panel1,gui_fmt.edtStyle,'position',pos{4,2}{2},'string',surv_options_obj.DepthMax.Value,'Tag','DepthMax','callback',{@check_fmt_box,0,Inf,surv_options_obj.DepthMax.Value,'%.1f'});

uicontrol(panel1,gui_fmt.txtStyle,'String','SoundSpeed(m/s)','Position',pos{5,1}{1});
xml_script_h.Options.SoundSpeed=uicontrol(panel1,gui_fmt.edtStyle,'position',pos{5,1}{2},'string',surv_options_obj.SoundSpeed.Value,'Tag','SoundSpeed','callback',{@check_fmt_box,1400,1600,surv_options_obj.SoundSpeed.Value,'%.2f'});


gui_fmt=init_gui_fmt_struct('norm',6,2);
pos=create_pos_3(6,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);
dd  =gui_fmt.box_w*1.5;
uicontrol(panel2,gui_fmt.txtStyle,'String','Integration type:','Position',pos{1,1}{1}+[0 0 -dd 0],'Tooltipstring',sprintf('"WC":\n-integrate all water at the given grid and given reference ignoring region specifications.\n"By regions":\n-only integrate specified regions.'));
int_opt={'By regions' 'WC'};
xml_script_h.Options.IntType=uicontrol(panel2,gui_fmt.popumenuStyle,'String',int_opt,'Value',1,'Position',pos{1,1}{2}+[-dd 0 dd 0],'Tag','IntType');

uicontrol(panel2,gui_fmt.txtStyle,'String','Reference:','Position',pos{1,2}{1}+[0 0 -dd 0]);
int_opt=[{'--'} list_echo_int_ref];
xml_script_h.Options.IntRef=uicontrol(panel2,gui_fmt.popumenuStyle,'String',int_opt,'Value',1,'Position',pos{1,2}{2}+[-dd 0 dd 0],'Tag','IntRef');

xml_script_h.Options.SvThr_bool=uicontrol(panel2,gui_fmt.chckboxStyle,'String','Sv Thr(dB)','Position',pos{2,1}{1},'Value',0,'Tag','SvThr_bool');
xml_script_h.Options.SvThr=uicontrol(panel2,gui_fmt.edtStyle,'position',pos{2,1}{2},'string',-999,'Tag','SvThr','callback',{@check_fmt_box,-999,0,surv_options_obj.SvThr.Value,'%.0f'});

uicontrol(panel2,gui_fmt.txtStyle,'String','Bad Pings % thr.','Position',pos{2,2}{1});
xml_script_h.Options.BadTransThr=uicontrol(panel2,gui_fmt.edtStyle,'position',pos{2,2}{2},'string','100','callback',{@ check_fmt_box,0,100,surv_options_obj.BadTransThr.Value,'%.0f'},'visible','on','tag','BadTransThr');

xml_script_h.Options.Es60_correction_bool=uicontrol(panel2,gui_fmt.chckboxStyle,'Value',0,'String','ES60 correction (dB)','Position',pos{3,1}{1},'visible','on','tag','Es60_correction_bool');
xml_script_h.Options.Es60_correction=uicontrol(panel2,gui_fmt.edtStyle,'position',pos{3,1}{2},'string',num2str(surv_options_obj.Es60_correction.Value),'callback',{@ check_fmt_box,0,inf,surv_options_obj.Es60_correction.Value,'%.2f'},'visible','on','tag','Es60_correction');

xml_script_h.Options.Shadow_zone=uicontrol(panel2,gui_fmt.chckboxStyle,'Value',surv_options_obj.Shadow_zone.Value,'String','Shadow zone Est. (m)','Position',pos{3,2}{1},'visible','on','tag','Shadow_zone');
xml_script_h.Options.Shadow_zone_height=uicontrol(panel2,gui_fmt.edtStyle,'position',pos{3,2}{2},'string',num2str(surv_options_obj.Shadow_zone_height.Value),'callback',{@ check_fmt_box,0,inf,surv_options_obj.Shadow_zone_height.Value,'%.1f'},'visible','on','tag','Shadow_zone_height');


xml_script_h.Options.Use_exclude_regions=uicontrol(panel2,gui_fmt.chckboxStyle,'Value',surv_options_obj.Use_exclude_regions.Value,'String','Rm. Bad Data Regions','Position',pos{4,1}{1},'tag','Use_exclude_regions');
xml_script_h.Options.Denoised=uicontrol(panel2,gui_fmt.chckboxStyle,'Value',surv_options_obj.Denoised.Value,'String','Denoised data','Position',pos{4,2}{1},'tag','Denoised');

xml_script_h.Options.Motion_correction=uicontrol(panel2,gui_fmt.chckboxStyle,'Value',surv_options_obj.Motion_correction.Value,'String','Motion Correction','Position',pos{5,1}{1},'tag','Motion_correction');
xml_script_h.Options.CopyBottomFromFrequency=uicontrol(panel2,gui_fmt.chckboxStyle,'position',pos{5,2}{1},'Value',surv_options_obj.CopyBottomFromFrequency.Value,'String','Copy Bot. from main Freq','tag','CopyBottomFromFrequency');

xml_script_h.Options.Remove_ST=uicontrol(panel2,gui_fmt.chckboxStyle,'Value',surv_options_obj.Remove_ST.Value,'String','Rm. Single Targets','Position',pos{6,1}{1},'tag','Remove_ST');
xml_script_h.Options.Remove_tracks=uicontrol(panel2,gui_fmt.chckboxStyle,'Value',surv_options_obj.Remove_tracks.Value,'String','Remove Tracks','Position',pos{6,2}{1},'tag','Remove_tracks');



gui_fmt=init_gui_fmt_struct('norm',2,2);
pos=create_pos_3(2,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);

xml_script_h.Options.SaveBot=uicontrol(panel3,gui_fmt.chckboxStyle,'position',pos{1,1}{1},'Value',surv_options_obj.SaveBot.Value,'String','Save Bottom','tag','SaveBot');
xml_script_h.Options.SaveReg=uicontrol(panel3,gui_fmt.chckboxStyle,'position',pos{1,2}{1},'Value',surv_options_obj.SaveReg.Value,'String','Save Regions','tag','SaveReg');
xml_script_h.Options.ExportRegions=uicontrol(panel3,gui_fmt.chckboxStyle,'position',pos{2,1}{1},'Value',surv_options_obj.ExportRegions.Value,'String','Export Regions','tag','ExportRegions');
xml_script_h.Options.ExportSlicedTransects=uicontrol(panel3,gui_fmt.chckboxStyle,'position',pos{2,2}{1},'Value',surv_options_obj.ExportSlicedTransects.Value,'String','Export Sliced transects','tag','ExportSlicedTransects');

fields_opt=fieldnames(xml_script_h.Options);
for iopt=1:numel(fields_opt)
    set(xml_script_h.Options.(fields_opt{iopt}),'callback',@update_survey_input_options);
end


colNames={'Denoise','Bot. Detect V1','Bot. Detect V2','Spikes Removal','Bad Pings','School Detect','Single Target','Track Target'};

col_fmt=cell(1,numel(colNames)+1);
col_fmt(:)={'logical'};
col_fmt(1)={'numeric'};

col_edit=true(1,numel(colNames)+1);
col_edit(1)=false;

data_init=cell(numel(surv_options_obj.FrequenciesToLoad.Value),numel(colNames));
data_init(:,1)=num2cell(surv_options_obj.FrequenciesToLoad.Value);
data_init(:,2)={0};

xml_script_h.algo_table=uitable('Parent',xml_script_h.algos_panel,...
    'Data', data_init,...
    'ColumnName', [{'Freq.'} colNames],...
    'ColumnFormat',col_fmt,...
    'ColumnEditable', col_edit,...
    'Units','Normalized','Position',[0 0 1 1],...
    'RowName',[]);
xml_script_h.algo_table.UserData.AlgosNames={'Denoise','BottomDetection','BottomDetectionV2','SpikesRemoval','BadPingsV2','SchoolDetection','SingleTarget','TrackTarget'};
set(xml_script_h.algo_table,'CellEditCallback',{@edit_algos_process_data_cback});
xml_script_h.process_list=process_cl.empty();


gui_fmt=init_gui_fmt_struct('norm',10,2);
pos=create_pos_3(10,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);
% possible values and default
ref = list_echo_int_ref();
ref_idx = 1;

% text
xml_script_h.reg_wc.bool=uicontrol(xml_script_h.regions_panel,...
    gui_fmt.chckboxStyle,...
    'String','Region WC:',...
    'FontWeight','Bold',...
    'Position',pos{1,1}{1});

uicontrol(xml_script_h.regions_panel,...
    gui_fmt.txtStyle,...
    'String','Reference (Ref):',...
    'Position',pos{2,1}{1});

% value
xml_script_h.reg_wc.Ref = uicontrol(xml_script_h.regions_panel,...
    gui_fmt.popumenuStyle,...
    'String',ref,...
    'Value',ref_idx,...
    'Position',pos{2,1}{2}+[0 0 gui_fmt.box_w 0]);


%% Region type

% possible values and default
data_type = {'Data' 'Bad Data'};
data_idx = 1;

% text
uicontrol(xml_script_h.regions_panel,...
    gui_fmt.txtStyle,...
    'String','Data Type (Type):',...
    'Position',pos{3,1}{1});

% value
xml_script_h.reg_wc.Type = uicontrol(xml_script_h.regions_panel,...
    gui_fmt.popumenuStyle,...
    'String',data_type,...
    'Value',data_idx,...
    'Position',pos{3,1}{2}+[0 0 gui_fmt.box_w 0]);

% ymin text
 uicontrol(xml_script_h.regions_panel,...
    gui_fmt.txtStyle,...
    'BackgroundColor','white',...
    'String','R min (m):',...
    'Position',pos{4,1}{1});

% ymin value
xml_script_h.reg_wc.y_min = uicontrol(xml_script_h.regions_panel,...
    gui_fmt.edtStyle,...
    'position',pos{4,1}{2},...
    'string',0,...
    'Tag','w');


% ymax text
 uicontrol(xml_script_h.regions_panel,...
    gui_fmt.txtStyle,...
    'String','R max (m):',...
    'Position',pos{4,2}{1});

% ymax value
xml_script_h.reg_wc.y_max = uicontrol(xml_script_h.regions_panel,...
    gui_fmt.edtStyle,...
    'position',pos{4,2}{2},...
    'string',inf,...
    'Tag','w');

%% Cell width

% possible values and default
units_w = {'pings','meters'};
w_unit_idx = 1;

% text
uicontrol(xml_script_h.regions_panel,...
    gui_fmt.txtStyle,...
    'String','Cell Width:',...
    'Position',pos{5,1}{1});

% value
xml_script_h.reg_wc.Cell_w = uicontrol(xml_script_h.regions_panel,...
    gui_fmt.edtStyle,...
    'position',pos{5,1}{2},...
    'string',10,...
    'Tag','w');

% unit
xml_script_h.reg_wc.Cell_w_unit = uicontrol(xml_script_h.regions_panel,...
    gui_fmt.popumenuStyle,...
    'String',units_w,...
    'Value',w_unit_idx,...
    'units','normalized',...
    'Position',pos{5,1}{2}+[gui_fmt.x_sep+gui_fmt.box_w 0 gui_fmt.box_w 0],...
    'Tag','w');

%% cell height

% possible values and default
units_h = {'meters','samples'};
h_unit_idx = 1;

% text
uicontrol(xml_script_h.regions_panel,...
    gui_fmt.txtStyle,...
    'String','Cell Height:',...
    'Position',pos{6,1}{1});

% value
xml_script_h.reg_wc.Cell_h = uicontrol(xml_script_h.regions_panel,...
    gui_fmt.edtStyle,...
    'position',pos{6,1}{2},...
    'string',10,...
    'Tag','h');

% unit
xml_script_h.reg_wc.Cell_h_unit = uicontrol(xml_script_h.regions_panel,...
    gui_fmt.popumenuStyle,...
    'String',units_h,...
    'Value',h_unit_idx,...
    'Position',pos{6,1}{2}+[gui_fmt.x_sep+gui_fmt.box_w 0 gui_fmt.box_w 0],...
    'Tag','h');


fields_wc=fieldnames(xml_script_h.reg_wc);
for iwc=1:numel(fields_wc)
       set(xml_script_h.reg_wc.(fields_wc{iwc}),'callback',{@update_reg_wc_region,fields_wc{iwc}});
    if ~strcmp(fields_wc{iwc},'bool')
        if xml_script_h.reg_wc.bool.Value>0
            set(xml_script_h.reg_wc.(fields_wc{iwc}),'enable','on');
        else
            set(xml_script_h.reg_wc.(fields_wc{iwc}),'enable','off');
        end
    end
end



xml_script_h.reg_only=uicontrol(xml_script_h.regions_panel,gui_fmt.chckboxStyle,'Value',1,'String','Filter by','Position',pos{8,1}{1},'Tooltipstring','unchecked: integrate all WC within bounds','Fontweight','bold');
int_opt={'Tag' 'IDs' 'Name' 'All Data Regions'};
xml_script_h.tog_int=uicontrol(xml_script_h.regions_panel,gui_fmt.popumenuStyle,'String',int_opt,'Value',1,'Position',pos{8,1}{2}+[0 0 gui_fmt.box_w 0]);
uicontrol(xml_script_h.regions_panel,gui_fmt.txtStyle,'position',pos{9,1}{1},'string','Region specs: ');
xml_script_h.reg_id_box=uicontrol(xml_script_h.regions_panel,gui_fmt.edtStyle,'position',pos{9,1}{2}+[0 0 gui_fmt.box_w 0],'string','');


colNames={' ','Frequency (Hz)','G0 (dB)','SaCorr.(dB)','EQA(dB)','Alpha(db/km)'};
col_fmt=cell(1,numel(colNames));

col_fmt(:)={'numeric'};
col_fmt(1)={'logical'};

col_edit=true(1,numel(colNames));
col_edit(2)=false;

data_init=cell(numel(surv_options_obj.FrequenciesToLoad.Value),numel(colNames));

data_init(:,1)={1==1};
data_init(:,2)=num2cell(cal.FREQ);
data_init(:,3)=num2cell(cal.G0);
data_init(:,4)=num2cell(cal.SACORRECT);
data_init(:,5)=num2cell(cal.EQA);
data_init(:,6)=num2cell(cal.alpha);



xml_script_h.cal_f_table=uitable('Parent',xml_script_h.cal_f_panel,...
    'Data', data_init,...
    'ColumnName',  colNames,...
    'ColumnFormat',col_fmt,...
    'ColumnEditable', col_edit,...
    'CellEditCallback',@cell_edit_cback,...
    'CellSelectionCallback',{},...
    'Units','Normalized','Position',[0 0 1 1],...
    'RowName',[]);


%%%%%%%%%%%%Transects table section%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
opt_table_panel=uipanel(xml_script_h.transect_panel,'units','normalized','Position',[0 0.8 1 0.2],'title','','BackgroundColor','white','fontweight','normal');
table_panel=uipanel(xml_script_h.transect_panel,'units','normalized','Position',[0 0 1 0.8],'title','','BackgroundColor','white','fontweight','normal');

colNames={' ','Folder','Snapshot','Type','Stratum','Transect','Comment'};
col_fmt={'logical' 'char' 'numeric' 'char' 'char' 'numeric' 'char' };

col_edit=false(1,numel(colNames));
col_edit(1)=true;

try
    [data_init,log_files]=get_table_data_from_survey_input_obj(p.Results.survey_input_obj,p.Results.logbook_file);
catch err
    print_errors_and_warnings([],'error',err);
    data_init = [];
    log_files = [];
end

xml_script_h.transects_table=uitable('Parent',table_panel,...
    'Data', data_init,...
    'ColumnName',  colNames,...
    'ColumnFormat',col_fmt,...
    'ColumnEditable', col_edit,...
    'Units','Normalized','Position',[0 0 1 1],...
    'RowName',[]);

gui_fmt=init_gui_fmt_struct('norm',2,2);
%pos=create_pos_3(2,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);

xml_script_h.logbook_table = uitable('Parent',opt_table_panel,...
    'Data',log_files(:),...
    'ColumnName',{'Logbooks in table'},...
    'ColumnFormat',{'char'},...
    'ColumnEditable',false,...
    'CellSelectionCallback',@cell_select_cback,...
    'RowName',[],...
    'Units','normalized',...
    'Position',[0 0 gui_fmt.txt_w+gui_fmt.box_w 1]);
xml_script_h.logbook_table.UserData.select=[];
table_width=getpixelposition(xml_script_h.logbook_table);
set(xml_script_h.logbook_table,'ColumnWidth',{table_width(3)});

rc_menu = uicontextmenu(ancestor(xml_script_h.logbook_table,'figure'));
uimenu(rc_menu,'Label','Add Logbook','Callback',{@add_logbook_cback,xml_script_h.logbook_table,1});
uimenu(rc_menu,'Label','Remove entry(ies)','Callback',{@add_logbook_cback,xml_script_h.logbook_table,-1});
xml_script_h.logbook_table.UIContextMenu =rc_menu;

%%%%%Create Scripts section%%%%%%%%%%

if ~isempty(p.Results.main_figure)
    app_path=get_esp3_prop('app_path');
    p_scripts=app_path.scripts.Path_to_folder;
else
    p_scripts=pwd;
end

uicontrol(xml_script_h.validation_panel,gui_fmt.txtStyle,...
    'Position',[0.05 0.65 0.2 0.15],...
    'string','File:','Tooltipstring',sprintf('in folder: %s',p_scripts),...
    'HorizontalAlignment','Right');
if isempty(survey_input_obj.Infos.Script)
    str_fname=generate_valid_filename([survey_input_obj.Infos.Voyage '_' survey_input_obj.Infos.SurveyName]);
else
    [~,str_fname,~] = fileparts(survey_input_obj.Infos.Script);
end
xml_script_h.f_name_edit = uicontrol(xml_script_h.validation_panel,gui_fmt.edtStyle,...
    'Position',[0.3 0.65 0.45 0.15],...
    'BackgroundColor','w',...
    'string', [str_fname '.xml'],...
    'HorizontalAlignment','left','Callback',@checkname_cback);

uicontrol(xml_script_h.validation_panel,gui_fmt.pushbtnStyle,...
    'Position',[0.3 0.3 0.3 0.2],...
    'string','Create ',...
    'Callback',{@create_script_cback,p.Results.main_figure});

survey_input_obj.Options = surv_options_obj;

setappdata(xml_scrip_fig,'xml_script_h',xml_script_h);
setappdata(xml_scrip_fig,'survey_input_obj',survey_input_obj);

set(xml_scrip_fig,'visible','on');
end

function cell_select_cback(src,evt)
src.UserData.select=evt.Indices;
end

function add_logbook_cback(src,~,tb,id)
xml_scrip_fig=ancestor(src,'figure');
xml_script_h=getappdata(xml_scrip_fig,'xml_script_h');
survey_input_obj=getappdata(xml_scrip_fig,'survey_input_obj');

if id<0 || ~isempty(tb.UserData.select)
    tb.Data(tb.UserData.select)=[];
     [data_init,log_files]=get_table_data_from_survey_input_obj(survey_input_obj,tb.Data);
     tb.Data=log_files(:);
     xml_script_h.transects_table.Data=data_init;
else
    path_init= tb.Data(tb.UserData.select);
    if isempty(path_init)
        path_init=tb.Data;
    end
    if isempty(path_init)
        path_init={pwd};
    end
    
    path_init=path_init{1};
        [~,path_f]= uigetfile({fullfile(path_init,'echo_logbook.db')}, 'Pick a logbook file','MultiSelect','off');
        if path_f==0
            return;
        end
        [data_init,log_files]=get_table_data_from_survey_input_obj(survey_input_obj,union({path_f},tb.Data));
         tb.Data=log_files(:);
        xml_script_h.transects_table.Data=data_init;
end
end

function create_script_cback(src,~,main_figure)

xml_scrip_fig=ancestor(src,'figure');
xml_script_h=getappdata(xml_scrip_fig,'xml_script_h');

survey_input_obj=getappdata(xml_scrip_fig,'survey_input_obj');

    app_path=get_esp3_prop('app_path');
    p_scripts=app_path.scripts.Path_to_folder;

algos_lists=xml_script_h.process_list();
ialin=0;
al_out={};
f_tot=[];
for ial=1:numel(algos_lists)
    f=algos_lists(ial).Freq;
    algos=algos_lists(ial).Algo;
    f_tot=union(f,f_tot);
    for iali=1:numel(algos)
        ialin=ialin+1;
        al_out{ialin}.Name=algos(iali).Name;
        al_out{ialin}.Varargin=algos(iali).input_params_to_struct;
        al_out{ialin}.Varargin.Frequencies=f;
    end
end

survey_input_obj.Algos=al_out;
int_opt=xml_script_h.tog_int.String;

switch int_opt{xml_script_h.tog_int.Value}
    case 'All Data Regions'
        ids='IDs';
        ids_str='';
    otherwise
        ids=int_opt{xml_script_h.tog_int.Value};
        ids_str=xml_script_h.reg_id_box.String;
end

data_init=xml_script_h.transects_table.Data;
if isempty(data_init)
    dlg_perso(main_figure,'No data','Nothing to put in the script.');
    return;
end
surv_data_struct.Folder=data_init(:,2);
surv_data_struct.Snapshot=cell2mat(data_init(:,3));
surv_data_struct.Type=data_init(:,4);
surv_data_struct.Stratum=data_init(:,5);
surv_data_struct.Transect=cell2mat(data_init(:,6));
idx_struct=cell2mat(data_init(:,1));
survey_input_obj.complete_survey_input_cl_from_struct(surv_data_struct,idx_struct,ids,ids_str);

data_init=xml_script_h.cal_f_table.Data;

idx_struct=find(cell2mat(data_init(:,1)));
cal.FREQ=cell2mat(data_init(:,2));
idx_f=union(idx_struct,find(ismember(cal.FREQ,f_tot)));

cal.FREQ=cal.FREQ(idx_f);
cal.G0=cell2mat(data_init(idx_f,3));
cal.CID=cell(size(idx_f));
cal.SACORRECT=cell2mat(data_init(idx_f,4));
cal.EQA=cell2mat(data_init(idx_f,5));
cal.alpha=cell2mat(data_init(idx_f,6));
survey_input_obj.Cal=[];

for i=1:length(cal.FREQ)
    cal_temp.FREQ=cal.FREQ(i);
    cal_temp.G0=cal.G0(i);
    cal_temp.SACORRECT=cal.SACORRECT(i);
     cal_temp.EQA=cal.EQA(i);
     survey_input_obj.Cal=[survey_input_obj.Cal cal_temp];
end
survey_input_obj.Options.FrequenciesToLoad.set_value(cal.FREQ);
survey_input_obj.Options.Absorption.set_value(cal.alpha);
survey_input_obj.Infos.Script = fullfile(p_scripts,xml_script_h.f_name_edit.String);
survey_input_obj.survey_input_to_survey_xml('xml_filename',fullfile(p_scripts,xml_script_h.f_name_edit.String));
open_txt_file(fullfile(p_scripts,xml_script_h.f_name_edit.String));
end

function update_reg_wc_region(src,~,field)

xml_scrip_fig=ancestor(src,'figure');
xml_script_h=getappdata(xml_scrip_fig,'xml_script_h');
survey_input_obj=getappdata(xml_scrip_fig,'survey_input_obj');
reg_def=struct(...
        'y_min',0,...
        'y_max',Inf,...
        'Ref','surface',...
        'Type','data',...
        'Cell_w',10,...
        'Cell_h',10,...
        'Cell_w_unit','pings',...
        'Cell_h_unit','meters'...
        );
switch src.Style
    case 'edit'
        val=str2double(src.String);
        if isnan(val)
            src.String=num2str(reg_def.(field));
        end  
end


fields_wc=fieldnames(xml_script_h.reg_wc);
for iwc=1:numel(fields_wc)
    if ~strcmp(fields_wc{iwc},'bool')
        if xml_script_h.reg_wc.bool.Value>0
            set(xml_script_h.reg_wc.(fields_wc{iwc}),'enable','on');
        else
            set(xml_script_h.reg_wc.(fields_wc{iwc}),'enable','off');
        end
    end
end
        
if xml_script_h.reg_wc.bool.Value
    ref = get(xml_script_h.reg_wc.Ref,'String');
    ref_idx = get(xml_script_h.reg_wc.Ref,'value');
    
    data_type = get(xml_script_h.reg_wc.Type,'String');
    data_type_idx = get(xml_script_h.reg_wc.Type,'value');
    
    h_units = get(xml_script_h.reg_wc.Cell_h_unit,'String');
    h_units_idx = get(xml_script_h.reg_wc.Cell_h_unit,'value');
    
    w_units = get(xml_script_h.reg_wc.Cell_w_unit,'String');
    w_units_idx = get(xml_script_h.reg_wc.Cell_w_unit,'value');
    
    y_min = str2double(get(xml_script_h.reg_wc.y_min,'string'));
    y_max = str2double(get(xml_script_h.reg_wc.y_max,'string'));
    
    cell_w = str2double(get(xml_script_h.reg_wc.Cell_w,'string'));
    cell_h = str2double(get(xml_script_h.reg_wc.Cell_h,'string'));
    
    
    Regions_WC{1}=struct(...
        'y_min',y_min,...
        'y_max',y_max,...
        'Ref',ref{ref_idx},...
        'Type',data_type{data_type_idx},...
        'Cell_w',cell_w,...
        'Cell_h',cell_h,...
        'Cell_w_unit',w_units{w_units_idx},...
        'Cell_h_unit',h_units{h_units_idx}...
        );

else
    Regions_WC={};
end
survey_input_obj.Regions_WC=Regions_WC;
end


function update_survey_input_options(src,~)
xml_scrip_fig=ancestor(src,'figure');
xml_script_h=getappdata(xml_scrip_fig,'xml_script_h');
survey_input_obj=getappdata(xml_scrip_fig,'survey_input_obj');
surv_options_obj = survey_input_obj.Options;
survey_opt_def=survey_options_cl();
opts_h=xml_script_h.Options;
switch src.Style
    case 'checkbox'
        if contains(src.Tag,'_bool')
            field=strrep(src.Tag,'_bool','');
            updt=get(src,'value');
            val=get(opts_h.(field),'string');
        else
            field=src.Tag;
            val=get(opts_h.(field),'value');
            updt=1;
        end
    case 'edit'
        field=src.Tag;
        if isfield(opts_h,[src.Tag '_bool'])
            updt=get(opts_h.([src.Tag '_bool']),'value');
        else
            updt=1;
        end
        val=get(opts_h.(field),'string');
    case 'popupmenu'
        field=src.Tag;
        switch field
            case 'ClassificationFile'
                val_cell=xml_script_h.classification_files;
            otherwise
                val_cell=get(opts_h.(field),'string');
        end
        
        if iscell(val_cell)
            val=val_cell{get(opts_h.(field),'value')};
        else
            val=val_cell(get(opts_h.(field),'value'));
        end
        updt=1;
end


if updt>0
    if ischar(surv_options_obj.(field))
        surv_options_obj.(field)=val;
    else
        if ischar(val)
            val=str2double(val);
        end
        if isnan(val)
            val=survey_opt_def.(field).Value;
            set(opts_h.(field),'string',survey_opt_def.(field).Value);
        end
        surv_options_obj.(field)=val;
    end
    
else
    surv_options_obj.(field)=survey_opt_def.(field).Value;
    if ischar(surv_options_obj.(field))
        set(opts_h.(field),'string',survey_opt_def.(field).Value)
    else
        
        set(opts_h.(field),'string',num2str(survey_opt_def.(field)).Value)
    end
end
%surv_options_obj
survey_input_obj.Options = surv_options_obj;

end


function update_survey_input_infos(src,~,field)
xml_scrip_fig=ancestor(src,'figure');
xml_script_h=getappdata(xml_scrip_fig,'xml_script_h');
survey_input_obj=getappdata(xml_scrip_fig,'survey_input_obj');
infos_h=xml_script_h.Infos;

val=get(infos_h.(field),'string');
switch field
    case {'Title' 'Voyage' 'SurveyName'}
        val = clean_str(val);
        src.String  =val;
end
survey_input_obj.Infos.(field)=val;

end



function checkname_cback(src,~)

[~, file_n,~]=fileparts(src.String);
file_n=generate_valid_filename(file_n);
set(src,'String',[file_n '.xml']);

end

function edit_algos_process_data_cback(src,evt)

if isempty(evt.Indices)
    return;
end

xml_scrip_fig=ancestor(src,'Figure');
xml_script_h=getappdata(xml_scrip_fig,'xml_script_h');
algo=init_algos(src.UserData.AlgosNames(evt.Indices(2)-1));

freq=src.Data{evt.Indices(1),1};

add=evt.EditData;
src.Data{evt.Indices(1),evt.Indices(2)}=evt.EditData;
xml_script_h.process_list=xml_script_h.process_list.set_process_list(freq,algo,add);

setappdata(xml_scrip_fig,'xml_script_h',xml_script_h);

end

function cell_edit_cback(src,evt)
idx=evt.Indices;
row_id=idx(1);
if ~iscell(src.ColumnFormat{idx(2)})
    switch src.ColumnFormat{idx(2)}
        case 'char'
            src.Data{row_id,idx(2)}=strtrim(src.Data{row_id,idx(2)});
        case 'numeric'
            if isnan(evt.NewData)
                src.Data{row_id,idx(2)}=evt.PreviousData;
            end
    end
end
end
