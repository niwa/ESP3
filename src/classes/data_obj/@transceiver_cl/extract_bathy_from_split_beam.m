function [bot_data_struct_tot,bot_reg_tot,slope_struct,nb_soundings_per_beam] = extract_bathy_from_split_beam(trans_obj,varargin)

default_val = get_default_bathy_extract_val();
p = inputParser;
addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addParameter(p,'dt_att',0,@isnumeric);
addParameter(p,'full_attitude',attitude_nav_cl.empty(),@(x) isa(x,'attitude_nav_cl'));
addParameter(p,'full_navigation',gps_data_cl.empty(),@(x) isa(x,'gps_data_cl'));
addParameter(p,'idx_beam',[],@isnumeric);
addParameter(p,'idx_r',[],@isnumeric);
addParameter(p,'idx_ping',[],@isnumeric);
addParameter(p,'keep_regs',false,@islogical);
addParameter(p,'clean_bot_bool',default_val.clean_bot_bool,@islogical);
addParameter(p,'win_filt',default_val.win_filt,@isnumeric);
addParameter(p,'echo_len_fact',default_val.echo_len_fact,@isnumeric);
addParameter(p,'default_slope',default_val.default_slope,@isnumeric);
addParameter(p,'estimate_slope_bool',default_val.estimate_slope_bool,@islogical);
addParameter(p,'full_bathy_extract',default_val.full_bathy_extract,@islogical);
addParameter(p,'thr_echo',default_val.thr_echo,@isnumeric);
addParameter(p,'slope_max',default_val.slope_max,@isnumeric);
addParameter(p,'beam_slope_est_to_display',[],@isnumeric);
addParameter(p,'robust_estimation',default_val.robust_estimation,@islogical);
addParameter(p,'rsq_slope_est_thr',default_val.rsq_slope_est_thr,@isnumeric);
addParameter(p,'fitmeth',default_val.fitmeth,@(x) ismember(x,{'poly1','poly11'}));
addParameter(p,'comp_angle',default_val.comp_angle,@(x) islogical(x)||isnumeric(x));
addParameter(p,'load_bar_comp',[]);
addParameter(p,'field',default_val.field,@ischar);
parse(p,trans_obj,varargin{:});


fitmeth = p.Results.fitmeth;
fitType = fittype(fitmeth);
if p.Results.robust_estimation
    opts = fitoptions('Method', 'LinearLeastSquares','Robust','bisquare');
    rsq_thr = 0.9;
    max_ite = 2;
    res_thr = 0.1;
else
    opts = fitoptions('Method', 'LinearLeastSquares');
    rsq_thr = 0.9;
    max_ite = 5;
    res_thr = 0.1;
end

idx_pings = p.Results.idx_ping;
idx_beam = p.Results.idx_beam;

if isempty(idx_beam)
    idx_beam = 1:max(trans_obj.Data.Nb_beams);
end

idx_pings = trans_obj.get_transceiver_pings(idx_pings);

bot_reg_tot = region_cl.empty();
bot_data_struct_tot = [];
r_tot = trans_obj.get_samples_range();

slope_struct.AbsSlope = nan(numel(idx_beam),numel(idx_pings));
slope_struct.AcrossSlope = nan(numel(idx_beam),numel(idx_pings));
slope_struct.AlongSlope = nan(numel(idx_beam),numel(idx_pings));
slope_struct.nb_ite = nan(numel(idx_beam),numel(idx_pings));
slope_struct.RSQSlope = nan(numel(idx_beam),numel(idx_pings));
slope_struct.Idx_ping = nan(numel(idx_beam),numel(idx_pings));
slope_struct.H = nan(numel(idx_beam),numel(idx_pings));
slope_struct.E = nan(numel(idx_beam),numel(idx_pings));
slope_struct.N = nan(numel(idx_beam),numel(idx_pings));
nb_soundings_per_beam = nan(numel(idx_beam),numel(idx_pings));

[faBW,psBW] = trans_obj.get_beamwidth_at_f_c([]);

[Tp,Np] = trans_obj.get_pulse_length(idx_pings);
if ~isempty(p.Results.load_bar_comp)
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(idx_beam), 'Value',0);
end

if ~p.Results.full_bathy_extract

    [data_struct_tmp,~]= ...
        trans_obj.get_xxx_ENH(...
        'comp_angle',p.Results.comp_angle,...
        'idx_ping',idx_pings,'idx_beam',idx_beam,'data_to_pos',{'bottom'},...
        'load_bar_comp',p.Results.load_bar_comp);
    data_struct_tmp = data_struct_tmp.bottom;

    if ~isempty(data_struct_tmp.E(:))
        bot_data_struct_tot.E = data_struct_tmp.E(:)';
        bot_data_struct_tot.N = data_struct_tmp.N(:)';
        bot_data_struct_tot.H =  data_struct_tmp.H(:)';
        bot_data_struct_tot.BS = pow2db(ones(size(data_struct_tmp.H(:)')));
        bot_data_struct_tot.Zone = data_struct_tmp.Zone(:)';
    end
else

    for uib = 1:numel(idx_beam)
    %for uib = 1:3
        id_beam  = idx_beam(uib);

        disp_bool = isdebugging && ismember(id_beam,p.Results.beam_slope_est_to_display);
        disp_bool_clean = isdebugging && ismember(id_beam,p.Results.beam_slope_est_to_display);
        % disp_bool  = true;
        % disp_bool_clean = true;

        if ~isempty(p.Results.load_bar_comp)
            p.Results.load_bar_comp.progress_bar.setText(sprintf('Extracting bottom echo on %s, beam %d',trans_obj.Config.ChannelID,id_beam));
            set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(idx_beam), 'Value',uib);
        end

        t_angle = trans_obj.get_beams_pointing_angles(idx_pings,id_beam,[0 0]);
        bot_idx  = trans_obj.get_bottom_idx(idx_pings,id_beam);
        reg_name = sprintf('BathyReg_%.0fkHz_%d',trans_obj.Config.Frequency(id_beam)/1e3,id_beam);
        trans_obj.rm_region_name(reg_name);

        std_angle_thr_al = faBW(id_beam)/2;
        std_angle_thr_ac = psBW(id_beam)/2;

        echo_len_max = ceil(echo_length(Np(:,:,id_beam),(faBW(id_beam)+psBW(id_beam))/2,(t_angle-90)+sign(t_angle-90)*p.Results.default_slope,bot_idx));
        [maskReg,idx_r_echo] = get_mask_reg_bot(bot_idx,idx_pings,r_tot,echo_len_max,p.Results.echo_len_fact(1),p.Results.echo_len_fact(2));

        if ~any(maskReg,'all')
            return;
        end

        bot_reg = region_cl('Idx_ping',idx_pings,'Idx_r',idx_r_echo,'MaskReg',maskReg,'Ref','transducer','Name',reg_name,'Shape','Polygon','ID',id_beam);

        [bot_data_struct_all_fields,~] = bot_reg.get_region_3D_echoes(trans_obj,...
            'dt_att',p.Results.dt_att,...
            'full_attitude',p.Results.full_attitude,...
            'full_navigation',p.Results.full_navigation,...
            'field',p.Results.field,...
            'comp_angle',p.Results.comp_angle,'idx_beam',id_beam);

        bot_data_struct = bot_data_struct_all_fields.WC;
        bot_data_struct.AcrossSlope = nan(size(bot_data_struct.data_disp));
        bot_data_struct.AlongSlope = nan(size(bot_data_struct.data_disp));
        bot_data_struct.AbsSlope = nan(size(bot_data_struct.data_disp));
        bot_data_struct.RSQSlope = nan(size(bot_data_struct.data_disp));

        bot_data_struct.Compensation(bot_data_struct.Compensation>-p.Results.thr_echo)  = nan;

        bot_data_struct.Nb_soundings = zeros(size(bot_data_struct.data_disp));
        [~,idx_tmp] = min(abs(bot_data_struct.Idx_ping-idx_pings'));
        bot_data_struct = bs_from_data(bot_data_struct,p.Results.field,faBW(id_beam),psBW(id_beam),Tp(:,idx_tmp,id_beam),90-abs(t_angle(idx_tmp)));

        if p.Results.clean_bot_bool
            bot_data_struct = clean_bot_data_struct(bot_data_struct,p.Results.thr_echo,p.Results.win_filt,std_angle_thr_al,std_angle_thr_ac,disp_bool_clean);
        end

        if p.Results.estimate_slope_bool

            data_struct_bot = bot_data_struct_all_fields.bottom;

            if disp_bool
                switch fitmeth
                    case {'poly1' 'poly2'}
                        slay = [3 3];
                        ax_pos_col = {[1 3],1,2,3};
                        ax_pos_row = {1,[2 3],[2 3],[2 3]};
                        tags = {'res' 'fx' 'fy' 'bs'};
                        xlab = {'','Along distance (m)','Across distance (m)', 'Dist from center (m)'};
                        ylab = {'Norm. Residuals','Depth (m)','Depth (m)', 'BS (dB)'};
                        zlab = {'', '', '', ''};
                    case {'poly11' 'poly22'}
                        slay = [3 2];
                        ax_pos_col = {[1 2],1,2};
                        ax_pos_row = {1,[2 3],[2 3]};
                        tags = {'res' 'fxy' 'bs'};
                        xlab = {'','Along distance (m)', 'Dist from center (m)'};
                        ylab = {'Norm. Residuals','Across distance (m)','BS (dB)'};
                        zlab = {'','Depth (m)', ''};
                end
                fig = new_echo_figure([],'UiFigureBool',true,'Name',sprintf('Slope estimation beam %d',id_beam));
                uig  = uigridlayout(fig,slay);

                for iax = 1:numel(ax_pos_col)
                    ax(iax) = uiaxes(uig,'NextPlot','add','Box','on','XGrid','on','YGrid','on','Tag',tags{iax});
                    ax(iax).Layout.Column = ax_pos_col{iax};
                    ax(iax).Layout.Row = ax_pos_row{iax};
                    xlabel(ax(iax),xlab{iax});
                    ylabel(ax(iax),ylab{iax});
                    zlabel(ax(iax),zlab{iax});
                    switch tags{iax} 
                        case {'fxy' 'fx' 'fy'}
                            ax(iax).ZDir = 'reverse';
                    end
                end
            else
                ax = matlab.ui.control.UIAxes.empty;
            end

            slope_struct_tmp = arrayfun(@(x,al_bot,ac_bot) estimate_slope(bot_data_struct.AlongDist,bot_data_struct.AcrossDist,bot_data_struct.H,db2pow(bot_data_struct.BS)...
                ,bot_data_struct.Idx_ping,x,al_bot,ac_bot,fitType,opts,p.Results.thr_echo,p.Results.win_filt,rsq_thr,res_thr,max_ite,ax),idx_pings,data_struct_bot.AlongDist,data_struct_bot.AcrossDist,'UniformOutput',false);

            x = atand([cell2mat(slope_struct_tmp(:)).dx]);
            y = atand([cell2mat(slope_struct_tmp(:)).dy]);
            rsqex = [cell2mat(slope_struct_tmp(:)).rsqex];
            rsqey = [cell2mat(slope_struct_tmp(:)).rsqey];
            x(rsqex>p.Results.rsq_slope_est_thr) = 0;
            y(rsqey>p.Results.rsq_slope_est_thr) = 0;
            abs_slope = acosd(cosd(x).*cosd(y));

            slope_struct.AbsSlope(uib,:) = abs_slope;
            slope_struct.nb_ite(uib,:) = [cell2mat(slope_struct_tmp(:)).nb_ite];
            slope_struct.AcrossSlope(uib,:) = y;
            slope_struct.AlongSlope(uib,:) = x;
            slope_struct.RSQSlope(uib,:) = sqrt((rsqex.^2+rsqey.^2)/2);
            slope_struct.H(uib,:) = data_struct_bot.H;
            slope_struct.E(uib,:) = data_struct_bot.E;
            slope_struct.N(uib,:) = data_struct_bot.N;
            slope_struct.Idx_ping(uib,:) = [cell2mat(slope_struct_tmp(:)).Idx_ping];

            ac_slope_filt = filter2_perso(ones(1,p.Results.win_filt),slope_struct.AcrossSlope(uib,:));
            ac_slope_filt(abs(ac_slope_filt)>p.Results.slope_max) = sign(ac_slope_filt(abs(ac_slope_filt)>p.Results.slope_max))*p.Results.slope_max;

            al_slope_filt = filter2_perso(ones(1,p.Results.win_filt),slope_struct.AlongSlope(uib,:));
            al_slope_filt(abs(al_slope_filt)>p.Results.slope_max) = sign(al_slope_filt(abs(al_slope_filt)>p.Results.slope_max))*p.Results.slope_max;


            % figure();
            %     plot(dist,ac_slope_filt);hold on;...
            %     plot(dist,al_slope_filt);...
            %     plot(dist,slope_filt);
            % legend({'Across slope' 'Along Slope' 'Absolute slope'});

            t_angle = arrayfun(@(ip,ax,ay) trans_obj.get_beams_pointing_angles(ip,id_beam,[ax ay]),idx_pings,al_slope_filt,ac_slope_filt);
            echo_len_max = ceil(echo_length(Np(:,:,id_beam),(faBW(id_beam)+psBW(id_beam))/2,(t_angle-90),bot_idx));

            [maskReg,idx_r_echo] = get_mask_reg_bot(bot_idx,idx_pings,r_tot,echo_len_max,...
                p.Results.echo_len_fact(1),p.Results.echo_len_fact(2));

            if ~any(maskReg,'all')
                return;
            end

            bot_reg = region_cl('Idx_ping',idx_pings,'Idx_r',idx_r_echo,'MaskReg',maskReg,'Ref','transducer','Name',reg_name,'Shape','Polygon','ID',id_beam);

        end

        if ~isempty(bot_reg)
            if p.Results.keep_regs
                trans_obj.add_region(bot_reg);
            end

            if p.Results.estimate_slope_bool
                [bot_data_struct_all_fields,~] = bot_reg.get_region_3D_echoes(trans_obj,...
                    'dt_att',p.Results.dt_att,...
                    'full_attitude',p.Results.full_attitude,...
                    'full_navigation',p.Results.full_navigation,...
                    'field',p.Results.field,'comp_angle',p.Results.comp_angle,'idx_beam',id_beam);
                bot_data_struct = bot_data_struct_all_fields.WC;

                bot_data_struct.Compensation(bot_data_struct.Compensation>-p.Results.thr_echo)  = nan;
                
                [~,idx_tmp] = min(abs(bot_data_struct.Idx_ping-slope_struct.Idx_ping(uib,:)'));
                bot_data_struct.AcrossSlope = slope_struct.AcrossSlope(uib,idx_tmp);
                bot_data_struct.AlongSlope = slope_struct.AlongSlope(uib,idx_tmp);
                bot_data_struct.AbsSlope = slope_struct.AbsSlope(uib,idx_tmp);
                bot_data_struct.RSQSlope = slope_struct.RSQSlope(uib,idx_tmp);
                
                bot_data_struct.Zone = bot_data_struct.Zone;
                bot_data_struct.Nb_soundings = zeros(size(bot_data_struct.data_disp));
                [~,idx_tmp] = min(abs(bot_data_struct.Idx_ping-idx_pings'));
                bot_data_struct = bs_from_data(bot_data_struct,p.Results.field,faBW(id_beam),psBW(id_beam),Tp(:,idx_tmp,id_beam),90-abs(t_angle(idx_tmp)));

                if p.Results.clean_bot_bool
                    bot_data_struct = clean_bot_data_struct(bot_data_struct,p.Results.thr_echo,p.Results.win_filt,std_angle_thr_al,std_angle_thr_ac,disp_bool_clean);
                end
            end

            if isempty(bot_data_struct.BS)
                continue;
            end

            for uip  =1:numel(idx_pings)
                nb_soundings_per_beam(uib,uip) = sum(bot_data_struct.Idx_ping == idx_pings(uip) & bot_data_struct.Idx_beam == idx_beam(uib));
            end

            bot_data_struct_tot = [bot_data_struct_tot bot_data_struct];
            bot_reg_tot = [bot_reg_tot bot_reg];
        end
        if ~isempty(p.Results.load_bar_comp)
            set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(idx_beam), 'Value',uib);
        end
    end
end
end

function bot_data_struct = clean_bot_data_struct(bot_data_struct,thr_echo,win_filt,std_angle_thr_al,std_angle_thr_ac,disp_bool)

idx_pings = unique(bot_data_struct.Idx_ping);
idx_beams = unique(bot_data_struct.Idx_beam);

if disp_bool
    nb_ax = 3;
    bot_data_struct_disp = bot_data_struct;
    bot_data_struct_disp.Time = (bot_data_struct_disp.Time-min(bot_data_struct_disp.Time))*24*60*60;
    uifig = new_echo_figure([],'UiFigureBool',true,'Name',sprintf('Cleaning bathy'));
    uigl  = uigridlayout(uifig,[nb_ax 1]);
    
    for uix = 1:nb_ax
        switch uix
            case {1 3}
                ax(uix) = uiaxes(uigl,'NextPlot','add','Box','on','XGrid','on','YGrid','on');
                yyaxis(ax(uix),'right');
                ax(uix).YAxis(2).Color = [0.6 0 0];
                ylabel(ax(uix),'Angle (deg)');
                yyaxis(ax(uix),'left');
                ax(uix).YAxis(1).Color = [0 0 0.6];
                ylabel(ax(uix),'BS (dB)');
                xlabel(ax(uix),'Time (s)');
            case 2
                ax(uix) = uiaxes(uigl,'NextPlot','add','Box','on','XGrid','on','YGrid','on');
                ylabel(ax(uix),'Angle (deg)');
                xlabel(ax(uix),'Time (s)');
        end
 
    end
    
end

ff  = fieldnames(bot_data_struct);
idx_rem = [];
%opts = fitoptions('Method', 'LinearLeastSquares','Robust','bisquare');
for uib = 1:numel(idx_beams)
    for uip  =1:numel(idx_pings)
        idx_p = find(bot_data_struct.Idx_ping == idx_pings(uip) & bot_data_struct.Idx_beam == idx_beams(uib));
        
        % x = bot_data_struct_disp.Time(idx_p);
        % w = bot_data_struct.BS(idx_p).^2;
        y_ac = bot_data_struct.AcrossAngle(idx_p);
        y_al = bot_data_struct.AlongAngle(idx_p);
         
         % opts = fitoptions(opts, 'Weights',w);
         % 
         % [f_ac,go_fac,output_ac] = fit(x(:),y_ac(:),'poly1',opts);
         % [f_al,go_fal,output_al] = fit(x(:),y_al(:),'poly1',opts);

        std_al = movstd(y_al,win_filt);
        std_ac = movstd(y_ac,win_filt);

        idx_tmp = bot_data_struct.BS(idx_p)<max(bot_data_struct.BS(idx_p))+thr_echo|...
            std_al>std_angle_thr_al|(std_al==0 & abs(y_al)>0)|...
            std_ac>std_angle_thr_ac|(std_ac==0 & abs(y_ac)>0);
            % std_al/2>abs(f_al(x)'-y_al)|...
            % std_ac/2>abs(f_ac(x)'-y_ac)...

        idx_rem = [idx_rem idx_p(idx_tmp)];

        if disp_bool
            for uix=1:nb_ax
                switch uix
                    case 1
                        title(ax(uix),sprintf('Before cleaning ping %d (%d/%d)',idx_pings(uip),uip,numel(idx_pings)));
                    case 2
                        title(ax(uix),sprintf('Std Angle %d (%d/%d)',idx_pings(uip),uip,numel(idx_pings)));
                    case 3
                        title(ax(uix),sprintf('After cleaning ping %d (%d/%d)',idx_pings(uip),uip,numel(idx_pings)));
                        idx_nan = idx_p(idx_tmp);
                        bot_data_struct_disp.AlongAngle(idx_nan) = nan;
                        bot_data_struct_disp.AcrossAngle(idx_nan) = nan;
                        bot_data_struct_disp.BS(idx_nan) = nan;
                end
                switch uix
                    case {1 3}
                        yyaxis(ax(uix),'right');
                        cla(ax(uix));
                        plot(ax(uix),bot_data_struct_disp.Time(idx_p),bot_data_struct_disp.AlongAngle(idx_p),'Color',[0.6 0 0],'LineStyle','-');
                        plot(ax(uix),bot_data_struct_disp.Time(idx_p),bot_data_struct_disp.AcrossAngle(idx_p),'Color',[0 0.6 0],'LineStyle','-');
                        ylim(ax(uix),[-2*std_angle_thr_al 2*std_angle_thr_al]);
                        yyaxis(ax(uix),'left');
                        cla(ax(uix));
                        plot(ax(uix),bot_data_struct_disp.Time(idx_p),bot_data_struct_disp.BS(idx_p),'Color',[0 0 0.6],'LineStyle','-');
                        yline(ax(uix),max(bot_data_struct_disp.BS(idx_p))+thr_echo,'Color',[0 0 0.6],'LineStyle','--');
                    case 2
                        cla(ax(uix));
                        plot(ax(uix),bot_data_struct_disp.Time(idx_p),std_al,'Color',[0.6 0 0],'LineStyle','-');
                        plot(ax(uix),bot_data_struct_disp.Time(idx_p),std_ac,'Color',[0 0.6 0],'LineStyle','-');
                        yline(ax(uix),std_angle_thr_al,'Color',[0.6 0 0],'LineStyle','--');
                        yline(ax(uix),std_angle_thr_ac,'Color',[0 0.6 0],'LineStyle','--');
                        %ylim(ax(uix),[-0.1 2*max(std_angle_thr_ac,std_angle_thr_al)])
                end
            end
            ylim(ax(3),ax(1).YLim)
            pause(0.1);
        end

    end
end

nb_elt = numel(bot_data_struct.BS);


for uif = 1:numel(ff)
    if numel(bot_data_struct.(ff{uif}))==nb_elt
        bot_data_struct.(ff{uif})(idx_rem) = [];
    end
end

end

function [maskReg,idx_r_echo] = get_mask_reg_bot(bot_idx,idx_pings,r_tot,echo_len_max,start_fact,end_fact)
echo_start_line = bot_idx-ceil(echo_len_max.*start_fact);

echo_start_line(echo_start_line<=0) = 1;
echo_start_line(echo_start_line>numel(r_tot)) = numel(r_tot);

echo_end_line = bot_idx+ceil(echo_len_max.*end_fact);

echo_end_line(echo_end_line<=0) = 1;
echo_end_line(echo_end_line>numel(r_tot)) = numel(r_tot);

idx_r_l = [echo_end_line,echo_start_line];
idx_r_echo = (min(idx_r_l,[],'omitmissing'):min(idx_r_l,[],'omitmissing')+range(idx_r_l)-1)';
idx_r_echo(idx_r_echo>numel(r_tot)) = [];
idx_r_echo_mat = idx_r_echo*ones(size(idx_pings));

maskReg = idx_r_echo_mat>=echo_start_line & idx_r_echo_mat<=echo_end_line;
end


function slope_struct = estimate_slope(x,y,z,w,idx_pings,ii,xbot,ybot,fitType,opts,echo_thr,win_size,rsq_thr,res_thr,max_ite,ax)

slope_struct.dx = nan;
slope_struct.dy = nan;
slope_struct.rsqex = nan;
slope_struct.rsqey = nan;
slope_struct.res = nan;
slope_struct.res2 = nan;
slope_struct.bs = nan;
slope_struct.nb_ite = 0;
slope_struct.Idx_ping = ii;

idx = find(idx_pings(:)' >= ii-win_size/2 & idx_pings(:)' < ii+win_size/2 & ~isnan(z(:)') & ~isnan(w(:)') & ~isinf(z(:)'));
%idx = find(idx_pings(:) == ii);
nb_points_lim = 11;

if numel(idx) < nb_points_lim
    return;
end

bds =  [max(w(idx)*db2pow(echo_thr)) max(w(idx))];

if diff(bds)>0
    idd = (w(idx)>=bds(1) & w(idx)<=bds(2));
    idx  = idx(idd);
end

if numel(idx) < nb_points_lim
    return;
end

x  = x(idx);
y = y(idx);
z = z(idx);
w = w(idx).^2;

rsq = inf;

xData = x(:);
yData = y(:);
zData = z(:);
wData = w(:);

while numel(xData)>nb_points_lim && rsq>rsq_thr && max_ite>slope_struct.nb_ite
    slope_struct.nb_ite = slope_struct.nb_ite+1;

    switch type(fitType)
        case {'poly11' 'poly22'}
            
            opts = fitoptions(opts, 'Weights',wData(:));

            [func_fit.fxy,gof,output] = fit([xData(:),yData(:)],zData(:), fitType,opts);
            
            % [func_fit.fxy2,gof2,output2] = fit([xData(:),yData(:)],zData(:), 'poly22',opts);
            % [dz_dx1, dz_dy1, slope] = slopes_from_fit(func_fit.fxy, xData, yData);
            % [dz_dx, dz_dy, slope] = slopes_from_fit(func_fit.fxy2, xData, yData);

            rsq_new = gof.rsquare;

            if rsq_new >rsq
                slope_struct.nb_ite = slope_struct.nb_ite-1;
                break;
            else
                rsq  = rsq_new;
            end

            slope_struct.dx = func_fit.fxy.p10;
            slope_struct.dy = func_fit.fxy.p01;

            slope_struct.rsqex = gof.rsquare;
            slope_struct.rsqey = gof.rsquare;
            slope_struct.res = abs(func_fit.fxy(xData,yData)-zData)/range(zData);
            %slope_struct.res2 = abs(func_fit.fxy2(xData,yData)-zData)/range(zData);
        case {'poly1' 'poly2'}

            opts = fitoptions(opts, 'Weights',wData(:));
            [func_fit.fx,gofx,outputx] = fit(xData(:),zData(:), fitType,opts);
            [func_fit.fy,gofy,outputy] = fit(yData(:),zData(:), fitType,opts);

            [func_fit.fx2,gofx2,outputx2] = fit(xData(:),zData(:), 'poly2',opts);
            [func_fit.fy2,gofy2,outputy2] = fit(yData(:),zData(:), 'poly2',opts);

            rsq_new = sqrt((gofx.rsquare.^2+gofy.rsquare.^2)/2);
            if rsq_new>rsq
                slope_struct.nb_ite = slope_struct.nb_ite-1;
                break;
            else
                rsq  = rsq_new;
            end

            slope_struct.dx = func_fit.fx.p1;
            slope_struct.dy = func_fit.fy.p1;

            slope_struct.rsqex = gofx.rsquare;
            slope_struct.rsqey = gofy.rsquare;
            slope_struct.res = sqrt(((func_fit.fx(xData)-zData).^2+(func_fit.fy(yData)-zData).^2))/range(zData);  
            %slope_struct.res2 = sqrt(((func_fit.fx2(xData)-zData).^2+(func_fit.fy2(yData)-zData).^2))/range(zData);



    end

    slope_struct.bs = pow2db(sqrt(wData));
    dd  = sqrt((xData-xbot).^2+(yData-ybot).^2);
    %dd = 1:numel(xData);
    for iax = 1:numel(ax)
        nb_pings = numel(unique(idx_pings));
        cla(ax(iax));
        switch ax(iax).Tag
            case 'res'
                plot(ax(iax),1:numel(xData),slope_struct.(ax(iax).Tag),'Color',[0 0 0.6]);
                %plot(ax(iax),1:numel(xData),slope_struct.res2,'Color',[0.6 0 0]);
                yline(ax(iax),prctile(slope_struct.(ax(iax).Tag),90),'-','90th perctile','Color',[0 0.6 0]);
                yline(ax(iax),res_thr,'-','Res. thr.','Color',[0.6 0 0]);
                title(ax(iax),sprintf('Ping %d/%d iteration %d, R^2 = %.2f',ii-idx_pings(1)+1,nb_pings,slope_struct.nb_ite,rsq));
            case 'bs'
                plot(ax(iax),dd,slope_struct.(ax(iax).Tag),'.'); 
            case 'fx'
                title(ax(iax),sprintf('Along Slope : %.0f deg.',mean(atand(slope_struct.dx))))
                scatter(ax(iax),xData,zData,10,slope_struct.bs,"filled");
                plot(ax(iax),func_fit.(ax(iax).Tag));daspect(ax(iax),[1 1 1]);
            case 'fy'
                title(ax(iax),sprintf('Across Slope : %.0f deg.',mean(atand(slope_struct.dy))))
                scatter(ax(iax),yData,zData,10,slope_struct.bs,"filled");
                plot(ax(iax),func_fit.(ax(iax).Tag));daspect(ax(iax),[1 1 1]);
            case 'fxy'
                title(ax(iax),sprintf('Along Slope : %.0f deg.; Across Slope : %.0f deg.',mean(atand(slope_struct.dx)),mean(atand(slope_struct.dy))))
                scatter3(ax(iax),xData,yData,zData,10,slope_struct.bs,"filled");
                plot(ax(iax),func_fit.(ax(iax).Tag));daspect(ax(iax),[1 1 1]);
                view(ax(iax),[-45 20]);
                clim(ax(iax),prctile(slope_struct.bs,[5 95])+[-1 1]);
        end  
    end
    if numel(ax)>1
        pause(0.1);
    end

    id_rem = abs(slope_struct.res)>res_thr;
    xData(id_rem) = [];
    yData(id_rem) = [];
    zData(id_rem) = [];
    wData(id_rem) = [];

end


end

function [dz_dx, dz_dy, slope] = slopes_from_fit(f, x, y)
    % coeff: Matrix of coefficients a_ij (rows: powers of x, cols: powers of y)
    % x, y: Grid points for evaluation

    order = (-3+sqrt(9-4*(2-2*numel(coeffvalues(f)))))/2;
    
    dz_dx = zeros(size(x));
    dz_dy = zeros(size(x));


    for ir = 0:order %power of x
        for jc = 0:order %power of y
            try
                % Add contribution to ∂z/∂x
                if ir > 0
                    dz_dx = dz_dx + ir * f.(sprintf('p%d%d',ir,jc)) * x.^(ir-1) .* y.^(jc);
                end
                % Add contribution to ∂z/∂y
                if jc > 0
                    dz_dy = dz_dy + jc * f.(sprintf('p%d%d',ir,jc)) * x.^(ir-1) .* y.^(jc);
                end
            end
        end
    end

    % Compute slope magnitude
    slope = sqrt(dz_dx.^2 + dz_dy.^2);
end


function bot_data_struct = bs_from_data(bot_data_struct,field,faBW,psBW,Tp,t_angle)

        switch field
            case {'sv' 'svdenoised'}
                bot_data_struct.BS = bot_data_struct.data_disp+10*log10(bot_data_struct.Range)+bot_data_struct.Compensation;
                    corr = -10*log10(1./cosd(t_angle).^2);
            case {'sp' 'spdenoised'}
                bot_data_struct.BS = bot_data_struct.data_disp-10*log10(bot_data_struct.Range)+ bot_data_struct.Compensation;...
                    corr = -10*log10(trans_obj.Envdata.Soundspeed*Tp(:,:,id_beam)/2./cosd(t_angle).^2);     
            otherwise
                bot_data_struct.BS = bot_data_struct.data_disp+bot_data_struct.Compensation;
                 corr = -10*log10(sind((faBW+psBW)/2)./cosd(t_angle).^2);
        end
        bot_data_struct.BS_corr = bot_data_struct.BS + corr;

end

