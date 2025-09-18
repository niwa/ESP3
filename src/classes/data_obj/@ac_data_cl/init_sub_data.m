function init_sub_data(data_obj,field,varargin)

[fields_tot,scale_fields,fmt_fields,factor_fields,default_values]=init_fields();

idx_field=strcmpi(fields_tot,deblank(field));

if ~any(idx_field)&&contains(lower(field),'khz')
    idx_field=contains(fields_tot,'khz');
end
p = inputParser;
addRequired(p,'data_obj');
addRequired(p,'field');
addParameter(p,'DefaultValue',default_values(idx_field),@isnumeric);
addParameter(p,'Scale',scale_fields{idx_field},@ischar);
addParameter(p,'Fmt',fmt_fields{idx_field},@ischar);
addParameter(p,'ConvFactor',factor_fields(idx_field),@isnumeric);
parse(p,data_obj,field,varargin{:});


data_obj.remove_sub_data(field);
nb_pings=data_obj.get_nb_pings_per_block();
nb_samples=data_obj.Nb_samples;
nb_beams=data_obj.Nb_beams;

data_mat_size=cell(1,numel(nb_pings));

for ifi=1:numel(nb_pings)
    if nb_beams(ifi)>1
        data_mat_size{ifi}=[nb_samples(ifi) nb_pings(ifi) nb_beams(ifi)];
    else
        data_mat_size{ifi}=[nb_samples(ifi) nb_pings(ifi)];
    end
end

new_sub_data=sub_ac_data_cl(field,'memapname',data_obj.MemapName,'data',data_mat_size,...
    'Scale',p.Results.Scale,'Fmt',p.Results.Fmt,'ConvFactor',p.Results.ConvFactor,'DefaultValue',p.Results.DefaultValue);
data_obj.SubData=[data_obj.SubData new_sub_data];
data_obj.Fieldname=[data_obj.Fieldname {new_sub_data.Fieldname}];
data_obj.Type=[data_obj.Type {new_sub_data.Type}];




end