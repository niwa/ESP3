
classdef transceiver_cl < handle

    properties

        Data = ac_data_cl.empty();
        Range;
        Sample_offset;
        Ping_offset;
        Alpha
        Alpha_ori = 'constant'
        Time
        Bottom = bottom_cl();
        ST
        Tracks
        Regions
        Features
        Params = params_cl();
        Config = config_cl();
        Filters
        GPSDataPing
        AttitudeNavPing
        Algo = algo_cl.empty();
        Mode
        TransducerImpedance={};
        TransceiverDepth double
        Spikes
        Version  = transceiver_cl.get_curr_transceiver_cl_version();
    end

    methods(Static)
        function ver  =  get_curr_transceiver_cl_version()
            ver = 'v1.0';
        end
    end

    methods

        %% constructor %%
        function trans_obj = transceiver_cl(varargin)

            p = inputParser;
            addParameter(p,'Data', ac_data_cl(), @(x) isa(x,'ac_data_cl'));
            addParameter(p,'Time',[],@isnumeric);
            addParameter(p,'Sample_offset',0,@isnumeric);
            addParameter(p,'Ping_offset',0,@isnumeric);
            addParameter(p,'TransceiverDepth',[],@isnumeric);
            addParameter(p,'TransducerImpedance',{},@(x) iscell(x)||isempty(x));
            addParameter(p,'Range',[],@isnumeric);
            addParameter(p,'Alpha',[],@isnumeric);
            addParameter(p,'Alpha_ori','constant',@(x) ismember(x,{'constant' 'profile' 'theoritical'}));
            addParameter(p,'Bottom',bottom_cl.empty(),@(x) isa(x,'bottom_cl'));
            addParameter(p,'ST',init_st_struct(0),@isstruct);
            addParameter(p,'Tracks',init_track_struct(),@isstruct);
            addParameter(p,'Regions',region_cl.empty(),@(x) isa(x,'region_cl'));
            addParameter(p,'Features',feature_3D_cl.empty(),@(x) isa(x,'feature_3D_cl'));
            addParameter(p,'Params',params_cl(),@(x) isa(x,'params_cl'));
            addParameter(p,'Config',config_cl(),@(x) isa(x,'config_cl'));
            addParameter(p,'Filters',filter_cl.empty(),@(x) isa(x,'filter_cl'));
            addParameter(p,'GPSDataPing',gps_data_cl.empty(),@(x) isa(x,'gps_data_cl'));
            addParameter(p,'AttitudeNavPing',attitude_nav_cl.empty(),@(x) isa(x,'attitude_nav_cl'));
            addParameter(p,'Algo',algo_cl.empty(),@(x) isa(x,'algo_cl')||isempty(x));
            addParameter(p,'ComputeImpedance',false,@islogical);
            addParameter(p,'Mode','CW',@ischar);

            parse(p,varargin{:});
            results = p.Results;
            props = fieldnames(results);

            for ip = 1:length(props)
                if isprop(trans_obj,props{ip})&& ~ismember(props{ip},{'Bottom'})
                    trans_obj.(props{ip}) = results.(props{ip});
                end
            end

            [~,idx_sort,ids]=unique(trans_obj.Time);
            if numel(idx_sort)<numel(trans_obj.Time)
                classes = unique(ids);
                for ui = 1:numel(classes)
                    ii = find(classes(ui) ==ids);
                    i0 = max(ii(1)-1,1);
                    i1 = min(ii(end)+1,numel(trans_obj.Time));
                    tt = linspace(trans_obj.Time(i0),trans_obj.Time(i1),numel(ii)+2);
                    trans_obj.Time(ii) = tt(2:end-1);
                end
            end

            if ~isempty(p.Results.Data)
                if isempty(p.Results.GPSDataPing)
                    trans_obj.GPSDataPing = gps_data_cl('Time',p.Results.Time);
                end
                if isempty(p.Results.AttitudeNavPing)
                    trans_obj.AttitudeNavPing = attitude_nav_cl('Time',p.Results.Time);
                end
            end

            if isempty(trans_obj.TransceiverDepth)
                trans_obj.reset_transceiver_depth();
            end

            if isempty(trans_obj.TransducerImpedance)&&p.Results.ComputeImpedance
                trans_obj.TransducerImpedance=cell(size(trans_obj.Time));
            else
                trans_obj.TransducerImpedance = [];
            end

            if isempty(trans_obj.Range)&&~isempty(trans_obj.Data)
                trans_obj.Range = nan(max(trans_obj.Data.Nb_samples,[],"omitnan"),1);
            end

            trans_obj.Params=trans_obj.Params.reduce_params();
            trans_obj.Bottom = p.Results.Bottom;

            if ~isempty(trans_obj.Params.PingNumber)
                trans_obj.set_pulse_Teff();
                trans_obj.set_pulse_comp_Teff();
            end

            trans_obj.Spikes=sparse(numel(trans_obj.Range),numel(trans_obj.Time));

        end

        function p_out = get_params_value(trans_obj,param_name,varargin)

            p = inputParser;
            addRequired(p,'trans_obj');
            addRequired(p,'param_name');
            addOptional(p,'idx_ping',[]);
            addOptional(p,'idx_beam',[]);
            parse(p,trans_obj,param_name,varargin{:});


            idx_ping = p.Results.idx_ping;
            idx_beam = p.Results.idx_beam;

            nb_pings = numel(trans_obj.Time);
            nb_beam = numel(trans_obj.Params.BeamNumber);

            if nb_pings == 0
                nb_pings = 1;
            end

            if isempty(idx_ping)
                idx_ping=1:nb_pings;
            end

            if isempty(idx_beam)
                idx_beam=1:nb_beam;
            end


            if size(trans_obj.Params.(param_name),2)==nb_pings
                p_out = trans_obj.Params.(param_name)(idx_beam,idx_ping);
                if nb_beam>1
                    p_out = permute(p_out,[3 2 1]);
                end
            else
                mat_diff=idx_ping(:)'-double(trans_obj.Params.PingNumber');
                mat_diff(mat_diff<0)=inf;

                [~,id]=min(mat_diff,[],1,'omitnan');
                p_out = trans_obj.Params.(param_name)(idx_beam,id);
                if nb_beam>1
                    p_out = permute(p_out,[3 2 1]);
                end
            end
            p_out = double(p_out);
        end

        function mask_spikes = get_spikes(trans_obj,idx_r,idx_ping)

            if isempty(trans_obj.Spikes)
                trans_obj.Spikes=sparse(numel(trans_obj.Range),numel(trans_obj.Time));
            end

            if isempty(idx_r)
                idx_r=1:numel(trans_obj.Range);
            end
            
            idx_r(idx_r>numel(trans_obj.Range)) = [];

            if isempty(idx_ping)
                idx_ping=1:numel(trans_obj.Time);
            end
            idx_ping(idx_ping>numel(trans_obj.Time)) = [];

            mask_spikes=trans_obj.Spikes(idx_r,idx_ping);

        end
        function str_tt = get_CID_freq_str(trans_obj)
            ss = trans_obj.get_freq_str();
            str_tt = cell(1,numel(trans_obj));
            for uit = 1:numel(trans_obj)
                str_tt{uit} = sprintf('%s %s',ss{uit},trans_obj(uit).Config.ChannelID);
            end
        end

        function ss = get_freq_str(trans_obj)
            ss = cell(1,numel(trans_obj));
            for uit = 1:numel(trans_obj)
                fs = min(trans_obj(uit).get_params_value('FrequencyStart',1,[]),[],'all');
                fe = max(trans_obj(uit).get_params_value('FrequencyEnd',1,[]),[],'all');
                if fs~=fe
                    ss{uit} = sprintf('%.0f-%.0fkHz',fs/1e3,fe/1e3);
                else
                    ss{uit} = sprintf('%.0fkHz',fs/1e3);
                end
            end
        end

        function set_spikes(trans_obj,idx_r,idx_ping,mask)

            if ~issparse(trans_obj.Spikes)
                trans_obj.Spikes=sparse(trans_obj.Spikes);
            end

            if isempty(trans_obj.Spikes)
                trans_obj.Spikes=sparse(numel(trans_obj.Range),numel(trans_obj.Time));
            end

            if isscalar(mask)&&isempty(idx_r)
                idx_r=1:numel(trans_obj.Range);
            elseif ~isscalar(mask)&&isempty(idx_r)
                idx_r=1:size(mask,1);
            end

            if isscalar(mask)&&isempty(idx_ping)
                idx_ping=1:numel(trans_obj.Time);
            elseif ~isscalar(mask)&&isempty(idx_ping)
                idx_ping=1:size(mask,1);
            end

            trans_obj.Spikes(idx_r,idx_ping) = sparse(mask);

        end



        %% set Bottom property %%
        function set.Bottom(obj,bottom_obj)

            if isempty(bottom_obj)
                bottom_obj = bottom_cl();
            end

            % indices of bad pings in the new bottom object
            IdxBad = find(bottom_obj.Tag==0);
            IdxBad(IdxBad<=0) = [];

            % get the bottom sample index in the new bottom object
            bot_sple = bottom_obj.Sample_idx;
            bot_sple(bot_sple<1) = 1;

            % size of channel
            samples = obj.get_transceiver_samples();
            pings   = obj.get_transceiver_pings();
            theta = obj.get_params_value('BeamAngleAthwartship',[],[]);
            [~,nb_pings,nb_beam] = size(theta);

            % initialize new bot_sple
            new_bot_sple = nan(nb_beam,nb_pings);

            if ~isempty(bot_sple)
                %i0 = abs(size(bot_sple,2)-length(pings));
                if size(bot_sple,2) > length(pings)
                    new_bot_sple = bot_sple(1:numel(pings));
                    IdxBad(IdxBad>numel(pings)) = [];
                elseif size(bot_sple,2) < length(pings)
                    new_bot_sple(:,1:length(bot_sple)) = bot_sple;
                else
                    new_bot_sple = bot_sple;
                end

                while max(IdxBad,[],'all','omitnan') > length(pings)
                    IdxBad = IdxBad-1;
                end

                new_bot_sple(new_bot_sple>length(samples)) = length(samples);
                new_bot_sple(new_bot_sple<=0) = 1;
            end


            % create new bad pings vector
            tag = ones(1,size(new_bot_sple,2));
            tag(IdxBad) = 0;

            % wherever there is no bottom or the ping is bad, set the
            % bottom at the last sample
            new_bot_sple(isnan(new_bot_sple)) = length(samples);

            if isempty(new_bot_sple)
                % brand new bottom object
                E1 = [];
            else
                % get the old and new values
                if isprop(obj,'Bottom')
                    old_E1 = obj.Bottom.Bottom_params.E1;
                else
                    old_E1 = [];
                end

                new_E1 = bottom_obj.Bottom_params.E1;
                E1 = old_E1;

                if isempty(E1) || ~(size(E1,2)==size(new_bot_sple,2))
                    % no data either old or new, initialize E1
                    E1 = -999.*ones(1,size(new_bot_sple,2));
                    %idx_ping_mod = pings;
                end

                if ~isempty(new_E1) && (size(new_E1,2)==size(new_bot_sple,2))
                    E1 = new_E1;
                end

            end


            % setting E2
            if isempty(new_bot_sple)
                % brand new bottom object
                E2 = [];
            else

                % get the old and new values
                if isprop(obj,'Bottom')
                    old_E2 = obj.Bottom.Bottom_params.E2;
                else
                    old_E2 = [];
                end

                new_E2 = bottom_obj.Bottom_params.E2;
                E2 = old_E2;

                if isempty(E2) || ~(size(E2,2)==size(new_bot_sple,2))
                    % no data either old or new, initialize E2
                    E2 = -999.*ones(1,size(new_bot_sple,2));
                    %idx_ping_mod = pings;
                end

                if ~isempty(new_E2) && (size(new_E2,2)==size(new_bot_sple,2))
                    E2 = new_E2;
                end

            end

            obj.Bottom = bottom_cl('Origin',bottom_obj.Origin,...
                'Sample_idx',round(new_bot_sple),...
                'Tag',tag,...
                'Version',bottom_obj.Version);

            obj.Bottom.Bottom_params.E1 = E1;
            obj.Bottom.Bottom_params.E2 = E2;

        end

        function f_c=get_center_frequency(trans_obj,ip)

            switch trans_obj.Mode
                case 'FM'
                    f_c=(trans_obj.get_params_value('FrequencyStart',ip)+trans_obj.get_params_value('FrequencyEnd',ip))/2;
                case 'CW'
                    f_c=trans_obj.get_params_value('Frequency',ip);
                otherwise
                    f_c=trans_obj.get_params_value('Frequency',ip);
            end

        end

        function rm_ST(trans_obj)
            trans_obj.Data.remove_sub_data('singletarget');
            trans_obj.ST = init_st_struct(0);
            trans_obj.Tracks = init_track_struct();
        end

        function delete(trans_obj)
            if  isdebugging
                c = class(trans_obj);
                disp(['ML trans_object destructor called for class ',c])
                %trans_obj.Data.remove_sub_data();
            end
        end

        function range_trans = get_samples_range(trans_obj,varargin)
            range_trans =trans_obj.Range;

            if isempty(range_trans)
                return;
            end

            if nargin>=2
                idx = varargin{1};
                idx(idx<1)=1;
                idx(idx>=numel(range_trans))=numel(range_trans);
                if ~isempty(idx)
                    tmp  = nan(size(idx));
                    tmp(~isnan(idx)) = range_trans(idx(~isnan(idx)));
                    range_trans = tmp(:);
                end
            end

        end


        function depth = get_samples_depth(trans_obj,idx_r,idx_ping,varargin)

            if nargin<4
                idx_beam = [];
            else
                idx_beam = varargin{1};
            end
            % [E,N,H,zone,no_nav,Across_dist_struct,Along_dist_struct,Range_struct,Time_struct] = get_xxx_ENH(trans_obj,...
            %     'data_to_pos',{'WC'},'idx_ping',idx_ping,'idx_r',idx_r,'idx_beam',idx_beam);
            [data_struct,~] = trans_obj.get_xxx_ENH('data_to_pos',{'WC'},...
                'idx_ping',idx_ping,...
                'idx_r',idx_r,...
                'idx_beam',idx_beam,...
                'no_nav',true);

            depth = data_struct.WC.H;
        end
    
        function t_angle = get_beams_pointing_angles(trans_obj,varargin)

            if nargin<2
                idx_ping = [];
            else
                idx_ping = varargin{1};
            end
            
            if nargin<3
                idx_beam = [];
            else
                idx_beam = varargin{2};
            end

            if nargin<4
                axy_offset = [0 0];
            else
                axy_offset = varargin{3};
            end

            Ax = trans_obj.get_params_value('BeamAngleAlongship',idx_ping,idx_beam)+trans_obj.Config.TransducerAlphaX+axy_offset(1);
            Ay = trans_obj.get_params_value('BeamAngleAthwartship',idx_ping,idx_beam)+trans_obj.Config.TransducerAlphaY+axy_offset(2);
            
            data_sz = size(Ax);
            Ax = Ax(:);
            Ay = Ay(:);
            attitude_mat=double(create_attitude_matrix(shiftdim(Ax,-2),shiftdim(Ay,-2),zeros(size(shiftdim(Ay,-2)))+trans_obj.Config.TransducerAlphaZ));
            %attitude_mat=double(create_attitude_matrix(Ax,Ay,zeros(size(Ay))+trans_obj.Config.TransducerAlphaZ));
            R=pagemtimes(attitude_mat,[0;0;1]);
            Along_pos=reshape(R(1,:),data_sz);
            Across_pos=reshape(R(2,:),data_sz);
            z=reshape(R(3,:),data_sz);
            [~,el,~]  = cart2sph(Along_pos,Across_pos,z);
            t_angle = rad2deg(el);
         end

        function t_angle = get_transducer_pointing_angle(trans_obj)
            Rx = @(t) [1 0 0; 0 cosd(t) -sind(t); 0 sind(t) cosd(t)];
            Ry = @(t)  [cosd(t) 0 sind(t); 0 1 0; -sind(t) 0 cosd(t)];
            Rz = @(t)  [cosd(t) -sind(t) 0; sind(t) cosd(t) 0; 0 0 1];
            
            R = Rx(trans_obj.Config.TransducerAlphaX)*Ry(trans_obj.Config.TransducerAlphaY)*Rz(trans_obj.Config.TransducerAlphaZ)*[0;0;1];
            [~,el,~]  = cart2sph(R(1),R(2),R(3));
            t_angle = rad2deg(el);
        end

        function depth = get_surface_height(trans_obj,varargin)
            idx_ping = 1:numel(trans_obj.Time);

            if nargin>=2
                idx_ping = varargin{1};
            end

            depth = trans_obj.AttitudeNavPing.Heave(idx_ping);

        end

        function depth = get_transducer_depth(trans_obj,varargin)
            idx_ping = [];
            if nargin>=2
                idx_ping = varargin{1};
            end
            
            [data_struct,~] = trans_obj.get_xxx_ENH('data_to_pos',{'transducer'},...
                'idx_ping',idx_ping,...
                'idx_r',[],...
                'idx_beam',[], ...
                'no_nav',true);

            depth = data_struct.transducer.H;

        end

        function heave=get_transducer_heave(trans_obj,varargin)
            heave=trans_obj.AttitudeNavPing.Heave(:)';

            if nargin>=2
                idx=varargin{1};
                idx(idx<1)=1;
                idx(idx>=numel(heave))=numel(heave);
                if ~isempty(idx)
                    tmp  = nan(size(idx));
                    tmp(~isnan(idx)) = heave(idx(~isnan(idx)));
                    heave = tmp;
                end
            end
            heave(isnan(heave))=0;
        end

        function set.Range(trans_obj,r)
            trans_obj.Range=r(:);
        end

        function set.Time(trans_obj,t)
            trans_obj.Time=t(:)';
        end

        function set_transceiver_range(trans_obj,range)
            trans_obj.Range=range(:);
            if isempty(trans_obj.Alpha)
                trans_obj.Alpha = nan(size(trans_obj.Range));
            end
        end

        function set_transceiver_time(trans_obj,time)
            trans_obj.Time=time(:)';
        end

        function samples = get_transceiver_samples(trans_obj,varargin)
            if ~isempty(trans_obj.Data)
                samples=(1:max(trans_obj.Data.Nb_samples))';
                if nargin>=2
                    idx=varargin{1};
                    idx(idx<1)=1;
                idx(idx>=numel(samples))=numel(samples);
                if ~isempty(idx)
                    samples=samples(idx);
                end
                end
            else
                samples=[];
            end

        end


        function time=get_transceiver_time(trans_obj,varargin)
            time=trans_obj.Time;
            if nargin>=2
                idx=varargin{1};
                idx(idx<1)=1;
                idx(idx>=numel(time))=numel(time);
                if ~isempty(idx)
                    time=time(idx);
                end
            end
        end


        function pings=get_transceiver_pings(trans_obj,varargin)
            if ~isempty(trans_obj.Data)
                pings=(1:trans_obj.Data.Nb_pings);
                if nargin>=2
                    idx=varargin{1};

                    idx(idx<1)=1;
                    idx(idx>=numel(pings))=numel(pings);
                    if ~isempty(idx)
                        pings=pings(idx);
                    end
                end
            else
                pings=[];
            end
        end


        function list=regions_to_str(trans_obj)
            if isempty(trans_obj.Regions)
                list={};
            else
                list=cell(1,length(trans_obj.Regions));
                for ip=1:length(trans_obj.Regions)
                    new_name=sprintf('%s %0.f %s',trans_obj.Regions(ip).Name,trans_obj.Regions(ip).ID,trans_obj.Regions(ip).Type);
                    u=1;
                    new_name_ori=new_name;
                    while sum(strcmpi(new_name,list))>=1
                        new_name=[new_name_ori '_' num2str(u)];
                        u=u+1;
                    end
                    list{ip}=new_name;
                end
            end
        end

        function idx=find_regions_origin(trans_obj,origin)
            if isempty(trans_obj.Regions)
                idx=[];
            else
                idx=find(strcmp({trans_obj.Regions(:).Origin},origin));
            end
        end


        function idx=find_regions_type(trans_obj,type)
            if isempty(trans_obj.Regions)
                idx=[];
            else
                idx=find(strcmpi({trans_obj.Regions(:).Type},type));
            end
        end


        function idx=find_regions_tag(trans_obj,tags)
            if isempty(trans_obj.Regions)
                idx=[];
            else
                idx=find(ismember({trans_obj.Regions(:).Tag},tags));
            end
        end

        function tags=get_reg_tags(trans_obj)
            if isempty(trans_obj.Regions)
                tags={};
            else

                tags=unique({trans_obj.Regions(:).Tag});
            end
        end

        function IDs=get_reg_IDs(trans_obj)
            if isempty(trans_obj.Regions)
                IDs=[];
            else
                IDs=[trans_obj.Regions(:).ID];
            end
        end


        function IDs=get_reg_Unique_IDs(trans_obj)
            if isempty(trans_obj.Regions)
                IDs={};
            else
                IDs={trans_obj.Regions(:).Unique_ID};
            end
        end

        function IDs=get_reg_first_Unique_ID(trans_obj)
            if isempty(trans_obj.Regions)
                IDs={};
            else
                IDs=trans_obj.Regions(1).Unique_ID;
            end
        end

        function fileID=get_fileID(trans_obj)
            fileID=trans_obj.Data.FileId;
        end

        function bID=get_blockID(trans_obj)
            bID=trans_obj.Data.blockId;
        end


        function idx=find_regions_ID(trans_obj,ID)
            if isempty(trans_obj.Regions)
                idx=[];
            else
                idx=find(ismember([trans_obj.Regions(:).ID],ID));
            end
        end

        function idx=find_regions_Unique_ID(trans_obj,ID)
            if~iscell(ID)
                ID={ID};
            end
            if isempty(trans_obj.Regions)||isempty(ID)
                idx=[];
            else
                reg_uids={trans_obj.Regions(:).Unique_ID};
                idx=cellfun(@(x) find(strcmpi(x,reg_uids)),ID,'un',0);
                idx(cellfun(@isempty,idx))=[];
                if ~isempty(idx)
                    idx=cell2mat(idx);
                else
                    idx=[];
                end

            end
        end
        function reg=get_region_from_name(trans_obj,nns)
            idx=trans_obj.find_regions_name(nns);
            if ~isempty(idx)
                reg=trans_obj.Regions(idx);
            else
                reg=[];
            end
        end


        function reg=get_region_from_Unique_ID(trans_obj,ID)
            idx=trans_obj.find_regions_Unique_ID(ID);
            if ~isempty(idx)
                reg=trans_obj.Regions(idx);
            else
                reg=region_cl.empty();
            end
        end

        function idx=find_regions_ref(trans_obj,Reference)
            if isempty(trans_obj.Regions)
                idx=[];
            else
                idx=find(strcmpi({trans_obj.Regions(:).Reference},Reference));
            end
        end

        function idx=find_regions_name(trans_obj,nns)
            if isempty(trans_obj.Regions)
                idx=[];
            else
                idx=find(ismember(lower({trans_obj.Regions(:).Name}),lower(nns)));
            end
        end

        function rm_all_region(trans_obj)
            trans_obj.Regions=[];
        end

        function rm_tracks(trans_obj)
            trans_obj.Tracks=init_track_struct();
        end



        function rm_region_name(trans_obj,nn)
            if ~isempty(trans_obj.Regions)
                idx=strcmpi({trans_obj.Regions(:).Name},nn);
                trans_obj.Regions(idx)=[];
            end
        end

        function rm_region_name_idx_r_idx_p(trans_obj,nn,idx_r,idx_p)
            reg_curr=trans_obj.Regions;
            reg_new=[];
            for ip=1:length(reg_curr)
                if ~strcmpi(reg_curr(ip).Name,nn)||(isempty(intersect(idx_r,reg_curr(ip).Idx_r))&&~isempty(idx_r))||(isempty(intersect(idx_p,reg_curr(ip).Idx_ping))&&~isempty(idx_p))%TODO
                    reg_new=[reg_new reg_curr(ip)];
                end
            end
            trans_obj.Regions=reg_new;
        end



        function rm_regions(trans_obj)
            trans_obj.Regions=[];
        end

        function rm_region_name_id(trans_obj,nn,ID)
            if ~isempty(trans_obj.Regions)
                idx=strcmpi({trans_obj.Regions(:).Name},nn)&([trans_obj.Regions(:).ID]==ID);
                trans_obj.Regions(idx)=[];
            end
        end

        function rm_region_type_id(trans_obj,type,ID)
            if ~isempty(trans_obj.Regions)
                idx=strcmpi({trans_obj.Regions(:).Type},type)&([trans_obj.Regions(:).ID]==ID);
                trans_obj.Regions(idx)=[];
            end
        end

        function rm_region_id(trans_obj,unique_ID)
            if ~isempty(trans_obj.Regions)
                idx=strcmpi({trans_obj.Regions(:).Unique_ID},unique_ID);
                trans_obj.Regions(idx)=[];
            end
        end

        function rm_feature_id(trans_obj,unique_ID)
            if ~isempty(trans_obj.Features)
                idx=strcmpi({trans_obj.Features(:).Unique_ID},unique_ID);
                trans_obj.Features(idx)=[];
            end
        end

        function features_obj = get_feature_by_id(trans_obj,unique_ID)
            features_obj = [];
            if ~isempty(trans_obj.Features)
                idx=strcmpi({trans_obj.Features(:).Unique_ID},unique_ID);
                features_obj = trans_obj.Features(idx);
            end
        end

        function rm_feature_idx(trans_obj,idx_r,idx_ping,idx_beam)
            idx_rem = [];
            for uif = 1:numel(trans_obj.Features)
                if ~isempty(intersect(trans_obj.Features(uif).Idx_r,idx_r)) && ...
                        ~isempty(intersect(trans_obj.Features(uif).Idx_ping,idx_ping)) && ...
                        ~isempty(intersect(trans_obj.Features(uif).Idx_beam,idx_beam))
                    idx_rem = union(idx_rem,uif);
                end
            end
            trans_obj.Features(idx_rem) = [];
        end

        function rm_region_origin(trans_obj,origin)
            if ~isempty(trans_obj.Regions)
                idx=strcmpi({trans_obj.Regions(:).Origin},origin);
                trans_obj.Regions(idx)=[];
            end
        end



        function id=new_id(trans_obj)
            reg_curr=trans_obj.Regions;

            if ~isempty(reg_curr)
                id_list=[reg_curr(:).ID];
            else
                id_list=[];
            end
            if~isempty(id_list)
                new_id=setdiff(1:max(id_list)+1,id_list);
                id=new_id(1);
            else
                id=1;
            end
        end

        function [idx,found]=find_reg_idx(trans_obj,unique_ID)

            if ~isempty(trans_obj.Regions)
                idx=find(strcmpi({trans_obj.Regions(:).Unique_ID},unique_ID));
            else
                idx=[];
            end

            if isempty(idx)
                idx=1;
                found=0;
            else
                found=1;
            end

            if length(idx)>1
                warning('several regions with the same ID')
            end
        end

        function [idx,found]=find_reg_name(trans_obj,nn)
            if ~isempty(trans_obj.Regions)
                idx=find(strcmpi({trans_obj.Regions(:).Name},nn));
            else
                idx=[];
            end
            if isempty(idx)
                idx=1;
                found=0;
            else
                found=1;
            end

        end

        function [idx,found]=find_reg_name_id(trans_obj,nn,ID)
            if ~isempty(trans_obj.Regions)
                idx=find(strcmpi({trans_obj.Regions(:).Name},nn)&([trans_obj.Regions(:).ID]==ID));
            else
                idx=[];
            end
            if isempty(idx)
                idx=1;
                found=0;
            else
                found=1;
            end

        end
        


        function [idx,found]=find_reg_idx_id(trans_obj,ID)
            idx=strcmpi({trans_obj.Regions(:).Name},nn)&([trans_obj.Regions(:).ID]==ID);

            if isempty(idx)
                idx=1;
                found=0;
            else
                found=1;
            end

        end

        %% get mean depth per ping in region
        function [mean_depth,Sa] = get_mean_depth_from_region(trans_obj,unique_id)

            % get active region
            [reg_idx,found] = trans_obj.find_reg_idx(unique_id);
            if found == 0
                mean_depth = [];
                Sa = [];
                return;
            end
            active_reg = trans_obj.Regions(reg_idx);

            % get data from region
            [Sv,idx_r,~,~,bad_data_mask,bad_trans_vec,intersection_mask,below_bot_mask,mask_from_st] = get_data_from_region(trans_obj,active_reg,...
                'field','sv');

            if isempty(Sv)
                return;
            end

            % combine masks and apply to Sv
            Mask_reg = ~bad_data_mask & intersection_mask & ~mask_from_st & ~isnan(Sv) & ~below_bot_mask;
            Mask_reg(:,bad_trans_vec) = false;
            Sv(Sv<-90) = -999;
            Sv(~Mask_reg) = nan;

            % calculate mean depth
            range = double(trans_obj.get_samples_range(idx_r));
            mean_depth = sum(db2pow(Sv).*repmat(range,1,size(Sv,2)),'omitnan')./sum(db2pow(Sv),'omitnan');

            % calculate Sa
            Sa = pow2db(sum(db2pow(Sv).*mean(diff(range)),'omitnan'));

            % remove depth where Sa too low
            mean_depth(Sa<-90) = NaN;

        end

        function ismb = ismb(trans_obj)
            ismb = false(1,numel(trans_obj));
            for uit = 1:numel(trans_obj)
                if ~isempty(trans_obj(uit).Data)
                    ismb(uit) =  max(trans_obj(uit).Data.Nb_beams)>1;
                end
            end
        end

        function issb  =is_split_beam(trans_obj)
            issb  =strcmpi(trans_obj.Config.BeamType,'split-beam');
        end

        function [BW_al,BW_at] = get_beamwidth_at_f_c(trans_obj,cal_struct)
            f_c = trans_obj.get_center_frequency([]);
            f_c = mean(f_c,2,'omitnan');

            if isempty(cal_struct)
                [cal_struct,~]=trans_obj.get_transceiver_fm_cal('verbose',false);
            end
            
            [~,idx] = arrayfun(@(x) min(abs(x.Frequency-f_c),[],'all','omitnan'),cal_struct);
            BW_al  = nan(1,numel(cal_struct));
            BW_at  = nan(1,numel(cal_struct));
            for uit  = 1:numel(cal_struct)
                BW_al(uit) = cal_struct(uit).BeamWidthAlongship(idx(uit));
                BW_at(uit) = cal_struct(uit).BeamWidthAthwartship(idx(uit));
            end

            nb_beams = max(trans_obj.Data.Nb_beams);

            if numel(BW_al)<nb_beams
                BW_al = ones(1,nb_beams)*mean(BW_al);
            end

            if numel(BW_at)<nb_beams
                BW_at = ones(1,nb_beams)*mean(BW_at);
            end


        end

        %% Set transducer position
        function set_position(trans_obj,pos_trans,trans_angle)
            trans_obj.Config.TransducerOffsetX=pos_trans(1);
            trans_obj.Config.TransducerOffsetY=pos_trans(2);
            trans_obj.Config.TransducerOffsetZ=pos_trans(3);
            trans_obj.Config.TransducerAlphaX=trans_angle(1);
            trans_obj.Config.TransducerAlphaY=trans_angle(2);
            trans_obj.Config.TransducerAlphaZ=trans_angle(3);
        end

        function pos_trans=get_position(trans_obj)
            pos_trans=nan(3,1);
            pos_trans(1)= trans_obj.Config.TransducerOffsetX;
            pos_trans(2)= trans_obj.Config.TransducerOffsetY;
            pos_trans(3)= trans_obj.Config.TransducerOffsetZ;
        end

        function trans_angle=get_angles(trans_obj)
            trans_angle(1)=trans_obj.Config.TransducerAlphaX;
            trans_angle(2)=trans_obj.Config.TransducerAlphaY;
            trans_angle(3)=trans_obj.Config.TransducerAlphaZ;
        end

    end


end

