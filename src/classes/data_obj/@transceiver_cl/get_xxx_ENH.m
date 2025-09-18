function [data_struct,no_nav] = get_xxx_ENH(trans_obj,varargin)
%[E,N,H,zone,no_nav,Across_dist_struct,Along_dist_struct,Range_struct,Time_struct,data_struct.Idx_ping.] = get_xxx_ENH(trans_obj,varargin)
p  =  inputParser;
nb_beams = max(trans_obj.Data.Nb_beams,[],'omitnan');
idx_beam_def =  1:nb_beams;
[roll_comp_bool,pitch_comp_bool,yaw_comp_bool,heave_comp_bool] = trans_obj.get_att_comp_bool();

addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addParameter(p,'full_attitude',attitude_nav_cl.empty(),@(x) isa(x,'attitude_nav_cl'));
addParameter(p,'full_navigation',gps_data_cl.empty(),@(x) isa(x,'gps_data_cl'));
addParameter(p,'dt_att',0,@isnumeric);
addParameter(p,'data_to_pos',{'bottom'},@iscell);
addParameter(p,'roll_comp',roll_comp_bool,@islogical);
addParameter(p,'pitch_comp',pitch_comp_bool,@islogical);
addParameter(p,'heave_comp',heave_comp_bool,@islogical);
addParameter(p,'yaw_comp',yaw_comp_bool,@islogical);
addParameter(p,'comp_angle',[true true],@(x) islogical(x)||isnumeric(x));
addParameter(p,'idx_ping',trans_obj.get_transceiver_pings(),@isnumeric);
addParameter(p,'idx_beam',idx_beam_def,@isnumeric);
addParameter(p,'idx_r',trans_obj.get_transceiver_samples(),@isnumeric);
addParameter(p,'detection_mask',[],@islogical);
addParameter(p,'no_nav',false,@islogical);
addParameter(p,'georef_bool',true,@islogical);
addParameter(p,'transceiver_depth_bool',true,@islogical);
addParameter(p,'load_bar_comp',[]);
parse(p,trans_obj,varargin{:});


data_struct = init_data_struct(p.Results.data_to_pos);
no_nav =  false;


comp_angle=p.Results.comp_angle;


if ~isempty(p.Results.idx_ping)
    idx_ping  =  p.Results.idx_ping;
else
    idx_ping  =  trans_obj.get_transceiver_pings();
end
idx_ping (idx_ping>numel(trans_obj.get_transceiver_pings())) = numel(trans_obj.get_transceiver_pings());

if isempty(idx_ping)
    return;
end

if ~isempty(p.Results.idx_r)
    idx_r  =  p.Results.idx_r;
else
    idx_r  =  trans_obj.get_transceiver_samples();
end

if isempty(idx_r)
    return;
end

if ~isempty(p.Results.idx_beam)
    idx_beam  =  p.Results.idx_beam;
else
    nb_beams = max(trans_obj.Data.Nb_beams,[],'omitnan');
    idx_beam =  1:nb_beams;
end

if isempty(idx_ping)
    return;
end


if numel(trans_obj.AttitudeNavPing.Pitch)>=max(idx_ping)
    pitch_geo = trans_obj.AttitudeNavPing.Pitch(idx_ping);
    roll_geo = trans_obj.AttitudeNavPing.Roll(idx_ping);
    yaw_geo = trans_obj.AttitudeNavPing.Yaw(idx_ping);
    heave_geo = trans_obj.AttitudeNavPing.Heave(idx_ping);
    heading_geo = trans_obj.AttitudeNavPing.Heading(idx_ping);
else
    if ~p.Results.no_nav
        print_errors_and_warnings([],'warning','No Attitude Data, we''ll pretend there''s no motion.');
    end
    pitch_geo = zeros(size(idx_ping));
    roll_geo = zeros(size(idx_ping));
    yaw_geo = zeros(size(idx_ping));
    heave_geo = zeros(size(idx_ping));
    heading_geo = [];
end


if ~isempty(trans_obj.GPSDataPing.Lat) && ~p.Results.no_nav
    lat = trans_obj.GPSDataPing.Lat(idx_ping);
    long = trans_obj.GPSDataPing.Long(idx_ping);
    %dist = trans_obj.GPSDataPing.Dist(idx_ping);
else
    lat = zeros(size(idx_ping));
    long = zeros(size(idx_ping));
    %dist = zeros(size(idx_ping));
end

if isempty(heading_geo)||all(isnan(heading_geo))||all(heading_geo == -999)
    attitude_heading=att_heading_from_gps(trans_obj.GPSDataPing,2);
    heading_geo=resample_data_v2(attitude_heading.Heading,attitude_heading.Time,trans_obj.GPSDataPing.Time,'Type','Angle');
    heading_geo = heading_geo(idx_ping);
end

if isempty(heading_geo)||all(isnan(heading_geo))||all(heading_geo == -999)
    if ~p.Results.no_nav
        print_errors_and_warnings([],'warning','No Heading Data, we''ll pretend to go north');
    end
    heading_geo = zeros(size(idx_ping));
end

if all(lat  ==  0)||all(isnan(lat))
    if ~p.Results.no_nav
        print_errors_and_warnings([],'warning','No navigation data, we will not move...');
    end
    %dist = zeros(size(heading_geo));
    easting = zeros(size(heading_geo));%
    northing = zeros(size(heading_geo));
    no_nav =  true;
    zone_tt = -60;
else
    [easting,northing,zone_tt] = ll2utm(lat,long);
    zone_tt(isnan(zone_tt)) = mode(zone_tt(~isnan(isnan(zone_tt))),'all');
end

if isscalar(zone_tt)
    zone_tt = repmat(zone_tt,1,size(northing,2));
end

if isempty(pitch_geo)
    if ~p.Results.no_nav
        disp('No motion Data, we''ll pretend everythings flat');
    end
    roll_geo=zeros(size(northing));
    pitch_geo=zeros(size(northing));
    heave_geo=zeros(size(northing));
    yaw_geo=zeros(size(northing));
end

if size(heading_geo,1)>1
    heading_geo=heading_geo';
end

if size(roll_geo,1)>1
    roll_geo=roll_geo';
    pitch_geo=pitch_geo';
    heave_geo=heave_geo';
    yaw_geo=yaw_geo';
end


pitch_geo(isnan(pitch_geo))=0;
roll_geo(isnan(roll_geo))=0;
heave_geo(isnan(heave_geo))=0;
yaw_geo(isnan(yaw_geo))=0;

if size(northing,1)>1
    northing=northing';
    easting=easting';
end

BeamAngleAthwartship = trans_obj.get_params_value('BeamAngleAthwartship',idx_ping,idx_beam);
BeamAngleAlongship = trans_obj.get_params_value('BeamAngleAlongship',idx_ping,idx_beam);

data_to_pos = p.Results.data_to_pos;
detection_mask = p.Results.detection_mask;

for uid = 1:numel(data_to_pos)
    heave_geo_tmp = heave_geo;
    roll_geo_tmp = roll_geo;
    pitch_geo_tmp = pitch_geo;
    yaw_geo_tmp = yaw_geo;
    heading_geo_tmp = heading_geo;
    easting_tmp = easting;
    northing_tmp = northing;
    zone_tmp = zone_tt;
    idx_ping_curr = idx_ping;

    switch data_to_pos{uid}
        case 'WC'
            if comp_angle(1)
                AlongAngle = trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping_curr,'idx_beam',idx_beam,'field','AlongAngle');                
            else
                AlongAngle=zeros(numel(idx_r),numel(idx_ping_curr),numel(idx_beam));
            end

            if comp_angle(2)
                AcrossAngle = trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping_curr,'idx_beam',idx_beam,'field','AcrossAngle');
            else
                AcrossAngle=zeros(numel(idx_r),numel(idx_ping_curr),numel(idx_beam));
            end

            if isempty(AlongAngle)
                AlongAngle=zeros(numel(idx_r),numel(idx_ping_curr),numel(idx_beam));
            end

            if isempty(AcrossAngle)
                AcrossAngle=zeros(numel(idx_r),numel(idx_ping_curr),numel(idx_beam));
            end

            r_data = repmat(trans_obj.get_samples_range(idx_r),1,numel(idx_ping_curr),numel(idx_beam));
            t_data = trans_obj.get_transceiver_time(idx_ping_curr) + trans_obj.get_time_range(idx_ping_curr,idx_r,idx_beam)/(24*60*60);
            idx_ping_data = repmat(idx_ping_curr,size(t_data,1),1,size(t_data,3));
            idx_r_data = repmat(idx_r(:),1,size(t_data,2),size(t_data,3));
            idx_beam_data = repmat(shiftdim(idx_beam,-2),size(t_data,1),size(t_data,2),1);

        case 'bottom'
            %rr = trans_obj.get_samples_range(idx_r);
            r_data = trans_obj.get_bottom_range(idx_ping_curr,idx_beam);
            idx_bot = trans_obj.get_bottom_idx(idx_ping_curr,idx_beam);

            t_data_p = trans_obj.get_transceiver_time(idx_ping_curr);
            t_data = nan(size(r_data));
            for uip = 1:numel(idx_ping_curr)
                for uib = 1:numel(idx_beam)
                    t_data(1,uip,uib)  = t_data_p(uip) + trans_obj.get_time_range(idx_ping_curr(uip),idx_bot(1,uip,uib),idx_beam(uib))/(24*60*60);
                end
            end

            idx_ping_data = repmat(idx_ping_curr,size(r_data,1),1,size(r_data,3));
            idx_r_data = repmat(idx_bot,size(t_data,1),1,1);
            idx_beam_data = repmat(shiftdim(idx_beam,-1),size(t_data,1),size(t_data,2),1);
            AlongAngle=zeros(size(r_data));
            AcrossAngle=zeros(size(r_data));

 
            if any(comp_angle)
                for uib = 1:numel(idx_beam)
                    if ~isempty(p.Results.load_bar_comp)
                        p.Results.load_bar_comp.progress_bar.setText(sprintf('Positionning bottom on %s, beam %d',trans_obj.Config.ChannelID,uib));
                        set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(idx_beam), 'Value',uib);
                    end
                    al = [];
                    ac = [];
                    if comp_angle(1) && ismember('AlongAngle',trans_obj.Data.Fieldname)
                        al =arrayfun(@(idx_b,idx_p) trans_obj.Data.get_subdatamat('idx_r',idx_b,'idx_ping',idx_p,'idx_beam',idx_beam(uib),'field','AlongAngle'),idx_bot(1,:,uib),idx_ping_curr);
                    end
                    if comp_angle(2)&& ismember('AcrossAngle',trans_obj.Data.Fieldname)
                        ac =arrayfun(@(idx_b,idx_p) trans_obj.Data.get_subdatamat('idx_r',idx_b,'idx_ping',idx_p,'idx_beam',idx_beam(uib),'field','AcrossAngle'),idx_bot(1,:,uib),idx_ping_curr);
                    end
                    if ~isempty(al)
                        AlongAngle(1,:,uib) = al;
                    end
                    if ~isempty(ac)
                        AlongAngle(1,:,uib) = ac;
                    end
                end
            end

        case 'transducer'
            t_data = trans_obj.get_transceiver_time(idx_ping_curr);
            idx_ping_data = idx_ping_curr;
            idx_r_data = zeros(size(t_data));
            idx_beam_data = zeros(size(t_data));
            r_data = zeros(size(t_data));
            AlongAngle=zeros(size(r_data));
            AcrossAngle=zeros(size(r_data));
            BeamAngleAthwartship=zeros(size(r_data));
            BeamAngleAlongship=zeros(size(r_data));
        case {'singletarget','trackedtarget'}


            if isempty(trans_obj.ST)
                dlg_perso([],'','No single targets');
                continue;
            end

            idx_keep_p=find(ismember(trans_obj.ST.Ping_number,idx_ping_curr));
            idx_keep_r=find(ismember(trans_obj.ST.idx_r,idx_r));
            idx_keep=intersect(idx_keep_r,idx_keep_p);

            if strcmpi(data_to_pos{uid},'trackedtarget')
                if isempty(trans_obj.Tracks)
                    dlg_perso([],'','No tracked targets');
                    continue;
                end
                idx_keep_ori=idx_keep;
                idx_keep=[];
                for i=1:numel(trans_obj.Tracks.target_id)
                    idx_keep=union(idx_keep,intersect(idx_keep_ori,trans_obj.Tracks.target_id{i}));
                end
            end

            if isempty(idx_keep)
                continue;
            end

            r_data=trans_obj.ST.Target_range(idx_keep);
            t_data = trans_obj.ST.Time(idx_keep);
            AlongAngle=trans_obj.ST.Angle_minor_axis(idx_keep);
            AcrossAngle=trans_obj.ST.Angle_major_axis(idx_keep);
            idx_ping_curr=trans_obj.ST.Ping_number(idx_keep);

            BeamAngleAthwartship=zeros(size(idx_ping_curr));
            BeamAngleAlongship=zeros(size(idx_ping_curr));

            heave_geo_tmp = trans_obj.ST.Heave(idx_keep);
            roll_geo_tmp = trans_obj.ST.Roll(idx_keep);
            pitch_geo_tmp = trans_obj.ST.Pitch(idx_keep);
            yaw_geo_tmp = trans_obj.ST.Yaw(idx_keep);
            heading_geo_tmp = trans_obj.ST.Heading(idx_keep);
            easting_tmp = easting(idx_ping_curr-idx_ping(1)+1);
            northing_tmp = northing(idx_ping_curr-idx_ping(1)+1);
            zone_tmp = zone_tmp(idx_ping_curr-idx_ping(1)+1);
            idx_ping_data = trans_obj.ST.Ping_number(idx_keep);
            idx_r_data = trans_obj.ST.idx_r(idx_keep);
            idx_beam_data = ones(size(trans_obj.ST.idx_r(idx_keep)));

    end

    list_uncorr = {'EM' 'ME' 'MS'};
    %list_uncorr = {'EM'};
    %list_uncorr = {'ME' 'MS' 'EM' 'WBT'};

    if all(~contains(trans_obj.Config.TransceiverName,list_uncorr))
        switch data_to_pos{uid}
            case {'bottom' 'WC'}
                [~,Np] = trans_obj.get_pulse_length(idx_ping_curr);
                Np = Np(:,:,idx_beam);
                R_pulse = trans_obj.get_samples_range(Np);
                R_pulse = reshape(R_pulse,1,numel(idx_ping_curr),numel(idx_beam));
                r_data = r_data-R_pulse/2;
        end
    end

    nb_samples = size(r_data,1);
    nb_beams = size(r_data,3);

    Heave = repmat(heave_geo_tmp,nb_samples,1,nb_beams);
    Roll = repmat(roll_geo_tmp,nb_samples,1,nb_beams);
    Pitch = repmat(pitch_geo_tmp,nb_samples,1,nb_beams);
    Yaw = repmat(yaw_geo_tmp,nb_samples,1,nb_beams);

    if ~isempty(p.Results.full_attitude)&&numel(p.Results.full_attitude.Time)>1
        idx_t_att = get_idx_t(t_data,p.Results.full_attitude.Time+p.Results.dt_att/(24*60*60));
            Heave = p.Results.full_attitude.Heave(idx_t_att);
            Roll = p.Results.full_attitude.Roll(idx_t_att);
            Pitch = p.Results.full_attitude.Pitch(idx_t_att);
            Yaw = p.Results.full_attitude.Yaw(idx_t_att);
    end


    AcrossAngle  = AcrossAngle + BeamAngleAthwartship;
    AlongAngle  = AlongAngle + BeamAngleAlongship;
    zone_tmp = repmat(zone_tmp,nb_samples,1,nb_beams);


    if ~isempty(detection_mask) && strcmpi(data_to_pos{uid},'WC')
       
        r_data = r_data(detection_mask)';
        t_data = t_data(detection_mask)';
        idx_ping_data = idx_ping_data(detection_mask)';
        idx_r_data = idx_r_data(detection_mask)';
        idx_beam_data = idx_beam_data(detection_mask)';
        AcrossAngle = AcrossAngle(detection_mask)';
        AlongAngle = AlongAngle(detection_mask)';
        Heave = Heave(detection_mask)';
        Roll = Roll(detection_mask)';
        Pitch = Pitch(detection_mask)';
        Yaw=  Yaw(detection_mask)';
        zone_tmp = zone_tmp(detection_mask)';

        heading_geo_tmp = repmat(heading_geo_tmp,nb_samples,1,nb_beams);
        heading_geo_tmp = heading_geo_tmp(detection_mask)';
        idx_ping_curr = repmat(idx_ping_curr,nb_samples,1,nb_beams);
        idx_ping_curr = idx_ping_curr(detection_mask)';

        easting_tmp = repmat(easting_tmp,nb_samples,1,nb_beams);
        easting_tmp = easting_tmp(detection_mask)';
        northing_tmp = repmat(northing_tmp,nb_samples,1,nb_beams);
        northing_tmp = northing_tmp(detection_mask)';
    end


    data_sz = size(r_data);

    %For MS70
    % trans_obj.Config.TransducerAlphaX = 90;
    % trans_obj.Config.TransducerAlphaY = 0;
    % trans_obj.Config.TransducerAlphaZ = -90;

    % trans_obj.Config.TransducerAlphaX = 0;
    % trans_obj.Config.TransducerAlphaY = 0;
    % trans_obj.Config.TransducerAlphaZ = 0;

     
    if p.Results.georef_bool
        [Along_dist,Across_dist,Z_t] = angles_to_pos_vec(...
            r_data(:),...
            -AcrossAngle(:),...
            AlongAngle(:),...
            Heave(:),...
            Roll(:),...
            Pitch(:),...
            Yaw(:),...
            trans_obj.Config.TransducerAlphaX,trans_obj.Config.TransducerAlphaY,trans_obj.Config.TransducerAlphaZ,...
            trans_obj.Config.TransducerOffsetX,trans_obj.Config.TransducerOffsetY,trans_obj.Config.TransducerOffsetZ, ...
            p.Results.roll_comp,p.Results.pitch_comp,p.Results.yaw_comp,p.Results.heave_comp...
            );

        Along_dist = reshape(Along_dist,data_sz);
        Across_dist = reshape(Across_dist,data_sz);
        Z_t = reshape(Z_t,data_sz);

        if isempty(trans_obj.TransceiverDepth) || ~p.Results.transceiver_depth_bool
            trans_depth = zeros(1,numel(idx_ping_curr));
        else
            trans_depth = trans_obj.TransceiverDepth(idx_ping_curr);
        end

        data_struct.(data_to_pos{uid}).H = Z_t + trans_depth;
        data_struct.(data_to_pos{uid}).E = easting_tmp+Across_dist.*cosd(heading_geo_tmp)+Along_dist.*sind(heading_geo_tmp);%W/E
        data_struct.(data_to_pos{uid}).N = northing_tmp-Across_dist.*sind(heading_geo_tmp)+Along_dist.*cosd(heading_geo_tmp);%N/S
        Along_dist = Along_dist+trans_obj.GPSDataPing.Dist(idx_ping_curr);

        data_struct.(data_to_pos{uid}).AlongDist  = Along_dist;
        data_struct.(data_to_pos{uid}).AcrossDist  = Across_dist;
    end

    data_struct.(data_to_pos{uid}).Range = r_data;
    data_struct.(data_to_pos{uid}).Time = t_data;
    data_struct.(data_to_pos{uid}).Idx_ping = idx_ping_data;
    data_struct.(data_to_pos{uid}).Idx_beam = idx_beam_data;
    data_struct.(data_to_pos{uid}).Idx_r = idx_r_data;
    data_struct.(data_to_pos{uid}).Zone = zone_tmp;

    if ~no_nav
        [Lat_t,Lon_t] = utm2ll(data_struct.(data_to_pos{uid}).E(:),data_struct.(data_to_pos{uid}).N(:),data_struct.(data_to_pos{uid}).Zone(:));
    else
        Lat_t=data_struct.(data_to_pos{uid}).N(:);
        Lon_t=data_struct.(data_to_pos{uid}).E(:);
    end

    data_struct.(data_to_pos{uid}).Lat  =reshape(Lat_t,size(data_struct.(data_to_pos{uid}).N));
    data_struct.(data_to_pos{uid}).Lon  =reshape(Lon_t,size(data_struct.(data_to_pos{uid}).N));

end
end


function idx_t = get_idx_t(t_data,time_to_use)
t_bounds = [min(t_data,[],'all') max(t_data,[],'all')];
[~,idx_start] = min(abs(time_to_use-t_bounds(1)),[],'all');
[~,idx_end] = min(abs(time_to_use-t_bounds(2)),[],'all');
time_to_use = shiftdim(time_to_use(idx_start:idx_end),-2);

idx_t = nan(size(t_data));
b_size  = ceil(1e12/numel(t_data)/numel(time_to_use()));
n_block = ceil(size(t_data,2)/b_size);

for ui  = 1 : n_block
    idx_s_tmp = (ui-1)*b_size+1;
    idx_e_tmp = min(ui*b_size,size(t_data,2));
    [~,idx_t_tmp] = min(abs(t_data(:,idx_s_tmp:idx_e_tmp)-time_to_use),[],4);
    idx_t(:,idx_s_tmp:idx_e_tmp,:) = idx_t_tmp+idx_start-1;
end

end

function data_struct = init_data_struct(data_to_pos)

    fields = {'E' 'N' 'H' 'Zone' 'AlongDist' 'AcrossDist' 'Range' 'Idx_beam' 'Time' 'Idx_ping' 'Idx_r'};
    tmp_struct = [];
    for ifi =1:numel(fields)
        tmp_struct.(fields{ifi}) = [];
    end
    for uip = 1:numel(data_to_pos)
        data_struct.(data_to_pos{uip}) = tmp_struct;
    end

end