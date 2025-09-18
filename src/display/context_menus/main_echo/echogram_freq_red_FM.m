function echogram_freq_red_FM(~,~,main_figure)

curr_disp=get_esp3_prop('curr_disp');
layer = get_current_layer;
[trans_obj,idx_chan] = layer.get_trans(curr_disp);

switch trans_obj.Mode
    case 'CW'
        dlg_perso(main_figure,'Warning','Current transducer is already in CW mode')
    case 'FM'
        size_max = get(groot, 'MonitorPositions');
        fig_input = new_echo_figure(main_figure);
        fig_input.Position(3) = size_max(1,3)/4;
        fig_input.Position(4) = size_max(1,4)/4;
        uicontrol(fig_input,'style','text','string','Enter the minimum frequency:','Position',[10 fig_input.Position(2)/2+50 250 20],'BackgroundColor','w');
        uicontrol(fig_input,'style','text','string','Enter the maximum frequency:','Position',[10 fig_input.Position(2)/2-10 250 20],'BackgroundColor','w');
        edit1 = uicontrol(fig_input,'style','edit','string',num2str(trans_obj.Params.FrequencyStart),'Position',[10+250 fig_input.Position(2)/2+50 80 20],'BackgroundColor','w');
        edit2 = uicontrol(fig_input,'style','edit','string',num2str(trans_obj.Params.FrequencyEnd),'Position',[10+250 fig_input.Position(2)/2-10 80 20],'BackgroundColor','w');
        
        button = uicontrol(fig_input,'style','push','string','Get Echogram','Position',[fig_input.Position(1)/2+10 fig_input.Position(2)/3-30 90 20],'BackgroundColor','r','Callback',@echogram_freq_red);

end

function echogram_freq_red(~,~)
    oldfs = trans_obj.Params.FrequencyStart;
    oldfe = trans_obj.Params.FrequencyEnd;

    if str2double(edit1.String)<oldfs
        edit1.String = num2str(oldfs);
    end
    if str2double(edit2.String)>oldfe
        edit2.String = num2str(oldfe);
    end

    if str2double(edit1.String)>str2double(edit2.String)
        dlg_perso(fig_input,'Warning','There is a problem with the frequency bounds selected, minimun frequency appears to be higher than maximum frequency');
    else
        trans_obj.Params.FrequencyStart = str2double(edit1.String);
        trans_obj.Params.FrequencyEnd = str2double(edit2.String);
    
        xdata=trans_obj.get_transceiver_pings();
        [cal_fm_cell,~]=layer.get_fm_cal([]);
        cal = cal_fm_cell{idx_chan};
        range=trans_obj.get_samples_range();
        
        Sv_f_all_freqc = cell(length(xdata),1);
        
        for iip=1:length(xdata)
            [~,~]=trans_obj.get_pulse_length(iip);
            [Sv_f,~,~]=trans_obj.processSv_f_r_2(layer.EnvData,iip,range,2,cal,'3D',0);
            sv_f_temp = 10.^(Sv_f/10);
            sv_f_temp_all_freq = 10*log10(mean(sv_f_temp,2));
            Sv_f_all_freqc{iip} = sv_f_temp_all_freq;
        end

        s2 = size(Sv_f_all_freqc{1},1);
        Sv_f_select = zeros(length(xdata),s2);
        for i=1:length(xdata)
            Sv_f_select(i,:) = Sv_f_all_freqc{i};
        end
        
        idnan = Sv_f_select<curr_disp.Cax(1);
        Sv_f_select(idnan) = NaN;
        
        fig = new_echo_figure([],'Name',append(num2str(trans_obj.Params.FrequencyStart/1000),'_',num2str(trans_obj.Params.FrequencyEnd/1000),'kHz ',trans_obj.Config.ChannelID));
        fi = imagesc(xdata,range,Sv_f_select(:,:,1)');
        %axis image off
        set(fi, 'AlphaData', ~isnan(Sv_f_select'))
        
        clim(curr_disp.Cax);
        cmap_struct = init_cmap('EK60');
        colormap(cmap_struct.cmap);
        colorbar;
        zoom(gca,'on');

        trans_obj.Params.FrequencyStart = oldfs;
        trans_obj.Params.FrequencyEnd = oldfe;
    end
    close(fig_input)
end
end
