function replace_sub_data_v2(data_obj,data_mat,field,varargin)

if isempty(data_mat)
    return;
end

[fields_tot,scale_fields,fmt_fields,factor_fields,default_values]=init_fields();

idx_field=strcmpi(fields_tot,field);

if ~any(idx_field)&&contains(lower(field),'khz')
    idx_field=contains(fields_tot,'khz');
end
p = inputParser;


addRequired(p,'data_obj',@(x) isa(x,'ac_data_cl'));
addRequired(p,'data_mat',@isnumeric);
addRequired(p,'field',@ischar);
addParameter(p,'idx_r',[],@isnumeric);
addParameter(p,'idx_beam',[],@isnumeric);
addParameter(p,'idx_ping',[],@isnumeric);
addParameter(p,'DefaultValue',default_values(idx_field),@isnumeric);
addParameter(p,'Scale',scale_fields{idx_field},@ischar);
addParameter(p,'Fmt',fmt_fields{idx_field},@ischar);
addParameter(p,'ConvFactor',factor_fields(idx_field),@isnumeric);

parse(p,data_obj,data_mat,field,varargin{:});

idx_r = p.Results.idx_r;
idx_beam = p.Results.idx_beam;
idx_ping = p.Results.idx_ping;


[idx,found]=data_obj.find_field_idx(field);

if found==0
    data_obj.init_sub_data(field,'Scale',p.Results.Scale,'Fmt',p.Results.Fmt,'ConvFactor',p.Results.ConvFactor,'DefaultValue',p.Results.DefaultValue);
    [idx,~]=find_field_idx(data_obj,field);
end

if isempty(data_mat)
    return;
end

nb_pings=data_obj.get_nb_pings_per_block();
nb_beams=data_obj.Nb_beams;
nb_samples=data_obj.Nb_samples;

ismb = max(data_obj.Nb_beams)>1;

if numel(data_mat)>1
      
    [data_mat_cell,idx_r_cell,idx_beam_cell,idx_ping_cell]=divide_mat_v2(data_mat,nb_samples,nb_beams,nb_pings,idx_r,idx_beam,idx_ping,ismb);
    
    for ii=1:length(data_mat_cell)
%         data_mat_cell{ii}(isnan(data_mat_cell{ii})) = default_value;
        
        if ~isempty(idx_ping_cell{ii}) && ~isempty(idx_r_cell{ii}) && ~isempty(idx_beam_cell{ii})
            nb_samples_data=size(data_obj.SubData(idx).Memap{ii}.Data.(lower(deblank(field))),1);
            nb_samples_data_cell=size(data_mat_cell{ii},1);
            
            idx_r=idx_r_cell{ii};
            idx_r(idx_r_cell{ii}>nb_samples_data)=[];
            idx_r((idx_r-idx_r(1)+1)>nb_samples_data_cell)=[];
            idx_r_data=idx_r-idx_r(1)+1;
            
            if ~ismb
                data_obj.SubData(idx).Memap{ii}.Data.(lower(deblank(field)))(idx_r,idx_ping_cell{ii})=data_mat_cell{ii}(idx_r_data,:)/data_obj.SubData(idx).ConvFactor;
            else         
                nb_beams_data=size(data_obj.SubData(idx).Memap{ii}.Data.(lower(deblank(field))),3);
                nb_beams_data_cell=size(data_mat_cell{ii},3);
                
                idx_beam=idx_beam_cell{ii};
                idx_beam(idx_beam_cell{ii}>nb_beams_data)=[];
                idx_beam((idx_beam-idx_beam(1)+1)>nb_beams_data_cell)=[];
                idx_beam_data=idx_beam-idx_beam(1)+1;
                
                data_obj.SubData(idx).Memap{ii}.Data.(lower(deblank(field)))(idx_r,idx_ping_cell{ii}(1:size(data_mat_cell{ii},2)),idx_beam)=data_mat_cell{ii}(idx_r_data,:,idx_beam_data)/data_obj.SubData(idx).ConvFactor;
                
            end
        end
        data_mat_cell{ii}=[];
    end
else
    for ii=1:length(nb_samples)
        data_obj.SubData(idx).Memap{ii}.Data.(lower(deblank(field)))(:)=data_mat/data_obj.SubData(idx).ConvFactor;
    end 
end
end
