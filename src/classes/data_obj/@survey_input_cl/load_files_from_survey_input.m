%% load_files_from_survey_input.m
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
% * |surv_input_obj|: TODO: write description and info on variable
% * |layers|: TODO: write description and info on variable
% * |origin|: TODO: write description and info on variable
% * |cvs_root|: TODO: write description and info on variable
% * |PathToMemmap|: TODO: write description and info on variable
% * |FieldNames|: TODO: write description and info on variable
% * |gui_main_handle|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |layers_new|: TODO: write description and info on variable
% * |layers_old|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-07-05: started code cleanup and comment (Alex Schimel)
% * 2015-12-18: first version (Yoann Ladroit).
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function [layers_new,layers_old] = load_files_from_survey_input(surv_input_obj,varargin)

%% Managing input variables

% input parser
p = inputParser;

% add parameters
addRequired(p,'surv_input_obj',@(obj) isa(obj,'survey_input_cl'));
addParameter(p,'layers',layer_cl.empty(),@(obj) isa(obj,'layer_cl'));
addParameter(p,'origin','xml',@ischar);
addParameter(p,'cvs_root','',@ischar);
addParameter(p,'PathToMemmap',tempdir,@ischar);
addParameter(p,'PathToResults',pwd,@ischar);
addParameter(p,'FieldNames',{},@iscell);
addParameter(p,'gui_main_handle',[],@(x)isempty(x)||ishandle(x));
addParameter(p,'fid_log_file',1);

% parse
parse(p,surv_input_obj,varargin{:});

% get results
layers_old      = p.Results.layers;
origin          = p.Results.origin;
cvs_root        = p.Results.cvs_root;
datapath        = p.Results.PathToMemmap;
%FieldNames      = p.Results.FieldNames;
gui_main_handle = p.Results.gui_main_handle;
fid_error  = p.Results.fid_log_file;

war_num=0;
err_num=0;

str_start=sprintf('Files Loading process for script %s started at %s',surv_input_obj.Infos.Title,string(datetime));
print_errors_and_warnings(fid_error,'log',str_start);

%%
block_len = get_block_len(50,'cpu',[]);
if isempty(gui_main_handle)
    gui_main_handle=get_esp3_prop('main_figure');
end

if ~isempty(gui_main_handle)
    load_bar_comp = getappdata(gui_main_handle,'Loading_bar');
else
    load_bar_comp = [];
end

infos      = surv_input_obj.Infos;
regions_wc = surv_input_obj.Regions_WC;
algos_xml      = surv_input_obj.Algos;
snapshots  = surv_input_obj.Snapshots;
cal_opt    = surv_input_obj.Cal;

[snapshot_vec,~,~,~,~,~,~,~,~]=surv_input_obj.list_transects();

layers_new = [];
iti_tot=0;

nb_trans = numel(snapshot_vec);
options_top = surv_input_obj.Options.surv_options_to_struct();

for isn = 1:length(snapshots)
    snap_num = snapshots{isn}.Number;
    stratum = snapshots{isn}.Stratum;
    type=strjoin(snapshots{isn}.Type, ' and ');

    if isfield(snapshots{isn},'Cal_rev')
        try
            svCorr = CVS_CalRevs(cvs_root,'CalRev',snapshots{isn}.Cal_rev);
        catch
            svCorr = 1;
        end
    else
        svCorr = 1;
    end

    if isfield(snapshots{isn},'Options')
        options_gen = snapshots{isn}.Options.surv_options_to_struct();
    else
        options_gen = options_top;
    end

    try
        cal_snap = get_cal_node(cal_opt,snapshots{isn});
    catch
        cal_snap = cal_opt;
    end

    try
        algos_xml = snapshots{isn}.Algos;
    catch

    end

    str_tmp=sprintf('Loading files from %s',snapshots{isn}.Folder);
    disp_perso(gui_main_handle,str_tmp);
    print_errors_and_warnings(fid_error,'',str_tmp);

    for ist = 1:length(stratum)
        strat_name = stratum{ist}.Name;
        transects = stratum{ist}.Transects;
        cal_strat = get_cal_node(cal_snap,stratum{ist});

        if isfield(stratum{ist},'Options')
            options = stratum{ist}.Options.surv_options_to_struct();
        else
            options = options_gen;
        end

        %         strat_type = stratum{ist}.Type;
        %         strat_radius = stratum{ist}.radius;

        for itr = 1:length(transects)
            up_disp_done=0;
            try
                filenames_cell = transects{itr}.files;
                iti_tot = iti_tot + 1;
                trans_num = transects{itr}.number;
                trans_num_str=strjoin(string(num2str(trans_num')),';');
                try
                    cal = get_cal_node(cal_strat,transects{itr});
                catch
                    cal = cal_strat;
                end
                cal=init_cal_struct(cal);
                show_status_bar(gui_main_handle);
                disp_str=sprintf('Loading Snapshot %.0f Type %s Stratum %s Transect(s) %s',snap_num,type,strat_name,trans_num_str);
                print_errors_and_warnings(fid_error,'',disp_str);
                disp_perso(gui_main_handle,disp_str);

                if ~iscell(filenames_cell)
                    filenames_cell = {filenames_cell};
                end

                regs = transects{itr}.Regions;
                reg_ver = 0;

                for ireg = 1:length(regs)
                    if isfield(regs{ireg},'ver')
                        reg_ver = max(reg_ver,regs{ireg}.ver,'omitnan');
                    end
                end


                bot = transects{itr}.Bottom;
                bot_ver = 0;

                if isfield(bot,'ver')
                    bot_ver = max(bot_ver,bot.ver,'omitnan');
                end

                layers_in = [];
                fType = cell(1,length(filenames_cell));
                already_proc = zeros(1,length(filenames_cell));

                for ifiles = 1:length(filenames_cell)
                    fileN = fullfile(snapshots{isn}.Folder,filenames_cell{ifiles});

                    if isfield(transects{itr},'Es60_correction')
                        es_offset = transects{itr}.Es60_correction(ifiles);
                    else
                        es_offset = options.Es60_correction;
                    end
                    freqs_to_load = round(options.FrequenciesToLoad);
                    chan_to_load = options.ChannelsToLoad;

                    if ~isempty(layers_old)
                        [idx_lays_no_f,found_lay_no_f] = layers_old.find_layer_idx_files_path(fileN);
                        [idx_lays,found_lay] = layers_old.find_layer_idx_files_path(fileN,'Frequencies',unique(freqs_to_load));
                    else
                        idx_lays_no_f = [];
                        found_lay_no_f = 0;
                        idx_lays= [];
                        found_lay = 0;
                    end

                    if found_lay_no_f==1 && found_lay==0
                        found_lay = 1;
                        freqs = round(layers_old(idx_lays_no_f).AvailableFrequencies);
                        freqs_l = round(layers_old(idx_lays_no_f).Frequencies);

                        freqs_to_add = setdiff(freqs_to_load,freqs_l);

                        id_chan = find(freqs_to_add==freqs);

                        if isempty(id_chan)
                            war_str=sprintf('Cannot file required all required Frequencies in file %s',fileN);
                            print_errors_and_warnings(fid_error,'warning',war_str);
                            continue;
                        end
                        idx_lays = idx_lays_no_f;
                        channels_to_add = layers_old(idx_lays_no_f).AvailableChannelIDs(id_chan);
                        disp_str=sprintf('File %s found in existing layer, loading extra channels...', fileN);
                        print_errors_and_warnings(fid_error,'',disp_str);
                        layers_old(idx_lays_no_f).add_transceiver('load_bar_comp',load_bar_comp,'channel',channels_to_add);
                    end

                    if ~isempty(layers_new)
                        [idx_lay_new,found_lay_new] = layers_new.find_layer_idx_files_path(fileN,'Frequencies',freqs_to_load);
                    else
                        found_lay_new = 0;
                    end

                    if ~isempty(layers_in)
                        [idx_lay_in,found_lay_in] = layers_in.find_layer_idx_files_path(fileN,'Frequencies',freqs_to_load);
                    else
                        found_lay_in = 0;
                    end


                    abs_f=freqs_to_load;
                    alpha_tot=nan(size(freqs_to_load));

                    for ui=1:numel(abs_f)
                        id_freq_abs = find(freqs_to_load == abs_f(ui));
                        if id_freq_abs<= numel(options.Absorption)  && ~isnan(options.Absorption(id_freq_abs))
                            alpha_tot(ui)=options.Absorption(id_freq_abs)/1e3;
                            no_abs=0;
                        else
                            try
                                idx_abs=cal.FREQ == freqs_to_load(ui);
                                if any(idx_cal)
                                    alpha_tot(ui)=cal.alpha(idx_abs)/1e3;
                                end
                                no_abs=0;
                                war_str = sprintf('No absorption specified in scripts for Frequency %.0f kHz. Using cal file value is available',freqs_to_load(ui)/1e3);
                                disp_perso(p.Results.gui_main_handle,disp_str);
                                print_errors_and_warnings(fid_error,'',war_str);
                            catch
                                no_abs=1;
                            end
                        end

                        if no_abs>0
                            disp_str=sprintf('No absorption specified for Frequency %.0f kHz. Using file value',freqs_to_load(ui)/1e3);
                            disp_perso(p.Results.gui_main_handle,disp_str);
                            print_errors_and_warnings(fid_error,'',disp_str);
                        end
                    end

                    env_data_opt=env_data_cl(...
                        'SoundSpeed',options.SoundSpeed,...
                        'Temperature',options.Temperature,...
                        'Salinity',options.Salinity,...
                        'SVP',options.SVP_profile,...
                        'CTD',options.CTD_profile,...
                        'CTD_fname',options.CTD_profile_fname);

                    if found_lay_in || found_lay_new || found_lay

                        if found_lay_in == 1
                            lay_proc = layers_in(idx_lay_in(1));
                            fType{ifiles} = layers_in(idx_lay_in(1)).Filetype;
                        end

                        if found_lay_new == 1
                            lay_proc = layers_new(idx_lay_new(1));
                            already_proc(ifiles) = 1;
                        end

                        if found_lay>0
                            lay_proc = layers_old(idx_lays(1));
                            layers_in = union(layers_in,layers_old(idx_lays(1)));
                            layers_old(idx_lays(1)) = [];
                        end

                        fType{ifiles} = lay_proc.Filetype;

                        curr_disp_struct_tmp.ChannelID=options.Channel;
                        curr_disp_struct_tmp.Freq=options.Frequency;

                        [trans_obj_primary,idx_primary] = lay_proc.get_trans(curr_disp_struct_tmp);
                        
                        if ~ismb(trans_obj_primary)
                            lay_proc.set_EnvData(env_data_opt);
                            lay_proc.layer_computeSpSv('calibration',cal,...
                                'absorption_f',abs_f,...
                                'absorption',alpha_tot,'block_len',block_len);
                        end

                        continue;
                    end
                    if isfile(fileN)
                        fType{ifiles} = get_ftype(fileN);
                        if strcmp(fType{ifiles},'CREST')
                            dfile=1;
                        else
                            dfile=0;
                        end
                        [new_lay,~]=open_file_standalone(fileN,fType{ifiles},...
                            'PathToMemmap',datapath,...
                            'Frequencies',freqs_to_load,...
                            'Channels',chan_to_load,...
                            'EnvData',env_data_opt,...
                            'absorption',alpha_tot,...
                            'absorption_f',abs_f,...
                            'EsOffset',es_offset,...
                            'calibration',cal,...
                            'load_bar_comp',load_bar_comp,...
                            'LoadEKbot',1,'CVSCheck',0,...
                            'force_open',1,...
                            'bot_ver',[],...
                            'reg_ver',[],...
                            'CVSroot',cvs_root,'dfile',dfile,'CVSCheck',true,'SvCorr',svCorr);
                        if isempty(new_lay)
                            continue;
                        end

                        [~,found] = new_lay.find_freq_idx(freqs_to_load);

                        if any(found == 0)
                            war_str=sprintf('Cannot file required Frequencies in file %s',filenames_cell{ifiles});
                            print_errors_and_warnings(fid_error,'warning',war_str);
                            war_num=war_num+1;

                            continue;
                        end
                        [ftypes,~] = get_ftypes_and_extensions();
                        if ~ismember(fType{ifiles},ftypes)
                            war_str=sprintf('Unrecognized file type for file %s',fileN);
                            print_errors_and_warnings(fid_error,'warning',war_str);
                            war_num=war_num+1;
                            continue
                        end


                        switch origin
                            case 'mbs'
                                new_lay.OriginCrest = transects{itr}.OriginCrest{ifiles};
                                new_lay.CVS_BottomRegions(cvs_root);
                                surv = survey_data_cl('Voyage',infos.Voyage,'SurveyName',infos.SurveyName,...
                                    'Snapshot',snap_num,'Stratum',strat_name,'Transect',trans_num);
                                new_lay.set_survey_data(surv);

                                switch fType{ifiles}
                                    case {'EK60'}
                                        new_lay.update_echo_logbook_dbfile('main_figure',gui_main_handle);
                                        new_lay.write_reg_to_reg_xml();
                                        new_lay.write_bot_to_bot_xml();
                                end
                        end

                        layers_in = union(layers_in,new_lay);
                        clear new_lay;
                    else

                        war_str=sprintf('Cannot Find specified file %s',filenames_cell{ifiles});
                        print_errors_and_warnings(fid_error,'warning',war_str);
                        war_num=war_num+1;

                        continue;
                    end


                end

                if all(already_proc)
                    continue;
                end

                if isempty(layers_in)
                    war_str=sprintf('Could not find any files in  Snapshot %.0f Type %s Stratum %s Transect %s',snap_num,type,strat_name,trans_num_str);
                    print_errors_and_warnings(fid_error,'warning',war_str);
                    war_num=war_num+1;
                    continue;
                end

                switch origin
                    case 'xml'
                        layers_out_temp = shuffle_layers(layers_in,'multi_layer',0);
                        clear layers_in;

                    case 'mbs'
                        layers_out_temp = layers_in;
                        clear layers_in;
                end

                if ~isempty(load_bar_comp)
                    load_bar_comp.progress_bar.setText('');
                end

                if numel(layers_out_temp)>numel(trans_num)
                    disp_str=sprintf('Non continuous files in Snapshot %.0f Type %s Stratum %s Transect(s) %s',snap_num,type,strat_name,trans_num_str);
                    disp_perso(p.Results.gui_main_handle,disp_str);
                    print_errors_and_warnings(fid_error,'',disp_str);
                end

                for i_lay = 1:length(layers_out_temp)
                    layer_new = layers_out_temp(i_lay);
                    curr_disp_struct_tmp.ChannelID=options.Channel;
                    curr_disp_struct_tmp.Freq=options.Frequency;

                    [trans_obj_primary,idx_primary] = layer_new.get_trans(curr_disp_struct_tmp);

                    idx_secondary=[];
                    for ifreq = 1:length(freqs_to_load)
                        if ~all(cellfun(@isempty,chan_to_load)) && numel(chan_to_load) == numel(freqs_to_load)
                            curr_disp_struct_sec_tmp.ChannelID=chan_to_load{ifreq};
                        end
                        curr_disp_struct_sec_tmp.Freq=freqs_to_load(ifreq);
                        [trans_obj_sec,i_freq] = layer_new.get_trans(curr_disp_struct_sec_tmp);
                        idx_secondary=union(idx_secondary,i_freq);
                        found =~isempty(trans_obj_sec);

                        if found==0
                            war_str=sprintf('Could not find %.0f kHz in  Snapshot %.0f Type %s Stratum %s Transect %s',freqs_to_load(ifreq)/1e3,snap_num,type,strat_name,trans_num_str);
                            print_errors_and_warnings(fid_error,'warning',war_str);
                            war_num=war_num+1;
                            continue;
                        end

                        switch origin
                            case 'xml'
                                layer_new.load_bot_regs('Frequencies',freqs_to_load,...
                                    'Channels',chan_to_load,...
                                    'bot_ver',bot_ver,'reg_ver',reg_ver);
                        end

                        if options.Motion_correction
                            create_motion_comp_subdata(layer_new,i_freq,load_bar_comp);
                        end

                    end
                    idx_other=[];

                    for ifreq = 1:length(freqs_to_load)
                        [i_freq,found]=layer_new.find_freq_idx(freqs_to_load(ifreq));
                        if found>0
                            idx_other=union(i_freq,idx_other) ;
                        end
                    end

                    [idx_bot_freq,~]=layer_new.find_freq_idx(options.Frequency);
                    idx_bot_freq = idx_bot_freq(1);
                    bot_copied = false;

                    if options.ShiftBot ~= 0
                        shift_bottom(layer_new.Transceivers(idx_bot_freq),options.ShiftBot,[]);
                        disp_str = sprintf('Shifted bottom by %.1f m',options.ShiftBot);
                        print_errors_and_warnings(fid_error,'',disp_str);
                    end

                    if ~isempty(algos_xml)
                        al_names = cellfun(@(x) x.Name,algos_xml,'un',0);
                        if ~any(contains(al_names,{'BottomDetection' 'BottomDetectionV2' 'DropOuts' 'SpikesRemoval' 'BadPingsV2' 'Denoise'}))
                            layer_new.copy_bottom_to_other_freq(idx_bot_freq,idx_other,1);
                            bot_copied = true;
                        end
                    elseif options.CopyBottomFromFrequency>0
                        bot_copied = true;
                        layer_new.copy_bottom_to_other_freq(idx_bot_freq,idx_other,1);
                    end

                    reg_trans = [];

                    reg_tot = trans_obj_primary.get_reg_specs_to_integrate(regs);

                    if isempty(reg_tot)
                        reg_tot = struct('name','','id',nan,'unique_id',nan,'startDepth',nan,'finishDepth',nan,'startSlice',nan,'finishSlice',nan);
                    end

                    if ~isempty(~strcmp({reg_tot(:).id},''))
                        idx_reg = trans_obj_primary.find_regions_Unique_ID({reg_tot(:).id});
                        reg_trans = trans_obj_primary.Regions(idx_reg);
                    end

                    for ire = 1:length(regs)
                        if isfield(regs{ire},'name')
                            switch regs{ire}.name
                                case 'WC'
                                    trans_obj_primary.rm_region_name('WC');
                                    for irewc = 1:length(regions_wc)
                                        if isfield(regions_wc{irewc},'y_max')
                                            y_max = regions_wc{irewc}.y_max;
                                        else
                                            y_max = inf;
                                        end
                                        if isfield(regions_wc{irewc},'t_min')
                                            t_min = datenum(regions_wc{irewc}.t_min,'yyyy/mm/dd HH:MM:SS');
                                        else
                                            t_min = 0;
                                        end

                                        if isfield(regions_wc{irewc},'t_max')
                                            t_max = datenum(regions_wc{irewc}.t_max,'yyyy/mm/dd HH:MM:SS');
                                        else
                                            t_max = Inf;
                                        end

                                        reg_wc = trans_obj_primary.create_WC_region(...
                                            'y_max',y_max,...
                                            'y_min',regions_wc{irewc}.y_min,...
                                            't_min',t_min,...
                                            't_max',t_max,...
                                            'Type',regions_wc{irewc}.Type,...
                                            'Ref',regions_wc{irewc}.Ref,...
                                            'Cell_w',regions_wc{irewc}.Cell_w,...
                                            'Cell_h',regions_wc{irewc}.Cell_h,...
                                            'Cell_w_unit',regions_wc{irewc}.Cell_w_unit,...
                                            'Cell_h_unit',regions_wc{irewc}.Cell_h_unit);


                                        trans_obj_primary.add_region(reg_wc,'Split',0);
                                    end
                            end
                        end
                    end


                    for ial = 1:length(algos_xml)
                        if  ~ismember(algos_xml{ial}.Name,{'BottomDetection' 'BottomDetectionV2' 'DropOuts' 'SpikesRemoval' 'BadPingsV2' 'Denoise'})&&~bot_copied
                            if options.CopyBottomFromFrequency>0
                                bot_copied = true;
                                layer_new.copy_bottom_to_other_freq(idx_bot_freq,idx_other,1);
                            end
                        end

                        disp_str=sprintf('Applying %s',algos_xml{ial}.Name);
                        print_errors_and_warnings(fid_error,'',disp_str);

                        try
                            if isempty(algos_xml{ial}.Varargin.Frequencies)
                                idx_chan=idx_primary;
                                found_freq_al=1;
                            else
                                [idx_chan,found_freq_al] = layer_new.find_freq_idx(algos_xml{ial}.Varargin.Frequencies);
                                idx_chan(found_freq_al==0)=[];
                            end

                            idx_not_found=find(found_freq_al==0);

                            for f_nf = idx_not_found
                                disp_str=sprintf('Could not find Frequency %.0f kHz. Algo %s not applied on it',algos_xml{ial}.Varargin.Frequencies(f_nf)/1e3,algos_xml{ial}.Name);
                                disp_perso(p.Results.gui_main_handle,disp_str);
                                print_errors_and_warnings(fid_error,'',disp_str);
                            end

                            if ~isempty(idx_chan)
                                al_from_xml = get_al_from_al_xml_struct(algos_xml{ial});
                                layer_new.add_algo(al_from_xml,'idx_chan',idx_chan);

                                switch algos_xml{ial}.Name
                                    case {'BottomDetection' 'BottomDetectionV2' 'DropOuts' 'SpikesRemoval' 'BadPingsV2' 'Denoise'}
                                        reg_algo = [];
                                    otherwise
                                        reg_algo = reg_trans;
                                end

                                layer_new.apply_algo(algos_xml{ial}.Name,'idx_chan',idx_chan,...
                                    'load_bar_comp',load_bar_comp,'survey_options',surv_input_obj.Options,'reg_obj',reg_algo);

                            end


                        catch err_1
                            war_str=sprintf('Error while applying %s',algos_xml{ial}.Name);
                            print_errors_and_warnings(fid_error,'warning',war_str);
                            print_errors_and_warnings(fid_error,'error',err_1);
                            err_num=err_num+1;

                        end
                    end

                    if options.CopyBottomFromFrequency>0 && ~bot_copied
                        layer_new.copy_bottom_to_other_freq(idx_bot_freq,idx_other,1);
                    end


                    if options.SaveBot>0
                        layer_new.write_bot_to_bot_xml();
                    end



                    for ireg=1:length(trans_obj_primary.Regions)
                        trans_obj_primary.Regions(ireg).Remove_ST=options.Remove_ST;
                    end

                    if options.Remove_tracks
                        trans_obj_primary.create_track_regs('Type','Bad Data');
                    end
                    if options.SaveReg>0
                        layer_new.write_reg_to_reg_xml();
                    end

                    layers_new = union(layers_new,layer_new);
                end
                clear layers_out_temp;

            catch err

                war_str=sprintf('Error opening file for Snapshot %.0f Type %s Stratum %s Transect %s',snap_num,type,strat_name,trans_num_str);
                print_errors_and_warnings(fid_error,'warning',war_str);
                print_errors_and_warnings(fid_error,'error',err);
                err_num=err_num+1;

            end

            if ~isempty(load_bar_comp)
                set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_trans,'Value',iti_tot);
            end
        end
    end
end


hide_status_bar(gui_main_handle);
sum_str=sprintf(['Files loading process for script %s finished with:\n' ...
    '%d Warnings\n'...
    '%d Errors \n\n']...
    ,surv_input_obj.Infos.Title,war_num,err_num);

print_errors_and_warnings(fid_error,'',sum_str);

str_end=sprintf('Files Loading process for script %s finished at %s\n',surv_input_obj.Infos.Title,datestr(now));
print_errors_and_warnings(fid_error,'log',str_end);

end

%% sub-functions

function cal = get_cal_node(cal_ori,node)

cal = cal_ori;

if ~isempty(node.Cal)

    cal_temp_cell = node.Cal;

    if ~iscell(cal_temp_cell)
        cal_temp_cell = {cal_temp_cell};
    end

    cal = cell(1,length(cal_temp_cell));

    for icell = 1:length(cal_temp_cell)
        call_out_temp = [];
        for ical = 1:length(cal_temp_cell{icell})
            cal_temp = cal_temp_cell{icell};
            if ~isempty(cal_ori)
                call_out_temp = cal_ori;
                if any([call_out_temp(:).FREQ] == cal_temp(ical).FREQ)
                    call_out_temp([call_out_temp(:).FREQ] == cal_temp(ical).FREQ) = cal_temp(ical);
                else
                    call_out_temp(length(call_out_temp)+1) = cal_temp(ical);
                end
            else
                call_out_temp = cal_temp;
            end
        end
        cal{icell} = call_out_temp;
    end

    if isscalar(cal)
        cal = cal{1};
    end

end

end

