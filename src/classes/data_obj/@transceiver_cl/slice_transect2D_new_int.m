function [output_2D,output_type,regs,regCellInt,shadow_height_est]=slice_transect2D_new_int(trans_obj,varargin)

p = inputParser;


addRequired(p,'trans_obj',@(trans_obj) isa(trans_obj,'transceiver_cl'));
addParameter(p,'idx_regs',[],@isnumeric);
addParameter(p,'regs',region_cl.empty(),@(x) isa(x,'region_cl')|isempty(x));
addParameter(p,'survey_options',[],@(x) isempty(x)||isa(x,'survey_options_cl'));
addParameter(p,'timeBounds',[0 inf],@isnumeric);
addParameter(p,'keep_all',false,@(x) isnumeric(x)||islogical(x));
addParameter(p,'keep_bottom',false,@(x) isnumeric(x)||islogical(x));
addParameter(p,'tag_sliced_output',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'output_type',list_echo_int_ref,@iscell);
addParameter(p,'cal',[],@(x) isstruct(x) || isempty(x));
addParameter(p,'envdata',[],@(x) isa(x,'env_data_cl') || isempty(x));
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
addParameter(p,'load_bar_comp',[]);

parse(p,trans_obj,varargin{:});

block_len = get_block_len(50,'cpu',p.Results.block_len);

if isempty(p.Results.survey_options)
    surv_options_obj  = layer_obj.get_survey_options();
else
    surv_options_obj  = p.Results.survey_options;
end

Vertical_slice_size=surv_options_obj.Vertical_slice_size.Value;
Vertical_slice_units=surv_options_obj.Vertical_slice_units.Value;
Horizontal_slice_size=surv_options_obj.Horizontal_slice_size.Value;

depthBounds=[surv_options_obj.DepthMin.Value surv_options_obj.DepthMax.Value];
rangeBounds=[surv_options_obj.RangeMin.Value surv_options_obj.RangeMax.Value];
refRangeBounds=[surv_options_obj.RefRangeMin.Value surv_options_obj.RefRangeMax.Value];
BeamAngularLimit=[surv_options_obj.AngleMin.Value surv_options_obj.AngleMax.Value];
if p.Results.timeBounds(1)<=0
    st=trans_obj.Time(1);
else
    st=p.Results.timeBounds(1);
end

if p.Results.timeBounds(2)==1||isinf(p.Results.timeBounds(2))
    et=trans_obj.Time(end);
else
    et=p.Results.timeBounds(2);
end


switch lower(surv_options_obj.IntRef.Value)
    case lower(list_echo_int_ref())
        output_type = {surv_options_obj.IntRef.Value};
    otherwise
        output_type = {list_echo_int_ref(2)};
end

if surv_options_obj.Shadow_zone.Value
    output_type=union(output_type,'Shadow');
end

t_depth=trans_obj.get_transducer_depth();
t_depth=unique(t_depth);

switch lower(surv_options_obj.IntType.Value)
    case 'by regions'
        slice_int = true;
        intersect_only=1;
        reg_int = true;
    case 'wc'
        slice_int = true;
        intersect_only=0;    
        reg_int = false;
    case 'regions only'
        slice_int = false;
        intersect_only=1;
        reg_int = true;
    otherwise
        slice_int = true;
        intersect_only=1;
        reg_int = true;
end

if all(t_depth==0) && ismember('Surface',output_type) && intersect_only ==0
    output_type(strcmpi(output_type,'Transducer'))=[];
end

bot_range=trans_obj.get_bottom_range();

if all(isnan(bot_range))
    output_type(strcmpi(output_type,'Bottom'))=[];
end

output_2D=cell(1,numel(output_type));
idx_reg=cell(1,numel(output_type));
regs_ref=cell(1,numel(output_type));

if slice_int 
        for ity=1:numel(output_type)
            idx_reg{ity}=find_regions_ref(trans_obj,output_type{ity});
            idx_reg{ity}=intersect(idx_reg{ity},p.Results.idx_regs);
            
            if ~isempty(p.Results.regs)&&intersect_only
                regs_ref{ity}=p.Results.regs(strcmp({p.Results.regs(:).Reference},output_type{ity}));
            else
                regs_ref{ity}=region_cl.empty();
            end
        end
    
    int_trans=all(cellfun(@isempty,idx_reg))&&all(cellfun(@isempty,regs_ref));
    
    for ity=1:numel(output_type)
        if strcmpi(output_type{ity},'Shadow')
            continue;
        end
        
        
        if ~isempty(idx_reg{ity})||~isempty(regs_ref{ity})||intersect_only==0||(int_trans&&all(cellfun(@isempty,output_2D)))
            
            switch lower(output_type{ity})
                case 'transducer'
                    y_min = min(rangeBounds);
                    y_max = max(rangeBounds);
                case 'surface'
                    dd  = trans_obj.get_transducer_depth();
                    y_min = max(min(depthBounds),min(dd)+min(rangeBounds));
                    y_max = min(max(depthBounds),max(dd)+max(rangeBounds));
                case 'bottom'
                    y_min= -max(refRangeBounds);
                    y_max= -min(refRangeBounds);
            end

            idx_beams = trans_obj.get_idx_beams(BeamAngularLimit);

            reg_wc=trans_obj.create_WC_region(...
                'idx_beam',round(mean(idx_beams)),...
                'y_min',y_min,...
                'y_max',y_max,...
                'Type','Data',...
                'Ref',output_type{ity},...
                'Cell_w',Vertical_slice_size,...
                'Cell_h',Horizontal_slice_size,...
                'Cell_w_unit',Vertical_slice_units,...
                'Cell_h_unit','meters',...
                'block_len',block_len,...
                'Remove_ST',surv_options_obj.Remove_ST.Value);
            
            if  ~isempty(reg_wc)
                switch output_type{ity}
                    case 'Bottom'
                        output_2D{ity}=	trans_obj.integrate_region(reg_wc,...
                            'depthBounds',depthBounds,...
                            'rangeBounds',rangeBounds,...
                            'refRangeBounds',refRangeBounds,...
                            'BeamAngularLimit',BeamAngularLimit,...
                            'timeBounds',[st et],...
                            'idx_regs',idx_reg{ity},...
                            'regs',regs_ref{ity},...
                            'select_reg','selected',...
                            'intersect_only',intersect_only,...
                            'denoised',surv_options_obj.Denoised.Value,...
                            'motion_correction',surv_options_obj.Motion_correction.Value,...
                            'keep_all',1,...
                            'sv_thr',surv_options_obj.SvThr.Value,...
                            'envdata',p.Results.envdata,'cal',p.Results.cal,...
                            'feature_bool',surv_options_obj.Feature_bool.Value,...
                            'block_len',block_len,...
                            'load_bar_comp',p.Results.load_bar_comp);
                    case {'Transducer','Surface'}
                        output_2D{ity}=	trans_obj.integrate_region(reg_wc,...
                            'depthBounds',depthBounds,...
                            'rangeBounds',rangeBounds,...
                            'refRangeBounds',refRangeBounds,...
                            'BeamAngularLimit',BeamAngularLimit,...
                            'timeBounds',[st et],...
                            'idx_regs',idx_reg{ity},...
                            'regs',regs_ref{ity},...
                            'select_reg','selected',...
                            'intersect_only',intersect_only,...
                            'denoised',surv_options_obj.Denoised.Value,...
                            'motion_correction',surv_options_obj.Motion_correction.Value,...
                            'keep_all',1,...
                            'sv_thr',surv_options_obj.SvThr.Value,...
                            'feature_bool',surv_options_obj.Feature_bool.Value,...
                            'envdata',p.Results.envdata,'cal',p.Results.cal,...
                            'block_len',block_len,...
                            'load_bar_comp',p.Results.load_bar_comp);
                end
            else
                output_2D{ity}=[];
            end
        else
            output_2D{ity}=[];
        end
        
        regs_temp=trans_obj.Regions;
        
        if ~isempty(regs_temp)&&~isempty(output_2D{ity})&&p.Results.tag_sliced_output
            tmp=regs_temp.tag_sliced_output(output_2D{ity},'all');
            output_2D{ity}.Tags=tmp{1};
        elseif ~isempty(output_2D{ity})
            s_eint=gather(size(output_2D{ity}.eint));
            output_2D{ity}.Tags=strings(s_eint);
        end
    end
end

idx_reg_out=unique([idx_reg{:}]);

regCellInt=cell(1,length(idx_reg_out)+numel(p.Results.regs));
regs=cell(1,length(idx_reg_out)+numel(p.Results.regs));

if reg_int
    for ireg=1:length(idx_reg_out)
        regs{ireg}=trans_obj.Regions(idx_reg_out(ireg));
        regCellInt{ireg}=trans_obj.integrate_region(trans_obj.Regions(idx_reg_out(ireg)),...
            'timeBounds',[st et],...
            'depthBounds',depthBounds,...
            'rangeBounds',rangeBounds,...
            'refRangeBounds',refRangeBounds,...
            'BeamAngularLimit',BeamAngularLimit,...
            'sv_thr',surv_options_obj.SvThr.Value,...
            'denoised',surv_options_obj.Denoised.Value,...
            'motion_correction',surv_options_obj.Motion_correction.Value,...
            'feature_bool',surv_options_obj.Feature_bool.Value,...
            'load_bar_comp',p.Results.load_bar_comp,...
            'envdata',p.Results.envdata,'cal',p.Results.cal,...
            'block_len',block_len,...
            'keep_all',p.Results.keep_all,....
            'keep_bottom',p.Results.keep_bottom);
    end
    for ireg=1:length(p.Results.regs)
        regs{ireg+length(idx_reg_out)}=p.Results.regs(ireg);
        regCellInt{ireg+length(idx_reg_out)}=trans_obj.integrate_region(p.Results.regs(ireg),...
            'timeBounds',[st et],...
            'depthBounds',depthBounds,...
            'rangeBounds',rangeBounds,...
            'BeamAngularLimit',BeamAngularLimit,...
            'refRangeBounds',refRangeBounds,...
            'sv_thr',surv_options_obj.SvThr.Value,...
            'denoised',surv_options_obj.Denoised.Value,....
            'motion_correction',surv_options_obj.Motion_correction.Value,.....
            'envdata',p.Results.envdata,'cal',p.Results.cal,...
            'feature_bool',surv_options_obj.Feature_bool.Value,...
            'load_bar_comp',p.Results.load_bar_comp,....
            'block_len',block_len,...
            'keep_all',p.Results.keep_all,....
            'keep_bottom',p.Results.keep_bottom);
    end
else
    regs=[];
    regCellInt={};
end

idx_sh=find(strcmpi(output_type,'Shadow'));
idx_filled=find(~cellfun(@isempty,output_2D),1);
shadow_height_est =[];

if ~isempty(idx_filled)
        shadow_height_est=zeros(1,size(output_2D{idx_filled}.Ping_E,2));
end

if(~isempty(idx_reg_out)||~isempty(p.Results.regs))&&surv_options_obj.Shadow_zone.Value&&surv_options_obj.Shadow_zone_height.Value>0
    [output_2D{idx_sh},~,shadow_height_est_temp]=trans_obj.estimate_shadow_zone(...
        'Shadow_zone_height',surv_options_obj.Shadow_zone_height.Value,...
        'StartTime',st,...
        'EndTime',et,...
        'Vertical_slice_size',Vertical_slice_size,'Slice_units',Vertical_slice_units,...
        'Denoised',surv_options_obj.Denoised.Value,...
        'Motion_correction',surv_options_obj.Motion_correction.Value,...
        'idx_regs',idx_reg_out,...
        'sv_thr',surv_options_obj.SvThr.Value,...
        'regs',p.Results.regs);
    
    if ~isempty(output_2D{idx_sh})
        shadow_height_est=zeros(1,size(output_2D{idx_sh}.eint,2));   
        for k=1:length(shadow_height_est)
            if ~isnan(output_2D{idx_sh}.Ping_S(k))
                shadow_height_est(k)=mean(shadow_height_est_temp(output_2D{idx_sh}.Ping_S(k):output_2D{idx_sh}.Ping_E(k)),'omitnan');
            end
        end
    end
end

idx_rem=cellfun(@isempty,output_2D);
output_2D(idx_rem)=[];
output_type(idx_rem)=[];

end