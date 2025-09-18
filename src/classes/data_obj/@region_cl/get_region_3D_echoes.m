function [data_struct,no_nav] = get_region_3D_echoes(reg_obj,trans_obj,varargin)

%% input variable management

p = inputParser;

% default values
field_def='sp';

[roll_comp_bool,pitch_comp_bool,yaw_comp_bool,heave_comp_bool] = trans_obj.get_att_comp_bool();

[cax_d,~,~]=init_cax(field_def);
addRequired(p,'reg_obj',@(obj) isa(obj,'region_cl'));
addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl')|isstruct(obj));
addParameter(p,'full_attitude',attitude_nav_cl.empty(),@(x) isa(x,'attitude_nav_cl'));
addParameter(p,'full_navigation',gps_data_cl.empty(),@(x) isa(x,'gps_data_cl'));
addParameter(p,'dt_att',0,@isnumeric);
addParameter(p,'Name',reg_obj.print(),@ischar);
addParameter(p,'Cax',cax_d,@isnumeric);
addParameter(p,'idx_beam',[],@isnumeric);
addParameter(p,'Cmap','ek60',@ischar);
addParameter(p,'alphadata',[],@isnumeric);
addParameter(p,'field',field_def,@ischar);
addParameter(p,'db',1,@isnumeric);
addParameter(p,'dr',1,@isnumeric);
addParameter(p,'dp',1,@isnumeric);
addParameter(p,'other_fields',{'bottom','transducer'},@iscell);
addParameter(p,'comp_angle',[true true],@(x) islogical(x)||isnumeric(x));
addParameter(p,'roll_comp',roll_comp_bool,@(x) islogical(x)||isnumeric(x));
addParameter(p,'pitch_comp',pitch_comp_bool,@(x) islogical(x)||isnumeric(x));
addParameter(p,'heave_comp',heave_comp_bool,@(x) islogical(x)||isnumeric(x));
addParameter(p,'yaw_comp',yaw_comp_bool,@(x) islogical(x)||isnumeric(x));
addParameter(p,'thr',nan,@isnumeric);
addParameter(p,'main_figure',[],@(h) isempty(h)|ishghandle(h));
addParameter(p,'parent',[],@(h) isempty(h)|ishghandle(h));
addParameter(p,'load_bar_comp',[]);

parse(p,reg_obj,trans_obj,varargin{:});

field=p.Results.field;


data_struct = [];
no_nav = false;

comp_angle=p.Results.comp_angle;


if isempty(reg_obj)
    idx_ping=trans_obj.get_transceiver_pings();
    idx_r=trans_obj.get_transceiver_samples();
else
    idx_ping=reg_obj.Idx_ping;
    idx_r=reg_obj.Idx_r;
end


switch field
    case {'singletarget' 'trackedtarget'}

        if isempty(trans_obj.ST)
            return;
        end

        idx_keep_p=find(ismember(trans_obj.ST.Ping_number,idx_ping));
        idx_keep_r=find(ismember(trans_obj.ST.idx_r,idx_r));
        idx_keep=intersect(idx_keep_r,idx_keep_p);

        if strcmpi(field,'trackedtarget')
            field_to_pos = 'trackedtarget';
            field = 'singletarget';
            if isempty(trans_obj.Tracks)
                dlg_perso([],'','No tracked targets');
                return;
            end
            idx_keep_ori=idx_keep;
            idx_keep=[];
            for i=1:numel(trans_obj.Tracks.target_id)
                idx_keep=union(idx_keep,intersect(idx_keep_ori,trans_obj.Tracks.target_id{i}));
            end
            
        else
            field_to_pos = 'singletarget';
        end

        if isempty(idx_keep)
            dlg_perso([],'','No single targets');
            return;
        end

       
        data_disp=trans_obj.ST.TS_comp(idx_keep);
        AlongAngle = trans_obj.ST.Angle_major_axis(idx_keep);
        AcrossAngle = trans_obj.ST.Angle_minor_axis(idx_keep);
        compensation=zeros(size(data_disp));
        Mask=ones(size(data_disp));
        idx_beam = 1;

    otherwise
        switch field
            case {'TS' 'sp' 'spdenoised'}
                field_load='sp';
            case {'sv' 'svdenoised'}
                field_load=field;
            otherwise
                field_load=field;
        end


        [data_disp,idx_r,idx_ping,idx_beam,bad_data_mask,bad_trans_vec,~,below_bot_mask,~]=trans_obj.get_data_from_region(reg_obj,...
            'idx_beam',p.Results.idx_beam,...
            'dr',p.Results.dr,'dp',p.Results.dp,'db',p.Results.db,...
            'field',field_load);
        
        if isempty(data_disp)
            return;
        end

        Mask=(~bad_data_mask)&(~below_bot_mask);
        Mask(:,bad_trans_vec,:)=0;

        if comp_angle(1)
            AlongAngle = trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'idx_beam',idx_beam,'field','AlongAngle');
        else
            AlongAngle = zeros(numel(idx_r),numel(idx_ping),numel(idx_beam));
        end

        if comp_angle(2)
            AcrossAngle = trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'idx_beam',idx_beam,'field','AcrossAngle');
        else
            AcrossAngle=zeros(numel(idx_r),numel(idx_ping),numel(idx_beam));
        end

        if isempty(AlongAngle)
            AlongAngle=zeros(numel(idx_r),numel(idx_ping),numel(idx_beam));
        end

        if isempty(AcrossAngle)
            AcrossAngle=zeros(numel(idx_r),numel(idx_ping),numel(idx_beam));
        end


        [faBW,psBW] = trans_obj.get_beamwidth_at_f_c([]);
        faBW = faBW(idx_beam);
        psBW = psBW(idx_beam);
        compensation = nan(size(AlongAngle));
        
        for uib = 1:numel(idx_beam)
            compensation(:,:,uib) = simradBeamCompensation(faBW(uib),...
                psBW(uib), AlongAngle(:,:,uib), AcrossAngle(:,:,uib));
        end

        field_to_pos = 'WC';

end


if isempty(data_disp)
    disp_perso([],sprintf('Field %s not found. Cannot get 3D region',field));
    return;
end

[fields_tot,~,~,~,default_values]=init_fields();

idx_field=find(strcmpi(fields_tot,field),1);
detection_mask = [];
da = 0.99;
if ~isempty(idx_field)
    detection_mask = data_disp>default_values(idx_field);
    detection_mask=  detection_mask & ~(abs(AcrossAngle) > da * max(abs(AcrossAngle),[],'all','includemissing') | abs(AlongAngle) > da *  max(abs(AlongAngle),[],'all','includemissing'));
end

all_fields = union(p.Results.other_fields,field_to_pos);

[data_struct,no_nav] = trans_obj.get_xxx_ENH('data_to_pos',all_fields,...
    'dt_att',p.Results.dt_att,...
    'full_attitude',p.Results.full_attitude,...
    'full_navigation',p.Results.full_navigation,...
    'idx_r',idx_r,'idx_ping',idx_ping,'idx_beam',idx_beam,...
    'detection_mask',detection_mask,...
    'comp_angle',comp_angle,...
    'yaw_comp',p.Results.yaw_comp,...
    'roll_comp',p.Results.roll_comp,...
    'pitch_comp',p.Results.pitch_comp);

data_struct.(field_to_pos).data_disp = data_disp;
data_struct.(field_to_pos).Mask = Mask;
data_struct.(field_to_pos).AlongAngle = AlongAngle;
data_struct.(field_to_pos).AcrossAngle = AcrossAngle;
data_struct.(field_to_pos).Compensation = compensation;

if ~isempty(detection_mask)
    data_struct.(field_to_pos).data_disp = data_struct.(field_to_pos).data_disp(detection_mask)';
    data_struct.(field_to_pos).Mask = data_struct.(field_to_pos).Mask(detection_mask)';
    data_struct.(field_to_pos).AlongAngle = data_struct.(field_to_pos).AlongAngle(detection_mask)';
    data_struct.(field_to_pos).AcrossAngle = data_struct.(field_to_pos).AcrossAngle(detection_mask)';
    data_struct.(field_to_pos).Compensation = data_struct.(field_to_pos).Compensation(detection_mask)';
end



end