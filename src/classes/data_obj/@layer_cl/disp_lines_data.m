function fig_line_data = disp_lines_data(lay_obj,curr_disp)
nb_l = numel(lay_obj.Lines);
out_struct.data = cell(1,nb_l);
out_struct.units = cell(1,nb_l);
out_struct.tt = cell(1,nb_l);
out_struct.time = cell(1,nb_l);
out_struct.dist = cell(1,nb_l);
out_struct.id_line = zeros(1,nb_l);

idx_rem = [];
trans_obj = lay_obj.get_trans(curr_disp);
for ui = 1:nb_l
    if ~isempty(lay_obj.Lines(ui).Data)
        [time_corr,dist_corr,~,data_corr] = lay_obj.Lines(ui).get_time_dist_and_range_corr(trans_obj.GPSDataPing.Time,trans_obj.GPSDataPing.Dist);
        out_struct.data{ui} = data_corr;
        out_struct.units{ui} = lay_obj.Lines(ui).Units;
        out_struct.time{ui} = time_corr;
        out_struct.dist{ui} = dist_corr;
        out_struct.id_line(ui) = ui;
        out_struct.tt{ui} = lay_obj.Lines(ui).Tag;

    else
        idx_rem = union(idx_rem,ui);
    end
end

ff = fieldnames(out_struct);
for uif  =1:numel(ff)
    out_struct.(ff{uif})(idx_rem) = [];
end

fig_line_data = [];

if isempty(out_struct.data)
    return;
end

nb_plot = numel(out_struct.data);

fig_line_data = new_echo_figure(get_esp3_prop('main_figure'),'Units','Pixels',...
    'Name','Lines_data','Tag','lines_data','WhichScreen','other','UiFigureBool',true);
uigl = uigridlayout(fig_line_data,[nb_plot,1]);

for uil = 1:nb_plot
     ax(uil) = uiaxes(uigl,'YGrid','on','XGrid','on','box','on');
     %ll = lay_obj.Lines(out_struct.id_line(uil));
     plot(ax(uil),datetime(out_struct.time{uil},'convertfrom','datenum'),out_struct.data{uil});
     ylabel(ax(uil),out_struct.units{uil});
     if uil < nb_plot
         ax(uil).XAxis.TickLabels = {};
     end
     legend(ax(uil),out_struct.tt{uil});
end
drawnow;
linkaxes(ax,'x');
