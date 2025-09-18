function uifig = display_tt_summary(data_struct,tt_summary,tracks,varargin)

    p = inputParser;

    addRequired(p,'tt_summary',@isstruct);
    addRequired(p,'data_struct',@isstruct);
    addRequired(p,'tracks',@isstruct);
    addParameter(p,'dt',30*60/(24*60*60),@(x) isnumeric(x) && x>0);
    addParameter(p,'dres',5,@(x) isnumeric(x) && x>0);
    addParameter(p,'db_res',0.5,@(x) isnumeric(x) && x>0);
    addParameter(p,'vel_res',0.05,@(x) isnumeric(x) && x>0);
    addParameter(p,'dv_thr',0.02,@(x) isnumeric(x) && x>0);
    addParameter(p,'ts_thr',-55,@(x) isnumeric(x));
    addParameter(p,'v_thr_h_max',0,@(x) isnumeric(x));
    addParameter(p,'v_thr_abs_max',1,@(x) isnumeric(x) && x>0);
    addParameter(p,'cax',[-55 -35],@(x) isnumeric(x));
    addParameter(p,'nb_targets_thr',1,@(x) isnumeric(x) && x>0);
    addParameter(p,'save_bool',true,@islogical);
    addParameter(p,'folder','',@ischar);
    
    parse(p,data_struct,tt_summary,tracks,varargin{:});

    dres = p.Results.dres;
    db_res = p.Results.db_res;
    dv_thr = p.Results.dv_thr;
    vel_res = p.Results.vel_res;
    ts_thr = p.Results.ts_thr;
    v_thr_h_max = p.Results.v_thr_h_max;
    v_thr_abs_max = p.Results.v_thr_abs_max;
    nb_targets_thr = p.Results.nb_targets_thr;
    cax = p.Results.cax;
    dt = p.Results.dt;

    nb_time_bins  = ceil(range(tt_summary.time(tt_summary.time>0))/dt);
    tt = linspace(min(tt_summary.time(tt_summary.time>0),[],'omitmissing'),max(tt_summary.time(tt_summary.time>0),[],'omitmissing'),nb_time_bins+1);
    

    if ~isempty(~isfolder(p.Results.folder)) && ~isfolder(p.Results.folder) && p.Results.save_bool
        mkdir(folder);
    end

    nb_comp_max = 5;
    AIC = inf(1,nb_comp_max);
    GMModels = cell(1,nb_comp_max);
    options = statset('MaxIter',50);
    for k = 1:nb_comp_max   
        GMModels{k} = fitgmdist(tt_summary.TS_mean(:),k,'Options',options);
        if GMModels{k}.Converged
            AIC(k)= GMModels{k}.AIC;
        else
            AIC(k) = inf;
            break;
        end
    end

        [minAIC,numComponents] = min(AIC);

        % xpdf = linspace(min(tt_summary.TS_mean(:),[],"all"),max(tt_summary.TS_mean(:),[],"all"),100)';
        % figure();histogram(tt_summary.TS_mean(:),100,'Normalization','pdf');hold on;plot(xpdf,pdf(GMModels{numComponents},xpdf));
        % figure();plot(xpdf,cdf(GMModels{numComponents},xpdf));
        dt = p.Results.dt;
        uifig_time = new_echo_figure([],'UiFigureBool',true,'Name','Tracked Target summary: evolution with time','Tag','tt_summary_time');
        uigl_time  = uigridlayout(uifig_time,[1,1]);
        ax_time = uiaxes(uigl_time,'NextPlot','add','Box','on','XGrid','on','YGrid','on');
        xlabel(ax_time,'Time');
        ylabel(ax_time,'nb_tracks');

        for uic = 1:numComponents+1
            idx_keep = ~isnan(tt_summary.TS_mean(:)) & tt_summary.time(:)>0;
            if uic<=numComponents
            idx_keep = tt_summary.TS_mean(:)>=GMModels{numComponents}.mu(uic)-GMModels{numComponents}.Sigma(uic) & ...
                tt_summary.TS_mean(:)<=GMModels{numComponents}.mu(uic)+GMModels{numComponents}.Sigma(uic) & ...
                idx_keep;
            end

            id_time = round(tt_summary.time(idx_keep)/dt);
            t0 = min(tt_summary.time(idx_keep));
            id_time = id_time - min(id_time)+1;
            
            nb_tracks = accumarray(id_time,tt_summary.track_id(idx_keep),[],@numel);
            time_t = t0 + dt*(0:numel(nb_tracks)-1);
            if uic<=numComponents
                lgd{uic} = sprintf('Component %d: Mean %.1fdB; Std: %.1fdB',uic,GMModels{numComponents}.mu(uic),GMModels{numComponents}.Sigma(uic));
            else
                lgd{uic} = 'All tracks';
            end

            plot(ax_time,datetime(time_t,'ConvertFrom','datenum'),nb_tracks);
        end
        
        legend(ax_time,lgd);

    ms_ori =  10;
    ms = ms_ori.*...
        sqrt(db2pow(data_struct.data_disp - cax(1)));
    ms(ms>50*ms_ori) = 50*ms_ori;
    cmap_struct = init_cmap('ek60');

    yy = (min(tt_summary.depth(:)):dres:max(tt_summary.depth(:)))';
    yl = [min(yy(:)) max(yy(:))]+[-dres/2 +dres/2];
    vel_dir = {'V_E_2' 'V_N_2' 'V_H_2' 'TS_mean'};
    disp_str = {'East Velocity (m/s)' 'North Velocity (m/s)' 'Down Velocity (m/s)' 'TS(db re 1m^-2)'};
    lay_col = {2 2 2 1};
    lay_row = {1 2 3 3};
    res = {vel_res vel_res vel_res/5 db_res};
    pdf_win = {'box' 'box' 'box' 'box'};
    pdf_win = {'gauss' 'gauss' 'gauss' 'gauss'};

    for uih = 1:numel(vel_dir)
        xx.(vel_dir{uih}) = (prctile(tt_summary.(vel_dir{uih})(:),2):res{uih}:prctile(tt_summary.(vel_dir{uih})(:),98))';
    end

    for uit = 1:nb_time_bins

        idx_disp = tt_summary.TS_mean>ts_thr & tt_summary.nb_targets>nb_targets_thr & ...
            tt_summary.V_H_2<v_thr_h_max &...
            abs(tt_summary.V_H_2)<v_thr_abs_max &...
            abs(tt_summary.V_E_2)<v_thr_abs_max &...
            abs(tt_summary.V_N_2)<v_thr_abs_max &...
            tt_summary.V_H<v_thr_h_max &...
            abs(tt_summary.V_H)<v_thr_abs_max &...
            abs(tt_summary.V_E)<v_thr_abs_max &...
            abs(tt_summary.V_N)<v_thr_abs_max & ...
            abs(tt_summary.V_E_2 - tt_summary.V_E)<dv_thr & ...
            abs(tt_summary.V_N_2 - tt_summary.V_N)<dv_thr & ...
            abs(tt_summary.V_H_2 - tt_summary.V_H)<dv_thr & ...
            (tt_summary.time>=tt(uit) & tt_summary.time<tt(uit+1));

        uifig(uit) = new_echo_figure([],'UiFigureBool',true,'Name',sprintf('Tracked Target summary (%s to %s)',datestr(tt(uit)),datestr(tt(uit+1))),'Tag','tt_summary');
        uigl  = uigridlayout(uifig(uit),[3,3]);

        ax_velocities = uiaxes(uigl,'NextPlot','add','Box','on','XGrid','on','YGrid','on');
        ax_velocities.Layout.Row = [1 2];
        ax_velocities.Layout.Column = 1;
        E_h = plot(ax_velocities,tt_summary.V_E_2(idx_disp)*100,tt_summary.depth(idx_disp),'o','Color',[0.6 0 0]);
        plot(ax_velocities,tt_summary.V_E(idx_disp)*100,tt_summary.depth(idx_disp),'.','Color',[0.6 0 0]);
        N_h = plot(ax_velocities,tt_summary.V_N_2(idx_disp)*100,tt_summary.depth(idx_disp),'o','Color',[0 0.6 0]);
        plot(ax_velocities,tt_summary.V_N(idx_disp)*100,tt_summary.depth(idx_disp),'.','Color',[0 0.6 0]);
        H_h = plot(ax_velocities,tt_summary.V_H_2(idx_disp)*100,tt_summary.depth(idx_disp),'o','Color',[0 0 0]);
        plot(ax_velocities,tt_summary.V_H(idx_disp)*100,tt_summary.depth(idx_disp),'.','Color',[0 0 0]);
        legend([E_h,N_h,H_h],{'East velocity' 'North velocity' 'Down velocity'});
        ylabel(ax_velocities,'Depth(m)');
        xlabel(ax_velocities,'Velocity(cm/s)');
        ax_velocities.YDir = "reverse";


        for uih = 1:numel(vel_dir)
            ax_tmp = uiaxes(uigl,'NextPlot','add','Box','on','XGrid','on','YGrid','on','ZGrid','on');
            ax_tmp.Layout.Row = lay_row{uih};
            ax_tmp.Layout.Column = lay_col{uih};
            [pdf_vel,x_mat_vel,y_mat_vel]=pdf_2d_perso(tt_summary.(vel_dir{uih})(idx_disp),tt_summary.depth(idx_disp),xx.(vel_dir{uih}),yy,pdf_win{uih});
            cax_tmp=[prctile(pdf_vel(pdf_vel>0),20) prctile(pdf_vel(pdf_vel>0),98)];
            ph = pcolor(ax_tmp,x_mat_vel,y_mat_vel,pdf_vel);
                ph.FaceColor = 'Flat';
                ph.FaceAlpha = 'Flat';
                ph.LineStyle = 'none';
                ph.EdgeColor = cmap_struct.col_grid;
                ph.AlphaData = single(pdf_vel>=cax_tmp(1));
                ylim(ax_tmp,yl);
            if diff(cax_tmp)>0
                ax_tmp.CLim = cax_tmp;
            end
            %plot(ax_tmp,tt_summary.TS_mean(idx_disp),tt_summary.depth(idx_disp),'ro');
            ylabel(ax_tmp,'Depth(m)');
            xlabel(ax_tmp,disp_str{uih});
            ax_tmp.YDir = "reverse";
            colormap(ax_tmp,cmap_struct.cmap);
        end


        id_tracks = unique(tt_summary.track_id(idx_disp));
        idx_tracks = ismember(tracks.id,id_tracks);

        idx_disp_st = cell2mat(tracks.target_id(idx_tracks)');

        ax_scatter = uiaxes(uigl,'NextPlot','add','Box','on','XGrid','on','YGrid','on','ZGrid','on');
        ax_scatter.Layout.Row = [1 3];
        ax_scatter.Layout.Column = 3;
        scatter3(ax_scatter,data_struct.E(idx_disp_st),data_struct.N(idx_disp_st),data_struct.H(idx_disp_st),ms(idx_disp_st),data_struct.data_disp(idx_disp_st)',...
            'AlphaData',single(data_struct.data_disp(idx_disp_st)>ts_thr),'MarkerFaceColor','Flat','MarkerEdgeColor','flat');
        zlabel(ax_scatter,'Depth(m)');
        xlabel(ax_scatter,'Easting (m)');
        ylabel(ax_scatter,'Northing (m)');
        colorbar(ax_scatter);
        colormap(ax_scatter,cmap_struct.cmap);
        %scatter3(ax_scatter,0,0,0,ms_ori,'black','filled');
        view(ax_scatter,[45 30]);
        ax_scatter.CLim = cax;
        ax_scatter.ZDir = "reverse";
        daspect(ax_scatter,[1 1 1]);

        pause(1);

    end
    if isfolder(p.Results.folder) && p.Results.save_bool
        for uit = 1:nb_time_bins
            exportapp(uifig(uit), fullfile(p.Results.folder,sprintf('tt_summary_velovities_%.0f.png',uit)));
        end
    end

end
