function output_struct=CFAR_wc_features_detection(trans_obj,varargin)

p = inputParser;

addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addParameter(p,'thr_sv',-70,@isnumeric);
addParameter(p,'N_2D',20,@isnumeric);
addParameter(p,'N_3D',50,@isnumeric);
addParameter(p,'AR_min',1,@isnumeric);
addParameter(p,'Rext_min',25,@isnumeric);
addParameter(p,'stdR_min',2,@isnumeric);
addParameter(p,'numPing_min',8,@isnumeric);
addParameter(p,'median_filter_bool',true,@islogical);
addParameter(p,'beamAngle_min',-inf,@isnumeric);
addParameter(p,'beamAngle_max',inf,@isnumeric);
addParameter(p,'L',20,@isnumeric);
addParameter(p,'GC',4,@isnumeric);
addParameter(p,'DT',5,@isnumeric);
addParameter(p,'NBeams',1,@isnumeric);
addParameter(p,'NSamps',2,@isnumeric);
addParameter(p,'conn_2D',8,@isnumeric);
addParameter(p,'Gx',5,@isnumeric);
addParameter(p,'Gy',5,@isnumeric);
addParameter(p,'Gz',5,@isnumeric);
addParameter(p,'rm_specular',true,@islogical);
addParameter(p,'r_max',Inf,@isnumeric);
addParameter(p,'r_min',0,@isnumeric);
addParameter(p,'load_bar_comp',[]);
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
parse(p,trans_obj,varargin{:});

output_struct.done =  false;
output_struct.feature_struct = init_ft_struct(0);


thr_sv = p.Results.thr_sv;
N_2D = p.Results.N_2D;
N_3D = p.Results.N_3D;
AR_min = p.Results.AR_min;
Rext_min = p.Results.Rext_min;
stdR_min = p.Results.stdR_min;
L = p.Results.L;
GC = p.Results.GC;
DT = p.Results.DT;
NBeams = p.Results.NBeams;
NSamps = p.Results.NSamps;
conn_2D = p.Results.conn_2D;
Gx = p.Results.Gx;
Gy = p.Results.Gy;
Gz = p.Results.Gz;

if isempty(p.Results.reg_obj)
    idx_r=1:length(trans_obj.get_samples_range());
    idx_ping_tot=1:length(trans_obj.get_transceiver_pings());
    reg_obj=region_cl('Name','Temp','Idx_r',idx_r,'Idx_ping',idx_ping_tot);
else
    reg_obj=p.Results.reg_obj;
end

idx_ping_tot=reg_obj.Idx_ping;
idx_r=reg_obj.Idx_r;

range_tot = trans_obj.get_samples_range(idx_r);

if ~isempty(idx_r)
    idx_r(range_tot<p.Results.r_min|range_tot>p.Results.r_max)=[];
end

%trans_obj_range = trans_obj.get_samples_range(idx_r);

load_bar_comp = p.Results.load_bar_comp;
up_bar=~isempty(load_bar_comp);

if isempty(p.Results.reg_obj)
    reg_obj=region_cl('Idx_r',idx_r,'Idx_ping',idx_ping_tot);
else
    reg_obj=p.Results.reg_obj;
end
BeamAngularLimit = [p.Results.beamAngle_min p.Results.beamAngle_max];

if diff(BeamAngularLimit)<=0
    BeamAngularLimit= [];
end

idx_beam = trans_obj.get_idx_beams(BeamAngularLimit);

trans_obj.rm_feature_idx(idx_r,idx_ping_tot(1)-L:idx_ping_tot(end)+L,idx_beam);

nb_Beams = numel(idx_beam);
block_len = get_block_len(10,'cpu',p.Results.block_len);


block_size=max(min(ceil(block_len/numel(idx_r)/nb_Beams),numel(idx_ping_tot)),min(L,numel(idx_ping_tot)));

num_ite=ceil(numel(idx_ping_tot)/block_size);

if up_bar
    p.Results.load_bar_comp.progress_bar.setText('CFAR WC Feature detection');
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
end
[~,Np] = trans_obj.get_pulse_length();
min_specular_sample_buffer = 5*max(Np,[],'all','omitnan');
debug_disp = isdebugging;

fandir = 'across';
%idx_p = 1030:1040;
idx_p = 621:630;

if debug_disp && (isempty(idx_p)||any(ismember(idx_ping_tot,idx_p)))

    %         detection_mask_3D = false(size(detection_mask_pc));
    %         detection_mask_3D(ii) = true;

    curr_disp = curr_state_disp_cl();

    ff = new_echo_figure([],...
        'Name','CFAR detector',...
        'tag','wc_fan',...
        'UiFigureBool',true,...
        'Position',[0 0 1200 400]);
    esp3_obj = getappdata(groot,'esp3_obj');

    ff.Alphamap = esp3_obj.main_figure.Alphamap;
    uigl = uigridlayout(ff,[1 3]);
    wc_fan = create_wc_fan('wc_fig',uigl,'curr_disp',curr_disp);
    wc_fan_cfar = create_wc_fan('wc_fig',uigl,'curr_disp',curr_disp);
    wc_fan_cfar_pc = create_wc_fan('wc_fig',uigl,'curr_disp',curr_disp);
    %wc_fan_cfar_pc_3D = create_wc_fan('wc_fig',uigl,'curr_disp',curr_disp);

    wc_fan.gl_ax.Tag = 'Original data';
    wc_fan_cfar.gl_ax.Tag = 'After CFAR detector';
    wc_fan_cfar_pc.gl_ax.Tag = 'After CFAR detector and within-ping clustering';
    %wc_fan_cfar_pc_3D.gl_ax.Tag = 'After CFAR detector, withing-ping clustering and 3D clustering';
end

for ui=1:num_ite

    idx_ping = idx_ping_tot((ui-1)*block_size+1:min(ui*block_size,numel(idx_ping_tot)));
    idx_ping  = idx_ping(1)-L:idx_ping(end)+L;
    idx_ping(idx_ping<1) = [];
    idx_ping(idx_ping>numel(trans_obj.get_transceiver_pings())) = [];

    reg_temp=region_cl('Name','Temp','Idx_r',idx_r,'Idx_ping',idx_ping);

    [sv_SPB,idx_r,idx_ping,idx_beam,bad_data_mask,~,~,below_bot_mask,~]=trans_obj.get_data_from_region(reg_temp,...
        'BeamAngularLimit',BeamAngularLimit,...
        'field','svdenoised','alt_fields',{'sv' 'wc_data','img_intensity'},'intersect_only',1,...
        'regs',reg_obj);

    bot_s = trans_obj.get_bottom_idx(idx_ping,idx_beam);
    bot_s(bot_s == 1 ) = nan;

    min_bot  = min(bot_s,[],3,"omitnan");
    BeamAngleAthwartship=trans_obj.get_params_value('BeamAngleAthwartship',idx_ping,idx_beam);

    if p.Results.rm_specular
        specular_mask = idx_r >= min_bot-2*min_specular_sample_buffer./cosd(BeamAngleAthwartship) & idx_r <= min_bot + 4*min_specular_sample_buffer./cosd(BeamAngleAthwartship);
        %specular_mask = idx_r >= min_bot-min_specular_sample_buffer./cosd(BeamAngleAthwartship);
    else
        specular_mask =  false(size(sv_SPB));
    end

    sv_SPB_lin = db2pow_perso(sv_SPB);

    if p.Results.median_filter_bool
        sv_SPB_lin = medfilt3(sv_SPB_lin,[2*round(NSamps/2)+1 1 2*round(NBeams/2)+1]);
    end

    sv_SPB_lin(sv_SPB_lin < db2pow(thr_sv) | specular_mask | below_bot_mask) = nan;
    sv_SPB_lin(bad_data_mask) = nan;

    if p.Results.median_filter_bool
        sv_SPB_lin_med = sv_SPB_lin./median(sv_SPB_lin,3,"omitmissing");
        sv_SPB_lin(pow2db(sv_SPB_lin_med) < DT) = nan;
    end

    detection_mask = CFAR_detector(sv_SPB_lin,'L',L,'GC',GC,'DT',DT,'load_bar_comp',load_bar_comp);

    if ~any(detection_mask,'all')
        continue;
    end

    ClusterID = ping_clustering(detection_mask,'NBeams',NBeams,'NSamps',NSamps,'N_2D',N_2D,'conn',conn_2D,'load_bar_comp',load_bar_comp);

    detection_mask_pc = (detection_mask & ClusterID > 0);
    %detection_mask_pc = (detection_mask & ClusterN > N_2D);

    if isempty(detection_mask_pc)||~any(detection_mask_pc,'all')
        continue;
    end

    [roll_comp_bool,pitch_comp_bool,yaw_comp_bool,heave_comp_bool] = trans_obj.get_att_comp_bool();
    [data_struct,~] = trans_obj.get_xxx_ENH('data_to_pos',{'WC'},...
        'idx_ping',idx_ping,'idx_r',idx_r,'idx_beam',idx_beam,...
        'comp_angle',[false false],...
        'yaw_comp',yaw_comp_bool,...
        'roll_comp',roll_comp_bool,...
        'pitch_comp',pitch_comp_bool,...
        'heave_comp',heave_comp_bool,...
        'detection_mask',detection_mask_pc);

    ald = data_struct.WC.AlongDist;
    acd = data_struct.WC.AcrossDist;
    rr= data_struct.WC.Range;
    tt = data_struct.WC.Time;

    [nb_samples,nb_pings,~] = size(detection_mask_pc);

    ii = find(detection_mask_pc);
    iBeam = ceil(ii/(nb_samples*nb_pings));
    iPing = ceil((ii-(iBeam-1)*nb_samples*nb_pings)/nb_samples);
    iSample  = ii-(iBeam-1)*nb_samples*nb_pings-(iPing-1)*nb_samples;

    iPing = iPing + idx_ping(1) - 1;
    iSample = iSample + idx_r(1) - 1;

    sv = sv_SPB(ii);

    if debug_disp && (isempty(idx_p)||any(ismember(idx_ping,idx_p)))

        for ip = 1:numel(idx_p)
            if ismember(idx_p(ip),idx_ping)
                ipp = find(idx_p(ip) == idx_ping);
                disp_ping_wc_fan(wc_fan,trans_obj,'idx_ping',idx_p(ip),'curr_disp',curr_disp,'idx_r',idx_r,'fandir',fandir,'idx_beam',idx_beam);
                disp_ping_wc_fan(wc_fan_cfar,trans_obj,'idx_ping',idx_p(ip),'mask',detection_mask(:,ipp,:),'curr_disp',curr_disp,'idx_r',idx_r,'fandir',fandir,'idx_beam',idx_beam);
                disp_ping_wc_fan(wc_fan_cfar_pc,trans_obj,'idx_ping',idx_p(ip),'mask',detection_mask_pc(:,ipp,:),'curr_disp',curr_disp,'idx_r',idx_r,'fandir',fandir,'idx_beam',idx_beam);
                %             disp_ping_wc_fan(wc_fan_cfar_pc_3D,trans_obj,'idx_ping',idx_ping(ip),'mask',detection_mask_3D(:,ipp,:),'curr_disp',curr_disp,'idx_r',idx_r,'idx_beam',idx_beam);
                pause(0.5);
            end
        end
    end

    output_struct.feature_struct.E = [output_struct.feature_struct.E E.WC];
    output_struct.feature_struct.N = [output_struct.feature_struct.N N.WC];
    output_struct.feature_struct.H = [output_struct.feature_struct.H H.WC];
    output_struct.feature_struct.zone = [output_struct.feature_struct.zone zone.WC];
    output_struct.feature_struct.alongdist = [output_struct.feature_struct.alongdist ald];
    output_struct.feature_struct.acrossdist = [output_struct.feature_struct.acrossdist acd];
    output_struct.feature_struct.range = [output_struct.feature_struct.range rr];
    output_struct.feature_struct.time = [output_struct.feature_struct.time tt];
    output_struct.feature_struct.idx_r = [output_struct.feature_struct.idx_r iSample'];
    output_struct.feature_struct.idx_beam = [output_struct.feature_struct.idx_beam idx_beam(iBeam)'];
    output_struct.feature_struct.idx_ping = [output_struct.feature_struct.idx_ping iPing'];
    output_struct.feature_struct.sv = [output_struct.feature_struct.sv sv'];

    if up_bar
        set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',ui);
    end

end

x = output_struct.feature_struct.alongdist;
y = output_struct.feature_struct.acrossdist;
z = output_struct.feature_struct.H;

if ~isempty(x) && debug_disp
    loc1 = [x',y',-z'];
    ptCloud = pointCloud(loc1);
    figure()
    pcshow(ptCloud.Location,output_struct.feature_struct.sv)
    title('Point Cloud Clusters before 3D clustering');
    xlabel('Along distance');
    ylabel('Across distance');
    clim([thr_sv thr_sv+30]);
end

ClusterID = data_3D_clustering(x,y,z,'Gx',Gx,'Gy',Gy,'Gz',Gz,'N_3D',N_3D,'load_bar_comp',load_bar_comp);

R = sqrt(y.^2+z.^2);

cids = unique(ClusterID);
cids(cids==0) = [];

Rext = nan(size(cids));
Zext = nan(size(cids));
Hext = nan(size(cids));
stdR = nan(size(cids));
N_clust = nan(size(cids));
N_pings = nan(size(cids));
rem_ft = true;

if ~isempty(cids)
    for uic = 1:numel(cids)
        id = ClusterID == cids(uic);
        Rc = R(id);
        Rext(uic)  = range(Rc);
        Zext(uic) = range(z(id));
        Hext(uic) = range(sqrt(y(id).^2+x(id).^2));
        stdR(uic) =  std(sqrt(y(id).^2+z(id).^2));
        N_clust(uic) = sum(id);
        N_pings(uic) = numel(unique(output_struct.feature_struct.idx_ping(id)));
    end

    AR = Zext./Hext;

    cids_rem = cids(Rext<Rext_min | AR<AR_min | stdR < stdR_min| N_pings < p.Results.numPing_min);

    fprintf('Number of features after 3D clustering : %.0f\n',numel(Rext));
    fprintf('   Removing %.0f features from 3D R extent\n',sum(Rext<Rext_min));
    fprintf('   Removing %.0f features from 3D Aspect Ratio\n',sum(AR<AR_min));
    fprintf('   Removing %.0f features from 3D R std\n',sum(stdR < stdR_min));
    fprintf('   Removing %.0f features from number of pings\n',sum(N_pings < p.Results.numPing_min));

    id_rem = ClusterID ==  0 | ismember(ClusterID,cids_rem);
    [~,~,tmp]  =unique(ClusterID);

    output_struct_final = output_struct;

    output_struct_final.feature_struct.id = tmp';
    output_struct_final_rem = output_struct_final;

    ff = fieldnames(output_struct_final.feature_struct);

    for uif = 1:numel(ff)
        if numel(output_struct_final.feature_struct.(ff{uif})) == numel(id_rem)
            output_struct_final.feature_struct.(ff{uif})(id_rem) = [];
            output_struct_final_rem.feature_struct.(ff{uif})(~id_rem) = [];
        end
    end
    [cids_final,~,tmp] = unique(output_struct_final.feature_struct.id);

    fprintf('Final number of features : %.0f\n',numel(cids_final));
    if ~isempty(cids_final)
        output_struct_final.feature_struct.id = tmp';

        if ~isempty(x) && debug_disp
            x_final = output_struct_final.feature_struct.alongdist;
            y_final = output_struct_final.feature_struct.acrossdist;
            z_final = output_struct_final.feature_struct.H;
            loc1 = [x_final',y_final',-z_final'];
            ptCloud = pointCloud(loc1);
            figure()
            pcshow(ptCloud.Location,output_struct_final.feature_struct.sv)
            xlabel('Along distance');
            ylabel('Across distance');
            title('Final Point Cloud Clusters (Sv)')
            clim([thr_sv thr_sv+30]);
            figure()
            pcshow(ptCloud.Location,output_struct_final.feature_struct.id)
            title('Final Point Cloud Clusters')
            xlabel('Along distance');
            ylabel('Across distance');

            x_final = output_struct_final_rem.feature_struct.alongdist;
            y_final = output_struct_final_rem.feature_struct.acrossdist;
            z_final = output_struct_final_rem.feature_struct.H;
            loc1 = [x_final',y_final',-z_final'];
            ptCloud = pointCloud(loc1);
            figure()
            pcshow(ptCloud.Location,output_struct_final_rem.feature_struct.sv)
            xlabel('Along distance');
            ylabel('Across distance');
            title('Removed Point Cloud Clusters (Sv)')
            clim([thr_sv thr_sv+30]);
            figure()
            pcshow(ptCloud.Location,output_struct_final_rem.feature_struct.id)
            title('Removed Point Cloud Clusters')
            xlabel('Along distance');
            ylabel('Across distance');
        end
        %         end
        rem_ft = false;
    end
end
FT = output_struct_final.feature_struct;
id_s = unique(FT.id);

if ~isempty(trans_obj.Features)
    ii = max([trans_obj.Features(:).ID])+1;
else
    ii = 1;
end
if up_bar
    p.Results.load_bar_comp.progress_bar.setText('Saving features');
end
for uid  = id_s
    
    idd = FT.id == uid;
    
    feature_obj = feature_3D_cl( 'ID',uid,...
                                 'E',FT.E(idd),...
                                 'N',FT.N(idd),...
                                 'H',FT.H(idd),...
                                 'Time',FT.time(idd),...
                                 'Alongdist',FT.alongdist(idd),...
                                 'Acrossdist',FT.acrossdist(idd),...
                                 'Zone',FT.zone(idd),...
                                 'Idx_r',FT.idx_r(idd),...
                                 'Idx_ping',FT.idx_ping(idd),...
                                 'Idx_beam',FT.idx_beam(idd),...
                                 'Range',FT.range(idd),...
                                 'Sv',FT.sv(idd)...
                                 );

    if ~isempty(feature_obj)
        trans_obj.add_feature(feature_obj);
        ii = ii+1;
    end

%     trans_obj.Data.replace_sub_data_v2(dataMat,'feature_sv','idx_r',idx_r,'idx_ping',idx_ping,'idx_beam',idx_beam);
%     trans_obj.Data.replace_sub_data_v2(dataMatid,'feature_id','idx_r',idx_r,'idx_ping',idx_ping,'idx_beam',idx_beam);

 end

if rem_ft
    p.Results.load_bar_comp.progress_bar.setText('No features after 3D clustering');
end
output_struct_final.done = true;
output_struct  = output_struct_final;
