function xml_scrip_fig=create_xml_script_gui(varargin)

p = inputParser;

addParameter(p,'survey_input_obj',survey_input_cl(),@(x) isa(x,'survey_input_cl'));
addParameter(p,'existing_scripts',0,@isnumeric);
addParameter(p,'logbook_file','',@(x) isfile(x)||isfolder(x));

parse(p,varargin{:});


size_max = get(groot, 'MonitorPositions');
size_max = min(size_max,[],1);
existing_layer = false;

survey_input_obj=p.Results.survey_input_obj;
surv_options_obj=survey_input_obj.Options;
default_row_height = 26;
default_col_width = 90;
cal = init_cal_struct(survey_input_obj.Cal);

layers = get_esp3_prop('layers');
main_figure = get_esp3_prop('main_figure');

if ~isempty(layers)
    [files_open,lay_IDs]=layers.list_files_layers();
    [folds,~,~]=cellfun(@fileparts,files_open,'un',0);

    if isfile(p.Results.logbook_file)
        path_f = fileparts(p.Results.logbook_file);
    elseif isfolder(p.Results.logbook_file)
        path_f = p.Results.logbook_file;
    else
        path_f = folds{1};
    end

    idx_f=find(strcmpi(folds,path_f));

    if ~isempty(idx_f)
        lay_id=lay_IDs{idx_f(1)};
        idx_lay=find(strcmpi({layers(:).Unique_ID},lay_id),1);
        if~ isempty(idx_f)
            existing_layer = true;
            cal=layers(idx_lay).get_cw_cal();
            if ismember('survey_input_obj',p.UsingDefaults)
                surv_options_obj = layers(idx_lay).get_survey_options();
            end
        end
    end

end

if ~existing_layer && ~p.Results.existing_scripts
    str_box='No layers from the trip you are trying to build a script on are currently open, please do so then re-open the script builder.';
    fig = dlg_perso(main_figure,'No layers',str_box);
    waitfor(fig);
    xml_scrip_fig = [];
    return;
end

if existing_layer

    surv_options_obj.Absorption.set_value(cal.alpha);
    surv_options_obj.FrequenciesToLoad.Value=cal.FREQ;
    surv_options_obj.ChannelsToLoad.Value=cal.CID;

    if ~isempty(survey_input_obj.Cal)
        [idx_f,idx_c]=ismember(cal.FREQ,[survey_input_obj.Cal(:).FREQ]);
        idx_c(idx_c==0)=[];
        if any(idx_f)
            cal.FREQ(idx_f)=[survey_input_obj.Cal(idx_c).FREQ];
            cal.G0(idx_f)=[survey_input_obj.Cal(idx_c).G0];
            cal.SACORRECT(idx_f)=[survey_input_obj.Cal(idx_c).SACORRECT];
            cal.EQA(idx_f)=[survey_input_obj.Cal(idx_c).EQA];
            %cal.CID(idx_f)=[survey_input_obj.Cal(idx_c).CID];
        end
    end
else
    for uif = 1:numel(cal.FREQ)
        id  = find(cal.FREQ(uif) == surv_options_obj.FrequenciesToLoad.Value,1);
        if ~isempty(id)&&numel(surv_options_obj.Absorption.Value)<=id
            cal.alpha(uif) = surv_options_obj.Absorption.Value(id);
        end
    end
end


xml_script_h.cal = cal;


ws='normal';

xml_scrip_fig=new_echo_figure(main_figure,'WindowStyle',ws,'Resize','on','Position',[0 0 size_max(3)*0.9 size_max(4)*0.9],...
    'Name','Script Builder','visible','off','Tag','XMLScriptCreationTool','UiFigureBool',true);

general_layout = uigridlayout(xml_scrip_fig,[6 3]);
general_layout.ColumnWidth = {'1x' '1x' '0.75x'};
general_layout.RowHeight = repmat({'1x'},6,1);

xml_script_h.infos_panel=uipanel(general_layout,'Title','(1) Information','BackgroundColor','white','fontweight','bold','Scrollable','on');
xml_script_h.infos_panel.Layout.Row = [1 2];
xml_script_h.infos_panel.Layout.Column = 1;

xml_script_h.options_panel=uipanel(general_layout,'Title','(2) Echo-Integrations settings','BackgroundColor','white','fontweight','bold','Scrollable','on');
xml_script_h.options_panel.Layout.Row = [3 6];
xml_script_h.options_panel.Layout.Column = 1;

xml_script_h.cal_f_panel=uipanel(general_layout,'Title','(3) Frequencies/Calibration/Absorption','BackgroundColor','white','fontweight','bold','Scrollable','on');
xml_script_h.cal_f_panel.Layout.Row = [1 2];
xml_script_h.cal_f_panel.Layout.Column = 2;

xml_script_h.regions_panel=uipanel(general_layout,'Title','(4) Regions','BackgroundColor','white','fontweight','bold','Scrollable','on');
xml_script_h.regions_panel.Layout.Row = [3 4];
xml_script_h.regions_panel.Layout.Column = 2;

xml_script_h.algos_panel=uipanel(general_layout,'Title','(5) Algorithms','BackgroundColor','white','fontweight','bold','Scrollable','on');
xml_script_h.algos_panel.Layout.Row = [5 6];
xml_script_h.algos_panel.Layout.Column = 2;

xml_script_h.transect_panel=uipanel(general_layout,'Title','(6) Select transects','BackgroundColor','white','fontweight','bold','Scrollable','on');
xml_script_h.transect_panel.Layout.Row = [1 5];
xml_script_h.transect_panel.Layout.Column = 3;

xml_script_h.validation_panel=uipanel(general_layout,'Title','(7) Create Script','BackgroundColor','white','fontweight','bold','Scrollable','on');
xml_script_h.validation_panel.Layout.Row = 6;
xml_script_h.validation_panel.Layout.Column = 3;

info_content = {'Title' 'Main_species' 'Areas' 'Voyage' 'SurveyName' 'Author' 'Comments'};
info_disp = {'Title' 'Main species' 'Area(s)' 'Voyage' 'Survey name' 'Author(s)' 'Comments'};
nb_entries = numel(info_content);
cc = ceil(nb_entries/2);
infos_gl = uigridlayout(xml_script_h.infos_panel,[cc 4]);
infos_gl.ColumnWidth = {default_col_width '1x' default_col_width '1x'};
infos_gl.RowHeight = [repmat({default_row_height},cc-1,1);{'1x'}];

for uinf = 1 : nb_entries-1
    uilabel(infos_gl,'Text',sprintf('%s:',info_disp{uinf}));
    xml_script_h.Infos.(info_content{uinf}) = uieditfield(infos_gl,"CharacterLimits",[0 100], ...
        'HorizontalAlignment','left','Value',survey_input_obj.Infos.(info_content{uinf}),'ValueChangedFcn',@update_info_value,'Tag',info_content{uinf});
end
tmp = uilabel(infos_gl,'Text',sprintf('%s:',info_disp{uinf+1}));
tmp.Layout.Row = cc;
tmp.Layout.Column = 1;

xml_script_h.Infos.Comments= uitextarea(infos_gl,'Value',survey_input_obj.Infos.(info_content{uinf+1}),'ValueChangedFcn',@update_info_value,'Tag',info_content{uinf+1});
xml_script_h.Infos.Comments.Layout.Column = [2 4];


echo_int_gl = uigridlayout(xml_script_h.options_panel,[5,1]);

chan_opt = {'Frequency' 'IntRef'...
    'IntType' 'Horizontal_slice_size'...
    'Vertical_slice_size' 'Vertical_slice_units' ...
    'DepthMin' 'DepthMax' ...
    'RangeMin' 'RangeMax' ...
    'SoundSpeed' 'Temperature' ...
    'CTD_profile' 'SVP_profile'
    };

opts_opt = {'SvThr' 'BadTransThr'...
    'Use_exclude_regions' 'Motion_correction'...
    'Denoised' 'Es60_correction'...
    'Shadow_zone' 'Shadow_zone_height'...
    'Remove_ST' 'Remove_tracks'...
    };
exp_opt = {'SaveBot' 'SaveReg' ...
    'ExportSlicedTransects' 'ExportRegions' ...
    'Export_ST' 'Export_TT' 'RunInt'...
    };
%
%                       SvThr: [1×1 input_param_cl]
%         Use_exclude_regions: [1×1 input_param_cl]
%             Es60_correction: [1×1 input_param_cl]
%           Motion_correction: [1×1 input_param_cl]
%                 Shadow_zone: [1×1 input_param_cl]
%          Shadow_zone_height: [1×1 input_param_cl]
%         Vertical_slice_size: [1×1 input_param_cl]
%        Vertical_slice_units: [1×1 input_param_cl]
%       Horizontal_slice_size: [1×1 input_param_cl]
%                     IntType: [1×1 input_param_cl]
%                      IntRef: [1×1 input_param_cl]
%               Remove_tracks: [1×1 input_param_cl]
%                   Remove_ST: [1×1 input_param_cl]
%                   Export_ST: [1×1 input_param_cl]
%                   Export_TT: [1×1 input_param_cl]
%                    Denoised: [1×1 input_param_cl]
%                   Frequency: [1×1 input_param_cl]
%                     Channel: [1×1 input_param_cl]
%           FrequenciesToLoad: [1×1 input_param_cl]
%              ChannelsToLoad: [1×1 input_param_cl]
%                  Absorption: [1×1 input_param_cl]
%     CopyBottomFromFrequency: [1×1 input_param_cl]
%                 CTD_profile: [1×1 input_param_cl]
%                 SVP_profile: [1×1 input_param_cl]
%                 Temperature: [1×1 input_param_cl]
%                    Salinity: [1×1 input_param_cl]
%                  SoundSpeed: [1×1 input_param_cl]
%                 BadTransThr: [1×1 input_param_cl]
%                     SaveBot: [1×1 input_param_cl]
%                     SaveReg: [1×1 input_param_cl]
%                    DepthMin: [1×1 input_param_cl]
%                    DepthMax: [1×1 input_param_cl]
%                    RangeMin: [1×1 input_param_cl]
%                    RangeMax: [1×1 input_param_cl]
%                 RefRangeMin: [1×1 input_param_cl]
%                 RefRangeMax: [1×1 input_param_cl]
%                    AngleMin: [1×1 input_param_cl]
%                    AngleMax: [1×1 input_param_cl]
%       ExportSlicedTransects: [1×1 input_param_cl]
%               ExportRegions: [1×1 input_param_cl]
%                      c: [1×1 input_param_cl]

tt_chan_opt = [];

for uip = 1:numel(chan_opt)
    tt_chan_opt = [tt_chan_opt surv_options_obj.(chan_opt{uip})];
end


tt_opts_opt = [];

for uip = 1:numel(opts_opt)
    tt_opts_opt = [tt_opts_opt surv_options_obj.(opts_opt{uip})];
end

tt_exp_opt = [];

for uip = 1:numel(exp_opt)
    tt_exp_opt = [tt_exp_opt surv_options_obj.(exp_opt{uip})];
end

tmp=uipanel(echo_int_gl,'BackgroundColor','white','Scrollable','on');
tmp.Layout.Row = [1 2];
xml_script_h.echo_chan_panel_h = input_set_panel_cl('container_h',tmp,'std_rowheight',default_row_height,...
    'Title','Channel, Integration, grid, bounds','Input_param_obj_vec',tt_chan_opt,'layout_size',[nan,2]);

tmp=uipanel(echo_int_gl,'BackgroundColor','white','Scrollable','on');
xml_script_h.opt_opts_panel_h = input_set_panel_cl('container_h',tmp,'std_rowheight',default_row_height,...
    'Title','Options','Input_param_obj_vec',tt_opts_opt,'layout_size',[nan,2]);
tmp.Layout.Row = [3 4];

tmp=uipanel(echo_int_gl,'BackgroundColor','white','Scrollable','on');
xml_script_h.echo_export_panel_h = input_set_panel_cl('container_h',tmp,'std_rowheight',default_row_height,...
    'Title','Exports','Input_param_obj_vec',tt_exp_opt,'layout_size',[nan,2]);


uigl_tmp = uigridlayout(xml_script_h.cal_f_panel,[1,1]);
uigl_tmp.Padding = [0 0 0 0];
xml_script_h.cal.select = true(size(xml_script_h.cal.G0,1),1);
cal_table = struct2table(xml_script_h.cal);
cal_table = cal_table(:,{'select' 'FREQ' 'G0' 'SACORRECT' 'EQA' 'alpha'});

colNames={' ','Frequency (Hz)','G0 (dB)','SaCorr.(dB)','EQA(dB)','Alpha(db/km)'};

col_edit=true(1,numel(colNames));
col_edit(2)=false;

col_fmt = repmat({''}, 1,size(cal_table,1));

xml_script_h.cal_f_table=uitable('Parent',uigl_tmp,...
    'Data', cal_table,...
    'ColumnName',  colNames,...
    'ColumnEditable', col_edit,...
    'ColumnFormat',col_fmt,...
    'CellEditCallback',@cell_edit_cback,...
    'CellSelectionCallback',{},...
    'RowName',[]);

if ~isempty(layers)
    fmin = surv_options_obj.FrequenciesMinToEI_FMmode.Value;
    fmax = surv_options_obj.FrequenciesMaxToEI_FMmode.Value;
    
    comptf = 1;
    for iif=1:size(surv_options_obj.ChannelsToLoad.Value,1)
        switch layers(idx_lay).get_trans(surv_options_obj.ChannelsToLoad.Value{iif}).Mode 
            case 'FM'
                varnames{comptf} = surv_options_obj.ChannelsToLoad.Value{iif};
                fmin(comptf) = layers(idx_lay).get_trans(surv_options_obj.ChannelsToLoad.Value{iif}).Params.FrequencyStart;
                fmax(comptf) = layers(idx_lay).get_trans(surv_options_obj.ChannelsToLoad.Value{iif}).Params.FrequencyEnd;
                comptf = comptf+1;
                sfm{iif} = surv_options_obj.FrequenciesToLoad.Value(iif);
        end
    end
    
    if comptf>1
        fbounds_table = array2table(vertcat(fmin,fmax),'RowNames',{'Min freq (Hz)','Max freq (Hz)'}, 'VariableNames', varnames);
        col_edit_f = true(1,size(fbounds_table,2));
        col_fmt_f = repmat({''}, 1,size(fbounds_table,1));
        
        xml_script_h.f_bounds_table=uitable('Parent',uigl_tmp,...
            'Data', fbounds_table,...
            'ColumnEditable', col_edit_f,...
            'ColumnFormat',col_fmt_f);
    else
        xml_script_h.f_bounds_table=uitable('Parent',[],...
        'Data', [], 'Position',[0 0 0 0]);
    end
else
        xml_script_h.f_bounds_table=uitable('Parent',[],...
        'Data', [],'Position',[0 0 0 0]);
end

disp(get(xml_script_h.cal_f_table))
reg_opts = {'IntRef'...
    'DataType' ...
    'RangeMin' 'RangeMax' ...
    'Cell_w' 'Cell_w_unit' 'Cell_h'...
    };

tt_reg_opt = [];

for uip = 1:numel(reg_opts)
    tmp  =init_input_params(reg_opts{uip});
    if ~isempty(survey_input_obj.Regions_WC)
        if isfield(survey_input_obj.Regions_WC{1},reg_opts{uip})
            tmp.set_value(survey_input_obj.Regions_WC{1}.(reg_opts{uip}));
        end
    end
    tt_reg_opt = [tt_reg_opt tmp];
end

uigl_tmp = uigridlayout(xml_script_h.regions_panel,[3 1]);
uigl_tmp.RowHeight = {default_row_height '2x' '1x'};

xml_script_h.reg_wc.bool = uicheckbox(uigl_tmp,"Text",'Region WC','Value',~isempty(survey_input_obj.Regions_WC),'fontweight','bold','ValueChangedFcn',@update_reg_wc_opt);
xml_script_h.reg_wc_h = input_set_panel_cl('container_h',uigl_tmp,...
    'std_rowheight',default_row_height,...
    'std_colwidth',default_col_width,...
    'Input_param_obj_vec',tt_reg_opt,'layout_size',[nan,2]);

update_reg_wc_opt(xml_script_h.reg_wc.bool,[]);

uigl_tmp_tmp = uigridlayout(uigl_tmp,[1 4]);
uigl_tmp_tmp.RowHeight = {default_row_height};
uigl_tmp_tmp.ColumnWidth = {default_col_width default_col_width default_col_width default_col_width};
xml_script_h.reg_only.bool = uicheckbox(uigl_tmp_tmp,"Text",'Filter by','Value',false,'fontweight','bold');
int_opt={'Tag' 'IDs' 'Name' 'All Data Regions'};

xml_script_h.tog_int=uidropdown(uigl_tmp_tmp,'Items',int_opt,'Value',int_opt{1});
uilabel(uigl_tmp_tmp,'Text','Region specs: ');
xml_script_h.reg_id_box=uieditfield(uigl_tmp_tmp);


alg_names=list_algos();
col_fmt=cell(1,numel(alg_names)+1);
col_fmt(:)={'logical'};
col_fmt(1)={'char'};

col_edit=true(1,numel(alg_names)+1);
col_edit(1)=false;
data_init=cell(numel(surv_options_obj.FrequenciesToLoad.Value),numel(alg_names));
data_init(:)={false};
data_init(:,1)=num2cell(surv_options_obj.FrequenciesToLoad.Value);

xml_script_h.algo_table=uitable('Parent',xml_script_h.algos_panel,...
    'Data', data_init,...
    'ColumnName', [{'Freq.'} alg_names],...
    'ColumnFormat',col_fmt,...
    'ColumnEditable', col_edit,...
    'Units','Normalized','Position',[0 0 1 1],...
    'RowName',[]);
xml_script_h.algo_table.UserData.AlgosNames=alg_names;
set(xml_script_h.algo_table,'CellEditCallback',{@edit_algos_process_data_cback});
xml_script_h.process_list=process_cl.empty();

%%%%%%%%%%%%Transects table section%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uigl_tmp = uigridlayout(xml_script_h.transect_panel,[2 1]);
uigl_tmp.Padding = [0 0 0 0];uigl_tmp.RowHeight = {'0.2x' '0.8x'};

colNames={' ','Folder','Snapshot','Type','Stratum','Transect','Comment'};

col_edit=false(1,numel(colNames));
col_edit(1)=true;

try
    [data_init,log_files]=get_table_data_from_survey_input_obj(p.Results.survey_input_obj,p.Results.logbook_file);
catch err
    print_errors_and_warnings([],'error',err);
    data_init = [];
    log_files = [];
end
xml_script_h.logbook_table = uitable(uigl_tmp,...
    'Data',log_files(:),...
    'ColumnName',{'Logbooks in table'},...
    'ColumnFormat',{'char'},...
    'ColumnEditable',false,...
    'CellSelectionCallback',@cell_select_cback,...
    'RowName',[]);

xml_script_h.logbook_table.UserData.select=[];

rc_menu = uicontextmenu(ancestor(xml_script_h.logbook_table,'figure'));
uimenu(rc_menu,'Label','Add Logbook','MenuSelectedFcn',{@add_logbook_cback,xml_script_h.logbook_table,1});
uimenu(rc_menu,'Label','Remove entry(ies)','MenuSelectedFcn',{@add_logbook_cback,xml_script_h.logbook_table,-1});
xml_script_h.logbook_table.ContextMenu =rc_menu;

xml_script_h.transects_table=uitable('Parent',uigl_tmp,...
    'Data', data_init,...
    'ColumnName',  colNames,...
    'ColumnEditable', col_edit,...
    'RowName',[]);


%%%%%Create Scripts section%%%%%%%%%%
app_path=get_esp3_prop('app_path');
if ~isempty(app_path)
    p_scripts=app_path.scripts.Path_to_folder;
else
    p_scripts=pwd;
end
uigl_tmp = uigridlayout(xml_script_h.validation_panel,[2 2]);
uigl_tmp.RowHeight = {default_row_height default_row_height};
uigl_tmp.ColumnWidth = {default_col_width '1x'};

uilabel(uigl_tmp,...
    'Text','File:','Tooltip',sprintf('in folder: %s',p_scripts),...
    'HorizontalAlignment','Right');

if isempty(survey_input_obj.Infos.Script)
    str_fname=generate_valid_filename([survey_input_obj.Infos.Voyage '_' survey_input_obj.Infos.SurveyName]);
else
    [~,str_fname,~] = fileparts(survey_input_obj.Infos.Script);
end
xml_script_h.f_name_edit = uieditfield(uigl_tmp,...
    "CharacterLimits",[numel(str_fname)+4 80], ...
    'Value', [str_fname '.xml'],...
    'HorizontalAlignment','left','ValueChangedFcn',@checkname_cback);

uibutton(uigl_tmp,...
    'Text','Create ',...
    'ButtonPushedFcn',{@create_script_cback,main_figure});

survey_input_obj.Options = surv_options_obj;

xml_scrip_fig.Visible = 'on';

setappdata(xml_scrip_fig,'xml_script_h',xml_script_h);
setappdata(xml_scrip_fig,'survey_input_obj_gui',survey_input_obj);

    function update_reg_wc_opt(src,~)
        for uir = 1:numel(reg_opts)
            xml_script_h.reg_wc_h.(reg_opts{uir}).Enable  = src.Value;
        end
    end

    function update_info_value(src,~)
        survey_input_obj.Infos.(src.Tag) = src.Value;
    end
end

function edit_algos_process_data_cback(src,evt)

if isempty(evt.Indices)
    return;
end

xml_scrip_fig=ancestor(src,'Figure');
xml_script_h=getappdata(xml_scrip_fig,'xml_script_h');
alg_names=list_algos();

algo=init_algos(alg_names(evt.Indices(2)-1));

freq=src.Data{evt.Indices(1),1};

add=evt.NewData;

xml_script_h.process_list=xml_script_h.process_list.set_process_list('',freq,algo,add);

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
function cell_select_cback(src,evt)
src.UserData.select=evt.Indices;
end

function add_logbook_cback(src,~,tb,id)
xml_scrip_fig=ancestor(src,'figure');
xml_script_h=getappdata(xml_scrip_fig,'xml_script_h');
survey_input_obj=getappdata(xml_scrip_fig,'survey_input_obj_gui');

if id<0
    if ~isempty(tb.UserData.select)
        tb.Data(tb.UserData.select)=[];
        [data_init,log_files]=get_table_data_from_survey_input_obj(survey_input_obj,tb.Data);
        tb.Data=log_files(:);
        xml_script_h.transects_table.Data=data_init;
    end
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
    [data_init,log_files]=get_table_data_from_survey_input_obj(survey_input_obj,union(path_f,tb.Data));
    tb.Data=log_files(:);
    xml_script_h.transects_table.Data=data_init;
end
end
function checkname_cback(src,~)

[~, file_n,~]=fileparts(src.Value);
file_n=generate_valid_filename(file_n);
src.Value = [file_n '.xml'];

end

function create_script_cback(src,~,main_figure)

xml_scrip_fig=ancestor(src,'figure');
xml_script_h=getappdata(xml_scrip_fig,'xml_script_h');

survey_input_obj=getappdata(xml_scrip_fig,'survey_input_obj_gui');

app_path=get_esp3_prop('app_path');
p_scripts=app_path.scripts.Path_to_folder;

algos_lists=xml_script_h.process_list();
survey_input_obj.Regions_WC=update_reg_wc_region(xml_script_h);

ialin=0;
al_out={};
f_tot=[];
cid_tot = {};
for ial=1:numel(algos_lists)
    f=algos_lists(ial).Freq;
    cid=algos_lists(ial).CID;
    algos=algos_lists(ial).Algo;
    f_tot=union(f,f_tot);
    cid_tot=union(cid_tot,cid);
    for iali=1:numel(algos)
        ialin=ialin+1;
        al_out{ialin}.Name=algos(iali).Name;
        al_out{ialin}.Varargin=algos(iali).input_params_to_struct;
        al_out{ialin}.Varargin.Frequencies=f;
    end
end

survey_input_obj.Algos=al_out;
int_opt=xml_script_h.tog_int.Value;

switch int_opt
    case 'All Data Regions'
        ids='IDs';
        ids_str='';
    otherwise
        ids=int_opt;
        ids_str=xml_script_h.reg_id_box.Value;
end

data_init=xml_script_h.transects_table.Data;
if isempty(data_init)
    dlg_perso(main_figure,'No data','Nothing to put in the script.');
    return;
end
surv_data_struct.Folder=data_init.Var2;
surv_data_struct.Snapshot=data_init.Snapshot;
surv_data_struct.Type=data_init.Type;
surv_data_struct.Stratum=data_init.Stratum;
surv_data_struct.Transect=data_init.Transect;
idx_struct=data_init.Var1;
survey_input_obj.complete_survey_input_cl_from_struct(surv_data_struct,idx_struct,ids,ids_str);

data_init=xml_script_h.cal_f_table.Data;

idx_struct=find(data_init.select);
cal.FREQ=data_init.FREQ;

idx_f=union(idx_struct,find(ismember(cal.FREQ,f_tot)));

cal.FREQ=cal.FREQ(idx_f);
cal.G0=data_init.G0(idx_f);
cal.CID=xml_script_h.cal.CID(ismember(xml_script_h.cal.FREQ,cal.FREQ));

cal.SACORRECT=data_init.SACORRECT(idx_f);
cal.EQA=data_init.EQA(idx_f);
cal.alpha=data_init.alpha(idx_f);
survey_input_obj.Cal=[];

for ic=1:length(cal.FREQ)
    cal_temp.FREQ=cal.FREQ(ic);
    cal_temp.CID=cal.CID{ic};
    cal_temp.G0=cal.G0(ic);
    cal_temp.SACORRECT=cal.SACORRECT(ic);
    cal_temp.EQA=cal.EQA(ic);
    survey_input_obj.Cal=[survey_input_obj.Cal cal_temp];
end
survey_input_obj.Options.FrequenciesToLoad.set_value(cal.FREQ);
survey_input_obj.Options.ChannelsToLoad.set_value(cal.CID);

if ~isempty(xml_script_h.f_bounds_table.Data) 
    fb=xml_script_h.f_bounds_table.Data.Variables;
    for ifm=1:numel(xml_script_h.f_bounds_table.ColumnName)
        idf = [];
        for iif=1:numel(cal.FREQ)
            idf = [idf findstr(xml_script_h.f_bounds_table.ColumnName{ifm},survey_input_obj.Options.ChannelsToLoad.Value{iif})];
        end
        if isempty(idf)
            fb(:,ifm) = nan(size(fb(:,ifm)));
        end
    end

    fb = fb(~isnan(fb));
    if ~isempty(fb)
        survey_input_obj.Options.FrequenciesMinToEI_FMmode.set_value(fb(1,:));
        survey_input_obj.Options.FrequenciesMaxToEI_FMmode.set_value(fb(2,:));
    else
        survey_input_obj.Options.FrequenciesMinToEI_FMmode.set_value([]);
        survey_input_obj.Options.FrequenciesMaxToEI_FMmode.set_value([]);
    end
else
    survey_input_obj.Options.FrequenciesMinToEI_FMmode.set_value([]);
    survey_input_obj.Options.FrequenciesMaxToEI_FMmode.set_value([]);
end

idx_chan = find(cal.FREQ == survey_input_obj.Options.Frequency.Value,1);
if isempty(idx_chan)
    idx_chan = 1;
end
survey_input_obj.Options.Channel.set_value(cal.CID{idx_chan});
survey_input_obj.Options.Absorption.set_value(cal.alpha);
survey_input_obj.Infos.Script = fullfile(p_scripts,xml_script_h.f_name_edit.Value);
survey_input_obj.survey_input_to_survey_xml('xml_filename',fullfile(p_scripts,xml_script_h.f_name_edit.Value));
open_txt_file(fullfile(p_scripts,xml_script_h.f_name_edit.Value));
end

function reg_wc = update_reg_wc_region(xml_script_h)

if xml_script_h.reg_wc.bool.Value

    reg_wc{1}=struct(...
        'y_min',xml_script_h.reg_wc_h.RangeMin.Value,...
        'y_max',xml_script_h.reg_wc_h.RangeMax.Value,...
        'Ref',xml_script_h.reg_wc_h.IntRef.Value,...
        'Type',xml_script_h.reg_wc_h.DataType.Value,...
        'Cell_w',xml_script_h.reg_wc_h.Cell_w.Value,...
        'Cell_h',xml_script_h.reg_wc_h.Cell_h.Value,...
        'Cell_w_unit',xml_script_h.reg_wc_h.Cell_w_unit.Value,...
        'Cell_h_unit','meters'...
        );

else
    reg_wc={};
end

end


