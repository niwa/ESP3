function  choose_field(obj,~,~)
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();
if isempty(layer)
    return;
end
trans_obj=layer.get_trans(curr_disp);
field=trans_obj.Data.Fieldname;

curr_disp.setField(field{min(get(obj,'value'),numel(field))});

end