function output_struct = canopy_height_estimation(layer_obj,varargin)

default_thr_sv=-70;
check_thr_sv=@(thr)(thr>=-999&&thr<=0);

default_nb_min_sples=100;
check_nb_min_sples=@(l)(l>0);

p = inputParser;

addRequired(p,'layer_obj',@(x) isa(x,'layer_cl'));
addParameter(p,'idx_chan',1:numel(layer_obj.ChannelID),@isnumeric);
addParameter(p,'thr_sv',default_thr_sv,check_thr_sv);
addParameter(p,'r_min',0,@isnumeric);
addParameter(p,'nb_min_sples',default_nb_min_sples,check_nb_min_sples);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'survey_options',[],@(x) isempty(x)||isa(x,'survey_options_cl'));
addParameter(p,'timeBounds',[0 inf],@isnumeric);
addParameter(p,'load_bar_comp',[]);
addParameter(p,'block_len',0,@(x) x>0 || isempty(x));

parse(p,layer_obj,varargin{:});

output_struct.done =  false;

idx_chan=p.Results.idx_chan;

idx_chan(idx_chan>numel(layer_obj.ChannelID))=[];

for ui = 1 : numel(idx_chan)
    trans_obj = layer_obj.Transceivers(idx_chan(ui));

    if trans_obj.ismb()
        disp('This algorithm has not been ported to MBES/Imaging sonar data (yet)... Sorry about that!');
        continue;
    end

    r_trans = trans_obj.get_samples_range();
    t_trans = trans_obj.get_transceiver_time();

    bot_idx = trans_obj.get_bottom_idx();
    idx_max = min(max(bot_idx,[],'omitnan'),numel(r_trans),'omitnan');
    rmax = r_trans(idx_max)+10;
    r_min = p.Results.r_min;


    reg_wc = trans_obj.create_WC_region(...
        'y_min',r_min,...
        'y_max',rmax,...
        'Type','Data',...
        'Ref','Surface',...
        'Cell_w',100,...
        'Cell_h',0.1,...
        'Cell_w_unit','pings',...
        'Cell_h_unit','meters');

    if isempty(p.Results.reg_obj)
        reg_obj = reg_wc;
    else
        reg_obj_temp = [reg_wc p.Results.reg_obj];
        reg_obj = reg_obj_temp.merge_regions('overlap_only',1);
    end

    field = 'sv';
    alt_fields = {'img_intensity'};
    [Sv_mat,idx_r,idx_ping,~,bad_data_mask,bad_trans_vec,~,~,~]=get_data_from_region(trans_obj,reg_obj,'field',field,'alt_fields',alt_fields);
    Sv_mat(bad_data_mask|bad_trans_vec) = -999;
    sv_thr_canopy = p.Results.thr_sv;
    %sv_thr_bot = -45;
    nb_samples = p.Results.nb_min_sples;

    CC_canopy = bwconncomp(Sv_mat >= sv_thr_canopy);
    %CC_bot = bwconncomp(Sv_mat >= sv_thr_bot);

    bot_idx_norm = bot_idx-min(idx_r)+1;
    idx_ping_norm = idx_ping-min(idx_ping)+1;
    bot_pixels = bot_idx_norm+size(Sv_mat,1)*(idx_ping_norm-1);

%     idx_keep_bot = find(cellfun(@numel,CC_bot.PixelIdxList)>nb_samples);
%     Sv_mat_Mask_bot = false(size(Sv_mat));
% 
%     for uit = 1:numel(idx_keep_bot)
%         if ~isempty(intersect(bot_pixels,CC.PixelIdxList{idx_keep_bot(uit)}))
%             Sv_mat_Mask_bot(CC.PixelIdxList{idx_keep_bot(uit)}) = true;
%         end
%     end

    idx_keep_canopy = find(cellfun(@numel,CC_canopy.PixelIdxList)>nb_samples);
    Sv_mat_Mask_canopy = false(size(Sv_mat));

    for uit = 1:numel(idx_keep_canopy)
        if ~isempty(intersect(bot_pixels,CC_canopy.PixelIdxList{idx_keep_canopy(uit)}))
            Sv_mat_Mask_canopy(CC_canopy.PixelIdxList{idx_keep_canopy(uit)}) = true;
        end
    end
    r_line = nan(1,numel(idx_ping));

    for imat = 1:size(Sv_mat_Mask_canopy,2)
        id_first = find(Sv_mat_Mask_canopy(:,imat),1);
        if ~isempty(id_first)
            r_line(imat) = r_trans(idx_r(id_first));
        end
    end
    b_d = trans_obj.get_bottom_depth(idx_ping);
    r_line(isnan(b_d)) = nan;
    line_obj = line_cl('Time',t_trans(idx_ping),...
        'Range',r_line,...
        'Reference','Transducer',...
        'Name',sprintf('Canopy_%s',layer_obj.ChannelID{idx_chan(ui)}),...
        'Tag','Canopy'...
        );
    idx = layer_obj.get_lines_per_Tag('Canopy');
    if ~isempty(idx)
        layer_obj.Lines(idx) = [];
    end

    if size(layer_obj.SurveyData,2)>1
        for iis=1:size(layer_obj.SurveyData,2)
            id = intersect(find(line_obj.Time<=layer_obj.SurveyData{iis}.EndTime),find(line_obj.Time>=layer_obj.SurveyData{iis}.StartTime));
            new_line = line_obj.copy_line;
            if (~isempty(layer_obj.SurveyData{iis}.Stratum))&&(~isempty(layer_obj.SurveyData{iis}.Type))
                new_line.Name = append(line_obj.Name,'_snapshot',num2str(layer_obj.SurveyData{iis}.Snapshot),'_',layer_obj.SurveyData{iis}.Stratum,'_',layer_obj.SurveyData{iis}.Type,'_transect',num2str(layer_obj.SurveyData{iis}.Transect));
                new_line.ID = append(line_obj.ID,'_snapshot',num2str(layer_obj.SurveyData{iis}.Snapshot),'_',layer_obj.SurveyData{iis}.Stratum,'_',layer_obj.SurveyData{iis}.Type,'_transect',num2str(layer_obj.SurveyData{iis}.Transect));
            else
                new_line.Name = append(line_obj.Name,'_part',num2str(iis));
                new_line.ID = append(line_obj.ID,'_part',num2str(iis));
            end
            new_line.Time = line_obj.Time(id);
            new_line.Range = line_obj.Range(id);
            new_line.Data = line_obj.Data(id);
            new_line.LineWidth = 0.5;
            layer_obj.add_lines(new_line);
        end
    else
        layer_obj.add_lines(line_obj);
    end

end

output_struct.done = true;
