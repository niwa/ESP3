%% generate_output_v2.m
%
% Key function for integration of surveys. Everything happens here. It
% needs cleaning, commenting and the output needs to be optimized.
%
%% Helpge
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |surv_obj|: TODO: write description and info on variable
% * |layers|: TODO: write description and info on variable
% * |PathToResults|: TODO: write description and info on variable
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
% * 2017-04-02: header (Alex Schimel).
% * YYYY-MM-DD: first version (Yoann Ladroit). TODO: complete date and comment
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function generate_output_v2(surv_obj,layers,varargin)

p = inputParser;

addRequired(p,'surv_obj',@(obj) isa(obj,'survey_cl'));
addRequired(p,'layers',@(obj) isa(obj,'layer_cl')||isempty(obj));
addParameter(p,'PathToResults',pwd,@ischar);
addParameter(p,'load_bar_comp',[]);
addParameter(p,'fid_log_file',1);
addParameter(p,'gui_main_handle',handle(groot),@ishandle);
parse(p,surv_obj,layers,varargin{:});

surv_input_obj = surv_obj.SurvInput;

fid_error  = p.Results.fid_log_file;

str_strat = sprintf('Integration process for script %s started at %s\n',surv_obj.SurvInput.Infos.Title,string(datetime));
print_errors_and_warnings(fid_error,'',str_strat);
load_bar_comp = p.Results.load_bar_comp;

if ~isempty(surv_input_obj.Infos.Title)
    str_fname = fullfile(p.Results.PathToResults,surv_input_obj.Infos.Title);
else
    str_fname  = [p.Results.PathToResults filesep];
end

war_num = 0;
err_num = 0;

algos_xml = surv_input_obj.Algos;

classified_by_cell = false;

if ~isempty(algos_xml)
    idx_al = find(cellfun(@(x) strcmpi(x.Name,'Classification'),algos_xml),1);
    if ~isempty(idx_al)&&isfield(algos_xml{idx_al}.Varargin,'classification_file')
        try
            class_tree_obj = decision_tree_cl(algos_xml{idx_al}.Varargin.classification_file);
            classified_by_cell = strcmpi(class_tree_obj.ClassificationType,'Cell by cell');
        catch
            warning('Cannot parse specified classification file: %s',algos_xml{idx_al}.Varargin.classification_file);
        end
    end
end

output = layers.list_layers_survey_data();

[snaps,types,strat,trans,regs_trans,cell_trans,opts_cell] = surv_input_obj.merge_survey_input_for_integration();

strat_grp = findgroups(snaps,types,strat);
trans_grp = findgroups(snaps,types,strat,trans);

reg_nb_vec = cellfun(@length,regs_trans);
surv_out_obj = survey_output_cl(numel(unique(strat_grp)),numel(unique(trans_grp)),sum(reg_nb_vec,'omitnan'));

nb_trans = numel(unique(trans_grp));
snap_temp = [surv_input_obj.Snapshots{:}];
folders = {snap_temp.Folder};
reg_descr_table = [];
idx_lay_processed = [];
i_trans = 0;
i_reg = 0;

if ~isempty(load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_trans,'Value',0);
    load_bar_comp.progress_bar.setText('Integration');
end
block_len = get_block_len(50,'cpu',[]);
disp_str = sprintf('----------------Integration-----------------');
print_errors_and_warnings(fid_error,'',disp_str);

try
    file_sql=fullfile(whereisEcho,'config','db','esp3_outputs.sql');
    ac_db_filename = generate_valid_filename(sprintf('%s.db',str_fname));
    create_ac_database(ac_db_filename,file_sql,1,false);

    dbconn_ac_db = sqlite(ac_db_filename);

    survey_opt_struct = surv_options_to_struct(surv_input_obj.Options);
    ssf =fieldnames(survey_opt_struct);
    for uis = 1:numel(ssf)
        if numel(survey_opt_struct.(ssf{uis}))>1
            if iscell(survey_opt_struct.(ssf{uis}))
                survey_opt_struct.(ssf{uis}) =  strjoin(survey_opt_struct.(ssf{uis}),';');
            elseif isnumeric(survey_opt_struct.(ssf{uis}))
                survey_opt_struct.(ssf{uis}) =  strjoin(cellfun(@num2str,num2cell(survey_opt_struct.(ssf{uis})),'UniformOutput',false),';');
            end
        end
        if isempty(survey_opt_struct.(ssf{uis}))
            survey_opt_struct = rmfield(survey_opt_struct,ssf{uis});
        end
    end

    survey_opt_table = struct2table(survey_opt_struct,'AsArray',true);
	sqlquery_FB = 'ALTER TABLE t_survey_options ADD Feature_bool ';
    execute(dbconn_ac_db,sqlquery_FB);
    sqlquery_SB = 'ALTER TABLE t_survey_options ADD ShiftBot ';
    execute(dbconn_ac_db,sqlquery_SB);
    dbconn_ac_db.sqlwrite('t_survey_options',survey_opt_table);
   % dbconn_ac_db.close();

    %dbconn_ac_db = connect_to_db(ac_db_filename);

    dbtmp = sqlfind(dbconn_ac_db,'t_echoint_transect_2D');
    t_echoint_transect_2D_cols  = dbtmp.Columns{:};

    dbtmp = sqlfind(dbconn_ac_db,'t_echoint_transect_1D');
    t_echoint_transect_1D_cols  = dbtmp.Columns{:};
    %dbconn_ac_db.close();

    dbconn_ac_db = sqlite(ac_db_filename); 
    create_vrt_file(ac_db_filename, {'t_transect','t_echoint_transect_1D'},{'transect_lon_start' 'Lon_S'},{'transect_lat_start' 'Lat_S'});

catch err
    war_str = sprintf('Error creating output .db file...');
    print_errors_and_warnings(fid_error,'warning',war_str);
    print_errors_and_warnings(fid_error,'error',err);
    err_num = err_num+1;
    dbconn_ac_db = [];
end

for isn = 1:length(snaps)

    try
        curr_options = opts_cell{isn};
        curr_options_struct = curr_options.surv_options_to_struct();
        vert_slice = curr_options_struct.Vertical_slice_size;
        %horz_slice = curr_options_struct.Horizontal_slice_size;

        snap_num = snaps(isn);
        type_t = types{isn};
        strat_name = strat{isn};
        trans_num = trans(isn);
        regs_tmp = regs_trans{isn};
        cells_tmp = cell_trans{isn};

        disp_str = sprintf('Integrating Snapshot %.0f Type %s Stratum %s Transect %d',snap_num,type_t,strat_name,trans_num);
        str = curr_options.print_survey_options();

        if ~isempty(load_bar_comp)
            load_bar_comp.progress_bar.setText(disp_str);
        end
        print_errors_and_warnings(fid_error,'',disp_str);
        print_errors_and_warnings(fid_error,'',str);
        i_trans = i_trans+1;

        att = {'Snapshot' 'Stratum' 'Type' 'Transect'};
        att_val = {snap_num strat_name type_t trans_num};
        idx_lay_bool = cellfun(@(x) any(strcmpi(x,fullfile(folders,'\'))),fullfile(output.Folder,'\'));

        for iatt = 1:numel(att_val)
            if ~isempty(att_val{iatt})
                if ischar((att_val{iatt}))
                    if ~isempty(deblank((att_val{iatt})))
                        switch att{iatt}
                            case 'Type'
                                idx_lay_bool = idx_lay_bool&contains(deblank(output.(att{iatt})),deblank(strsplit(att_val{iatt},';')));
                            otherwise
                                idx_lay_bool = idx_lay_bool&strcmpi(deblank(output.(att{iatt})),deblank(att_val{iatt}));
                        end
                    end
                else
                    if (att_val{iatt})~= 0
                        idx_lay_bool = idx_lay_bool&output.(att{iatt}) == att_val{iatt};
                    end
                end
            end
        end

        idx_lay = find(idx_lay_bool);
        id_lay = output.Layer_idx(idx_lay);
        [~,itmp] = unique(id_lay);
        idx_lay = idx_lay(itmp);

        [tb,~] = layers(output.Layer_idx(idx_lay)).get_time_bounds;
        [~,idx_lay_sort] = sort(tb);
        idx_lay = idx_lay(idx_lay_sort);

        if isempty(idx_lay)
            war_str = sprintf('Could not find layers for Snapshot %.0f Type %s Stratum %s Transect %d\n',snap_num,type_t,strat_name,trans_num);
            print_errors_and_warnings(fid_error,'warning',war_str);
            war_num = war_num+1;
            continue;
        end


        idx_lay = setdiff(idx_lay,idx_lay_processed,'stable');
        idx_lay_processed = union(idx_lay_processed,idx_lay);

        if isempty(idx_lay)
            fprintf('     Already integrated\n');
            continue;
        end

        nb_bad_trans = 0;
        nb_ping_tot = 0;

        for i_test_bt = idx_lay
            layer_obj_tr = layers(output.Layer_idx(i_test_bt));

            trans_obj = layer_obj_tr.get_trans(struct('ChannelID',curr_options_struct.Channel,'Freq',curr_options_struct.Frequency));

            idx_beam = trans_obj.get_idx_beams([curr_options_struct.AngleMin curr_options_struct.AngleMax]);
            [perc_temp,nb_ping_temp] = trans_obj.get_badtrans_perc();
            nb_bad_trans = nb_bad_trans+nb_ping_temp*perc_temp/100;
            nb_ping_tot = nb_ping_tot+nb_ping_temp;
        end

        if nb_bad_trans/nb_ping_tot>curr_options_struct.BadTransThr/100
            war_str = sprintf('Too many bad pings on Snapshot %.0f Type %s Stratum %s Transect %d\n',snap_num,type_t,strat_name,trans_num);
            print_errors_and_warnings(fid_error,'warning',war_str);
            war_num = war_num+1;
            continue;
        end
        Output_echo = [];


        dist_tot = 0;
        timediff_tot = 0;
        nb_good_pings = 0;
        mean_bot_w = 0;
        mean_bot = nan(1,length(idx_lay));
        av_speed = nan(1,length(idx_lay));
        idx_good_pings = [];
        nb_pings_tot = 0;
        iping0 = 0;


        for ill = 1:length(idx_lay)
            layer_obj_tr = layers(output.Layer_idx(idx_lay(ill)));
            trans_obj = layer_obj_tr.get_trans(struct('ChannelID',curr_options_struct.Channel,'Freq',curr_options_struct.Frequency));
            tag_add = trans_obj.Bottom.Tag;
            bot_depth_add = trans_obj.get_bottom_depth();
            gps_add = trans_obj.GPSDataPing;
            gps_add.Long(gps_add.Long>180) = gps_add.Long(gps_add.Long>180)-360;
            if ill>1
                gps_tot = concatenate_GPSData(gps_tot,gps_add);
            else
                gps_tot = gps_add;
            end


            idx_ping = 1:length(gps_add.Time);
            idx_in_transect = find(gps_add.Time(:)>= min(output.StartTime(idx_lay(ill)))&gps_add.Time(:)<= max(output.EndTime(idx_lay(ill))));
            idx_good_pings_add = intersect(idx_ping,idx_in_transect);
            idx_good_pings_add = intersect(idx_good_pings_add,find(tag_add>0));
            idx_good_pings_dist = intersect(idx_good_pings_add,find(~isnan(gps_add.Lat)));

            if ~isempty(idx_good_pings_dist)
                [dist_km,timediff] = gps_add.get_tot_dist_and_time_diff(idx_good_pings_dist);
                %[dist_km,timediff] = gps_add.get_straigth_dist_and_time_diff(idx_good_pings_dist);
                dist_add = dist_km/1.852;
            else
                dist_add = 0;
                timediff = 0;
            end

            dist_tot = dist_tot+dist_add;
            timediff_tot = timediff_tot+timediff;
            nb_pings_tot = nb_pings_tot+numel(idx_in_transect);
            nb_good_pings = nb_good_pings+length(idx_good_pings_add);
            mean_bot(ill) = mean(bot_depth_add,'omitnan');
            mean_bot_w = mean_bot_w+mean_bot(ill)*length(idx_good_pings_add);
            av_speed(ill) = dist_add/timediff;
            idx_good_pings = union(idx_good_pings,idx_good_pings_add+iping0);
            iping0 = iping0+length(idx_ping);
        end

        if isempty(idx_good_pings)
            war_str = sprintf('No good pings in Snapshot %.0f Type %s Stratum %s Transect %d\n',snap_num,type_t,strat_name,trans_num);
            print_errors_and_warnings(fid_error,'warning',war_str);
            war_num = war_num+1;
            continue;
        end

        av_speed_tot = dist_tot/timediff_tot;

        good_bot_tot = mean_bot_w/nb_good_pings;
        output_2D_tot  ={};
        output_2D_type_tot = {};
        ir = 0;

        for ilay = idx_lay
            ir = ir+1;
            layer_obj_tr = layers(output.Layer_idx(ilay));
            [trans_obj_tr,idx_freq_main] = layer_obj_tr.get_trans(struct('ChannelID',curr_options_struct.Channel,'Freq',curr_options_struct.Frequency));
            %if ~isempty(curr_options_struct.ChannelsToLoad)
            if ~cellfun(@isempty,curr_options_struct.ChannelsToLoad)
                [idx_freq_sec,found] = layer_obj_tr.find_cid_idx(curr_options_struct.ChannelsToLoad);
            else
                [idx_freq_sec,found] = layer_obj_tr.find_freq_idx(curr_options_struct.FrequenciesToLoad);
            end
            idx_freq_sec(found == 0) = [];
            idx_freq_sec = union(idx_freq_sec,idx_freq_main);

            gps = trans_obj_tr.GPSDataPing;
            gps.Long(gps.Long>180) = gps.Long(gps.Long>180)-360;

            if isnan(good_bot_tot)
                depth = trans_obj_tr.get_samples_depth([],[],idx_beam);
                good_bot_tot = max(depth,[],'all','omitnan');
            end

            if isempty(cells_tmp)
                reg_tot = trans_obj_tr.get_reg_specs_to_integrate(regs_tmp);
                
                if isempty(reg_tot)
                    reg_tot = struct('name','','id',nan,'unique_id',nan,'startDepth',nan,'finishDepth',nan,'startSlice',nan,'finishSlice',nan);
                end

                if ~isempty(~strcmp({reg_tot(:).id},''))
                    idx_reg = trans_obj_tr.find_regions_Unique_ID({reg_tot(:).id});
                else
                    idx_reg = [];
                end
            else
                idx_reg = 1:numel(trans_obj_tr.Regions);
            end

            if ~classified_by_cell  
                layer_obj_tr.multi_freq_slice_transect2D(...
                    'survey_options',curr_options,...
                    'idx_main_freq',idx_freq_main,...
                    'idx_sec_freq',idx_freq_sec,...
                    'block_len',block_len,...
                    'timeBounds',[output.StartTime(ilay),output.EndTime(ilay)],...%'load_bar_comp',p.Results.load_bar_comp
                    'idx_regs',idx_reg);
            end

            output_2D_t = layer_obj_tr.EchoIntStruct.output_2D;
            output_2D_type_t = layer_obj_tr.EchoIntStruct.output_2D_type;
            regs_t = layer_obj_tr.EchoIntStruct.regs_tot;
            regCellInt_t = layer_obj_tr.EchoIntStruct.regCellInt_tot;
            reg_descr_table_n = layer_obj_tr.EchoIntStruct.reg_descr_table;
            shadow_height_est_t = layer_obj_tr.EchoIntStruct.shz_height_est;
            idx_freq_out_tot = layer_obj_tr.EchoIntStruct.idx_freq_out;

            %%%%%%%%%%
            %         profile off;
            %         profile viewer;
            idx_f = idx_freq_main == idx_freq_out_tot;
            
            output_2D = output_2D_t{idx_f};
            output_2D_type = output_2D_type_t{idx_f};

            regCellInt = regCellInt_t{idx_f};
            regs = regs_t{idx_f};
            shadow_height_est = shadow_height_est_t{idx_f};

            if all(cellfun(@isempty,output_2D))
                war_str = sprintf('Nothing to integrate in Snapshot %.0f Stratum %s Type %s Transect %s in layer %d\n',snap_num,strat_name,type_t,trans_num,ilay);
                print_errors_and_warnings(fid_error,'warning',war_str);
                war_num = war_num+1;
                continue;
            end

            if istall(output_2D{1}.eint)
                output_2D = cellfun(@(x) structfun(@gather,x,'un',0),output_2D,'un',0);
                regCellInt = cellfun(@(x) structfun(@gather,x,'un',0),regCellInt,'un',0);
                shadow_height_est = gather(shadow_height_est);
            end

            num_slice = size(output_2D{1}.eint,2);


            slice_int = zeros(1,num_slice);
            good_pings = 0;
            slice_int_sh = zeros(1,num_slice);

            idxs_sec = idx_freq_sec(idx_freq_sec~=idx_freq_main);

            for iout = 1:numel(output_2D)
                if ~isempty(cells_tmp)
                    idx_tag_keep = ismember(output_2D{iout}.Tags,cells_tmp);
                    output_2D{iout}.eint(~idx_tag_keep) = 0;
                    output_2D{iout}.sv(~idx_tag_keep) = 0;
                    output_2D{iout}.sd_Sv(~idx_tag_keep) = 0;
                    output_2D{iout}.ABC(~idx_tag_keep) = 0;
                    output_2D{iout}.NASC(~idx_tag_keep) = 0;
                end


                if any(output_2D{iout}.eint(:)>0)&&~isdeployed()&&0
                    disp_str = sprintf('Snapshot %.0f Type %s Stratum %s Transect %d',snap_num,type_t,strat_name,trans_num);
                    reg_tmp = region_cl('Reference',output_2D_type{iout},'Cell_w',vert_slice,...
                        'Cell_w_unit','meters','Cell_h_unit','meters','Cell_h',horz_slice);
                    f_tmp = reg_tmp.display_region(output_2D{iout},'main_figure',p.Results.gui_main_handle);
                    f_tmp.Name = disp_str;
                    pause(1);
                end

                if ~strcmpi(output_2D_type{iout},'shadow')
                    slice_int = slice_int+sum(output_2D{iout}.eint,'omitnan');
                else
                    slice_int_sh = sum(output_2D{iout}.eint,'omitnan').*shadow_height_est/curr_options_struct.Shadow_zone_height;
                end
                good_pings = max(good_pings,max(output_2D{iout}.Nb_good_pings,[],1,'omitnan'),'omitnan');

                try
                    for idx_sec=idxs_sec
                        if ~istall(output_2D{iout}.eint)
                            tags=output_2D{iout}.Tags;  
                            tagstr=output_2D{iout}.Tag_str;
                            tagcmap=output_2D{iout}.Tag_cmap;
                            tagdescr=output_2D{iout}.Tag_descr;
                        else
                            tags=gather(output_2D{iout}.Tags);
                            tagstr=gather(output_2D{iout}.Tag_str);
                            tagcmap=gather(output_2D{iout}.Tag_cmap);
                            tagdescr=gather(output_2D{iout}.Tag_descr);
                        end
                        
                        [mask_in,mask_out] = match_data(gather(output_2D{iout}.Time_S),output_2D{iout}.Range_ref_min,output_2D_t{idx_sec}{1}.Time_S,output_2D_t{idx_sec}{1}.Range_ref_min);
                        layer_obj_tr.EchoIntStruct.output_2D{idx_sec}{1}.Tags(mask_out)=tags(mask_in);
                        layer_obj_tr.EchoIntStruct.output_2D{idx_sec}{1}.Tag_str = tagstr;
                        layer_obj_tr.EchoIntStruct.output_2D{idx_sec}{1}.Tag_cmap = tagcmap;
                        layer_obj_tr.EchoIntStruct.output_2D{idx_sec}{1}.Tag_descr = tagdescr;
                    end
                catch
                end         
            end

            %reg_descr_table = [reg_descr_table;reg_descr_table_n];
            reg_descr_table = [reg_descr_table;reg_descr_table_n];
        
            if  curr_options_struct.ExportSlicedTransects
                for iout = 1:numel(output_2D_type)
                    if ~isempty(output_2D{iout})
                        outputFileXLS = generate_valid_filename(sprintf('%s_transect_snap_%d_type_%s_strat_%s_trans_%d_%d_%s_sliced%s',str_fname,snap_num,type_t,strat_name,trans_num,ir,output_2D_type{iout},'.csv'));
                    end

                    if ~isempty(output_2D{iout})
                        if isfile(outputFileXLS)
                            try
                                delete(outputFileXLS);
                            catch err
                                if strcmpi(err.identifier,'MATLAB:DELETE:Permission')
                                    war_fig = dlg_perso([],'Could not overwrite file',sprintf('File %s is open in another process. Please close it and then close this box to continue...',outputFileXLS),'Timeout',30);
                                    waitfor(war_fig);
                                    delete(outputFileXLS);
                                else
                                    rethrow(err);
                                end
                            end
                        end

                        sliced_output_table = reg_output_to_table(output_2D{iout});
                        
                        try
                            writetable(sliced_output_table,outputFileXLS);
                        catch err
                            war_str = sprintf('Could not Save sliced output Snapshot %.0f Type %s Stratum %s Transect %d\n',snap_num,type_t,strat_name,trans_num);
                            print_errors_and_warnings(fid_error,'warning',war_str);
                            print_errors_and_warnings(fid_error,'error',err);
                        end
                    end
                    
                    

                end

                
            end

            idx_chan = union(idx_freq_sec,idx_freq_main);

            for i_freq_al = idx_chan
                %lay_name=list_layers(layer_new,'nb_char',80);

                if isempty(layer_obj_tr.Transceivers(i_freq_al).ST)||isempty(layer_obj_tr.Transceivers(i_freq_al).ST.TS_comp)
                    continue;
                end

                if curr_options_struct.Export_ST
                    file_st = generate_valid_filename(sprintf('%s_transect_snap_%d_type_%s_strat_%s_trans_%d_%d_%s_ST_%.0f%s',str_fname,snap_num,type_t,strat_name,trans_num,ir,output_2D_type{iout},layer_obj_tr.Frequencies(i_freq_al),'.xlsx'));
                    layer_obj_tr.Transceivers(i_freq_al).save_st_to_xls(file_st,0,output.StartTime(ilay),output.EndTime(ilay));
                end


                if isempty(layer_obj_tr.Transceivers(i_freq_al).Tracks)
                    continue;
                end

                if curr_options_struct.Export_TT
                    file_tt = generate_valid_filename(sprintf('%s_transect_snap_%d_type_%s_strat_%s_trans_%d_%d_%s_TT_%.0f%s',str_fname,snap_num,type_t,strat_name,trans_num,ir,output_2D_type{iout},layer_obj_tr.Frequencies(i_freq_al),'.xlsx'));
                    layer_obj_tr.Transceivers(i_freq_al).save_tt_to_xls(file_tt,output.StartTime(ilay),output.EndTime(ilay));
                end

            end


            sliced_output.eint = slice_int;
            sliced_output.slice_abscf = slice_int./good_pings;
            sliced_output.slice_abscf(isnan(sliced_output.slice_abscf)) = 0;
            sliced_output.slice_size = vert_slice;
            sliced_output.num_slices = num_slice;
            sliced_output.shadow_zone_slice_abscf = slice_int_sh./good_pings;
            sliced_output.shadow_zone_slice_abscf(isnan(sliced_output.shadow_zone_slice_abscf)) = 0;

            output_2D_ref = output_2D{1};

            sliced_output.slice_lat = output_2D_ref.Lat_S;
            sliced_output.slice_lon = output_2D_ref.Lon_S;
            sliced_output.slice_lat_s = output_2D_ref.Lat_S;
            sliced_output.slice_lon_s = output_2D_ref.Lon_S;
            sliced_output.slice_lat_e = output_2D_ref.Lat_E;
            sliced_output.slice_lon_e = output_2D_ref.Lon_E;

            sliced_output.slice_time_start = output_2D_ref.Time_S;
            sliced_output.slice_time_end = output_2D_ref.Time_E;

            sliced_output.slice_nb_tracks = sum(output_2D_ref.nb_tracks,'omitnan');
            sliced_output.slice_nb_st = sum(output_2D_ref.nb_st,'omitnan');

            if ~isempty(Output_echo) && max([Output_echo(:).slice_time_end],[],'omitnan')<sliced_output.slice_time_start(1)
                Output_echo = [Output_echo sliced_output];
            else
                Output_echo = [sliced_output Output_echo];
            end

            sliced_output=[];

            for j = 1:length(regs)

                reg_curr = regs{j};
                regCellInt_r = regCellInt{j};


                if isempty(regCellInt_r)
                    continue;
                end

                if sum(regCellInt_r.eint,'all','omitnan') == 0
                    continue;
                end

                if ~isempty(cells_tmp) && ~isempty(reg_curr.Tag) && ~ismember(reg_curr.Tag,cells_tmp)
                    continue;
                end

                if  curr_options_struct.ExportRegions>0

                    outputFileXLS = generate_valid_filename(sprintf('%s_region_snap_%d_type_%s_strat_%s_trans_%d_%d_%s_%d_%s%s',str_fname,snap_num,type_t,strat_name,trans_num,ir,reg_curr.Reference,reg_curr.ID,reg_curr.Tag,'.csv'));

                    if ~isempty(regCellInt_r)
   

                        reg_output_table = reg_output_to_table(regCellInt_r);

                        if isfile(outputFileXLS)
                            try
                                delete(outputFileXLS);
                            catch err
                                if strcmpi(err.identifier,'MATLAB:DELETE:Permission')
                                    war_fig = dlg_perso([],'Could not overwrite file',sprintf('File %s is open in another process. Please close it and then close this box to continue...',outputFileXLS),'Timeout',30);
                                    waitfor(war_fig);
                                    delete(outputFileXLS);
                                else
                                    rethrow(err);
                                end
                            end
                        end
                        writetable(reg_output_table,outputFileXLS);
                    end
                end


                i_reg = i_reg+1;
                startPing = regCellInt_r.Ping_S(1);
                stopPing = regCellInt_r.Ping_E(end);
                ix = (startPing:stopPing);
                ix_good = intersect(ix,find(trans_obj_tr.Bottom.Tag>0));


                switch reg_curr.Reference
                    case 'Surface'
                        refType = 's';
                    case 'Bottom'
                        refType = 'b';
                    case 'Transducer'
                        refType = 't';
                end

                if ~isnan(min(regCellInt_r.Sample_S,[],'all','omitnan'))&&~isnan(min(regCellInt_r.Ping_S,[],'all','omitnan'))
                    start_d = trans_obj_tr.get_transceiver_depth(min(regCellInt_r.Sample_S,[],'all','omitnan'),...
                        min(regCellInt_r.Ping_S,[],'all','omitnan'),ceil(mean(idx_beam,'all','omitnan')));
                else
                    start_d = 0;
                end

                if ~isnan(min(regCellInt_r.Sample_S,[],'all','omitnan'))&&~isnan(max(regCellInt_r.Ping_E,[],'all','omitnan'))
                    finish_d = trans_obj_tr.get_transceiver_depth(min(regCellInt_r.Sample_S,[],'all','omitnan'),...
                        max(regCellInt_r.Ping_S,[],'all','omitnan'),ceil(mean(idx_beam,'all','omitnan')));
                else
                    finish_d = 0;
                end

                surv_out_obj.regionsIntegrated.snapshot(i_reg) = snap_num;
                surv_out_obj.regionsIntegrated.stratum{i_reg} = strat_name;
                surv_out_obj.regionsIntegrated.type{i_reg} = type_t;
                surv_out_obj.regionsIntegrated.transect(i_reg) = trans_num;

                surv_out_obj.regionsIntegrated.file{i_reg} = layer_obj_tr.Filename;
                surv_out_obj.regionsIntegrated.Region{i_reg} = reg_curr;
                surv_out_obj.regionsIntegrated.RegOutput{i_reg} = regCellInt_r;

                surv_out_obj.regionSum.snapshot(i_reg) = snap_num;
                surv_out_obj.regionSumAbscf.snapshot(i_reg) = snap_num;
                surv_out_obj.regionSumVbscf.snapshot(i_reg) = snap_num;

                surv_out_obj.regionSum.stratum{i_reg} = strat_name;
                surv_out_obj.regionSumAbscf.stratum{i_reg} = strat_name;
                surv_out_obj.regionSumVbscf.stratum{i_reg} = strat_name;

                surv_out_obj.regionSum.type{i_reg} = type_t;
                surv_out_obj.regionSumAbscf.type{i_reg} = type_t;
                surv_out_obj.regionSumVbscf.type{i_reg} = type_t;

                surv_out_obj.regionSum.transect(i_reg) = trans_num;
                surv_out_obj.regionSumAbscf.transect(i_reg) = trans_num;
                surv_out_obj.regionSumVbscf.transect(i_reg) = trans_num;

                surv_out_obj.regionSum.file{i_reg} = layer_obj_tr.Filename;
                surv_out_obj.regionSumAbscf.file{i_reg} = layer_obj_tr.Filename;
                surv_out_obj.regionSumVbscf.file{i_reg} = layer_obj_tr.Filename;

                surv_out_obj.regionSum.region_id(i_reg) = reg_curr.ID;
                surv_out_obj.regionSumAbscf.region_id(i_reg) = reg_curr.ID;
                surv_out_obj.regionSumVbscf.region_id(i_reg) = reg_curr.ID;

                %% Region Summary (4th Mbs Output Block)
                surv_out_obj.regionSum.time_end(i_reg) = regCellInt_r.Time_E(end);
                surv_out_obj.regionSum.time_start(i_reg) = regCellInt_r.Time_S(1);
                surv_out_obj.regionSum.ref{i_reg} = refType;
                surv_out_obj.regionSum.slice_size(i_reg) = reg_curr.Cell_h;
                surv_out_obj.regionSum.good_pings(i_reg) = length(ix_good);
                surv_out_obj.regionSum.start_d(i_reg) = start_d;
                surv_out_obj.regionSum.mean_d(i_reg) = mean_bot(ir);
                surv_out_obj.regionSum.finish_d(i_reg) = finish_d;
                surv_out_obj.regionSum.av_speed(i_reg) = av_speed(ir);
                surv_out_obj.regionSum.vbscf(i_reg) = sum(regCellInt_r.eint,'all','omitnan')./sum(regCellInt_r.Nb_good_pings.*regCellInt_r.Thickness_mean,'all','omitnan');
                surv_out_obj.regionSum.abscf(i_reg) = sum(regCellInt_r.eint,'all','omitnan')./max(regCellInt_r.Nb_good_pings,[],'all','omitnan');%Abscf Region
                surv_out_obj.regionSum.tag{i_reg} = reg_curr.Tag;

                %% Region Summary (abscf by vertical slice) (5th Mbs Output Block)
                surv_out_obj.regionSumAbscf.time_end{i_reg} = regCellInt_r.Time_E(end);
                surv_out_obj.regionSumAbscf.time_start{i_reg} = regCellInt_r.Time_S(1);
                surv_out_obj.regionSumAbscf.num_v_slices(i_reg) = size(regCellInt_r.eint,2);
                surv_out_obj.regionSumAbscf.transmit_start{i_reg} = regCellInt_r.Ping_S; % transmit Start vertical slice
                surv_out_obj.regionSumAbscf.latitude{i_reg} = regCellInt_r.Lat_S; % lat vertical slice
                surv_out_obj.regionSumAbscf.longitude{i_reg} = regCellInt_r.Lon_S; % lon vertical slice
                surv_out_obj.regionSumAbscf.column_abscf{i_reg} = sum(regCellInt_r.eint,1,'omitnan')./max(regCellInt_r.Nb_good_pings,[],1,'omitnan');%sum up all abcsf per vertical slice

                %% Region vbscf (6th Mbs Output Block)
                surv_out_obj.regionSumVbscf.time_end{i_reg} = regCellInt_r.Time_E;
                surv_out_obj.regionSumVbscf.time_start{i_reg} = regCellInt_r.Time_S;
                surv_out_obj.regionSumVbscf.num_h_slices(i_reg) = size(regCellInt_r.sv,1);% num_h_slices
                surv_out_obj.regionSumVbscf.num_v_slices(i_reg) = size(regCellInt_r.sv,2); % num_v_slices
                tmp = surv_out_obj.regionSum.vbscf(i_reg);
                tmp(isnan(tmp)) = 0;
                surv_out_obj.regionSumVbscf.region_vbscf(i_reg) = tmp; % Vbscf Region
                surv_out_obj.regionSumVbscf.vbscf_values{i_reg} = regCellInt_r.sv; %

                %% Region echo integral for Transect Summary
            end%end of regions iteration for this file

            output_2D_tot{ir} = output_2D;
            output_2D_type_tot{ir} = output_2D_type;
        end%end of layer iteration for this transect


        %% Transect Summary
        if ~all(find(~isnan(gps_tot.Long)))
            idx_s = intersect(idx_good_pings,find(~isnan(gps_tot.Long)));
        else
            idx_s = idx_good_pings;
        end
        if isempty(idx_s)
            idx_s = [1 numel(idx_good_pings)];
        end

        surv_out_obj.transectSum.snapshot(i_trans) = snap_num;
        surv_out_obj.transectSum.stratum{i_trans} = strat_name;
        surv_out_obj.transectSum.type{i_trans} = type_t;
        surv_out_obj.transectSum.transect(i_trans) = trans_num;
        surv_out_obj.transectSum.dist(i_trans) = dist_tot;

        surv_out_obj.transectSum.mean_d(i_trans) = mean(good_bot_tot,'omitnan'); % mean_d
        surv_out_obj.transectSum.pings(i_trans) = numel(idx_good_pings); % pings %

        surv_out_obj.transectSum.av_speed(i_trans) = av_speed_tot; % av_speed

        surv_out_obj.transectSum.start_lat(i_trans) = gps_tot.Lat(idx_s(1)); % start_lat
        surv_out_obj.transectSum.start_lon(i_trans) = gps_tot.Long(idx_s(1)); % start_lon

        surv_out_obj.transectSum.finish_lat(i_trans) = gps_tot.Lat(idx_s(end)); % finish_lat
        surv_out_obj.transectSum.finish_lon(i_trans) = gps_tot.Long(idx_s(end)); % finish_lon

        surv_out_obj.transectSum.time_start(i_trans) = gps_tot.Time(idx_s(1)); % finish_lat
        surv_out_obj.transectSum.time_end(i_trans) = gps_tot.Time(idx_s(end)); % finish_lon

        surv_out_obj.transectSum.vbscf(i_trans) = sum([Output_echo(:).eint],'omitnan')/(surv_out_obj.transectSum.mean_d(i_trans)*surv_out_obj.transectSum.pings(i_trans)); % vbscf according to Esp2 formula
        surv_out_obj.transectSum.abscf(i_trans) = sum([Output_echo(:).eint],'omitnan')/surv_out_obj.transectSum.pings(i_trans); % abscf according to Esp2 formula

        surv_out_obj.transectSum.shadow_zone_abscf(i_trans) = sum([Output_echo(:).shadow_zone_slice_abscf],'omitnan')/surv_out_obj.transectSum.pings(i_trans);

        surv_out_obj.transectSum.nb_pings_tot(i_trans) = nb_pings_tot;
        surv_out_obj.transectSum.nb_tracks(i_trans) = sum([Output_echo(:).slice_nb_tracks],'omitnan');
        surv_out_obj.transectSum.nb_st(i_trans) = sum([Output_echo(:).slice_nb_st],'omitnan');


        %% Sliced Transect Summary
        surv_out_obj.slicedTransectSum.snapshot(i_trans) = snap_num;
        surv_out_obj.slicedTransectSum.stratum{i_trans} = strat_name;
        surv_out_obj.slicedTransectSum.type{i_trans} = type_t;
        surv_out_obj.slicedTransectSum.transect(i_trans) = trans_num;

        surv_out_obj.slicedTransectSum.slice_size(i_trans) = mean([Output_echo(:).slice_size],'omitnan'); % slice_size
        surv_out_obj.slicedTransectSum.num_slices(i_trans) = sum([Output_echo(:).num_slices],'omitnan'); % num_slices

        surv_out_obj.slicedTransectSum.latitude{i_trans} = [Output_echo(:).slice_lat_s]; % latitude
        surv_out_obj.slicedTransectSum.longitude{i_trans} = [Output_echo(:).slice_lon_s]; % longitude

        surv_out_obj.slicedTransectSum.latitude_e{i_trans} = [Output_echo(:).slice_lat_e]; % latitude
        surv_out_obj.slicedTransectSum.longitude_e{i_trans} = [Output_echo(:).slice_lon_e]; % longitude

        surv_out_obj.slicedTransectSum.time_start{i_trans} = [Output_echo(:).slice_time_start]; %
        surv_out_obj.slicedTransectSum.time_end{i_trans} = [Output_echo(:).slice_time_end]; %
        surv_out_obj.slicedTransectSum.slice_abscf{i_trans} = [Output_echo(:).slice_abscf]; % slice_abscf
        surv_out_obj.slicedTransectSum.slice_nb_tracks{i_trans} = [Output_echo(:).slice_nb_tracks];
        surv_out_obj.slicedTransectSum.slice_nb_st{i_trans} = [Output_echo(:).slice_nb_st];
        
        slice_shadow_zone_abscf_temp = [Output_echo(:).shadow_zone_slice_abscf];
        slice_shadow_zone_abscf_temp(surv_out_obj.slicedTransectSum.slice_abscf{i_trans} == 0) = 0;
        surv_out_obj.slicedTransectSum.slice_shadow_zone_abscf{i_trans} = slice_shadow_zone_abscf_temp;

        if ~isempty(dbconn_ac_db)
            % Let's put everything we can in the database we have created
            % earlier

            %First, general transect informations
            t_name = sprintf('%s_%s_transect_snap_%d_type_%s_strat_%s_trans_%d_%d',surv_input_obj.Infos.SurveyName,surv_input_obj.Infos.Voyage,snap_num,type_t,strat_name,trans_num);
            trans_struct.transect_name = {t_name};
            trans_struct.transect_description = {'--'};
            trans_struct.transect_related_activity = {'--'};
            trans_struct.transect_start_time = {datestr(min(output.StartTime(idx_lay)),'yyyy-mm-dd HH:MM:SS')};
            trans_struct.transect_end_time = {datestr(max(output.EndTime(idx_lay)),'yyyy-mm-dd HH:MM:SS')};
            trans_struct.transect_lat_start	= surv_out_obj.slicedTransectSum.latitude{i_trans}(1);
            trans_struct.transect_lon_start = surv_out_obj.slicedTransectSum.longitude{i_trans}(1);
            trans_struct.transect_lat_end = surv_out_obj.slicedTransectSum.latitude_e{i_trans}(end);
            trans_struct.transect_lon_end = surv_out_obj.slicedTransectSum.longitude_e{i_trans}(end);
            trans_struct.transect_snapshot = snap_num;
            trans_struct.transect_stratum = {strat_name};
            trans_struct.transect_station = {'--'};
            trans_struct.transect_type = {type_t};
            trans_struct.transect_number = trans_num;
            trans_struct.transect_comments = {'--'};

            dbconn_ac_db.sqlwrite('t_transect',struct2table(trans_struct));
            trans_struct_get = rmfield(trans_struct,{'transect_lat_start','transect_lon_start','transect_lat_end','transect_lon_end'});
            [~,trans_pkey,~] = get_cols_from_table(dbconn_ac_db,'t_transect','input_struct',trans_struct_get,'output_cols',{'transect_pkey'});

            if istable(trans_pkey)
                trans_pkey = trans_pkey.transect_pkey;
            end
            
            %then transect summary in t_transect_summary
	        trans_summary_struct.transect_key		= trans_pkey;
	        trans_summary_struct.distance			= surv_out_obj.transectSum.dist(i_trans);% in mn
	        trans_summary_struct.average_speed		= surv_out_obj.transectSum.av_speed(i_trans);%in knots
	        trans_summary_struct.sv					= surv_out_obj.transectSum.vbscf(i_trans);%mean volumic acoustic backscatter
	        trans_summary_struct.sa				    = surv_out_obj.transectSum.abscf(i_trans);%mean areal acoustic bacsckatter
	        trans_summary_struct.sa_deadzone		= surv_out_obj.transectSum.shadow_zone_abscf(i_trans);%mean areal acoustic backscatter coming from dead-zone
	        trans_summary_struct.nb_st				= surv_out_obj.transectSum.nb_st(i_trans);%number of single targets
	        trans_summary_struct.nb_tracks			= surv_out_obj.transectSum.nb_tracks(i_trans);%number of tracked targets
	        trans_summary_struct.nb_pings 			= surv_out_obj.transectSum.nb_pings_tot(i_trans);%number of pings in transects
            
            dbconn_ac_db.sqlwrite('t_transect_summary',struct2table(trans_summary_struct));


            %now let's try to populate t_echoint_transect_2D and t_echoint_transect_1D

            for itout = 1:numel(output_2D_tot)
                output_2D_t  = output_2D_tot{itout};
                for itouti = 1:numel(output_2D_t)
                    output_2D = output_2D_t{itouti};
                    if strcmpi(output_2D_type_tot{itout}{itouti},'shadow')&&~any(output_2D.eint,'all')
                        continue;
                    end
                    
                    ff =fieldnames(output_2D);
                    idx_rem = ~ismember(ff,t_echoint_transect_2D_cols);
                    output_2D = rmfield(output_2D,ff(idx_rem));

                    output_1D  = output_reg_2D_to_1D(output_2D);
                    ff =fieldnames(output_1D);
                    idx_rem = ~ismember(ff,t_echoint_transect_1D_cols);
                    output_1D = rmfield(output_1D,ff(idx_rem));

                    output_1D.Reference=strings(size(output_1D.eint));
                    output_1D.Reference(:)  = output_2D_type_tot{itout}{itouti};

                    output_2D.Reference=strings(size(output_2D.eint));
                    output_2D.Reference(:)  = output_2D_type_tot{itout}{itouti};
                    
                    output_1D.transect_key = trans_pkey*ones(size(output_1D.eint),class(trans_pkey));
                    output_2D.transect_key = trans_pkey*ones(size(output_2D.eint),class(trans_pkey));

                    dbconn_ac_db.sqlwrite('t_echoint_transect_2D',reg_output_to_table(output_2D));
                    dbconn_ac_db.sqlwrite('t_echoint_transect_1D',reg_output_to_table(output_1D));
                end
            end

        end
    catch err
        war_str = sprintf('Could not Integrate Snapshot %.0f Type %s Stratum %s Transect %d\n',snap_num,type_t,strat_name,trans_num);
        print_errors_and_warnings(fid_error,'warning',war_str);
        print_errors_and_warnings(fid_error,'error',err);
        err_num = err_num+1;
        continue;
    end
    if ~isempty(load_bar_comp)
        set(load_bar_comp.progress_bar,'Value',i_trans);
    end
end


%% Stratum Summary (1st mbs Output block)

i_strat = 0;

snapshots = unique(snaps);

for isn = 1:length(snapshots)
    % loop over all snapshots and get Data subset
    ix = find(surv_out_obj.transectSum.snapshot == snapshots(isn));
    strats = unique(surv_out_obj.transectSum.stratum(ix));

    for j = 1:length(strats)
        i_strat = i_strat+1;

        jx = strcmpi(surv_out_obj.transectSum.stratum(ix), strats{j});
        idx = ix(jx);

        [design,radius] = surv_input_obj.get_start_design_and_radius(snapshots(isn),strats{j});
        i_trans_strat = find(surv_out_obj.slicedTransectSum.snapshot == snapshots(isn)&strcmp(strats{j},surv_out_obj.slicedTransectSum.stratum));
        il = 0;
        slice_trans_obj = surv_out_obj.slicedTransectSum;
        switch design
            case 'hill'
                [~,~,lat_trans,long_trans] = find_centre(slice_trans_obj.latitude(i_trans_strat),...
                    slice_trans_obj.longitude(i_trans_strat));

                for it = i_trans_strat
                    il = il+1;
                    [surv_out_obj.slicedTransectSum.slice_hill_weight{it},~,~] = compute_slice_weight_hills(...
                        slice_trans_obj.latitude{it},slice_trans_obj.longitude{it},...
                        slice_trans_obj.latitude_e{it},slice_trans_obj.longitude_e{it},...
                        lat_trans(il),long_trans(il),radius);
                end
            otherwise
                for it = i_trans_strat
                    il = il+1;
                    surv_out_obj.slicedTransectSum.slice_hill_weight{it} = zeros(size(surv_out_obj.slicedTransectSum.latitude{it}));
                end
        end

        surv_out_obj.stratumSum.snapshot(i_strat) = surv_out_obj.transectSum.snapshot(idx(1));
        surv_out_obj.stratumSum.stratum{i_strat} = surv_out_obj.transectSum.stratum{idx(1)};
        surv_out_obj.stratumSum.time_start(i_strat) = min(surv_out_obj.transectSum.time_start(idx),[],'omitnan');
        surv_out_obj.stratumSum.time_end(i_strat) = max(surv_out_obj.transectSum.time_end(idx),[],'omitnan');
        surv_out_obj.stratumSum.no_transects(i_strat) = length(surv_out_obj.transectSum.transect(idx));

        dist = surv_out_obj.transectSum.dist(idx);
        trans_abscf = surv_out_obj.transectSum.abscf(idx);
        trans_abscf_with_shz = trans_abscf+surv_out_obj.transectSum.shadow_zone_abscf(idx);

        [surv_out_obj.stratumSum.abscf_mean(i_strat),surv_out_obj.stratumSum.abscf_sd(i_strat)] = calc_abscf_and_sd(trans_abscf);
        [surv_out_obj.stratumSum.abscf_wmean(i_strat),surv_out_obj.stratumSum.abscf_var(i_strat)] = calc_weighted_abscf_and_var(trans_abscf,dist);

        [surv_out_obj.stratumSum.abscf_with_shz_mean(i_strat),surv_out_obj.stratumSum.abscf_with_shz_sd(i_strat)] = calc_abscf_and_sd(trans_abscf_with_shz);
        [surv_out_obj.stratumSum.abscf_with_shz_wmean(i_strat),surv_out_obj.stratumSum.abscf_with_shz_var(i_strat)] = calc_weighted_abscf_and_var(trans_abscf_with_shz,dist);


    end
end

sum_str = sprintf(['Integration process for script %s finished with:\n' ...
    '%d Warnings\n'...
    '%d Errors\n']...
    ,surv_obj.SurvInput.Infos.Title,war_num,err_num);

print_errors_and_warnings(fid_error,'',sum_str);

str_end = sprintf('Integration process for script %s finished at %s\n',surv_obj.SurvInput.Infos.Title,datestr(now));
print_errors_and_warnings(fid_error,'',str_end);

surv_obj.SurvOutput = surv_out_obj;

surv_obj.clean_output();

if  ~isempty(dbconn_ac_db)
    dbconn_ac_db.close();

    create_spatial_SQL(ac_db_filename,...
    {'t_transect','t_echoint_transect_1D'},{'transect_lon_start','Lon_S'},{'transect_lat_start','Lat_S'},4326);
end

if curr_options_struct.ExportRegions>0&&~isempty(reg_descr_table)
    outputFileXLS = generate_valid_filename(sprintf('%s%s',str_fname,'_reg_descriptors.csv'));
    if isfile(outputFileXLS)
        try
            delete(outputFileXLS);
        catch err
            if strcmpi(err.identifier,'MATLAB:DELETE:Permission')
                war_fig = dlg_perso([],'Could not overwrite file',sprintf('File %s is open in another process. Please close it and then close this box to continue...',outputFileXLS),'Timeout',30);
                waitfor(war_fig);
                delete(outputFileXLS);
            else
                rethrow(err);
            end
        end
    end
    writetable(reg_descr_table,outputFileXLS);
end


end

function [mask_in,mask_out]=match_data(t_in,r_in,t_out,r_out)

if istall(t_in)
    t_in = gather(t_in);
end

if istall(r_in)
    r_in = gather(r_in);
end

if istall(t_out)
    t_out = gather(t_out);
end

if istall(r_out)
    r_out = gather(r_out);
end


mask_in=zeros(size(r_in,1),size(t_in,2));
mask_out=zeros(size(r_out,1),size(t_out,2));
dt=gradient(t_out);

if size(r_out,2)==1
    dr = gradient(r_out);
elseif size(r_out,1)==1
    dr=inf;
else
    [~,dr] = gradient(r_out);
end

for j=1:size(t_out,2)
    [~,idx_t]=min(abs(t_out(j)-t_in));
    if abs(t_in(idx_t)-t_out(j))>abs(dt(j))
        t_in(idx_t)=nan;
        r_in(:,idx_t)
        continue;
    end
    for i=1:size(r_out,1)
        [~,idx_r]=min(abs(r_out(i,j)-r_in(:,idx_t)));
        if abs(r_in(idx_r,idx_t)-r_out(i,j))<=abs(dr(i,j))
            mask_out(i,j)=1;
            mask_in(idx_r,idx_t)=1;
        end
        r_in(idx_r,idx_t)=nan;
    end
    
end
mask_in=mask_in>0;
mask_out=mask_out>0;


end