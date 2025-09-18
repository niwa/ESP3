function[cal_cw_tot,cal_fm_tot,idx_cal]=TS_calibration_curves_func(main_figure,layer_obj,idx_cal)

cal_cw_tot=[];
cal_fm_tot={};

int_meth='linear';
ext_meth = nan;

update_algos('algo_name',{'SingleTarget'});

load_bar_comp=getappdata(main_figure,'Loading_bar');
block_len = get_block_len(50,'cpu',[]);

if isempty(layer_obj)
    layer_obj=get_current_layer();
end

curr_disp=get_esp3_prop('curr_disp');
axes_panel_comp=getappdata(main_figure,'Axes_panel');
ah=axes_panel_comp.echo_obj.main_ax;

cmap_struct = init_cmap(curr_disp.Cmap,curr_disp.ReverseCmap);
cmap = cmap_struct.cmap;
[~,idx_freq]=layer_obj.get_trans(curr_disp);

calibration_tab_comp=getappdata(main_figure,'Calibration_tab');
env_tab_comp=getappdata(main_figure,'Env_tab');

sphere_list=get(calibration_tab_comp.sphere,'String');
sphere_type = sphere_list{get(calibration_tab_comp.sphere,'value')};
sph=list_spheres(sphere_type);

%f_vec_save=[];
if isempty(idx_cal)
    list_freq_str = cellfun(@(x,y) sprintf('%.0f kHz: %s',x,y),num2cell(layer_obj.Frequencies/1e3), layer_obj.ChannelID,'un',0);

    if numel(list_freq_str)>1
        [idx_cal,val] = listdlg_perso(main_figure,'Choose Frequencies to calibrate',list_freq_str);

        if val==0||isempty(idx_cal)
            return;
        end
    else
        idx_cal=1;
    end
end

t_out = 10;

show_status_bar(main_figure);

cal_fm_tot=cell(1,numel(idx_cal));

fields_fm_cal = get_cal_fm_fields();

absorption=cell(1,numel(layer_obj.Transceivers));
soundspeed=cell(1,numel(layer_obj.Transceivers));
range_trans=cell(1,numel(layer_obj.Transceivers));
ori_abs=cell(1,numel(layer_obj.Transceivers));

att_list=get(env_tab_comp.att_choice,'String');
abs_comp=att_list{get(env_tab_comp.att_choice,'value')};

ss_list=get(env_tab_comp.ss_choice,'String');
ss_comp=ss_list{get(env_tab_comp.ss_choice,'value')};

layer_obj.EnvData.set_ctd(layer_obj.EnvData.CTD.depth,layer_obj.EnvData.CTD.temperature,layer_obj.EnvData.CTD.salinity,lower(abs_comp));
layer_obj.EnvData.set_svp(layer_obj.EnvData.SVP.depth,layer_obj.EnvData.SVP.soundspeed,lower(ss_comp));


cal_cw_tot = layer_obj.get_cw_cal();
t_cal_str = string(datetime,'yyyyMMdd_HHmmSS');
[path_out,~]=fileparts(layer_obj.Filename{1});

cal_cw_tot.RMS  =zeros(numel(layer_obj.Transceivers),1);
cal_cw_tot.nb_echoes = nan(numel(layer_obj.Transceivers),1);
cal_cw_tot.nb_central_echoes = nan(numel(layer_obj.Transceivers),1);
cal_cw_tot.central_echoes_angle = nan(numel(layer_obj.Transceivers),1);
cal_cw_tot.depth = nan(numel(layer_obj.Transceivers),1);
cal_cw_tot.sphere_range_av = nan(numel(layer_obj.Transceivers),1);
cal_cw_tot.sphere_range_std = nan(numel(layer_obj.Transceivers),1);
cal_cw_tot.sphere_ts = nan(numel(layer_obj.Transceivers),1);
cal_cw_tot.sphere_type = cell(numel(layer_obj.Transceivers),1);
cal_cw_tot.up_or_down_cast = cell(numel(layer_obj.Transceivers),1);

save_bool = false(1,numel(layer_obj.Transceivers));
save_bool(idx_cal) = true;

cal_keys = [];
deep_cal = false(1,numel(layer_obj.Transceivers));
ori_tt = layer_obj.EnvData.CTD.ori;
ori_tts = layer_obj.EnvData.SVP.ori;

for uui=idx_cal
    prev_depth = 0;


    trans_obj=layer_obj.Transceivers(uui);
    

    cal_fm_tot{uui} = trans_obj.get_transceiver_fm_cal();

    if isempty(trans_obj.Regions)||trans_obj.ismb()
        continue;
    end

    idx_good=find(strcmpi({trans_obj.Regions(:).Type},'Data'));

    if isempty(idx_good)
        continue;
    end


    calibration_regs = trans_obj.Regions(idx_good);
    t_depth_regs  = nan(1,numel(calibration_regs));
    idx_ping_regs  = nan(1,numel(calibration_regs));
    str_regs  = cell(1,numel(calibration_regs));

    for uireg = 1:numel(calibration_regs)
        t_depth_regs(uireg) = mean(trans_obj.get_transducer_depth(calibration_regs(uireg).Idx_ping));
        str_regs{uireg} = sprintf('Region %s: %.0fm',calibration_regs(uireg).disp_str(),t_depth_regs(uireg));
        idx_ping_regs(uireg) = mean(calibration_regs(uireg).Idx_ping);
    end

    %t_depth_regs = (1:numel(calibration_regs))*100;

    [~,id_sort_reg] = sort(idx_ping_regs);
    calibration_regs = calibration_regs(id_sort_reg);
    t_depth_regs = t_depth_regs(id_sort_reg);
    str_regs = str_regs(id_sort_reg);

    t_depth_unique = unique(round(t_depth_regs/10)*10);

    if numel(t_depth_unique)>1
        deep_cal(uui) = true;
    end

    if deep_cal(uui)
        choice=question_dialog_fig(main_figure,...
            'Multiple-depth calibration detected',...
            'Multiple-depth calibration detected. Do you want to run a calibration separately for each defined region? For it to be correct you will need to have loaded a proper CTD and/or SVP profile. Alternatively, use the "theoritical" option...',...
            'timeout',30);

        % Handle response
        switch choice
            case 'Yes'
                deep_cal(uui) = true;
                [iregs,val] = listdlg_perso(main_figure,'Choose depth to calibrate at.',str_regs,'init_val',1:numel(calibration_regs));
                if val==0 || isempty(iregs)
                    deep_cal(uui) = false;
                    continue;
                end
            otherwise
                deep_cal(uui) = false;
        end
    end

    if ~deep_cal(uui)
        calibration_regs=trans_obj.Regions(idx_good).merge_regions('overlap_only',0);
        iregs = 1;
    end

    for uireg = iregs

        new_region = calibration_regs(uireg);

        t_depth=trans_obj.get_transducer_depth(round(mean(new_region.Idx_ping)));

        %t_depth = t_depth_regs(uireg);

        layer_obj.EnvData.CTD.ori = ori_tt;
        layer_obj.EnvData.SVP.ori = ori_tts;
        idx_ping_ref = round(mean(new_region.Idx_ping));
        [absorption{uui},ori_abs{uui}]=trans_obj.compute_absorption(layer_obj.EnvData,abs_comp,idx_ping_ref = idx_ping_ref);
        [soundspeed{uui},range_trans{uui}]=trans_obj.compute_soundspeed_and_range(layer_obj.EnvData,ss_comp,idx_ping_ref = idx_ping_ref);

        if t_depth < prev_depth
            direction = 'upcast';
        elseif t_depth > prev_depth
            direction = 'downcast';
        else
            direction = 'static';
        end

        prev_depth = t_depth_regs(uireg);
        Freq=trans_obj.Config.Frequency;
        Freq_c=trans_obj.get_center_frequency(1);


        idx_r_from_transducer = 1:max(new_region.Idx_r);
        range_sph=(ceil(range_trans{uui}(new_region.Idx_r)*10/2)*2/10);
        depth=range_sph+t_depth;
        mean_sphere_depth  = mean(depth,'all','omitnan');

        log_file=fullfile(path_out,generate_valid_filename(sprintf('cal_log_%s_%dm_%s.txt',layer_obj.ChannelID{uui},round(t_depth),t_cal_str)));
        fid=[1 fopen(log_file,'w')];
        for ifi=1:numel(fid)
            if fid(ifi)>=0
                fprintf(fid(ifi),'Calibration of Channel %s recorded on  %s\nProcessed on the %s using ESP3 version %s\n',...
                    trans_obj.Config.ChannelID,...
                    datestr(trans_obj.Time(1), 'dd/mm/yyyy HH:MM:SS'),...
                    string(datetime, 'dd/MM/yyyy HH:mm:SS'),...
                    get_ver());
            end
        end

        t_sphere=layer_obj.EnvData.Temperature;
        s_sphere=layer_obj.EnvData.Salinity;

        switch lower(ori_abs{uui})
            case {'profile' 'theoritical'}
                if ~isempty(layer_obj.EnvData.CTD.depth)
                    [~,idx_sphere] = min(abs(layer_obj.EnvData.CTD.depth-mean_sphere_depth),[],'all','omitnan');
                    s_sphere=layer_obj.EnvData.CTD.salinity(idx_sphere);
                    t_sphere=layer_obj.EnvData.CTD.temperature(idx_sphere);
                end
                abs_app = mean(absorption{uui}(idx_r_from_transducer),'omitnan');
                layer_obj.EnvData.CTD.ori = 'constant';
            case 'constant'
                if ~env_tab_comp.att_over.Value||~strcmpi(trans_obj.Alpha_ori,'constant')
                    abs_app = mean(seawater_absorption(Freq_c/1e3, layer_obj.EnvData.Salinity, layer_obj.EnvData.Temperature, depth,layer_obj.EnvData.AttModel),'all','omitnan')/1e3;
                else
                    abs_app = mean(trans_obj.Alpha(idx_r_from_transducer),'all','omitnan');
                end

                if deep_cal(uui)
                    print_errors_and_warnings(fid,'warning','No CTD profile loaded. Your multiple depth calibration might be biased...');
                end
        end

        density = seawater_dens(s_sphere, t_sphere, t_depth+range_sph);

        density_at_sphere = mean(density,'all','omitnan');

        if numel(soundspeed{uui})>1
            mean_ss = mean(soundspeed{uui}(idx_r_from_transducer),'omitnan');
            ss_at_sphere = mean(soundspeed{uui}(new_region.Idx_r),'omitnan');
        else
            mean_ss = soundspeed{uui};
            ss_at_sphere = soundspeed{uui};
        end

        if deep_cal(uui) && isscalar(soundspeed{uui})
            print_errors_and_warnings(fid,'warning','No SVP profile loaded. Your multiple depth calibration might be biased...');
        end

        if env_tab_comp.soundspeed_over.Value
            mean_ss =str2double(get(env_tab_comp.soundspeed,'string'));
            ss_at_sphere = mean_ss;
        end


        cal_cw_tot.sphere_ts(uui) = spherets(2*pi*Freq_c/layer_obj.EnvData.SoundSpeed,sph.diameter/2, ss_at_sphere, ...
            sph.lont_c, sph.trans_c, density_at_sphere, sph.rho);

        force_recompute_sv = false;

        layer_obj.layer_computeSpSv(...
            'new_soundspeed',mean_ss,...
            'absorption',abs_app,...
            'absorption_f',layer_obj.Frequencies(uui),...
            'force',force_recompute_sv,...
            'load_bar_comp',load_bar_comp,...
            'block_len',block_len);

        cal_cw_tot.alpha(uui) = abs_app;

        range_tot=range_trans{uui};

        trans_obj.ST = init_st_struct(0);

        trans_obj.apply_algo_trans_obj('SingleTarget','reg_obj',new_region,'load_bar_comp',load_bar_comp);

        if isempty(trans_obj.ST.TS_comp)
            dlg_perso(main_figure,'','No sphere echoes at all... Try changing your single target detection parameter for this frequency');
            if ~isempty(path_out)
                fclose(fid(2));
            end
            continue;
        end


        [idx_alg,alg_found]=find_algo_idx(trans_obj,'SingleTarget');


        if alg_found
            varin=trans_obj.Algo(idx_alg).input_params_to_struct();
            max_beam_comp=varin.MaxBeamComp;
        else

            max_beam_comp=12;
        end

        % When calculating the RMS fit of the data to the Simrad beam pattern, only
        % consider echoes out to (rmsOutTo * beamwidth) degrees.

        rmsOutTo = max_beam_comp/12;

        % Optional single target and sphere processing parameters:
        %

        % Any sphere echo more than maxDbDiff1 from the theoretical will be
        % discarded as an outlier. Used in a coarse filter prior to actually
        % working out the beam width.
        maxdBDiff1 = 10;

        % Beam compensated TS values more than maxdBDiff2 dB above or below the
        % sphere TS are discarded. Done after working out the beam width.
        % Note that this forces an upper limit on the RMS of the final fit to the
        % beam pattern.
        maxdBDiff2 = 1;

        % All echoes within onAxisFactor times the beam width will be considered to
        % be on-axis for the purposes of working out the on-axis gain.
        onAxisFactor = 0.015; % [factor]

        % If there are less than minOnAxisEchos sphere echoes close to the
        % beam centre (as calculated using onAxisFactor), use
        % onAxisFactorExpanded instead.
        minOnAxisEchoes = 6;

        % If insufficient echoes are found with onAxisFactor multiplied by
        % the average of the fore/aft and port/stbd beamwidths,
        % onAxisFactorExpanded will be used instead.
        onAxisFactorExpension = 5; % [factor]

        % What method to use when calculating the 'best' estimate of the on-axis
        % sphere TS. Max of on-axis echoes, mean of on-axis echoes, or the peak of
        % the fitted beam pattern.
        onAxisMethod = {'mean','max','beam fitting'};

        mean_sphere_depth  = mean(depth,'all','omitnan');

        % print out the parameters
        for ifi=1:numel(fid)
            if fid(ifi)>=0
                fprintf(fid(ifi),['Ping rate = ' num2str(1/mode(diff(trans_obj.Time*24*60*60))) ' Hz\n']);
                fprintf(fid(ifi),['Mean sphere depth= ' num2str(mean_sphere_depth) ' m\n']);
                fprintf(fid(ifi),['Sound speed at sphere = ' num2str(ss_at_sphere) ' m/s\n']);
                fprintf(fid(ifi),['Density at sphere = ' num2str(density_at_sphere) ' kg/m^3\n']);
                fprintf(fid(ifi),['Mean Absorption = ' num2str(mean(absorption{uui}(idx_r_from_transducer),'omitnan')*1e3) ' dB/km\n']);
                fprintf(fid(ifi),['Mean sound speed = ' num2str(mean_ss) ' m/s\n']);
                fprintf(fid(ifi),['Sphere TS at ' num2str(Freq_c/1e3) ' kHz is ' num2str(cal_cw_tot.sphere_ts(uui)) ' dB\n\n']);
            end
        end
        switch trans_obj.Mode
            case 'FM'
                cal_struct=trans_obj.get_transceiver_fm_cal('origin','th');
            case 'CW'
                cal_struct = trans_obj.get_transceiver_cw_cal();
                cal_struct.Frequency = trans_obj.get_center_frequency(1);
        end

        [faBW,psBW] = trans_obj.get_beamwidth_at_f_c(cal_struct);

        % Calculate the mean_ts from echoes that are on-axis
        on_axis = onAxisFactor * mean(faBW + psBW)/2;

        AlongAngle_sph = trans_obj.ST.Angle_minor_axis;
        AcrossAngle_sph = trans_obj.ST.Angle_major_axis;

        Sp_sph = trans_obj.ST.TS_uncomp;
        %Power_norm = trans_obj.ST.Power_norm;

        test_sb_cal_fm = false;
        [~, ~] = simradAnglesToSpherical(AlongAngle_sph, AcrossAngle_sph);
        
        if test_sb_cal_fm
            BeamType = 'single-beam';
            comp_angle = [false false];
            AcrossAngle_sph = zeros(size(AcrossAngle_sph));
            AlongAngle_sph = zeros(size(AlongAngle_sph));
        else
            BeamType = trans_obj.Config.BeamType;
            comp_angle = [true true];
        end

        [phi, ~] = simradAnglesToSpherical(AlongAngle_sph, AcrossAngle_sph);

        idx_high=get_highest_target_per_ping(trans_obj.ST);

        idx_keep=idx_high&...
            abs(trans_obj.ST.TS_comp-cal_cw_tot.sphere_ts(uui))<=maxdBDiff1&...
            trans_obj.ST.Angle_minor_axis<=faBW*rmsOutTo&...
            trans_obj.ST.Angle_major_axis<=psBW*rmsOutTo;

        if sum(idx_keep)<minOnAxisEchoes
            choice=question_dialog_fig(main_figure,'','It appears that there is no spheres here... Do you want to try and run a calibration anyway?','timeout',t_out);
            % Handle response
            switch choice
                case 'Yes'
                    idx_keep=~isnan(trans_obj.ST.TS_comp)&~isinf(trans_obj.ST.TS_comp);
                case 'No'
                    if~isempty(path_out)
                        fclose(fid(2));
                    end
                    continue
            end
        end

        if sum(idx_keep)<6
            dlg_perso(main_figure,'Not enough sphere echoes','It looks like there is no sphere here...','Timeout',t_out);
            continue;
        end

        freq_str=generate_valid_filename(sprintf('%.0d_%s_%dm',Freq,layer_obj.ChannelID{uui},round(t_depth)));
        freq_str_disp=sprintf('%s %.0f kHz (%dm)',layer_obj.ChannelID{uui},Freq/1e3,round(t_depth));

        if idx_freq==uui
            [~,idx_disp] = min(abs(range_tot-trans_obj.ST.Target_range(idx_keep)));
            plot(ah,trans_obj.ST.Ping_number(idx_keep),idx_disp,'.k','linewidth',2);
        end

        cax=[cal_cw_tot.sphere_ts(uui)-max_beam_comp-3 cal_cw_tot.sphere_ts(uui)+3];

        switch trans_obj.Mode
            case 'FM'
                switch BeamType
                    case 'single-beam'
                        %peak_ts = prctile(Sp_sph(idx_keep),95);
                        %idx_keep = idx_keep&abs(Sp_sph-peak_ts)<=maxdBDiff2;
                    otherwise
                        fig_bp=plot_bp(AcrossAngle_sph,AlongAngle_sph,Sp_sph,idx_keep,strcmpi(trans_obj.Mode,'CW'));

                        if~isempty(path_out)&&~isempty(fig_bp)
                            print(fig_bp,fullfile(path_out,generate_valid_filename(['bp_contour_plot_' freq_str '.png'])),'-dpng','-r300');
                        end
                end


            case 'CW'
                [sim_pulse,~]=trans_obj.get_pulse();
                Np=length(sim_pulse);

                gain=trans_obj.get_current_gain();

                % Fit the simrad beam pattern to the data. We get estimated beamwidth,
                % offsets, and peak value from this.
                switch BeamType
                    case 'single-beam'
                        offset_fa = trans_obj.Config.AngleOffsetAlongship;
                        offset_ps = trans_obj.Config.AngleOffsetAthwartship;

                        [faBW,psBW] = trans_obj.get_beamwidth_at_f_c(cal_struct);

                        peak_ts = prctile(Sp_sph(idx_keep),99);
                        exitflag=1;
                    otherwise
                        [offset_fa,faBW,offset_ps,psBW,~,peak_ts,exitflag] = ...
                            fit_beampattern(Sp_sph(idx_keep),AcrossAngle_sph(idx_keep),AlongAngle_sph(idx_keep),maxdBDiff2, (faBW+psBW)/2);
                end

                % If a beam pattern couldn't be fitted, give up with some diagonistics.
                if exitflag ~= 1
                    for ifi=1:length(fid)
                        fprintf(fid(ifi),'Failed to fit the theoritical beam pattern to the data.\n');
                        fprintf(fid(ifi),'This probably means that the beampattern is far from circular\n');
                        fprintf(fid(ifi),'It is likely that there is something wrong with the sounder.\n\n');
                    end
                    % Plot the probably wrong data, using the un-filtered dataset

                    plot_bp(AcrossAngle_sph,AlongAngle_sph,Sp_sph,1:numel(Sp_sph),strcmpi(trans_obj.Mode,'CW'));

                    if~isempty(path_out)
                        fclose(fid(2));
                    end
                    continue
                end

                % Apply the offsets to the target angles
                AcrossAngle_sph = AcrossAngle_sph - offset_ps;
                AlongAngle_sph = AlongAngle_sph - offset_fa;

                [phi, ~] = simradAnglesToSpherical(AlongAngle_sph, AcrossAngle_sph);
                compensation = simradBeamCompensation(faBW, psBW, AlongAngle_sph, AcrossAngle_sph);
                % Filter outliers based on the beam compensated corrected data

                switch BeamType
                    case 'single-beam'
                        idx_keep = idx_keep&abs(Sp_sph+compensation-peak_ts)<=maxdBDiff2/2;
                    otherwise
                        idx_keep = idx_keep&abs(Sp_sph+compensation-peak_ts)<=maxdBDiff2;
                end

        end

        idx_keep_sec=idx_keep&abs(phi)<=on_axis;

        switch BeamType
            case 'single-beam'
                if sum(idx_keep_sec)<minOnAxisEchoes
                    dlg_perso(main_figure,'','Cannot find any usable sphere echoes in there for this single-beam calibration... Try changing your single target detection parameter for this frequency');
                    if~isempty(path_out)
                        fclose(fid(2));
                    end
                    continue;
                end
            otherwise
                if sum(idx_keep_sec)<minOnAxisEchoes
                    dlg_perso(main_figure,'',sprintf('Less than %d echoes closer than %.1f degrees to the center. Looking out to %.1f degree.',minOnAxisEchoes,on_axis, onAxisFactorExpension*on_axis),'Timeout',5);
                    on_axis = onAxisFactorExpension*on_axis;
                    idx_keep_sec=idx_keep&abs(phi)<=on_axis;
                end

                if sum(idx_keep_sec)<minOnAxisEchoes
                    dlg_perso(main_figure,'POOR CALIBRATION DATA',sprintf(['Less than %d echoes closer than %.1f degrees to the center. Looking out to %.1f degree.\n'...
                        'PRETTY POOR CALIBRATION DATA, I WOULD NOT TRUST IT!!!!'],minOnAxisEchoes,on_axis, onAxisFactorExpension*on_axis),'Timeout',5);
                    on_axis = onAxisFactorExpension*on_axis;
                    idx_keep_sec=idx_keep&abs(phi)<=on_axis;
                end

                if sum(idx_keep_sec)<minOnAxisEchoes
                    dlg_perso(main_figure,'POOR CALIBRATION DATA',sprintf(['Less than %d echoes closer than %.1f degrees to the center. Looking out to %.1f degree.\n'...
                        'You are about to try to obtain a calibration from very poor quality data, with very low number of central echoes...'],minOnAxisEchoes,on_axis, onAxisFactorExpension*on_axis/2),'Timeout',5);
                    on_axis = onAxisFactorExpension*on_axis/2;
                    idx_keep_sec=idx_keep&abs(phi)<=on_axis;
                end

                if sum(idx_keep_sec)<minOnAxisEchoes
                    dlg_perso(main_figure,'','I have tried very hard and cannot find any usable spere echoes in there... Try changing your single target detection parameter for this frequency');
                    if~isempty(path_out)
                        fclose(fid(2));
                    end
                    continue
                end
        end

        if  sum(idx_keep_sec)<minOnAxisEchoes
            choice=question_dialog_fig(main_figure,'Crappy calibration data detected','Do you want REALLY want to try to calibrate with those crappy data? Well, nothing I can do to stop you then...','Timeout',t_out);

            % Handle response
            switch choice
                case 'Yes'
                    idx_keep_sec=idx_keep;
                case 'No'
                    if ~isempty(path_out)
                        fclose(fid(2));
                    end
                    continue
            end
        end

        r_disp=trans_obj.ST.Target_range();
        switch BeamType
            case 'single-beam'
            otherwise
                r_disp(~idx_keep)=nan;
        end

        % Do a plot of the sphere depth during the calibration;
        fig_r=new_echo_figure(main_figure,'Name',sprintf('%s: Sphere range',freq_str_disp),'Tag',sprintf('Sphere range'));
        ax=axes(fig_r,'nextplot','add');
        plot(ax,trans_obj.ST.Ping_number,r_disp);
        axis(ax,'ij');
        box(ax,'on');
        grid(ax,'on');
        title(ax,'Sphere range during the calibration.')
        xlabel(ax,'Ping number')
        ylabel(ax,'Sphere range (m)')

        if~isempty(path_out)
            print(fig_r,fullfile(path_out,generate_valid_filename(['sph_depth_' freq_str '.png'])),'-dpng','-r300');
        end



        switch trans_obj.Mode
            case 'FM'

                idx_peak_tot = trans_obj.ST.idx_r(idx_keep_sec);
                idx_ping = trans_obj.ST.Ping_number(idx_keep_sec);

                if isempty(idx_peak_tot)
                    dlg_perso(main_figure,'','Not enough central echoes');
                    continue;
                end

                set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(idx_ping), 'Value',0);
                load_bar_comp.progress_bar.setText(sprintf('Processing TS estimation Frequency %.0fkHz',trans_obj.Config.Frequency/1e3));

                idx_rem=[];
                f_corr=nan(1,numel(idx_ping));

                win_fact = 1;

                for kk=1:length(idx_ping)
                    [sp,cp,f,~,f_corr(kk)] = processTS_f_v2(trans_obj,layer_obj.EnvData,idx_ping(kk),range_tot(idx_peak_tot(kk)),win_fact,cal_struct,comp_angle);
                    if kk==1
                        Sp_f=nan(numel(sp),numel(idx_ping));
                        Compensation_f=nan(numel(sp),numel(idx_ping));
                        f_vec=nan(numel(sp),numel(idx_ping));
                    end
                    
                    if numel(sp)==size(Sp_f,1)
                        Sp_f(:,kk)=sp;
                        Compensation_f(:,kk)=cp;
                        f_vec(:,kk)=f;
                    else
                        idx_rem=union(idx_rem,kk);
                    end
                    set(load_bar_comp.progress_bar, 'Value',kk);
                end

                Sp_f(:,idx_rem)=[];
                Compensation_f(:,idx_rem)=[];
                f_vec(:,idx_rem)=[];
                f_corr(idx_rem)=[];
                freq_vec=f_vec(:,1)';

                th_ts=arrayfun(@(x) spherets(x/ss_at_sphere,sph.diameter/2, ss_at_sphere, ...
                    sph.lont_c, sph.trans_c, density_at_sphere, sph.rho),2*pi*freq_vec);

                switch BeamType
                    case 'split-beam'

                    case 'single-beam'
                        %f_corr = 1;
                        BeamWidthAlongship_th = interp1(cal_struct.Frequency,cal_struct.BeamWidthAlongship_th,freq_vec,int_meth,ext_meth);
                        BeamWidthAthwartship_th = interp1(cal_struct.Frequency,cal_struct.BeamWidthAthwartship_th,freq_vec,int_meth,ext_meth);
                        exitflag = nan(1,size(Sp_f,2));
                        init = 0;
                        peak_ts = prctile(Sp_sph(idx_keep),95);
                        idx_keep_tmp = idx_keep&abs(Sp_sph-peak_ts)<=maxdBDiff2;
                        ts_tmp = pow2db(mean(db2pow(Sp_f(:,idx_keep_tmp)),2))';
                        %off_phi = simradAnglesToSpherical(trans_obj.Config.AngleOffsetAlongship,trans_obj.Config.AngleOffsetAthwartship);
                        phi_est = nan(1,size(Sp_f,2));
                        for uip = 1:size(Sp_f,2)
                            tmp  = Sp_f(:,uip)';
                            %tmp(freq_vec<60000) = nan;
                            min_func = @(xx) sum((db2pow(ts_tmp)-db2pow(tmp+simradBeamCompensation(BeamWidthAlongship_th, BeamWidthAthwartship_th, xx, 0))).^2,"all","omitmissing");
                            [res , ~, exitflag(uip), ~] = fminsearch(min_func, init);
                            phi_est(uip) = abs(res(1));
                            %init = phi(uip);
                            Compensation_f(:,uip) = simradBeamCompensation(BeamWidthAlongship_th, BeamWidthAthwartship_th, phi_est(uip), 0);
                        end

                        Compensation_f(:,exitflag == 0) = 100;

                        ff = new_echo_figure([],'Name',sprintf('Spherical angle FM estimation %s',freq_str_disp),'Tag',sprintf('sb_cal_%s',freq_str));
                        ti = tiledlayout(ff,1,2);
                        ax = nexttile(ti);
                        ax.Box='on';
                        plot(ax,phi_est);hold on;
                        grid on;
                        ylabel('Spherical angle');xlabel('Ping number');

                        if test_sb_cal_fm
                            plot(ax,abs(phi_ori-off_phi));
                            legend(ax,{'Single-beam processing' 'Split-beam processing'})
                        end
                        
                        axx = nexttile(ti);
                        axx.Box='on';
                        xx = linspace(0,max(BeamWidthAthwartship_th),1e3);
                        %plot(axx,xx,simradBeamCompensation(BeamWidthAlongship_th, BeamWidthAlongship_th,xx, 0),'k');hold on;
                        contourf(axx,repmat(phi_est,size(Compensation_f,1),1)',repmat(freq_vec'/1e3,1,size(Compensation_f,2))',Compensation_f',(0:5:20));
                        xlabel('Spherical angle');ylabel('Frequency (kHz)');title(axx,'Compensation (dB)');
                        colormap(axx,cmap)
                        shading(axx,'flat');
                        cb=colorbar(axx);
                        clim(axx,[0 20]);
                        
                        if~isempty(path_out)
                            print(ff,fullfile(path_out,generate_valid_filename(['single_beam_cal_' freq_str '.png'])),'-dpng','-r300');
                        end
                end

                Compensation_f(Compensation_f>6)=nan;

                TS_f=Sp_f+Compensation_f;

                TS_f_mean = 10*log10(mean(10.^(TS_f'/10),'omitnan'));
                SD_TS = std(TS_f,0,2,'omitnan')';
                idx_high_sd = SD_TS > 2*maxdBDiff2;

                cal_ts = TS_f_mean;

                Gf_th=interp1(cal_struct.Frequency,cal_struct.Gain,freq_vec,'linear','extrap');

                Gf=(cal_ts-th_ts)/2+Gf_th(:)';


                try
                    Gf(idx_high_sd)  =nan;
                    [xData, yData] = prepareCurveData( freq_vec, Gf );
                    ft = fittype( 'smoothingspline' );

                    [fitresult, ~] = fit( xData, yData, ft );

                    Gf_filtered_tot = fitresult(freq_vec)';

                catch

                    Gf_filtered_tot = smoothdata(Gf,'loess',range(freq_vec)/10,'SamplePoints',freq_vec);
                    Gf_filtered_tot(idx_high_sd) = nan;
                    Gf(idx_high_sd)  =nan;

                end


                idx_keep_g = sqrt((Gf_filtered_tot-Gf).^2) < 2*maxdBDiff2;

                Gf_filtered_tot (~idx_keep_g) = nan;

                Gf_cleaned = Gf;

                Gf_cleaned(idx_high_sd|~idx_keep_g) = nan;


                cal_fm.Frequency=freq_vec;

                for uif = 1:numel(fields_fm_cal)
                    cal_fm.(fields_fm_cal{uif})=interp1(cal_struct.Frequency,cal_struct.(fields_fm_cal{uif}),cal_fm.Frequency,'linear','extrap');
                end

                ts_fig=new_echo_figure(main_figure,'Name',sprintf('FM cal. %s',freq_str_disp),'Tag',sprintf('FM cal.'),'Toolbar','esp3','MenuBar','esp3');
                fm_ti = tiledlayout(ts_fig,3,1);
                ax_ts = nexttile(fm_ti);
                ax_ts.Box='on';
                %plot(freq_vec/1e3,TS_f,'linewidth',0.5,'color',[0 0.6 0]);
                hold(ax_ts,'on');
                pp =plot(ax_ts,freq_vec/1e3,TS_f_mean,'color',[0.6 0 0],'linewidth',1);
                plot(ax_ts,freq_vec/1e3,TS_f_mean-2*SD_TS,'color',[0.6 0 0],'linewidth',1,'linestyle','--');
                plot(ax_ts,freq_vec/1e3,TS_f_mean+2*SD_TS,'color',[0.6 0 0],'linewidth',1,'linestyle','--');
                pp_th = plot(ax_ts,freq_vec/1e3,th_ts,'color',[0 0.6 0],'linewidth',1);
                xlim(ax_ts,[freq_vec(1)/1e3 freq_vec(end)/1e3]);
                grid(ax_ts,'on');
                ylabel(ax_ts,'TS(dB)');
                legend(ax_ts,[pp_th pp],{'Theoritical TS' 'Measured TS'});
                ax_gf = nexttile(fm_ti);
                ax_gf.Box='on';
                hold(ax_gf,'on');
                plot(ax_gf,cal_struct.Frequency/1e3,cal_struct.Gain_th,'color',[0 0.6 0]);
                plot(ax_gf,freq_vec/1e3,Gf,'linewidth',0.5,'color','k');
                plot(ax_gf,freq_vec/1e3,Gf_cleaned,'color',[0.6 0 0],'linewidth',1);
                plot(ax_gf,freq_vec/1e3,Gf_filtered_tot,'--','linewidth',0.5,'color',[0.6 0 0]);
                grid(ax_gf,'on');
                ylabel(ax_gf,'G_f(dB)');
                legend(ax_gf,{'Original Gain' '"Measured" Gain' '"Cleaned"  Gain' '"Fitted" Gain'});
                ax_bw = nexttile(fm_ti);
                ax_bw.Box = 'on';
                hold(ax_bw,'on');
                plot(ax_bw,cal_struct.Frequency/1e3,cal_struct.BeamWidthAlongship_th,'color',[0 0.6 0],'linewidth',1,'linestyle','--');
                plot(ax_bw,cal_struct.Frequency/1e3,cal_struct.BeamWidthAthwartship_th,'color',[0.2 0.2 0.2],'linewidth',1,'linestyle','--');
                xlabel(ax_bw,'Frequency (kHz)')
                ylabel(ax_bw,'BeamWidth(deg)')
                grid(ax_bw,'on');
                drawnow;
                linkaxes([ax_ts ax_gf ax_bw],'x');
                xlim(ax_bw,[freq_vec(1)/1e3 freq_vec(end)/1e3])
                ylim(ax_bw,[min(cal_struct.BeamWidthAthwartship_th,[],'all','omitnan')*0.8 max(cal_struct.BeamWidthAthwartship_th,[],'all','omitnan')*1.2]);


                if~isempty(path_out)
                    print(ts_fig,fullfile(path_out,generate_valid_filename(['gf_f_' freq_str '.png'])),'-dpng','-r300');
                end

                oa = num2str(on_axis);

                for ifi=1:length(fid)
                    fprintf(fid(ifi),['\nNumber of echoes within ' oa ' deg of centre = ' num2str(size(TS_f,2)) '\n']);
                    fprintf(fid(ifi),['Results obtained from ' num2str(sum(idx_keep,'all','omitnan')) ' sphere echoes\n']);
                end

                qstring=sprintf('Do you want to save those results for Channel %s',layer_obj.ChannelID{uui});
                choice=question_dialog_fig(main_figure,'Calibration',qstring,'opt',{'Yes' 'No'},'timeout',t_out,'default_answer',1);


                switch choice
                    case 'No'
                        save_bool(uui) = false;
                    otherwise

                        qstring=sprintf('Which gain results for frequency do you want to use %.0f kHz (see figure)',Freq/1e3);
                        choice=question_dialog_fig(main_figure,'Calibration',qstring,'opt',{'"Measured" Gain' '"Cleaned"  Gain' '"Fitted" Gain'},'timeout',t_out,'default_answer',3);
                        switch choice
                            case '"Measured" Gain'

                            case '"Cleaned" Gain'
                                Gf = Gf_cleaned;
                            case '"Fitted" Gain'
                                Gf = Gf_filtered_tot;
                        end
                end


                if save_bool(uui)
                    cal_fm.Gain=Gf(:)';
                else
                    cal_fm.Gain=Gf_th(:)';
                end



                switch BeamType
                    case 'single-beam'
                        cal_fm_tot{uui} = cal_fm;
                    otherwise

                        qstring=sprintf('Do also want to try and calibrate the Angles for frequency %.0f kHz',Freq/1e3);
                        choice=question_dialog_fig(main_figure,'Calibration',qstring,'opt',{'Yes' 'No'},'timeout',t_out,'default_answer',2);

                        % Handle response
                        switch choice
                            case 'No'
                                cal_fm_tot{uui} = cal_fm;

                            otherwise

                                idx_peak_tot = trans_obj.ST.idx_r(idx_keep);
                                idx_ping = trans_obj.ST.Ping_number(idx_keep);

                                set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(idx_ping), 'Value',0);
                                load_bar_comp.progress_bar.setText(sprintf('Processing EQA estimation Frequency %.0fkHz',trans_obj.Config.Frequency/1e3));

                                idx_rem=[];
                                f_corr=nan(1,numel(idx_ping));
                                win_fact = 1;
                                for kk=1:length(idx_ping)
                                    [sp,cp,f,~,f_corr(kk)]=trans_obj.processTS_f_v2(layer_obj.EnvData,idx_ping(kk),range_tot(idx_peak_tot(kk)),win_fact,cal_fm,comp_angle);
                                    if kk==1
                                        Sp_f=nan(numel(sp),numel(idx_ping));
                                        Compensation_f=nan(numel(sp),numel(idx_ping));
                                        f_vec=nan(numel(sp),numel(idx_ping));
                                    end
                                    if numel(sp)==size(Sp_f,1)
                                        Sp_f(:,kk)=sp;
                                        Compensation_f(:,kk)=cp;
                                        f_vec(:,kk)=f;
                                    else
                                        idx_rem=union(idx_rem,kk);
                                    end
                                    set(load_bar_comp.progress_bar, 'Value',kk);
                                end

                                diff_ts = mean(abs(Sp_f+Compensation_f - th_ts(:)),1,'omitnan');

                                idx_rem_angles = find(diff_ts >= maxdBDiff1);

                                idx_rem = union(idx_rem,idx_rem_angles);

                                Sp_f(:,idx_rem)=[];

                                Compensation_f(:,idx_rem)=[];
                                f_vec(:,idx_rem)=[];
                                f_corr(idx_rem)=[];
                                freq_vec_new=f_vec(:,1);
                                along_s = AlongAngle_sph(idx_keep);
                                along_s(idx_rem) = [];
                                across_s = AcrossAngle_sph(idx_keep);
                                across_s(idx_rem) = [];

                                BeamWidthAlongship=nan(1,size(f_vec,1));
                                BeamWidthAthwartship=nan(1,size(f_vec,1));
                                offset_Alongship=nan(1,size(f_vec,1));
                                offset_Athwartship=nan(1,size(f_vec,1));
                                peak=nan(1,size(f_vec,1));
                                exitflag=nan(1,size(f_vec,1));
                                pt_used=cell(1,size(f_vec,1));
                                BeamWidthAlongship_th = interp1(cal_struct.Frequency,cal_struct.BeamWidthAlongship_th,freq_vec_new,int_meth,ext_meth);
                                BeamWidthAthwartship_th = interp1(cal_struct.Frequency,cal_struct.BeamWidthAthwartship_th,freq_vec_new,int_meth,ext_meth);

                                set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',size(f_vec,1), 'Value',0);
                                load_bar_comp.progress_bar.setText(sprintf('Processing BeamWidth estimation Frequency %.0fkHz',layer_obj.Transceivers(uui).Config.Frequency/1e3));
                                bw = mean([BeamWidthAlongship_th(:), BeamWidthAthwartship_th(:)],2);

                                f_corr = 1;
                                for tt=1:size(f_vec,1)
                                    [offset_Alongship(tt), BeamWidthAlongship(tt), offset_Athwartship(tt), BeamWidthAthwartship(tt), pt_used{tt}, peak(tt), exitflag(tt)]...
                                        =fit_beampattern(Sp_f(tt,:), across_s.*f_corr, along_s.*f_corr,maxdBDiff2,bw(tt));
                                    set(load_bar_comp.progress_bar,'Value',tt);
                                end

                                idx_angle_rm = sqrt((BeamWidthAlongship_th'-BeamWidthAlongship).^2)>faBW/4|...
                                    sqrt((BeamWidthAthwartship_th'-BeamWidthAthwartship).^2)>psBW/4|...
                                    exitflag~=1|...
                                    cellfun(@numel,pt_used)<=100;

                                if all(idx_angle_rm)
                                    dlg_perso(main_figure,'','Could not estimated EBA properly for any frequencies in the band...');
                                else
                                    BeamWidthAlongship_tmp = interp1(freq_vec_new(~idx_angle_rm),BeamWidthAlongship(~idx_angle_rm)',cal_fm.Frequency,int_meth,ext_meth);
                                    BeamWidthAthwartship_tmp = interp1(freq_vec_new(~idx_angle_rm),BeamWidthAthwartship(~idx_angle_rm)',cal_fm.Frequency,int_meth,ext_meth);

                                    AngleOffsetAlongship_tmp = interp1(freq_vec_new(~idx_angle_rm), offset_Alongship(~idx_angle_rm)',cal_fm.Frequency,int_meth,ext_meth);
                                    AngleOffsetAthwartship_tmp = interp1(freq_vec_new(~idx_angle_rm), offset_Athwartship(~idx_angle_rm)',cal_fm.Frequency,int_meth,ext_meth);

                                    BeamWidthAlongship_tmp(idx_high_sd) = nan;
                                    BeamWidthAthwartship_tmp(idx_high_sd) = nan;
                                    AngleOffsetAlongship_tmp(idx_high_sd) = nan;
                                    AngleOffsetAthwartship_tmp(idx_high_sd) = nan;

                                    plot(ax_bw,cal_fm.Frequency/1e3,BeamWidthAlongship_tmp,'color',[0 0.6 0],'linewidth',1,'linestyle','-');
                                    plot(ax_bw,cal_fm.Frequency/1e3,BeamWidthAthwartship_tmp,'color',[0.2 0.2 0.2],'linewidth',1,'linestyle','-');
                                    legend(ax_bw,'Measured Alongship Beamwidth','Theoritical Alongship Beamwidth','Measured Athwardship Beamwidth','Theoritical Athwardship Beamwidth');

                                    if~isempty(path_out)
                                        print(ts_fig,fullfile(path_out,generate_valid_filename(['gf_f_' freq_str '.png'])),'-dpng','-r300');
                                    end


                                    choice=question_dialog_fig(main_figure,'Calibration',sprintf('Do you want to save those results for Channel %s',layer_obj.ChannelID{uui}),'opt',{'Yes' 'No'},'timeout',t_out,'default_answer',1);

                                    % Handle response
                                    switch choice
                                        case 'Yes'
                                            cal_fm.BeamWidthAlongship = BeamWidthAlongship_tmp ;
                                            cal_fm.BeamWidthAthwartship = BeamWidthAthwartship_tmp;

                                            cal_fm.AngleOffsetAlongship = AngleOffsetAlongship_tmp;
                                            cal_fm.AngleOffsetAthwartship = AngleOffsetAthwartship_tmp;
                                            save_bool(uui) = true;
                                    end
                                end
                        end
                end

                cal_fm_tot{uui} = cal_fm;
                cal_fm_tot{uui}.nb_echoes = sum(idx_keep,'all','omitnan');
                cal_fm_tot{uui}.central_echoes_angle = on_axis;
                cal_fm_tot{uui}.nb_central_echoes = size(TS_f,2);
                cal_fm_tot{uui}.depth = mean(trans_obj.get_transducer_depth(new_region.Idx_ping));
                cal_fm_tot{uui}.sphere_range_av = mean(trans_obj.ST.Target_range(idx_keep_sec));
                cal_fm_tot{uui}.sphere_range_std = std(trans_obj.ST.Target_range(idx_keep_sec));
                cal_fm_tot{uui}.sphere_ts = th_ts;
                cal_fm_tot{uui}.sphere_type = sphere_type;
                cal_fm_tot{uui}.up_or_down_cast= direction;

            case 'CW'

                ts_values = Sp_sph(idx_keep_sec) + compensation(idx_keep_sec);
                mean_ts_on_axis = 10*log10(mean(10.^(ts_values/10)));
                std_ts_on_axis = std(ts_values);
                max_ts_on_axis = max(ts_values);

                % plot up the on-axis TS values
                fig_ts=new_echo_figure(main_figure,'Name', sprintf('%s %.0f kHz On-axis sphere TS',freq_str,Freq/1e3),'Tag', sprintf('On-axis sphere TS'));
                ax1=axes(fig_ts,'units','normalized','position',[0.05 0.05 0.9 0.4]);
                boxplot(ax1,ts_values);
                ax2=axes(fig_ts,'units','normalized','outerposition',[0.05 0.55 0.9 0.4]);
                histogram(ax2,ts_values);
                xlabel(ax2,'TS (dB re 1 m^2)')
                ylabel(ax1,'TS (dB re 1 m^2)')
                title(ax2,['On axis TS values for ' num2str(numel(ts_values)) ' targets']);

                if~isempty(path_out)
                    print(fig_ts,fullfile(path_out,generate_valid_filename(['on_axis_ts_' freq_str '.png'])),'-dpng','-r300');
                end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Produce plots and output text

                % The calibration results
                oa = num2str(on_axis);
                for ifi=1:length(fid)
                    if fid(ifi)>=0
                        fprintf(fid(ifi),['\nMean ts within ' oa ' deg of centre = ' num2str(mean_ts_on_axis) ' dB\n']);
                        fprintf(fid(ifi),['Std of ts within ' oa ' deg of centre = ' num2str(std_ts_on_axis) ' dB\n']);
                        fprintf(fid(ifi),['Maximum TS within ' oa ' deg of centre = ' num2str(max_ts_on_axis) ' dB\n']);
                        fprintf(fid(ifi),['Number of echoes within ' oa ' deg of centre = ' num2str(numel(ts_values)) '\n']);
                        fprintf(fid(ifi),['On axis TS from beam fitting = ' num2str(peak_ts) ' dB\n\n']);
                    end
                end

                old_cal=trans_obj.get_transceiver_cw_cal();
                outby=nan(1,length(onAxisMethod));
                for k=1:length(onAxisMethod)
                    if strcmp(onAxisMethod{k}, 'max')
                        outby(k) = cal_cw_tot.sphere_ts(uui) - max_ts_on_axis;
                    elseif strcmp(onAxisMethod{k}, 'mean')
                        outby(k) = cal_cw_tot.sphere_ts(uui) - mean_ts_on_axis;
                    elseif strcmp(onAxisMethod{k}, 'beam fitting')
                        outby(k) = cal_cw_tot.sphere_ts(uui) - peak_ts;
                    end
                    for ifi=1:length(fid)
                        if fid(ifi)>=0
                            if outby(k) > 0
                                fprintf(fid(ifi),['Hence Ex60 is reading ' num2str(outby(k)) ' dB too low (' onAxisMethod{k} ' method)\n']);
                            else
                                fprintf(fid(ifi),['Hence Ex60 is reading ' num2str(abs(outby(k))) ' dB too high (' onAxisMethod{k} ' method)\n']);
                            end
                            fprintf(fid(ifi),['So add ' num2str(-outby(k)/2) ' dB to G_o (' onAxisMethod{k} ' method)\n']);
                            fprintf(fid(ifi),['G_o from .raw file is ' num2str(gain) ' dB\n']);
                            fprintf(fid(ifi),['So the calibrated G_o = ' num2str(old_cal.G0-outby(k)/2) ' dB (' onAxisMethod{k} ' method)\n\n']);
                        end
                    end
                end
                for ifi=1:length(fid)
                    if fid(ifi)>=0
                        fprintf(fid(ifi),['Mean sphere range = ' num2str(mean(trans_obj.ST.Target_range(idx_keep_sec))) ...
                            ' m, std = ' num2str(std(trans_obj.ST.Target_range(idx_keep_sec))) ' m\n\n']);
                    end
                end

                switch lower(BeamType)
                    case 'single-beam'

                    otherwise
                        fig_bp=plot_bp(AcrossAngle_sph,AlongAngle_sph,Sp_sph+outby(1),idx_keep,strcmpi(trans_obj.Mode,'CW'));
                        if~isempty(path_out)&&~isempty(fig_bp)
                            print(fig_bp,fullfile(path_out,generate_valid_filename(['bp_contour_plot_' freq_str '.png'])),'-dpng','-r300');
                        end

                        % Do a plot of the compensated and uncompensated echoes at a selection of
                        % angles, similar to what one can get from the Simrad calibration program

                        fig=plotBeamSlices(AcrossAngle_sph(idx_keep),AlongAngle_sph(idx_keep),Sp_sph(idx_keep),outby(1),(faBW + psBW)/2, faBW, psBW, peak_ts, 1/2);

                        if~isempty(path_out)&&~isempty(fig)
                            print(fig,fullfile(path_out,generate_valid_filename(['slices_' freq_str '.png'])),'-dpng','-r300');
                        end
                end
                % The Sa correction is a value that corrects for the received pulse having
                % less energy in it than that nominal, transmitted pulse. The formula for
                % Sv  includes a term -10log10(Teff) (where Teff is the
                % effective pulse length). We don'thave Teff, so need to calculate it. We
                % do have Tnom (the nominal pulse length), or a theoritical Teff and just need to scale Tnom so
                % that it gives the same result as the integral of Teff:
                %
                % Teff = Tnom * sa_corr_lin
                % sa_corr_lin = Teff / Tnom
                % sa_corr_lin = Int(dt) / (Pmax * Tnom)
                %  where P is the power measurements throughout the echo,
                %  Pmax is the max power in the echo, and dt the time
                %  between P measurements. This is simply the ratio of the area under the
                %  nominal pulse and the area under the actual pulse.
                %
                % For the EK60/80, dt = Tnom/Np (it samples Np times every pulse length)
                % So, sa_corr_lin = Sum(P * Tnom) / (Np * Pmax * Tnom)
                %     sa_corr_lin = Sum(P) / (Np * Pmax)
                %
                % Correction factor is excpected to be in dB, and
                % furthermore is used as (10log10(Tnom) + 2 * Sa). Hence
                % Sa = 0.5 * 10log10(sa_corr_lin)

                % Work in the linear domain to calculate the scale factor to convert the
                % nominal pulse length into the effective pulse length


                sig_pulse=zeros(1,2*Np);
                sig_pulse(floor(Np/2)+rem(Np,2)+1:floor(Np/2)+Np+rem(Np,2))=sim_pulse(:)';
                %absorption_new = mean(Power_norm(idx_keep_sec))/sum(abs(sim_pulse).^2);

                st_sig_tmp=trans_obj.get_st_sig('power');

                norm_pow=cellfun(@(x) x/max(x),st_sig_tmp(idx_keep_sec),'un',0);
                sum_pow=cellfun(@sum,norm_pow);

                sa_corr_lin = mean(sum_pow)/sum(abs(sim_pulse).^2,'omitnan');
                % And convert that to dB, taking account of how this ratio is used as 2Sa
                % everywhere (i.e., it needs to be halved after converting to dB).

                sa_correction = 5 * log10(sa_corr_lin);
                %sa_correction_new = 5 * log10(absorption_new);
                tp = ((1:numel(sig_pulse))-1)*trans_obj.get_params_value('SampleInterval',1)*1e3;

                ff=new_echo_figure(main_figure,'Name',sprintf('%s: Pulse Comparison',freq_str_disp),'Tag',sprintf('Pulse Comparison'));
                ax=axes(ff,'nextplot','add','box','on');
                ax.XAxis.TickLabelFormat='%.3fms';
                ax.XAxis.Exponent = 0;
                cellfun(@(x) plot(((1:numel(x))-1)*trans_obj.get_params_value('SampleInterval',1)*1e3,x,'k'),norm_pow);
                plot(ax,tp,abs(sig_pulse.^2),'r','linewidth',2);
                grid(ax,'on');
                xlim(ax,[0 tp(end)]);
                xlabel(ax,'Time');
                ylabel(ax,'Normalized Power');

                if~isempty(path_out)
                    print(ff,fullfile(path_out,generate_valid_filename(['pulse_comparison_' freq_str '.png'])),'-dpng','-r300');
                end

                % Calculate the RMS fit to the beam model
                fit_out_to = rmsOutTo * (faBW+psBW)/2; % fit out to rmsOutTo of the beamangle
                id = find(phi <= fit_out_to & idx_keep);
                beam_model = peak_ts - compensation;
                rms_fit = sqrt( mean( ( (Sp_sph(id) - beam_model(id))/2 ).^2 ) );

                cal_cw_tot.SACORRECT(uui)=sa_correction;
                cal_cw_tot.G0(uui)=old_cal.G0-outby(strcmp(onAxisMethod,'mean'))/2;

                cal_cw_tot.AngleOffsetAlongship(uui)=offset_fa-trans_obj.Config.AngleOffsetAlongship;
                cal_cw_tot.AngleOffsetAthwartship(uui)=offset_ps-trans_obj.Config.AngleOffsetAthwartship;

                cal_cw_tot.BeamWidthAlongship(uui)=faBW;
                cal_cw_tot.BeamWidthAthwartship(uui)=psBW;
                cal_cw_tot.EQA(uui)=estimate_eba(faBW,psBW);

                cal_cw_tot.RMS(uui) = rms_fit;
                cal_cw_tot.nb_echoes(uui) = sum(idx_keep,'all','omitnan');
                cal_cw_tot.central_echoes_angle(uui) = on_axis;
                cal_cw_tot.nb_central_echoes(uui) = numel(ts_values);
                cal_cw_tot.depth(uui) = mean(trans_obj.get_transducer_depth(new_region.Idx_ping));
                cal_cw_tot.sphere_range_av(uui) = mean(trans_obj.ST.Target_range(idx_keep_sec));
                cal_cw_tot.sphere_range_std(uui) = std(trans_obj.ST.Target_range(idx_keep_sec));
                cal_cw_tot.sphere_type{uui} = sphere_type;
                cal_cw_tot.up_or_down_cast{uui} = direction;


                for ifi=1:length(fid)
                    if fid(ifi)>=0
                        % Print out some more cal results
                        fprintf(fid(ifi),['So sa correction = ' num2str(sa_correction) ' dB\n']);
                        fprintf(fid(ifi),['(the effective pulse length = ' num2str(sa_corr_lin) ' * nominal pulse length)\n\n']);

                        fprintf(fid(ifi),['Fore/aft beamwidth = ' num2str(faBW) ' degrees\n']);
                        fprintf(fid(ifi),['Fore/aft offset = ' num2str(offset_fa-trans_obj.Config.AngleOffsetAlongship) ' degrees (to be subtracted from angles)\n']);
                        fprintf(fid(ifi),['Port/stbd beamwidth = ' num2str(psBW) ' degrees\n']);
                        fprintf(fid(ifi),['Port/stbd offset = ' num2str(offset_ps-trans_obj.Config.AngleOffsetAthwartship) ' degrees (to be subtracted from angles)\n']);
                        fprintf(fid(ifi),['New EBA estimated at = ' num2str(cal_cw_tot.EQA(uui)) ' dB\n']);
                        fprintf(fid(ifi),['Results obtained from ' num2str(numel(Sp_sph(id))) ' sphere echoes\n']);
                        fprintf(fid(ifi),['Using c = ' num2str(mean_ss) ' m/s\n']);
                        fprintf(fid(ifi),['Using absorption = ' num2str(abs_app*1e3) ' dB/km\n\n']);
                        fprintf(fid(ifi),['RMS of fit to beam model out to ' num2str(fit_out_to) ' degrees = ' num2str(rms_fit) ' dB\n\n']);
                    end
                end

                choice=question_dialog_fig(main_figure,'Calibration',sprintf('Do you want to save those results for Channel %s',freq_str_disp),'opt',{'Yes' 'No'},'timeout',t_out);

                % Handle response
                switch choice
                    case 'Yes'
                        save_bool(uui) = true;
                end

        end

        if~isempty(path_out)
            fclose(fid(2));
        end
        cal_keys_tmp = layer_obj.layer_cal_to_db('cal_cw',cal_cw_tot,'cal_fm',cal_fm_tot,'save_bool',save_bool,'idx_trans',uui);
        cal_keys = [cal_keys cal_keys_tmp];
        layer_obj.EnvData.CTD.ori = ori_tt;
        layer_obj.EnvData.SVP.ori = ori_tts;
    end

    curr_disp.setField('singletarget');
    cids_up=union({'main','mini'},curr_disp.SecChannelIDs,'stable');
    display_bottom(main_figure,cids_up);
    clear_regions(main_figure,{},cids_up);
    display_regions(cids_up);
    set_alpha_map(main_figure,'main_or_mini',cids_up,'update_bt',0);

    display_tracks(main_figure);
    update_st_tracks_tab(main_figure,'histo',1,'st',1);
    update_environnement_tab(main_figure,0);
end

if any(save_bool)
    disp('Summary table for the CW calibration:');

    [pathtofile,~]=layer_obj.get_path_files();
    pathtofile=unique(pathtofile);

    pathtofile(cellfun(@isempty,pathtofile))=[];

    fileN=fullfile(pathtofile{1},'cal_echo.db');
    dbconn = connect_to_db(fileN);

    if isempty(dbconn)
        file_sql=fullfile(whereisEcho,'config','db','cal_db.sql');
        create_ac_database(fileN,file_sql,1,false);
        dbconn = connect_to_db(fileN);
    end


    if ~isempty(dbconn)

        db_to_cal_struct_cell = translate_db_to_cal_cell();
        db_to_params_struct_cell = translate_db_to_params_cell();

        cal_str = strjoin(cellfun(@(x) sprintf('cal.%s AS %s',x{1},x{2}),db_to_cal_struct_cell,'UniformOutput',false),', ');
        params_str = strjoin(cellfun(@(x) sprintf('params.%s AS %s',x{1},x{2}),db_to_params_struct_cell,'UniformOutput',false),', ');
        idx_cal = intersect(idx_cal,find(save_bool));

        sql_cmd = sprintf(['SELECT %s, %s ,'...
            'soundprop.sound_propagation_absorption AS abs, soundprop.sound_propagation_velocity AS soundspeed '...
            'FROM t_calibration AS cal, t_parameters AS params, t_sound_propagation as soundprop '...
            'WHERE cal.calibration_pkey in (%s) AND cal.calibration_channel_ID in (%s) AND cal.calibration_parameters_key = params.parameters_pkey AND cal.calibration_sound_propagation_key = soundprop.sound_propagation_pkey'],...
            cal_str,params_str,strjoin(compose('%d',cal_keys),', '),strjoin(cellfun(@(x) sprintf('''%s''',x),layer_obj.ChannelID(idx_cal),'UniformOutput',false),', '));


        %         sql_cmd = sprintf(['SELECT %s, %s ,'...
        %             'soundprop.sound_propagation_absorption AS abs, soundprop.sound_propagation_velocity AS soundspeed '...
        %             'FROM t_calibration AS cal, t_parameters AS params, t_sound_propagation as soundprop '...
        %             'WHERE cal.calibration_channel_ID in (%s) AND cal.calibration_parameters_key = params.parameters_pkey AND cal.calibration_sound_propagation_key = soundprop.sound_propagation_pkey'],...
        %             cal_str,params_str,strjoin(cellfun(@(x) sprintf('''%s''',x),layer_obj.ChannelID(idx_cal(save_bool)),'UniformOutput',false),', '));

        %sql_cmd = 'SELECT * FROM t_calibration AS cal'

        summary_table = dbconn.fetch(sql_cmd);
        disp(summary_table);
        summary_file=fullfile(path_out,sprintf('cw_cal_summary_%s.csv',t_cal_str));
        writetable(summary_table,summary_file);
        dbconn.close();

        if any(deep_cal)
            for uui = idx_cal
                if deep_cal(uui) && strcmpi(layer_obj.Transceivers(uui).Mode,'CW')

                    fig_cal = new_echo_figure(main_figure,'UiFigureBool',true,'Name',sprintf('Deep calibration %s',layer_obj.ChannelID{uui}),'Tag',sprintf('Deep calibration %s',layer_obj.ChannelID{uui}));

                    uigl = uigridlayout(fig_cal,[1,4]);
                    ax_abs = uiaxes(uigl,'YDir','reverse','NextPlot','add','Box','on');
                    grid(ax_abs,'on');ylabel(ax_abs,'Depth(m)');xlabel(ax_abs,'Absorption(dB/km)');

                    ax_ss = uiaxes(uigl,'YDir','reverse','NextPlot','add','Box','on');
                    grid(ax_ss,'on'); grid(ax_abs,'on');xlabel(ax_ss,'Soundspeed(m/s)');

                    ax_g0 = uiaxes(uigl,'YDir','reverse','NextPlot','add','Box','on');
                    grid(ax_g0,'on'); grid(ax_g0,'on');xlabel(ax_g0,'Gain(dB)');

                    ax_sac = uiaxes(uigl,'YDir','reverse','NextPlot','add','Box','on');
                    grid(ax_sac,'on'); grid(ax_sac,'on');xlabel(ax_sac,'s_{a,corr}(dB)');

                    dcast = {'upcast' 'downcast'};
                    lgd = {};

                    for uid = 1:numel(dcast)
                        idx_t = find(strcmpi(summary_table.CID,layer_obj.ChannelID{uui})&strcmpi(summary_table.up_or_down_cast,dcast{uid}));

                        [dd,idx_s] = sort(summary_table.depth(idx_t));

                        if ~isempty(idx_t)
                            plot(ax_sac,summary_table.SACORRECT(idx_t(idx_s)),dd);
                            plot(ax_g0,summary_table.G0(idx_t(idx_s)),dd);
                            plot(ax_abs,summary_table.abs(idx_t(idx_s)),dd);
                            plot(ax_ss,summary_table.soundspeed(idx_t(idx_s)),dd);

                            lgd  = [lgd dcast{uid}];
                        end
                    end

                    ax_sac.XLim = ax_sac.XLim +[-0.05 0.05];
                    ax_g0.XLim = ax_g0.XLim +[-0.5 0.5];

                    if ~isempty(lgd)
                        legend(ax_abs,lgd);
                        if~isempty(path_out)
                            exportgraphics(uigl,fullfile(path_out,generate_valid_filename(['cw_cal_results' freq_str '.png'])),'Resolution',300);
                        end
                    end

                end
            end
        end

    end

end


hide_status_bar(main_figure);
loadEcho(main_figure);


    function bpfig=plot_bp(ac_a, al_a, sp,idx_keep,corr_bool)

        [xg,yg]=meshgrid(-psBW:.1:psBW,...
            -faBW:.1:faBW);

        c_l=cax(1):2:cax(2);

        zg = griddata(ac_a(idx_keep), al_a(idx_keep), sp(idx_keep), xg, yg);

        bpfig=new_echo_figure(main_figure,'Name',sprintf('%s Beam Pattern',freq_str_disp),'Tag',sprintf('Beam Pattern'),'Toolbar','esp3','MenuBar','esp3');
        ax_bp=axes(bpfig,'nextplot','add','outerposition',[0 0 0.5 1],'box','on');
        contourf(ax_bp,xg,yg,zg,c_l)
        hold(ax_bp,'on');
        plot(ax_bp,ac_a(idx_keep),al_a(idx_keep),'+','MarkerSize',1,'MarkerEdgeColor',[.5 .5 .5])
        axis(ax_bp,'equal')
        grid(ax_bp,'on');
        colormap(ax_bp,cmap)
        shading(ax_bp,'flat');
        xlabel(ax_bp,'Port/stbd angle (\circ)')
        ylabel(ax_bp,'Fore/aft angle (\circ)')
        title(ax_bp,sprintf('%.0f kHz',Freq/1e3))
        clim(ax_bp,cax)

        for r_p = 2:4
            x = psBW/r_p * cos(0:.01:2*pi);
            y = faBW/r_p * sin(0:.01:2*pi);
            plot(ax_bp,x, y, 'k')
        end

        comp = simradBeamCompensation(faBW, psBW, al_a, ac_a);

        zg_comp = griddata(ac_a(idx_keep), al_a(idx_keep), sp(idx_keep)+comp(idx_keep), xg, yg);

        ax_bp=axes(bpfig,'nextplot','add','outerposition',[0.5 0 0.5 1],'box','on');
        surf(ax_bp,xg,yg, zg)
        if corr_bool
            surf(ax_bp,xg,yg, zg_comp)
        end
        axis(ax_bp,'equal');
        grid(ax_bp,'on');
        colormap(ax_bp,cmap)
        shading(ax_bp,'flat');
        cb=colorbar(ax_bp);
        cb.UIContextMenu=[];
        xlabel(ax_bp,'Port/stbd angle (\circ)')
        ylabel(ax_bp,'Fore/aft angle (\circ)')
        zlabel(ax_bp,'TS (dB re 1m^2)')
        title(ax_bp,sprintf('%.0f kHz',Freq/1e3))
        clim(ax_bp,cax)
        view(ax_bp,[-37.5 30]);
        drawnow;
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function fig_out=plotBeamSlices(ac_a, al_a, sp, outby, trimTo, faBW, psBW, peak_ts, tol)
        % Produce a plot of the sphere echoes and the fitted beam pattern at 4
        % slices (0 45, 90, and 135 degrees) through the beam.
        %

        fig_out=new_echo_figure(main_figure,'Name',sprintf('%s: Beam slice plot',freq_str_disp),'Tag',sprintf('Beam slice plot'));
        x = -trimTo:.1:trimTo;

        % 0 degrees
        ax_1=axes(fig_out,'position',[0.05 0.55 0.4 0.4],'nextplot','add');
        id = find(abs(ac_a) < tol);
        plot(ax_1,al_a(id), sp(id)+ outby(1),'k.')

        plot(ax_1,x, peak_ts+ outby(1)  - simradBeamCompensation(faBW, psBW, x, 0), 'k');

        % 45 degrees. Needs special treatment to get angle off axis from the fa and
        % ps angles
        ax_2=axes(fig_out,'position',[0.55 0.55 0.4 0.4],'nextplot','add');
        id = find(abs(ac_a - al_a) < tol);
        [phi_x,~] = simradAnglesToSpherical(al_a(id), ac_a(id));
        ss = sp(id) + outby(1);

        id = find(abs(phi_x) <= trimTo);
        plot(ax_2,phi_x(id), ss(id), 'k.')

        [phi_x,~] = simradAnglesToSpherical(x, x);
        beam = peak_ts+ outby(1) - simradBeamCompensation(faBW, psBW, x, x);
        id = find(abs(phi_x) <= trimTo);
        plot(ax_2,phi_x(id), beam(id), 'k');

        % 90 degrees
        ax_3=axes(fig_out,'position',[0.05 0.1 0.4 0.4],'nextplot','add');
        id = find(abs(al_a) < tol);
        plot(ax_3,ac_a(id), sp(id)+ outby(1),'k.')

        plot(ax_3,x, peak_ts + outby(1) - simradBeamCompensation(faBW, psBW, 0, x), 'k');
        xlabel(ax_3,'Angle (\circ) off normal')
        ylabel(ax_3,'TS (dB re 1m^2)')

        % 135 degrees. Needs special treatment to get angle off axis from the fa and
        % ps angles
        ax_4=axes(fig_out,'position',[0.55 0.1 0.4 0.4],'nextplot','add');
        id = find(abs(-ac_a - al_a) < tol);
        [phi_x,~] = simradAnglesToSpherical(al_a(id), ac_a(id));
        ss = sp(id) + outby(1);
        id = find(abs(phi_x) <= trimTo);
        plot(ax_4,phi_x(id), ss(id),'k.')

        [phi_x,~] = simradAnglesToSpherical(-x, x);
        beam = peak_ts + outby(1) - simradBeamCompensation(faBW, psBW, -x, x);
        id = find(abs(phi_x) <= trimTo);
        plot(ax_4,phi_x(id), beam(id), 'k');
        ax_t=[ax_1 ax_2 ax_3 ax_4];

        % Make the y-axis limits the same for all 4 subplots
        limits = [1000 -1000 1000 -1000];
        for it = 1:4
            lim = axis(ax_t(it));
            limits(1) = min(limits(1), lim(1));
            limits(2) = max(limits(2), lim(2));
            limits(3) = min(limits(3), lim(3));
            limits(4) = max(limits(4), lim(4));
        end

        % Expand the axis limits so that axis labels don't overlap
        limits(1) = limits(1) - .2; % x-axis, units of degrees
        limits(2) = limits(2) + .2; % x-axis, units of degrees
        limits(3) = limits(3) - 1; % y-axis, units of dB
        limits(4) = limits(4) + 1; % y-axis, units of dB
        for it = 1:4
            axis(ax_t(it),limits)
        end

        % Add a line to each subplot to indicate which angle the slice is for.
        % Work out the position for the ship schematic with angled line.
        angles = [0 45 90 135]; % angles of the four plots
        for it = 1:length(angles)
            pos = get(ax_t(it), 'Position');
            ax_b=axes('Position', [pos(1)+0.02*pos(3) pos(2)+0.7*pos(4) 0.2*pos(3) 0.2*pos(4)],'nextplot','add');
            plot_angle_diagram(angles(it),ax_b)
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function plot_angle_diagram(angle,ax_b)
        % Plots a little figure of the ship and an angled line on the given axes

        % The ship shape
        x = [0 1 1 .5 0 0];
        y = [0 0 2 2.5 2 0];
        plot(ax_b,x,y,'k')

        % The circle to represent the transducer
        theta = 0:.01:2.1*pi;
        r = 0.3;
        centre = [0.5 1.5];
        ll = 0.9;
        plot(ax_b,centre(1) + r*cos(theta), centre(2) + r*sin(theta), 'k')

        % The angled line
        switch angle
            case 0
                plot(ax_b,[centre(1) centre(1)], [centre(2)-ll centre(2)+ll], 'k', 'LineWidth', 2)
            case 45
                x = ll*cos(angle*pi/180);
                y = ll*sin(angle*pi/180);
                plot(ax_b,[centre(1)-x centre(1)+x] ,[centre(2)-y centre(2)+y], 'k', 'LineWidth', 2)
            case 90
                plot(ax_b,[centre(1)-ll centre(1)+ll], [centre(2) centre(2)], 'k', 'LineWidth', 2)
            case 135
                x = ll*cos(angle*pi/180);
                y = ll*sin(angle*pi/180);
                plot(ax_b,[centre(1)+x centre(1)-x] ,[centre(2)+y centre(2)-y], 'k', 'LineWidth', 2)
        end

        axis(ax_b,'equal');

        % The bottom of some figures get chopped off when removing the axis, so
        % extend the axis a little to prevent this
        set(ax_b, 'YLim', [-0.1 2.6])
        axis(ax_b,'off')

    end

    function idx_high=get_highest_target_per_ping(ST)
        pings=unique(ST.Ping_number);
        idx_high=zeros(size(ST.Ping_number));
        for uitp=1:numel(pings)
            id_p = find(pings(uitp) == ST.Ping_number);

            [~,id_max] = max(ST.TS_uncomp(id_p),[],'all','omitnan');
            idx_high(id_p(id_max))=1;
        end
    end

end
