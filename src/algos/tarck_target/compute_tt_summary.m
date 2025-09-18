function tt_summary = compute_tt_summary(layer_obj,idx_trans,dres)
comp_ts_f = false;
load_bar_comp = [];


trans_obj = layer_obj.Transceivers(idx_trans);

tt_summary = init_tt_summary(0,0);

ST = trans_obj.ST;
if isempty(ST)||isempty(ST.TS_comp)
    return;
end
tracks = trans_obj.Tracks;
if isempty(tracks)||isempty(tracks.target_id)
    return;
end

reg_wc = trans_obj.create_WC_region(...
    'y_min',0,...
    'y_max',inf,...
    'Type','Data',...
    'Ref','Transducer',...
    'Cell_w',10,...
    'Cell_h',10,...
    'Cell_w_unit','pings',...
    'Cell_h_unit','meters');

[data_struct,no_nav] = reg_wc.get_region_3D_echoes(trans_obj,'field','singletarget','other_fields',{},'comp_angle',[true true]);

data_struct = data_struct.singletarget;

nb_tracks = numel(tracks.target_id);

%[cal_fm_cell,~]=layer_obj.get_fm_cal([]);
cal_fm_trans = trans_obj.get_transceiver_fm_cal();
nb_depth_bins  = ceil(range(data_struct.H)/dres);
dd = linspace(min(data_struct.H),max(data_struct.H),nb_depth_bins+1);

tt_summary = init_tt_summary(nb_depth_bins,nb_tracks);
%reg_obj = trans_obj.create_track_regs('uid',tracks.uid,'Add',false);

if ~isempty(tracks)
    for idd = 1:nb_depth_bins
        id_keep = find(~(data_struct.H<dd(idd) | data_struct.H >= dd(idd+1)));
        %reg_bin = trans_obj.create_WC_region('Ref','surface','y_min',dd(idd),'y_max',dd(idd+1));
        % id_keep = intersect(idx_t,idx_d);
        for k=1:nb_tracks
            idx_targets = tracks.target_id{k};
            idx_targets = intersect(idx_targets,id_keep);

            if isempty(idx_targets)
                continue;
            end

            [~,id] = sort(data_struct.Time(idx_targets));
            idx_targets = idx_targets(id);

            tt_summary.track_id(idd,k) = tracks.id(k);
            tt_summary.nb_targets(idd,k) = numel(idx_targets);
            tt_summary.TS_mean(idd,k) = pow2db(mean(db2pow(data_struct.data_disp(idx_targets))));
            tt_summary.TS_std(idd,k) = pow2db(std(db2pow(data_struct.data_disp(idx_targets))));
            tt_summary.time(idd,k) = mean(data_struct.Time(idx_targets));
            tt_summary.E(idd,k) = mean(data_struct.E(idx_targets));
            tt_summary.N(idd,k) = mean(data_struct.N(idx_targets));
            tt_summary.depth(idd,k) = mean(data_struct.H(idx_targets));
            tt_summary.along_pos(idd,k) = mean(diff(data_struct.AlongDist(idx_targets)));
            tt_summary.across_pos(idd,k) = mean(diff(data_struct.AcrossDist(idx_targets)));
            tt_summary.range(idd,k) = mean(diff(data_struct.Range(idx_targets)));

            if numel(idx_targets)>1
                tt_summary.V_E(idd,k) = mean(diff(data_struct.E(idx_targets))./(diff(data_struct.Time(idx_targets))*24*60*60));
                tt_summary.V_N(idd,k) = mean(diff(data_struct.N(idx_targets))./(diff(data_struct.Time(idx_targets))*24*60*60));
                tt_summary.V_H(idd,k) = mean(diff(data_struct.H(idx_targets))./(diff(data_struct.Time(idx_targets))*24*60*60));

                tt_summary.V_E_2(idd,k) = mean(diff(data_struct.E(idx_targets([1 end])))./(diff(data_struct.Time(idx_targets([1 end])))*24*60*60));
                tt_summary.V_N_2(idd,k) = mean(diff(data_struct.N(idx_targets([1 end])))./(diff(data_struct.Time(idx_targets([1 end])))*24*60*60));
                tt_summary.V_H_2(idd,k) = mean(diff(data_struct.H(idx_targets([1 end])))./(diff(data_struct.Time(idx_targets([1 end])))*24*60*60));

                tt_summary.V_along(idd,k) = mean(diff(data_struct.AlongDist(idx_targets))./(diff(data_struct.Time(idx_targets))*24*60*60));
                tt_summary.V_across(idd,k) = mean(diff(data_struct.AcrossDist(idx_targets))./(diff(data_struct.Time(idx_targets))*24*60*60));
                tt_summary.V_r(idd,k) = mean(diff(data_struct.Range(idx_targets))./(diff(data_struct.Time(idx_targets))*24*60*60));

                tt_summary.V_along_2(idd,k) = mean(diff(data_struct.AlongDist(idx_targets([1 end]))')./(diff(data_struct.Time(idx_targets([1 end])))*24*60*60));
                tt_summary.V_across_2(idd,k) = mean(diff(data_struct.AcrossDist(idx_targets([1 end]))')./(diff(data_struct.Time(idx_targets([1 end])))*24*60*60));
                tt_summary.V_r_2(idd,k) = mean(diff(data_struct.Range(idx_targets([1 end]))')./(diff(data_struct.Time(idx_targets([1 end])))*24*60*60));
            end
            if comp_ts_f && abs(tt_summary.V_H_2 - tt_summary.V_H)<dv_thr
                st_struct = structfun(@(x) x(idx_targets),trans_obj.ST,'UniformOutput',false);
                [TS_f_tmp,f_vec_temp,~,~]=trans_obj.TS_f_from_region(st_struct,'cal',cal_fm_trans,'load_bar_comp',load_bar_comp,'mode','max_reg','win_fact',1);

                tt_summary.F_vec{k} = f_vec_temp;
                tt_summary.TS_f{k} = squeeze(pow2db(mean(db2pow(TS_f_tmp),1,'omitmissing')))';
            end
        end
    end
    dt = 1/2*60*60/(24*60*60);
    dv_thr = 0.025;
    db_res = 0.25;
    vel_res = 0.01;
    [folder,~,~] = fileparts(layer_obj.Filename{1});
    uifig = display_tt_summary(data_struct,tt_summary,tracks,...
        'dt',dt,...
        'dres',dres,...
        'dv_thr',dv_thr,...
        'db_res',db_res,...
        'vel_res',vel_res,....
        'v_thr_h_max',0,...
        'v_thr_abs_max',0.5,...
        'ts_thr',-55,...
        'save_bool',true,'folder',folder);
end
end
