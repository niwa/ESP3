function plot_ping_spectrum_callback(~,~,main_figure)

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
win_fact = 1;
update_algos('algo_name',{'SingleTarget'});
for uui=idx_sort
    if strcmp(layer_obj.Transceivers(uui).Mode,'FM')
        

        cal=cal_fm_cell{uui};
        
        range=layer_obj.Transceivers(uui).get_samples_range();

        [Sp_f,Compensation_f,f_vec,r_disp,~]=processTS_f_v2(layer_obj.Transceivers(uui),layer_obj.EnvData,idx_ping,range,win_fact,cal,[true true]);
        
        Compensation_f(Sp_f<-200)=0;
        Sp_f(Sp_f<-200)=nan;
        TS_f=Sp_f+Compensation_f;

       cmap_struct = init_cmap(curr_disp.Cmap,curr_disp.ReverseCmap);
       df=abs(min(diff(f_vec))/1e3);
        fig=new_echo_figure(main_figure,'Tag',sprintf('ts_ping %.0f%.0f kHz',df,layer_obj.Frequencies(uui)/1e3),'Toolbar','esp3','MenuBar','esp3');
        ax=axes(fig);
        echo=image(ax,f_vec/1e3,r_disp,TS_f,'CDataMapping','scaled');
        set(echo,'AlphaData',TS_f>-80);
        xlabel('Frequency (kHz)');
        ylabel('Range(m)');
        clim(curr_disp.getCaxField('sp')); colormap(cmap_struct.cmap);
        title(sprintf('TS(f) for %.0f kHz, Ping %i, Frequency resolution %.1fkHz',layer_obj.Frequencies(uui)/1e3,idx_ping,df));
         
        cb=colorbar(ax,'PickableParts','none');
        cb.UIContextMenu=[];
        set(ax,'YColor',cmap_struct.col_lab);
        set(ax,'XColor',cmap_struct.col_lab);
        set(ax,'Color',cmap_struct.col_ax,'GridColor',cmap_struct.col_grid);
        grid(ax,'on');
        clear Sp_f Compensation_f  f_vec
        

    else
        fprintf('%s not in  FM mode\n',layer_obj.Transceivers(uui).Config.ChannelID);
    end
end