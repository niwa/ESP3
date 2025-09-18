function sub_out=concatenate_SubData(sub_1,sub_2)

if ~strcmp(sub_1.Fieldname,sub_2.Fieldname)
    warning('Concatenating two different subdataset');
end

sub_out=sub_ac_data_cl(sub_1.Fieldname,...
    'Fmt',sub_1.Fmt,...
    'ConvFactor',sub_1.ConvFactor,...
    'Scale',sub_1.Scale,...
    'DefaultValue',sub_1.DefaultValue);

sub_out.Memap=[sub_1.Memap sub_2.Memap];

end