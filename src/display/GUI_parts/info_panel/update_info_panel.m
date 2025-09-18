function update_info_panel(~,~,force_update)
%profile on;

esp3_obj=getappdata(groot,'esp3_obj');

%dpause=1e-2;
%pause(dpause);
if isempty(esp3_obj)
    %pause(dpause);
    return;
end

main_figure=esp3_obj.main_figure;

if isempty(main_figure)||~ishandle(main_figure)
    %pause(dpause);
    return;
end

if ~isdeployed()&& isdebugging
    disp('Update info panel');
    disp(datestr(now,'HH:MM:SS.FFF'));
end

try
    layer=get_current_layer();
    
    echo_tab_panel=getappdata(main_figure,'echo_tab_panel');
    info_panel_comp=getappdata(main_figure,'Info_panel');
    axes_panel_comp=getappdata(main_figure,'Axes_panel');
    
    bool =(isempty(axes_panel_comp)||(~isa(axes_panel_comp.axes_panel,'matlab.ui.Figure') && ~strcmpi(echo_tab_panel.SelectedTab.Tag,'axes_panel')))&&~force_update;
    if  bool ||isempty(layer)||~isvalid(layer)
        %pause(dpause);
        return;
    end
    
    curr_disp=get_esp3_prop('curr_disp'); 

   [~,Type,Units]=init_cax(curr_disp.Fieldname);

    cur_str=sprintf('Cursor mode: %s',curr_disp.CursorMode);
    set(info_panel_comp.cursor_mode,'String',cur_str);
    
    [trans_obj,~]=layer.get_trans(curr_disp);
    

    if isempty(trans_obj)
        %pause(dpause);
        return;
    end
    
     echo_obj = axes_panel_comp.echo_obj;
    
    [x,y,idx_ping,idx_r] = echo_obj.get_main_ax_cp(trans_obj);
    
    if isempty(idx_r)&&force_update
        idx_r = 1;
    end
    
    if isempty(idx_ping)&&force_update
        idx_ping = 1;
    end
    return_bool = isempty(idx_r)||isempty(idx_ping);
    
    Range_trans=trans_obj.get_samples_range();
    
    Bottom=trans_obj.Bottom;
    Time_trans=trans_obj.Time;
    
    Number=trans_obj.get_transceiver_pings();
    Samples=trans_obj.get_transceiver_samples();    
    
    ax_main=echo_obj.main_ax;
    

    if force_update&&return_bool
        idx_ping=1;
        idx_r=1;
    elseif return_bool
        return;
    end
    
    %disp('up');
    x_lim=double(get(ax_main,'xlim'));
    y_lim=double(get(ax_main,'ylim'));
    
    set(echo_obj.hori_ax,'xlim',x_lim);
    set(echo_obj.vert_ax,'ylim',y_lim); 
    
    cdata=single(get(echo_obj.echo_surf,'CData'));
    
    xdata=double(get(echo_obj.echo_surf,'XData'));
    ydata=double(get(echo_obj.echo_surf,'YData'));
       
    [~,~]=size(cdata);
        
    nb_pings=length(Time_trans);
    nb_samples=length(Range_trans);
    
        
    if (x>x_lim(2)||x<x_lim(1)|| y>y_lim(2)||y<y_lim(1))&&force_update==0||numel(xdata)<2||numel(ydata)<2
        return;
    end
    
    cax=curr_disp.Cax;
    
    idx_ping=min(nb_pings,idx_ping);
    idx_ping=max(1,idx_ping);
    
    idx_r=min(nb_samples,idx_r);
    idx_r=max(1,idx_r);
    
    if ~isempty(cdata)
 
        [~,idx_ping_red]=min(abs(xdata-x));                
        [~,idx_r_red]=min(abs(ydata-y));

        if idx_ping<=length(Bottom.Sample_idx)
            if ~isnan(Bottom.Sample_idx(idx_ping))
                bot_val=Bottom.Sample_idx(idx_ping);
            else
                bot_val=nan;
            end
        else
            bot_val=nan;
        end
        
        bot_x_val=cax(:)'+[-3 3];
        bot_y_val=cax(:)'+[-3 3];
        
        if return_bool
            %pause(dpause);
            return;
        end
        
        switch echo_obj.echo_usrdata.geometry_y
            case 'samples'
                dx = 1/2;
            otherwise
                dx = 0;
        end
        
        switch curr_disp.CursorMode
            case {'Edit Bottom' 'Bad Pings'}
                switch curr_disp.Fieldname
                    case {'sv','sp','sp_comp','spdenoised','svdenoised','spunmatched','svunmatched','powerunmatched','powerdenoised','power'}
                        
                        sub_bot=echo_obj.bottom_line_plot.YData;
                        x_horz_val=echo_obj.echo_surf.XData(1,:);  
                        
                        sub_tag=sum(echo_obj.echo_bt_surf.AlphaData,1)>=1;

                        sub_bot = resample_data_v2(sub_bot,x_horz_val,xdata);
                        sub_tag = resample_data_v2(single(sub_tag),x_horz_val,xdata,'Opt','previous');
                          
                        cdata_above_bottom = nan(size(cdata),'single');
                        
                        switch echo_obj.echo_usrdata.geometry_y
                            case 'samples'
                                idx_bot = ydata<=sub_bot&ydata>=sub_bot-10*mean(diff(ydata));
                            otherwise
                                idx_bot = ydata<=sub_bot&ydata>=sub_bot-2;                       
                        end 
                        
                        cdata_above_bottom(idx_bot) = cdata(idx_bot);
                        
                        horz_val=max(cdata_above_bottom,[],1);
              
                        if isempty(horz_val)
                            horz_val=nan(1,numel(sub_bot));
                        end
                        idx_low=~((horz_val>=prctile(cdata_above_bottom,90,'all'))&(horz_val>=(curr_disp.Cax(2)-6)));
                        
                        bot_x_val=[cax(1)-3  cax(2)+3];
                        
                        bot_y_val=[cax(1)-3 max(cax(2),max(horz_val))+10];
                        
                        horz_val(horz_val<cax(1))=cax(1);          
                        idx_low(sub_tag==1) = true;
                        
                    otherwise
                        horz_val=cdata(idx_r_red,:);
                        horz_val(horz_val>cax(2))=cax(2);
                        horz_val(horz_val<cax(1))=cax(1);
                        idx_low=ones(size(horz_val));
                        %idx_high=zeros(size(horz_val));
                end
                
            otherwise
                horz_val=cdata(idx_r_red,:);
                horz_val(horz_val>cax(2))=cax(2);
                horz_val(horz_val<cax(1))=cax(1);
                idx_low=ones(size(horz_val));
                %idx_high=zeros(size(horz_val));
                
        end
        
        
        vert_val=cdata(:,idx_ping_red);
        vert_val(vert_val<=-999)=nan;
        
        vert_val(vert_val>cax(2))=cax(2);
        vert_val(vert_val<cax(1))=cax(1);
        
        
        t_n=Time_trans(idx_ping);
        
        i_str='';
        
        if length(layer.SurveyData)>=1
            for is=1:length(layer.SurveyData)
                surv_temp=layer.get_survey_data('Idx',is);
                if ~isempty(surv_temp)
                    if t_n>=surv_temp.StartTime&&t_n<=surv_temp.EndTime
                        i_str=surv_temp.print_survey_data();
                    end
                end
            end
        end
        idx_beam = trans_obj.get_idx_beams(curr_disp.BeamAngularLimit);

        d = trans_obj.get_samples_depth(idx_r,idx_ping,round(mean(idx_beam)));

        if d~=Range_trans(idx_r)
            xy_string=sprintf('Range: %.2fm Depth: %.2fm\n  Sample: %.0f Ping #:%.0f of  %.0f',Range_trans(idx_r),d,Samples(idx_r),Number(idx_ping),Number(end));
        else
            xy_string=sprintf('Range: %.2fm\n  Sample: %.0f Ping #%.0f of  %.0f',Range_trans(idx_r),Samples(idx_r),Number(idx_ping),Number(end));
        end
            Lat=trans_obj.GPSDataPing.Lat(idx_ping);
            Long=trans_obj.GPSDataPing.Long(idx_ping);
            
        if ~isempty(Lat) && sum(Lat+Long,'omitnan')>0
            [lat_str,lon_str]=print_pos_str(Lat,Long);
            pos_string=sprintf('%s\n%s',lat_str,lon_str);
            pos_weigtht='normal';

            if isdebugging()
                disp('Update info panel: lat/lon');
                disp(datestr(now,'HH:MM:SS.FFF'));
            end
        else
            pos_string=sprintf('No Navigation Data');
            pos_weigtht='Bold';
        end
        time_str=datestr(Time_trans(idx_ping),'yyyy-mm-dd HH:MM:SS.FFF');

        val_str=sprintf('%s: %.2f %s',Type,cdata(idx_r_red,idx_ping_red),Units);
        
        
        iFile=trans_obj.Data.FileId(idx_ping);
        [~,file_curr,ext]=fileparts(layer.Filename{iFile});
        switch trans_obj.Mode
            case 'CW'
                freq_str = sprintf('%.0f kHz',mean(trans_obj.get_params_value('Frequency',idx_ping,idx_beam)/1e3));
            case 'FM'
                freq_str = sprintf('%.0f-%.0f kHz',mean(trans_obj.get_params_value('FrequencyStart',idx_ping,idx_beam)/1e3),mean(trans_obj.get_params_value('FrequencyEnd',idx_ping,idx_beam)/1e3));
        end
        summary_str=sprintf('%s%s \nMode: %s Freq: %s\nPower: %.0f W Pulse: %.3f ms Av. Ping rate: %.1f Hz',file_curr,ext,...
            trans_obj.Mode,freq_str,...
            mean(trans_obj.get_params_value('TransmitPower',idx_ping,idx_beam)),...
            mean(trans_obj.get_params_value('PulseLength',idx_ping,idx_beam)*1e3),...
            1./mode(diff(trans_obj.Time*24*60*60)));
        
        
        set(info_panel_comp.i_str,'String',i_str);
        set(info_panel_comp.summary,'string',summary_str);
        set(info_panel_comp.xy_disp,'string',xy_string);
        set(info_panel_comp.pos_disp,'string',pos_string,'Fontweight',pos_weigtht);
        set(info_panel_comp.time_disp,'string',time_str);
        set(info_panel_comp.value,'string',val_str);
        
        axh=echo_obj.hori_ax;
        axh_plot_high=echo_obj.h_plot_high;
        axh_plot_low=echo_obj.h_plot_low;
        
        axv=echo_obj.vert_ax;
        axv_plot=echo_obj.v_plot;
        axv_bot=echo_obj.v_bot_val;
        axv_curr=echo_obj.v_curr_val;
        
        set(axv_plot,'XData',vert_val,'YData',ydata);
        
        if bot_x_val(2)>bot_x_val(1)
            set(axv,'xlim',bot_x_val);
        end
        
        if bot_y_val(2)>bot_y_val(1)
            set(axh,'ylim',bot_y_val);
        end
        
        depth=trans_obj.get_bottom_range(idx_ping);
        if ~isnan(depth)
            str=sprintf('%.2fm',depth(:,:,round(mean(idx_beam))));
        else
            str='';
        end
        
        set(axv_curr,'value',idx_r,'Label',sprintf('%.2fm',Range_trans(idx_r)));

        
        if ~isnan(bot_val)
            set(axv_bot,'value',bot_val,'Label',str);
        end
        
        horz_val_high=horz_val;
        horz_val_high(idx_low>0)=nan;
        
        set(axh_plot_low,'XData',xdata+dx,'YData',horz_val);
        set(axh_plot_high,'XData',xdata+dx,'YData',horz_val_high);
        
        set(axes_panel_comp.echo_obj.h_curr_val,'Value',xdata(idx_ping_red)+dx);
        
        display_ping_impedance_cback([],[],main_figure,idx_ping,0);
        
        %listen_ping_cback(idx_ping);
        
        update_boat_position(main_figure,idx_ping,0);
        update_wc_fig(layer,idx_ping);
        update_xline_speed_att_fig(main_figure,x);

        echo_3D_obj = get_esp3_prop('echo_3D_obj');

        if ~isempty(echo_3D_obj)
            cax=curr_disp.getCaxField('sv');
            echo_3D_obj.add_wc_fan(trans_obj,'idx_ping',idx_ping,'idx_beam',[],'cax',cax);
        end
        
%         if ~isempty(esp3_obj.w_h) && isvalid(esp3_obj.w_h.waitbar_fig)
%             esp3_obj.w_h.update_waitbar([]);
%         end
        
    end
    
catch err
    if ~isdeployed
        print_errors_and_warnings(1,'error',err)
        disp('Could not update info panel');
    end
end

end