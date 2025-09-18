function plot_ping_sv_spectrum_callback(~,~,main_figure)

layer_obj=get_current_layer();
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~]=layer_obj.get_trans(curr_disp);
trans=trans_obj;

ax_main=axes_panel_comp.echo_obj.main_ax;

x_lim=double(get(ax_main,'xlim'));

cp = ax_main.CurrentPoint;
x=cp(1,1);

x=max(x,x_lim(1));
x=min(x,x_lim(2));


xdata=trans.get_transceiver_pings();

[~,idx_ping]=min(abs(xdata-x));
[~,idx_sort]=sort(layer_obj.Frequencies);

[cal_fm_cell,~]=layer_obj.get_fm_cal([]);

for uui=idx_sort
    if strcmp(layer_obj.Transceivers(uui).Mode,'FM')
        
        cal = cal_fm_cell{uui};
        
        range=layer_obj.Transceivers(uui).get_samples_range();

        [~,~]=layer_obj.Transceivers(uui).get_pulse_length(idx_ping);
        [Sv_f,f_vec,r_disp]=layer_obj.Transceivers(uui).processSv_f_r_2(layer_obj.EnvData,idx_ping,range,2,cal,'3D',0);

       cmap_struct = init_cmap(curr_disp.Cmap,curr_disp.ReverseCmap);
       df=abs(mean(diff(f_vec))/1e3);
        fig=new_echo_figure(main_figure,'Tag',sprintf('sv_ping %.0f%.0f kHz',df,layer_obj.Frequencies(uui)/1e3),'Toolbar','esp3','MenuBar','esp3');
        ax=axes(fig);
        echo=image(ax,f_vec/1e3,r_disp,Sv_f,'CDataMapping','scaled');
        set(echo,'AlphaData',Sv_f>-80);
        xlabel('Frequency (kHz)');
        ylabel('Range(m)');
        clim(curr_disp.getCaxField('sv')); colormap(cmap_struct.cmap);
        title(sprintf('Sv(f) for %.0f kHz, Ping %i, Frequency resolution %.1fkHz',layer_obj.Frequencies(uui)/1e3,idx_ping,df));
         
        cb=colorbar(ax,'PickableParts','none');
        cb.UIContextMenu=[];
        set(ax,'YColor',cmap_struct.col_lab);
        set(ax,'XColor',cmap_struct.col_lab);
        set(ax,'Color',cmap_struct.col_ax,'GridColor',cmap_struct.col_grid);

        clear Sp_f Compensation_f  f_vec
        
       
    else
        fprintf('%s not in  FM mode\n',layer_obj.Transceivers(uui).Config.ChannelID);

    end
end