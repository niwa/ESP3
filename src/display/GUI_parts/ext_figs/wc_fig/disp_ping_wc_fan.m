function disp_ping_wc_fan(wc_fan,trans_obj,varargin)

p = inputParser;
addRequired(p,'wc_fan',@isstruct);
addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addParameter(p,'mask',[]);
addParameter(p,'curr_disp',[]);
addParameter(p,'tt','');
addParameter(p,'idx_ping',1,@(x) x>0);
addParameter(p,'idx_beam',[]);
addParameter(p,'idx_r',[]);
addParameter(p,'fandir','across',@(x) ismember(x,{'along' 'across'}));


parse(p,wc_fan,trans_obj,varargin{:});

mask =  p.Results.mask;
curr_disp = p.Results.curr_disp;
idx_ping = p.Results.idx_ping;
tt = p.Results.tt;

if isempty(curr_disp)
    curr_disp  = curr_state_disp_cl();
end

if ~trans_obj.ismb
    return;
end

cax = curr_disp.Cax;

if ~isempty(idx_ping)

    nb_beams = max(trans_obj.Data.Nb_beams);
    
    nb_samples = max(trans_obj.Data.Nb_samples);

    if isempty(p.Results.idx_r)
        idx_r = 1:nb_samples;
    else
        idx_r = p.Results.idx_r;
    end

    if isempty(p.Results.idx_beam)
        idx_beams = 1:nb_beams;
    else
        idx_beams = p.Results.idx_beam;
    end

    db = ceil(nb_beams/200);
    dr = ceil(numel(idx_r)/1e3);

    idx_r = idx_r(1:dr:end);
    idx_beams = idx_beams(1:db:end);
    idx_beams_red = trans_obj.get_idx_beams(curr_disp.BeamAngularLimit);

    [~,id_beam_start] = min(abs(idx_beams-idx_beams_red(1)));
    [~,id_beam_end] = min(abs(idx_beams-idx_beams_red(end)));

    [amp,sc,~] = trans_obj.Data.get_subdatamat('field',curr_disp.Fieldname,'idx_ping',idx_ping,'idx_beam',idx_beams,'idx_r',idx_r);
    if isempty(amp)
        [amp,sc,~] = trans_obj.Data.get_subdatamat('field','sv','idx_ping',idx_ping,'idx_beam',idx_beams,'idx_r',idx_r);
    end
    switch sc
        case 'lin'
            amp=10*log10(abs(amp));
        case 'db'
            %amp=amp;
        otherwise
            %amp=amp;
    end

    [roll_comp_bool,pitch_comp_bool,yaw_comp_bool,heave_comp_bool] = trans_obj.get_att_comp_bool();
    

    [data_struct,~]= trans_obj.get_xxx_ENH('data_to_pos',{'WC','bottom'},...
        'idx_r',idx_r,'idx_ping',idx_ping,'idx_beam',idx_beams,...
        'comp_angle',[false false],...
        'yaw_comp',yaw_comp_bool,...
        'roll_comp',roll_comp_bool,...
        'pitch_comp',pitch_comp_bool,...
        'heave_comp',heave_comp_bool,...
        'no_nav',true);

    if isempty(amp)
        return;
    end

    amp  =squeeze(amp);

    if size(mask,3) > 1
        mask = squeeze(mask);
    end
    idx_keep_cax = amp>=cax(1);

    if isempty(mask)
        idx_keep = amp>=cax(1);
    else
        idx_keep = amp>=cax(1) & mask(1:dr:end,1:db:end);
    end

    wc_fan.wc_axes.UserData.current_ping = idx_ping;
    wc_fan.wc_axes.UserData.CID = trans_obj.Config.ChannelID;

    switch wc_fan.wc_axes.UserData.geometry

        case 'fan'
            botUpDist = squeeze(data_struct.bottom.H);
            sampleUpDist = squeeze(data_struct.WC.H);
            
            switch p.Results.fandir
                case 'across'
                    sampleDist = squeeze(data_struct.WC.AcrossDist);
                    botDist = squeeze(data_struct.bottom.AcrossDist);
                    beam_lim_x = [data_struct.WC.AcrossDist(:,:,id_beam_start) data_struct.WC.AcrossDist(:,:,id_beam_end)];
                case 'along'
                    sampleDist = squeeze(data_struct.WC.AlongDist);
                    botDist = squeeze(data_struct.bottom.AlongDist);
                    beam_lim_x = [data_struct.WC.AlongDist(:,:,id_beam_start) data_struct.WC.AlongDist(:,:,id_beam_end)];
            end

        case 'rangebeam'
            botUpDist = squeeze(data_struct.bottom.Range);
            sampleUpDist = squeeze(data_struct.WC.Range);
            sampleDist = (1:numel(squeeze(data_struct.bottom.AlongDist))).*ones(size(sampleUpDist,1),1);
            botDist = (1:numel(squeeze(data_struct.bottom.AlongDist)));
            beam_lim_x =  [id_beam_start*ones(size(sampleUpDist,1),1) id_beam_end*ones(size(sampleUpDist,1),1)];

        case 'rangefreq'
            f_ori = squeeze(trans_obj.get_params_value('Frequency',idx_ping,idx_beams))';
            [freqs,idx_freq] = sort(f_ori);
            botUpDist = squeeze(data_struct.bottom.Range);
            botUpDist = botUpDist(idx_freq);
            sampleUpDist = squeeze(data_struct.WC.Range);
            sampleUpDist = sampleUpDist(:,idx_freq);
            sampleDist = (freqs/1e3).*ones(size(sampleUpDist,1),1);
            sampleDist = sampleDist(:,idx_freq);
            botDist = squeeze(data_struct.bottom.AlongDist);
            botDist  = botDist(idx_freq);
            beam_lim_x = [f_ori(id_beam_start)*ones(size(sampleUpDist,1),1) f_ori(id_beam_end)*ones(size(sampleUpDist,1),1)];
    end

    beam_lim_y = [sampleUpDist(:,id_beam_start) sampleUpDist(:,id_beam_end)];

    set(wc_fan.bot_gh,...
        'XData',botDist,...
        'YData',botUpDist);
    alpha_map = ones(size(idx_keep),'single')*numel(wc_fan.wc_fan_fig.Alphamap);
    
    alpha_map(botUpDist' <= sampleUpDist) = 2;
    
    if ~isempty(trans_obj.Features) && strcmpi(curr_disp.DispFeatures,'on')
        mask_ft = trans_obj.get_feature_mask('idx_ping',idx_ping,'idx_r',idx_r,'idx_beam',idx_beams);  
        alpha_map(~squeeze(mask_ft) & (alpha_map == numel(wc_fan.wc_fan_fig.Alphamap))) = 6;
    end
    alpha_map(~idx_keep) = 1;

    set(wc_fan.beam_limit_plot_h(1),...
        'XData',beam_lim_x(:,1),...
        'YData',beam_lim_y(:,1));

    set(wc_fan.beam_limit_plot_h(2),...
        'XData',beam_lim_x(:,2),...
        'YData',beam_lim_y(:,2));

    % display WC data itself
    set(wc_fan.wc_gh,...
        'XData',sampleDist,...
        'YData',sampleUpDist,...
        'ZData',zeros(size(amp),'int8'),...
        'CData',amp,...
        'AlphaData',alpha_map);

    idx_keep_yl = squeeze(data_struct.WC.Range >= curr_disp.R_disp(1) & data_struct.WC.Range <= curr_disp.R_disp(2));

    if ~any(idx_keep_cax,'all')
        idx_keep_yl  = true(size(amp));
    end

    switch curr_disp.Fieldname
        case {'feature_id' 'feature_sv'}
            yl = [min(sampleUpDist,[],"all",'omitnan') min(max(sampleUpDist,[],"all",'omitnan'),max(botUpDist))];
        otherwise
            yl = [min(sampleUpDist(idx_keep_yl),[],"all",'omitnan') max(sampleUpDist(idx_keep_yl),[],"all",'omitnan')];
    end
    
    % yl = [min(sampleUpDist(amp>defval & ~isnan(amp)),[],"all",'omitnan') max(max(sampleUpDist(amp>defval & ~isnan(amp)),[],"all",'omitnan'),max(botUpDist))];
    % yl(1) = max(yl(1),curr_disp.R_disp(1),'omitnan');
    % yl(2) = min(yl(2),curr_disp.R_disp(2),'omitnan');

    idx_keep_up = sampleUpDist>=yl(1) & sampleUpDist<=yl(2);
    xl = [min(sampleDist(idx_keep_up)) max(sampleDist(idx_keep_up))];

    switch wc_fan.wc_axes.UserData.geometry

        case 'fan'
            if yl(2)>10
                wc_fan.wc_axes.XAxis.TickLabelFormat='%.0fm';
                wc_fan.wc_axes.YAxis.TickLabelFormat='%.0fm';
            elseif yl(2)<=1
                wc_fan.wc_axes.XAxis.TickLabelFormat='%.2fm';
                wc_fan.wc_axes.YAxis.TickLabelFormat='%.2fm';
            else
                wc_fan.wc_axes.XAxis.TickLabelFormat='%.1fm';
                wc_fan.wc_axes.YAxis.TickLabelFormat='%.1fm';
            end
        case 'rangebeam'
            wc_fan.wc_axes.XAxis.TickLabelFormat='%.0f';
        case 'rangefreq'
            wc_fan.wc_axes.XAxis.TickLabelFormat='%.0f kHz';
    end

    if diff(yl)>0
        set(wc_fan.wc_axes,...
            'YLim',yl);
    end
    
    if diff(xl)>0
        set(wc_fan.wc_axes,...
            'XLim',xl);

    end
    set(wc_fan.wc_axes,...
        'CLim',curr_disp.Cax,...
        'Layer','top','Visible','on');
    if isempty(tt)
        tt = sprintf('Ping: %.0f/%.0f. Time: %s.',idx_ping,numel(trans_obj.Time),datestr(trans_obj.get_transceiver_time(idx_ping),'HH:MM:SS'));
    end
    wc_fan.wc_axes_tt.String = tt;


else
    amp = wc_fan.wc_gh.CData;

    if isempty(mask)
        idx_keep = amp>=cax(1);
    else
        idx_keep = amp>=cax(1) & mask;
    end
    % display WC data itself


    set(wc_fan.wc_gh,...
        'AlphaData',idx_keep);

    wc_fan.wc_axes.CLim = curr_disp.Cax;
end
