function load_feature_table(~,~)
main_figure = get_esp3_prop('main_figure');
curr_disp = get_esp3_prop('curr_disp');
layer_obj  = get_current_layer();

trans_obj = layer_obj.get_trans(curr_disp);

nb_features = numel(trans_obj.Features);

if nb_features == 0
    return;
end
hfig=new_echo_figure(main_figure,'Tag',sprintf('feature_stat_%s',layer_obj.Unique_ID),'Resize','off','Units','pixels','Position',[200 200 800 400],'UiFigureBool',true);
hfig.Name = 'Feature table';
layout = uigridlayout(hfig);
layout.RowHeight = {'1x'};
layout.ColumnWidth = {'1x'};

columnname = {'Sel.','ID','Mean Sv','Volume','Mean Depth','Total Length','Total Width','Total Height','Number of Samples','Unique ID'};
vtypes = {'logical' 'uint32','double','double','double','double','double','double','uint32','string'};
units = {'' '' 'dB re m^{-1}' 'm^3' 'm' 'm' 'm' 'm' '' ''};
ColumnSortable  = [false false true true true true true true true false];

t = table('Size',[nb_features numel(columnname)],'VariableTypes',vtypes,'VariableNames',columnname);
t.Properties.VariableUnits = units;

for uif = 1:nb_features
    t.("Sel.")(uif) = true;
    t.("ID")(uif) = trans_obj.Features(uif).ID;
    t.("Mean Sv")(uif) = pow2db(mean(db2pow(trans_obj.Features(uif).Sv)));
    t.("Volume")(uif) = trans_obj.Features(uif).Volume;
    t.("Mean Depth")(uif) = mean(trans_obj.Features(uif).H);
    t.("Total Length")(uif) = max(range(trans_obj.Features(uif).E),range(trans_obj.Features(uif).N));
    t.("Total Width")(uif) = min(range(trans_obj.Features(uif).E),range(trans_obj.Features(uif).N));
    t.("Total Height")(uif) = range(trans_obj.Features(uif).H);
    t.("Number of Samples")(uif) = numel(trans_obj.Features(uif).Sv);
    t.("Unique ID")(uif) = trans_obj.Features(uif).Unique_ID;
end

tt = uitable(layout,'Data',t,'ColumnSortable',ColumnSortable);
tt.ColumnEditable = false;


end