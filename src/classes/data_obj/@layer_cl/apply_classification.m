function output_struct = apply_classification(layer,varargin)

p = inputParser;

addRequired(p,'layer',@(x) isa(x,'layer_cl'));
addParameter(p,'classification_file','',@ischar);
addParameter(p,'idx_chan',1:numel(layer.ChannelID),@isnumeric);
addParameter(p,'ref',list_echo_int_ref(1),@(x) ismember(x,list_echo_int_ref));
addParameter(p,'create_regions',true,@islogical);
addParameter(p,'cluster_tags',true,@islogical);
addParameter(p,'replicates',1,@(x) isnumeric(x)&&x>=1);
addParameter(p,'max_iter',1e3,@(x) isnumeric(x)&&x>=10);
addParameter(p,'nb_min_cells',3,@(x) isnumeric(x)&&x>=1);
addParameter(p,'distance','sqeuclidean',@(x) ismember(x,{'sqeuclidean' 'cityblock' 'cosine' 'correlation'}));
addParameter(p,'reslice',true,@islogical);
addParameter(p,'thr_cluster',10,@isnumeric);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl')||isempty(x));
addParameter(p,'survey_options',[],@(x) isempty(x)||isa(x,'survey_options_cl'));
addParameter(p,'timeBounds',[0 inf],@isnumeric);
addParameter(p,'load_bar_comp',[]);

parse(p,layer,varargin{:});

if isempty(p.Results.survey_options)
    surv_options_obj  = layer.get_survey_options();
else
    surv_options_obj  = p.Results.survey_options;
end

primary_freq=surv_options_obj.Frequency.Value;
reg_obj=p.Results.reg_obj;

output_struct.school_struct=[];
output_struct.out_type={};
output_struct.done=false;

if any(layer.Transceivers.ismb)
    disp('This algorithm has not been ported to MBES/Imaging sonar data (yet)... Sorry about that!');
    return;
end

classification_file=p.Results.classification_file;

if ~isempty(classification_file) && ~isfile(classification_file)
    [files_classif,~,~]=list_classification_files();
    idx_c = find(contains(files_classif,classification_file),1);
    if ~isempty(idx_c)
        classification_file = files_classif{idx_c};
    end
end

if isempty(classification_file)||~isfile(classification_file)
    dlg_perso([],'',sprintf('Cannot find classification file %s.',classification_file));
    return;
end

if isfile(classification_file)
    try
        class_tree_obj = decision_tree_cl(classification_file);
    catch
        dlg_perso([],'Warning',sprintf('Cannot parse specified classification file: %s',classification_file));
        return;
    end
else
    dlg_perso([],'Warning',sprintf('Cannot find specified classification file: %s',classification_file));
    return;
end

[vars,use_for_clustering]=class_tree_obj.get_variables();

sv_freqs=cellfun(@(x) textscan(x,'Sv_%dkHz'),vars,'un',1);
delta_sv_freqs=cellfun(@(x) textscan(x,'delta_Sv_%dkHz_%dkHz'),vars,'un',0);

idx_var_freq=find(cellfun(@(x) ~any(isempty(x)),sv_freqs));
idx_var_freq_sec=find(cellfun(@(x) numel([x{:}])==numel(x),delta_sv_freqs));

primary_freqs_sv = [sv_freqs{idx_var_freq}];

primary_freqs_delta = cellfun(@(x) [x{1}],delta_sv_freqs(idx_var_freq_sec));
sec_freqs_delta = cellfun(@(x) [x{2}],delta_sv_freqs(idx_var_freq_sec));

primary_freqs = double([primary_freqs_delta(:)' setdiff(primary_freqs_sv,primary_freqs_delta)]);
primary_freqs = primary_freqs*1e3;
secondary_freqs = nan(1,numel(primary_freqs));
secondary_freqs(1:numel(sec_freqs_delta)) = double(sec_freqs_delta);
secondary_freqs = secondary_freqs*1e3;
idx_primary_freqs=nan(1,numel(primary_freqs));
idx_secondary_freqs=nan(1,numel(primary_freqs));

[trans_obj_primary,idx_primary_freq]=layer.get_trans(primary_freqs(1));

if isempty(trans_obj_primary)
    dlg_perso([],'',sprintf('Cannot find %dkHz! Cannot apply classification here....',primary_freq/1e3));
    return;
end

switch lower(class_tree_obj.ClassificationType)
    case 'by regions'
        if isempty(reg_obj)
            idx_schools=trans_obj_primary.find_regions_type('Data');
            if isempty(idx_schools)
                dlg_perso([],'',sprintf('No regions defined on %dkHz!',primary_freq/1e3));
            end
        else
            idx_schools=trans_obj_primary.find_regions_Unique_ID(reg_obj.Unique_ID);
        end

        nb_schools=numel(idx_schools);
        output_struct.school_struct=cell(nb_schools,1);
        surv_options_obj.IntRef.set_value('');
        surv_options_obj.IntType.set_value('Regions only');

    case 'cell by cell'
        nb_schools=0;
        idx_schools=[];
        output_struct.school_struct=[];
        surv_options_obj.IntRef.set_value(p.Results.ref);
        if isempty(reg_obj)
            surv_options_obj.IntType.set_value('WC');
        else
            surv_options_obj.IntType.set_value('By regions');
        end
    otherwise
        dlg_perso([],'Warning',sprintf('Un regognized ClassificationType in classification file: %s\n Should be "Cell by cell" or "By regions"',classification_file));
        return;
end


if isempty(primary_freqs)
    dlg_perso([],'Warning',sprintf('No Sv acoustic parameter defined in the classification file(either Sv_XXkHz or delta_Sv_XXkHz_YYkHz).\nThere needs to be at least one.'));
    return;
end

for ii=1:numel(primary_freqs)

    [idx_primary_freqs(ii),found]=find_freq_idx(layer,primary_freqs(ii));

    if ~found
        dlg_perso([],'Warning',sprintf('Cannot find %dkHz! Cannot apply classification here...',primary_freqs(ii)/1e3));
        return;
    end
    if ~isnan(secondary_freqs(ii))
        [idx_secondary_freqs(ii),found]=find_freq_idx(layer,secondary_freqs(ii));
        if ~found
            dlg_perso([],'Warning',sprintf('Cannot find %dkHz! Cannot apply classification here...',secondary_freqs(ii)/1e3));
            return;
        end
    end
end

idx_freq_tot=union(idx_primary_freqs,idx_secondary_freqs);
idx_freq_tot(isnan(idx_freq_tot))=[];

if strcmpi(class_tree_obj.ClassificationType,'by regions')||p.Results.reslice||isempty(layer.EchoIntStruct)||~all(ismember(idx_freq_tot,layer.EchoIntStruct.idx_freq_out))
    layer.multi_freq_slice_transect2D(...
        'idx_regs',idx_schools,...
        'timeBounds',p.Results.timeBounds,...
        'regs',p.Results.reg_obj,...
        'idx_main_freq',idx_primary_freq,...
        'idx_sec_freq',idx_freq_tot,...
        'tag_sliced_output',false,...
        'keep_all',1,...
        'keep_bottom',1,...
        'survey_options',surv_options_obj,...
        'load_bar_comp',p.Results.load_bar_comp);
end

switch lower(class_tree_obj.ClassificationType)
    case 'by regions'
        if nb_schools>0
            reg_descr_struct = table2struct(layer.EchoIntStruct.reg_descr_table);

            reg_descr_struct = rmfield(reg_descr_struct,{'SurveyName' 'Voyage' 'ID' 'Tag' 'Type' 'Snapshot' 'Stratum' 'Transect'});
            reg_descr_f  =    fieldnames(reg_descr_struct);
        end

        for jj=1:nb_schools
            for ii=1:numel(primary_freqs)
                i_freq_p=layer.EchoIntStruct.idx_freq_out==idx_primary_freqs(ii);
                output_reg_p=layer.EchoIntStruct.regCellInt_tot{i_freq_p}{jj};
                output_struct.school_struct{jj}.(sprintf('Sv_%dkHz',primary_freqs(ii)/1e3))=pow2db_perso(mean(output_reg_p.sv,'all'));
                output_struct.school_struct{jj}.(sprintf('sd_Sv_%dkHz',primary_freqs(ii)/1e3))=std(pow2db_perso(output_reg_p.sv),0,'all','omitnan');
                if ~isnan(idx_secondary_freqs(ii))
                    i_freq_s=layer.EchoIntStruct.idx_freq_out==idx_secondary_freqs(ii);
                    output_reg_s=layer.EchoIntStruct.regCellInt_tot{i_freq_s}{jj};
                    ns=numel(output_reg_s.nb_samples);
                    np=numel(output_reg_p.nb_samples);
                    n=min(ns,np);
                    delta_temp=mean(pow2db_perso(output_reg_p.sv(1:n))-pow2db_perso(output_reg_s.sv(1:n)));
                    delta_temp(isnan(delta_temp))=0;
                    output_struct.school_struct{jj}.(sprintf('delta_Sv_%dkHz_%dkHz',primary_freqs(ii)/1e3,secondary_freqs(ii)/1e3))=delta_temp;
                    output_struct.school_struct{jj}.(sprintf('Sv_%dkHz',secondary_freqs(ii)/1e3))=pow2db_perso(mean(output_reg_s.sv,'all'));
                    output_struct.school_struct{jj}.(sprintf('sd_Sv_%dkHz',secondary_freqs(ii)/1e3))=std(pow2db_perso(output_reg_s.sv),0,'all','omitnan');
                end
            end

            output_struct.school_struct{jj}.nb_cell=sum(output_reg_p.sv>0,'all','omitnan');
            output_struct.school_struct{jj}.aggregation_depth_min=min(output_reg_p.Depth_mean,[],'all');
            output_struct.school_struct{jj}.aggregation_depth_mean=mean(output_reg_p.Depth_mean,'all');
            output_struct.school_struct{jj}.aggregation_depth_max=max(output_reg_p.Depth_mean,[],'all');
            output_struct.school_struct{jj}.bottom_depth=mean(trans_obj_primary.get_bottom_range(output_reg_p.Ping_S(1):output_reg_p.Ping_E(end)));

            for ifi = 1:numel(reg_descr_struct)
                output_struct.school_struct{jj}.(reg_descr_f{ifi}) = reg_descr_struct(jj).(reg_descr_f{ifi});
            end

        end

    case 'cell by cell'
       
        idx_main=find(idx_primary_freq==layer.EchoIntStruct.idx_freq_out);
        output_struct.school_struct=cell(1,numel(layer.EchoIntStruct.output_2D{idx_main}));

        for ui=1:numel(output_struct.school_struct)
            output_struct.school_struct{ui}=layer.EchoIntStruct.output_2D{idx_main}{ui};
            output_struct.out_type{ui}=layer.EchoIntStruct.output_2D_type{idx_main}{ui};
            for ip=1:numel(primary_freqs)

                if idx_primary_freq==idx_primary_freqs(ip)
                    tmp=pow2db_perso(output_struct.school_struct{ui}.sv);
                else
                    tmp=pow2db_perso(output_struct.school_struct{ui}.(sprintf('sv_%dkHz',primary_freqs(ip)/1e3)));
                end
                output_struct.school_struct{ui}.(sprintf('Sv_%dkHz',primary_freqs(ip)/1e3))=tmp;

                if ~isnan(secondary_freqs(ip))

                    if idx_primary_freq==idx_secondary_freqs(ip)
                        tmp_sec=pow2db_perso(output_struct.school_struct{ui}.sv);
                    else
                        tmp_sec=pow2db_perso(output_struct.school_struct{ui}.(sprintf('sv_%dkHz',secondary_freqs(ip)/1e3)));
                    end

                    delta_tmp=tmp-tmp_sec;
                    output_struct.school_struct{ui}.(sprintf('delta_Sv_%dkHz_%dkHz',primary_freqs(ip)/1e3,secondary_freqs(ip)/1e3))=delta_tmp;
                    output_struct.school_struct{ui}.(sprintf('Sv_%dkHz',secondary_freqs(ip)/1e3))=tmp_sec;
                end


            end
        end
end

if ~isempty(p.Results.load_bar_comp)
    p.Results.load_bar_comp.progress_bar.setText('Applying classification tree...');
end

for ui=1:length(output_struct.school_struct)
    switch lower(class_tree_obj.ClassificationType)
        case 'by regions'
            tag=class_tree_obj.apply_classification_tree(output_struct.school_struct{ui},p.Results.load_bar_comp);
            trans_obj_primary.Regions(idx_schools(ui)).Tag=char(tag);

        case 'cell by cell'
            tag=class_tree_obj.apply_classification_tree(output_struct.school_struct{ui},p.Results.load_bar_comp);
            l_min_can = surv_options_obj.Vertical_slice_size.Value/2;
            h_min_can = surv_options_obj.Horizontal_slice_size.Value/2;
            nb_min_cells = p.Results.nb_min_cells;

            switch lower(surv_options_obj.Vertical_slice_units.Value)
                case 'pings'
                    dist_can = output_struct.school_struct{ui}.Ping_S;
                case 'meters'
                    dist_can= output_struct.school_struct{ui}.Dist_S;
                    if mean(diff(dist_can))==0
                        warning('No Distance was computed, using ping instead of distance for linking');
                        dist_can= output_struct.school_struct{ui}.Ping_S;
                    end
                case 'seconds'
                    dist_can = output_struct.school_struct{ui}.Time_S;
            end


            tags  = class_tree_obj.Classes.Class;
            thr_clusters = class_tree_obj.Classes.Class_cluster_thr;
            thr_clusters(isnan(thr_clusters) | thr_clusters==0) = p.Results.thr_cluster;
            
            thr_clusters(tags=="") = [];
            tags(tags=="") = [];

            nb_tags = numel(tags);

            vars = vars(use_for_clustering);

            if p.Results.cluster_tags

                output = output_struct.school_struct{ui};
                %vars = {'Sv_38kHz' 'sd_Sv' 'Depth_min'};
                nb_vars = numel(vars);
                [nb_r,nb_c] = size(output.ABC);

                data_to_segment = nan(nb_r*nb_c,nb_vars);
                id_rem = [];

                for uiv = 1:nb_vars
                    if all(isnan(output.(vars{uiv})),'all')||all(isinf(output.(vars{uiv})),'all')
                        id_rem = union(id_rem,uiv);
                        continue;
                    end
                    if all(size(output.(vars{uiv})) == [nb_r nb_c])
                        tmp = output.(vars{uiv});
                    elseif  size(output.(vars{uiv}),1) == nb_r
                        tmp = repmat(output.(vars{uiv}),1,nb_c);
                    elseif size(output.(vars{uiv}),2) == nb_c
                        tmp = repmat(output.(vars{uiv}),nb_r,1);
                    end

                    tmp(tag == "") = nan;
                    tmp = (tmp-mean(tmp,'all','omitnan'))./std(tmp,0,'all','omitnan');
                    data_to_segment(:,uiv) = tmp(:);
                end
                
                if ~isempty(id_rem)
                    data_to_segment(:,id_rem) = [];
                end

                stream = RandStream('mlfg6331_64');  

                options = statset('UseParallel',1,'UseSubstreams',1,...
                    'Streams',stream);
                nb_tags = min(size(data_to_segment,1),nb_tags);

                [idx,~,~,~] = kmeans(data_to_segment,nb_tags,'Options',options,'MaxIter',p.Results.max_iter,...
                    'Display','final','Replicates',p.Results.replicates,'Distance',p.Results.distance,'Display','final','EmptyAction','drop','OnlinePhase','on','Start','cluster');

                idx_mat = reshape(idx,nb_r,nb_c);
                nb_clusters = numel(unique(idx(~isnan(idx))));

                tag_f=strings(size(tag));
                new_id_mat = zeros(size(tag_f));
                perc_val = zeros(nb_tags,nb_clusters);


                for uid =  1:nb_clusters
                    id_temp = zeros(nb_tags,1);
                    curr_id = (idx_mat == uid);
                    nb_cells = sum(curr_id,'all');
                    for uidd = 1:nb_tags
                        id_temp(uidd) = sum(curr_id & tag == tags(uidd),'all')/nb_cells*100;
                        %figure();imagesc(curr_id & output.Tags == tags(uidd))
                    end
                    perc_val(:,uid) = id_temp;

                    if ~any(id_temp>=thr_clusters)
                        id_temp(id_temp<max(id_temp)) = 0;
                    else
                        id_temp(id_temp<thr_clusters) = 0;
                    end

                    id_temp(id_temp>0) = 100;
                    [val,id_val] = sort(id_temp);
                    
                    for uival = 1:nb_tags
                        if val(uival)<thr_clusters(uival)
                            continue;
                        end
                        if uival<nb_tags
                            mask = curr_id & tag == tags(id_val(uival));
                        else
                            mask = curr_id;
                        end

                        new_id_mat(mask) = id_val(uival);
                        tag_f(mask) = tags(id_val(uival));
                        curr_id(mask) = false;
                    end
                end
            else
                tag_f = tag;
            end

            candidates=find_candidates_v3(tag_f~="",mean(output_struct.school_struct{ui}.Range_ref_min(:,:),2,'omitnan'),dist_can,l_min_can,h_min_can,nb_min_cells,'mat',[]);
            tag_f(~candidates) = "";

            layer.EchoIntStruct.output_2D{idx_main}{ui}.Tags=tag_f;
            layer.EchoIntStruct.output_2D{idx_main}{ui}.Tag_cmap = cell2mat(class_tree_obj.Classes.Class_color);
            layer.EchoIntStruct.output_2D{idx_main}{ui}.Tag_str = class_tree_obj.Classes.Class;
            layer.EchoIntStruct.output_2D{idx_main}{ui}.Tag_descr = class_tree_obj.Classes.Class_descr;

            if p.Results.create_regions

                if ~isempty(p.Results.load_bar_comp)
                    p.Results.load_bar_comp.progress_bar.setText('Creating regions...');
                    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(tags), 'Value',0);
                end

                for itag = 1:numel(tags)
                    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(tags), 'Value',itag);
                    can_temp=candidates;
                    can_temp(tag_f~=tags{itag})=0;

                    if ~any(can_temp,'all')
                        continue;
                    end

                    trans_obj_primary.create_regions_from_linked_candidates(can_temp,...
                        'idx_ping',ceil(1/2*(output_struct.school_struct{ui}.Ping_S+output_struct.school_struct{ui}.Ping_E)),...
                        'idx_r',ceil(1/2*(output_struct.school_struct{ui}.Sample_S+output_struct.school_struct{ui}.Sample_E)),...
                        'w_unit',surv_options_obj.Vertical_slice_units.Value,...
                        'cell_w',surv_options_obj.Vertical_slice_size.Value,...
                        'h_unit','meters',...
                        'ref',layer.EchoIntStruct.output_2D_type{idx_main}{ui},...
                        'cell_h',surv_options_obj.Horizontal_slice_size.Value,...
                        'reg_names','Classified',...
                        'tag',tags{itag},...
                        'rm_overlapping_regions',false);

                end
            end

    end
end

output_struct.done=true;
disp('Done.');
end



