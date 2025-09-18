%% Create Region button callback
function create_unsclassif_callback(~,~,reg_fig_comp,~,~)

layer = get_current_layer();

curr_disp=get_esp3_prop('curr_disp');

[trans_obj,~]=layer.get_trans(curr_disp);
if isempty(trans_obj)
    return;
end

ref = get(reg_fig_comp.tog_ref,'String');
ref_idx = get(reg_fig_comp.tog_ref,'value');

data_type = get(reg_fig_comp.data_type,'String');
data_type_idx = get(reg_fig_comp.data_type,'value');

h_units = get(reg_fig_comp.cell_h_unit,'String');
h_units_idx = get(reg_fig_comp.cell_h_unit,'value');

w_units = get(reg_fig_comp.cell_w_unit,'String');
w_units_idx = get(reg_fig_comp.cell_w_unit,'value');

y_min = str2double(get(reg_fig_comp.y_min,'string'));
y_max = str2double(get(reg_fig_comp.y_max,'string'));

freqs = (get(reg_fig_comp.freqs,'string'));
nclusters = str2double(get(reg_fig_comp.tog_clus,'string'));

disp(nclusters)

end