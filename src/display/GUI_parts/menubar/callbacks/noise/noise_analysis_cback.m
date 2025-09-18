function noise_analysis_cback(src,evt)

main_figure  = get_esp3_prop('main_figure');
layer_obj = get_current_layer();
load_bar_comp=getappdata(main_figure,'Loading_bar');

ss = layer_obj.Transceivers.get_CID_freq_str();
nb_trans = numel(layer_obj.Transceivers);
output = cell(1,nb_trans);

show_status_bar(main_figure);                 

for itrans = 1:nb_trans
    trans_obj = layer_obj.Transceivers(itrans);
    output{itrans} = trans_obj.apply_algo_trans_obj('Denoise','load_bar_comp',load_bar_comp);
end
hide_status_bar(main_figure);  

noise_fig =  new_echo_figure(main_figure,...
    'Name','Noise estimation',...
    'tag','noise_fig',...
    'Position',[0 0 1200 600],...
    'UiFigureBool',true);

uigl_ax = uigridlayout(noise_fig,[3 1]);
noise_axes=uiaxes(uigl_ax,'Box','on','Nextplot','add');
grid(noise_axes,'on');
ylabel(noise_axes,'Noise level (dB)')
noise_axes.XTickLabels={''};


ax_speed=uiaxes(uigl_ax,'Box','on','Nextplot','add');
grid(ax_speed,'on');
ylabel(ax_speed,'Vessel speed (knots)');


ax_heading=uiaxes(uigl_ax,'Box','on','Nextplot','add');
grid(ax_heading,'on');
ylabel(ax_heading,'Heading (degrees)');


ax_att  =uiaxes(uigl_ax,'Box','on','Nextplot','add');
yyaxis(ax_att,'left');
ax_att.YAxis(1).Color = 'r';
ylabel(ax_att,'Heave (m)');
yyaxis(ax_att,'right');
ax_att.YAxis(2).Color = 'k';
ax_att.YAxis(2).TickLabelFormat  = '%g^\\circ';
xlabel(ax_att,'Ping number');
grid(ax_att,'on');

noise_lim = [nan nan];
pause(0.1);
for itrans = 1:nb_trans
    plot(noise_axes,output{itrans}.noise_avg);  
    noise_lim = [min(noise_lim(1),min(output{itrans}.noise_avg-10,[],'omitnan'),'omitnan') max(noise_lim(2),max(output{itrans}.noise_avg+10,[],'omitnan'),'omitnan')];
    if itrans == 1
        plot(ax_speed,trans_obj.GPSDataPing.Speed,'r');
        plot(ax_heading,trans_obj.AttitudeNavPing.Heading,'b');
        yyaxis(ax_att,'left');
        a_h = plot(ax_att,trans_obj.AttitudeNavPing.Heave,'r');
        yyaxis(ax_att,'right');
        a_p = plot(ax_att,trans_obj.AttitudeNavPing.Pitch,'k');
        a_r = plot(ax_att,trans_obj.AttitudeNavPing.Roll,'color',[0 0.5 0]);
        legend([a_h a_p a_r],{'Heave','Pitch','Roll'},'Location','northeast');
    end
end
pause(0.1);
legend(noise_axes,ss);
ylim(noise_axes,noise_lim);