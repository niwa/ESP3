function output_struct=school_3d_features_detection(trans_obj,varargin)

p = inputParser;
filt_3D_methods={'None','Median','Gaussian' ,'Mean'};
addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addParameter(p,'thr_sv',-70,@isnumeric);
addParameter(p,'N_3D',50,@isnumeric);
addParameter(p,'numPing_min',8,@isnumeric);
addParameter(p,'filt_3D','None',@(x) ismember(x,filt_3D_methods));
addParameter(p,'beamAngle_min',-inf,@isnumeric);
addParameter(p,'beamAngle_max',inf,@isnumeric);
addParameter(p,'rm_specular',true,@islogical);
addParameter(p,'NBeams',1,@isnumeric);
addParameter(p,'NSamps',2,@isnumeric);
addParameter(p,'Gx',5,@isnumeric);
addParameter(p,'Gy',5,@isnumeric);
addParameter(p,'Gz',5,@isnumeric);
addParameter(p,'DT',3,@isnumeric);
addParameter(p,'Hext_min',50,@isnumeric);
addParameter(p,'Zext_min',10,@isnumeric);
addParameter(p,'r_max',Inf,@isnumeric);
addParameter(p,'r_min',0,@isnumeric);
addParameter(p,'geo_ref','ship',@(x) ismember(lower(x),{'geo' 'ship'}));
addParameter(p,'load_bar_comp',[]);
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
addParameter(p,'denoised',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
parse(p,trans_obj,varargin{:});

output_struct.done =  false;
output_struct.feature_struct = init_ft_struct(0);

thr_sv = p.Results.thr_sv;
N_3D = p.Results.N_3D;
NBeams = p.Results.NBeams;
NSamps = p.Results.NSamps;
Hext_min = p.Results.Hext_min;
Zext_min = p.Results.Zext_min;
numPing_min = p.Results.numPing_min;
Gx = p.Results.Gx;
Gy = p.Results.Gy;
Gz = p.Results.Gz;
DT = p.Results.DT;

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

if isempty(idx_r) || isempty(idx_ping_tot) || isempty(idx_beam)
    output_struct.done = true;
    return;
end

trans_obj.rm_feature_idx(idx_r,idx_ping_tot,idx_beam);

nb_Beams = numel(idx_beam);
block_len = get_block_len(10,'cpu',p.Results.block_len);


block_size=min(ceil(block_len/numel(idx_r)/nb_Beams),numel(idx_ping_tot));

num_ite=ceil(numel(idx_ping_tot)/block_size);

if up_bar
    p.Results.load_bar_comp.progress_bar.setText('3D School detection');
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
end
[~,Np] = trans_obj.get_pulse_length();
min_specular_sample_buffer = 5*max(Np,[],'all','omitnan');
debug_disp = isdebugging;


for ui=1:num_ite

    idx_ping = idx_ping_tot((ui-1)*block_size+1:min(ui*block_size,numel(idx_ping_tot)));

    reg_temp=region_cl('Name','Temp','Idx_r',idx_r,'Idx_ping',idx_ping);

    if p.Results.denoised
        ff = 'svdenoised';
    else
        ff = 'sv';
    end

    [sv_SPB,idx_r,idx_ping,idx_beam,bad_data_mask,bad_trans_vec,~,below_bot_mask,~]=trans_obj.get_data_from_region(reg_temp,...
        'BeamAngularLimit',BeamAngularLimit,...
        'field',ff,'alt_fields',{'sv' 'wc_data','img_intensity'},'intersect_only',1,...
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

    switch p.Results.filt_3D
        case 'Median'
            sv_SPB_lin = medfilt3(sv_SPB_lin,[2*round(NSamps/2)+1 1 2*round(NBeams/2)+1]);
        case 'Mean'
            sv_SPB_lin = imboxfilt3(sv_SPB_lin,[2*round(NSamps/2)+1 1 2*round(NBeams/2)+1]);
        case 'Gaussian'
            sv_SPB_lin = imgaussfilt3(sv_SPB_lin);
    end

    sv_SPB_lin(sv_SPB_lin < db2pow(thr_sv) | specular_mask | below_bot_mask) = nan;
    sv_SPB_lin(bad_data_mask,:) = nan;
    sv_SPB_lin(:,bad_trans_vec,:) = nan;
    
    switch p.Results.filt_3D
        case 'Median'
            sv_SPB_lin_filt = sv_SPB_lin./median(sv_SPB_lin,3,"omitmissing");
        case 'Mean'
            sv_SPB_lin_filt = sv_SPB_lin./mean(sv_SPB_lin,3,"omitmissing");
        case 'Gaussian'
            sv_SPB_lin_filt = sv_SPB_lin./mean(sv_SPB_lin.*shiftdim(gausswin(size(sv_SPB_lin,3),0.5),-2),3,"omitmissing");
        otherwise
            sv_SPB_lin_filt = ones(size(sv_SPB_lin))*db2pow(DT);
    end

    sv_SPB_lin(pow2db(sv_SPB_lin_filt) < DT) = nan;
    sv_data = pow2db(sv_SPB_lin);

    detection_mask = sv_data > thr_sv & sv_SPB > thr_sv;

    if ~any(detection_mask,'all')
        continue;
    end

    [roll_comp_bool,pitch_comp_bool,yaw_comp_bool,heave_comp_bool] = trans_obj.get_att_comp_bool();

    [data_struct,no_nav] = trans_obj.get_xxx_ENH('data_to_pos',{'WC'},...
        'idx_ping',idx_ping,'idx_r',idx_r,'idx_beam',idx_beam,...
        'comp_angle',[false false],...
        'yaw_comp',yaw_comp_bool,...
        'roll_comp',roll_comp_bool,...
        'pitch_comp',pitch_comp_bool,...
        'heave_comp',heave_comp_bool,...
        'detection_mask',detection_mask);


    sv = sv_SPB(detection_mask);

    fields = fieldnames(data_struct.WC);
    for uif = 1:numel(fields)
        if isfield(output_struct.feature_struct,fields{uif})
            output_struct.feature_struct.(fields{uif}) = [output_struct.feature_struct.(fields{uif}) data_struct.WC.(fields{uif})];
        end
    end

    output_struct.feature_struct.Sv = [output_struct.feature_struct.Sv sv'];

    if up_bar
        set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',ui);
    end

end

switch lower(p.Results.geo_ref)
    case 'geo'
        x = output_struct.feature_struct.E;
        y = output_struct.feature_struct.N;
    case 'ship'
        x = output_struct.feature_struct.AlongDist;
        y = output_struct.feature_struct.AcrossDist;
end
        z = output_struct.feature_struct.H;

if ~isempty(x) && debug_disp
    loc1 = [x',y',-z'];
    ptCloud = pointCloud(loc1);
    figure()
    pcshow(ptCloud.Location,output_struct.feature_struct.Sv)
    title('Point Cloud Clusters before 3D clustering');
    xlabel('Along distance');
    ylabel('Across distance');
    clim([thr_sv thr_sv+30]);
end

if isempty(x)
    return;
end

ClusterID = data_3D_clustering(x,y,z,'Gx',Gx,'Gy',Gy,'Gz',Gz,'N_3D',N_3D,'block_len',block_len,'load_bar_comp',load_bar_comp);

cids = unique(ClusterID);
cids(cids==0) = [];

Zext = nan(size(cids));
Hext = nan(size(cids));
N_clust = nan(size(cids));
N_pings = nan(size(cids));
rem_ft = true;

if up_bar
    p.Results.load_bar_comp.progress_bar.setText('Filtering features');
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(cids), 'Value',0);
end

if ~isempty(cids)
    for uic = 1:numel(cids)

        id = ClusterID == cids(uic);
        Zext(uic) = range(z(id));
        Hext(uic) = range(sqrt(y(id).^2+x(id).^2));
        N_clust(uic) = sum(id);
        N_pings(uic) = numel(unique(output_struct.feature_struct.Idx_ping(id)));

        if up_bar && rem(round(numel(cids)/100),round(uic/100)) == 0
            set(p.Results.load_bar_comp.progress_bar,'Value',uic);
        end
    end
    
    cids_rem = cids(Hext<Hext_min| Zext<Zext_min| N_pings < numPing_min);

    fprintf('Number of features after 3D clustering : %.0f\n',numel(Zext));
    fprintf('   Removing %.0f features from 3D H extent\n',sum(Zext<Zext_min));
    fprintf('   Removing %.0f features from 3D Z extent\n',sum(Hext<Hext_min));
    fprintf('   Removing %.0f features from number of pings\n',sum(N_pings < numPing_min));

    id_rem = ClusterID ==  0 | ismember(ClusterID,cids_rem);

    output_struct.feature_struct.id = ClusterID;
    output_struct_rem = output_struct;

    ff = fieldnames(output_struct.feature_struct);

    for uif = 1:numel(ff)
        if numel(output_struct.feature_struct.(ff{uif})) == numel(id_rem)
            output_struct.feature_struct.(ff{uif})(id_rem) = [];
            output_struct_rem.feature_struct.(ff{uif})(~id_rem) = [];
        end
    end
    [cids_final,~,tmp] = unique(output_struct.feature_struct.id);
    output_struct.feature_struct.id = tmp';
    
    fprintf('Final number of features : %.0f\n',numel(cids_final));
    if ~isempty(cids_final)
        output_struct.feature_struct.id = tmp';

        if ~isempty(x) && debug_disp
            x_final = output_struct.feature_struct.AlongDist;
            y_final = output_struct.feature_struct.AcrossDist;
            z_final = output_struct.feature_struct.H;
            loc1 = [x_final',y_final',-z_final'];
            ptCloud = pointCloud(loc1);
            figure()
            pcshow(ptCloud.Location,output_struct.feature_struct.Sv)
            xlabel('Along distance');
            ylabel('Across distance');
            title('Final Point Cloud Clusters (Sv)')
            clim([thr_sv thr_sv+30]);
            figure()
            pcshow(ptCloud.Location,output_struct.feature_struct.id)
            title('Final Point Cloud Clusters')
            xlabel('Along distance');
            ylabel('Across distance');

            x_final = output_struct_rem.feature_struct.AlongDist;
            y_final = output_struct_rem.feature_struct.AcrossDist;
            z_final = output_struct_rem.feature_struct.H;
            loc1 = [x_final',y_final',-z_final'];
            ptCloud = pointCloud(loc1);
            figure()
            pcshow(ptCloud.Location,output_struct_rem.feature_struct.Sv)
            xlabel('Along distance');
            ylabel('Across distance');
            title('Removed Point Cloud Clusters (Sv)')
            clim([thr_sv thr_sv+30]);
            figure()
            pcshow(ptCloud.Location,output_struct_rem.feature_struct.id)
            title('Removed Point Cloud Clusters')
            xlabel('Along distance');
            ylabel('Across distance');
        end
        %         end

        rem_ft = false;
    end
end

id_s = unique(output_struct.feature_struct.id);

if ~isempty(trans_obj.Features)
    ii = max([trans_obj.Features(:).ID])+1;
else
    ii = 1;
end

if up_bar
    p.Results.load_bar_comp.progress_bar.setText('Saving features');
end

for uid  = id_s
    
    idd = output_struct.feature_struct.id == uid;
    
    feature_obj = feature_3D_cl( 'ID',uid,...
                                 'E',output_struct.feature_struct.E(idd),...
                                 'N',output_struct.feature_struct.N(idd),...
                                 'H',output_struct.feature_struct.H(idd),...
                                 'Time',output_struct.feature_struct.Time(idd),...
                                 'Alongdist',output_struct.feature_struct.AlongDist(idd),...
                                 'Acrossdist',output_struct.feature_struct.AcrossDist(idd),...
                                 'Zone',output_struct.feature_struct.Zone(idd),...
                                 'Idx_r',output_struct.feature_struct.Idx_r(idd),...
                                 'Idx_ping',output_struct.feature_struct.Idx_ping(idd),...
                                 'Idx_beam',output_struct.feature_struct.Idx_beam(idd),...
                                 'Range',output_struct.feature_struct.Range(idd),...
                                 'Sv',output_struct.feature_struct.Sv(idd)...
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

output_struct.done = true;

