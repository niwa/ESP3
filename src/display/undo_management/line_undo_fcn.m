function line_undo_fcn(main_figure,~,line)
if ~isdeployed()
    disp_perso(main_figure,'Undo Line')
end

curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();

l_id = cell(1,length(layer.Lines));
for iid=1:length(layer.Lines)
    l_id{iid} = layer.Lines(iid).ID;
end
idx_l = find(cellfun(@(x) any(strcmpi(x,{line.ID})),l_id(:)));
layer.Lines(idx_l) = line;

display_lines();
end





