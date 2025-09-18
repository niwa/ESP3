function [trans_obj,envdata,NMEA,mru0_att,mru1_att,mru1_gps]=data_from_raw_idx_cl(path_f,idx_raw_obj,varargin)
HEADER_LEN=12;

p = inputParser;
addRequired(p,'path_f',@(x) ischar(x));
addRequired(p,'idx_raw_obj',@(x) isa(x,'raw_idx_cl'));
addParameter(p,'Frequencies',[],@isnumeric);
addParameter(p,'Channels',{},@iscell);
addParameter(p,'GPSOnly',0,@isnumeric);
addParameter(p,'DataOnly',0,@isnumeric);
addParameter(p,'Keep_complex_data',false,@islogical);
addParameter(p,'ComputeImpedance',false,@islogical);
addParameter(p,'PathToMemmap',path_f,@ischar);
addParameter(p,'FieldNames',{});
addParameter(p,'load_bar_comp',[]);
addParameter(p,'env_data',env_data_cl.empty());
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));

parse(p,path_f,idx_raw_obj,varargin{:});

enc = 'US-ASCII';

results=p.Results;
Frequencies=results.Frequencies;
Channels=deblank(results.Channels);
gps_only=p.Results.GPSOnly;
trans_obj=transceiver_cl.empty();

envdata_def=p.Results.env_data;

envdata=env_data_cl();
NMEA={};
mru0_att=attitude_nav_cl.empty();

filename=fullfile(path_f,idx_raw_obj.filename);

recent_times=idx_raw_obj.time_dg > datenum('01-Jan-1901');

if any(recent_times)
    prop_idx=properties(idx_raw_obj);
    for iprop=1:numel(prop_idx)
        if numel(idx_raw_obj.(prop_idx{iprop}))==numel(recent_times)
            idx_raw_obj.(prop_idx{iprop})(~recent_times)=[];
        end
    end
end

ftype=get_ftype(filename,idx_raw_obj.raw_type);

load_bar_comp=results.load_bar_comp;

block_len = get_block_len(50,'cpu',p.Results.block_len);

[block_len_gpu,gpu_comp]=get_block_len(20,'gpu',[]);

if gpu_comp
    block_len=block_len_gpu;
end

PROF = false && ~isdeployed;

if PROF
    profile on;
end
config_trans = [];
switch ftype
    case 'EK80'
        [~,config]=read_EK80_config(filename);
        nb_trans_tot=length(config);

        freq=nan(1,nb_trans_tot);
        CIDs=cell(1,nb_trans_tot);

        for uif=1:length(freq)
            freq(uif)=config{uif}.Frequency;
            CIDs{uif}=deblank(config{uif}.ChannelID);
        end
        array_type='double';

    case {'EK60' 'ME70' 'MS70'}
        array_type='single';
        fid=fopen(fullfile(path_f,idx_raw_obj.filename),'r','l',enc);
        %fid=fopen(fullfile(path_f,idx_raw_obj.filename),'r');
        [header, freq,CIDs] = readEKRaw_ReadHeader(fid);

        if isempty(header)
            frewind(fid);
            [~,~] = read_EK80_config(fid);
            [header, freq,CIDs] = readEKRaw_ReadHeader(fid);
        end


        fclose(fid);
        config_EK60=header.transceiver;

        for uif=1:length(freq)
            config_EK60(uif).soundername = deblank(header.header.soundername);
            config_EK60(uif).version = deblank(header.header.version);
        end
end


if isempty(Frequencies)
    idx_chan=(1:length(freq))';
else
    idx_chan=find(ismember(CIDs,Channels));
end

channels_tot = unique(idx_raw_obj.chan_dg(~isnan(idx_raw_obj.chan_dg)));
%%
idx_freq = find(ismember(channels_tot,idx_chan));

idx_freq(idx_freq>numel(channels_tot))=[];

channels=channels_tot(idx_freq);
CIDs_freq=CIDs(idx_chan);

if isempty(channels)
    dlg_perso([],'Failed',sprintf('Cannot open file %s, cannot find required channels',filename));
    return;
end

id_adcp = find(contains(CIDs_freq,'ADCP'));
CIDs(ismember(CIDs,CIDs_freq)) = [];
new_CIDs_freq = {};
new_channels = [];
new_idx_freq = [];

for uid = 1:numel(CIDs_freq)
    if ismember(uid,id_adcp)
        %"EC150 181982-15 EC150-3C - ADCP_ADCP_114"
        %"EC150 181982-15 EC150-3C - ADCP_ADCP#ADCP-P1"
        nb_trans_tot = nb_trans_tot +3;
        cid_adcp  = CIDs_freq{uid};
        channel_adcp = channels(uid);
        id = strfind(cid_adcp,'_');
        new_cids_tmp = cell(1,4);
        new_channels_tmp = channel_adcp + (0:3);
        new_idx_freq_tmp = idx_freq(uid) + (0:3);

        for uidd = 0:3
            if contains(cid_adcp,'EC150')
                new_cids_tmp{uidd+1} = strrep(cid_adcp,cid_adcp(id(end):end),sprintf('#%s-P%.0f',cid_adcp(id(end-1)+1:id(end)-1),uidd));
            elseif   contains(cid_adcp,'CP300')
                 new_cids_tmp{uidd+1} = strrep(cid_adcp,cid_adcp(id(end):end),sprintf('#%s-0%.0f',cid_adcp(id(end-1)+1:id(end)-1),uidd));
            else
                new_cids_tmp{uidd+1} = strrep(cid_adcp,cid_adcp(id(end):end),sprintf('#%s-3%.0f',cid_adcp(id(end-1)+1:id(end)-1),uidd));
            end
        end

        idx_raw_obj.chan_dg(idx_raw_obj.chan_dg>channel_adcp) = idx_raw_obj.chan_dg(idx_raw_obj.chan_dg>channel_adcp)+3;
        idx_raw_obj.chan_dg(idx_raw_obj.chan_dg == channel_adcp) = channel_adcp + mod(1:sum(idx_raw_obj.chan_dg == channel_adcp),4);
        channels(channels>channel_adcp) = channels(channels>channel_adcp)+3;
        idx_freq(idx_freq>uid) = idx_freq(idx_freq>uid)+3;

        new_CIDs_freq = [new_CIDs_freq new_cids_tmp];
        new_channels = [new_channels new_channels_tmp];
        new_idx_freq = [new_idx_freq new_idx_freq_tmp];
    else
        new_CIDs_freq = [new_CIDs_freq CIDs_freq{uid}];
        new_channels = [new_channels channels(uid)];
        new_idx_freq = [new_idx_freq idx_freq(uid)];
    end
end

CIDs_freq = new_CIDs_freq;
channels = new_channels;
idx_freq = new_idx_freq;

CIDs = union(CIDs,CIDs_freq);

nb_trans=length(CIDs_freq);

nb_pings=idx_raw_obj.get_nb_pings_per_channels();
nb_pings=nb_pings(idx_freq);
nb_pings(nb_pings<0)=0;

%block_len=min(min(ceil(nb_pings/2)),block_len);

nb_samples=idx_raw_obj.get_nb_samples_per_channels();
nb_samples=nb_samples(idx_freq);
nb_samples(nb_samples<0)=0;

nb_samples_cell=idx_raw_obj.get_nb_samples_per_block_per_channels(1);
nb_samples_cell=nb_samples_cell(idx_freq);

[nb_samples_group,~,~,block_id]=cellfun(@(x) group_pings_per_samples(x,1:numel(x)),nb_samples_cell,'un',0);

block_len = max(100,ceil(block_len/max(nb_samples)));

nb_samples_per_block=idx_raw_obj.get_nb_samples_per_block_per_channels(block_len);
nb_samples_per_block=nb_samples_per_block(idx_freq);

if gps_only>0
    nb_pings=min(ones(1,length(CIDs_freq)),nb_pings,'omitnan');
end


nb_nmea=idx_raw_obj.get_nb_nmea_dg();

time_nmea=idx_raw_obj.get_time_dg('NME0');
NMEA.time= time_nmea;
NMEA.string= cell(1,nb_nmea);
NMEA.type= cell(1,nb_nmea);
NMEA.ori= cell(1,nb_nmea);

params_cl_init(nb_trans)=params_cl();

curr_data_name_t=cell(nb_trans,1);

time_cell=idx_raw_obj.get_time_per_channels();
time_cell=time_cell(idx_freq);
[~,fname_stripped,~] = fileparts(idx_raw_obj.filename);
fname_stripped = generate_valid_filename(fname_stripped);

for itr=1:nb_trans
    data.pings(itr).number=nan(1,nb_pings(itr));
    data.pings(itr).time=nan(1,nb_pings(itr));

    if gps_only==0
        % [~,curr_filename,~]=fileparts(tempname);   
        % curr_data_name_t{itr}=fullfile(p.Results.PathToMemmap,curr_filename);
        curr_data_name_t{itr}=fullfile(p.Results.PathToMemmap,fname_stripped,generate_valid_filename(CIDs_freq{itr}),'transceiver_data');
    end

    % instantiate acoustic data object
    if gps_only==0
        ac_data_temp = ac_data_cl('SubData',[],...
            'Nb_samples', nb_samples_group{itr},...
            'Nb_pings',   nb_pings(itr),...
            'Nb_beams',ones(size(nb_samples_group{itr})),...
            'BlockId' , block_id{itr},...
            'MemapName',  curr_data_name_t{itr});
    else
        ac_data_temp = ac_data_cl.empty();
    end

    trans_obj(itr)=transceiver_cl('Data',ac_data_temp,'Time',time_cell{itr},'ComputeImpedance',p.Results.ComputeImpedance);

end


block_i = ones(1,nb_trans);
block_nb = ones(1,nb_trans);
data_tmp = cell(1,nb_trans);
i_ping = ones(nb_trans,1);
i_nmea = 0;
id_mru0 = 0;
id_mru1 = 0;
%fil_process = 0;
conf_dg = 0;
env_dg = 0;

prop_params=properties(params_cl);
%prop_config=properties(config_cl);
prop_env=properties(env_data_cl);

param_str_init=cell(1,nb_trans);

i_params = zeros(1,nb_trans);
alpha_file = nan(1,nb_trans);
param_str_init_over=cell(1,numel(CIDs));
param_str_init(:)={''};
param_str_init_over(:)={''};
idx_mru0=strcmp(idx_raw_obj.type_dg,'MRU0');
idx_mru1=strcmp(idx_raw_obj.type_dg,'MRU1');


mru0_att = attitude_nav_cl('Time',idx_raw_obj.time_dg(idx_mru0)');
mru1_att = attitude_nav_cl('Time',idx_raw_obj.time_dg(idx_mru1)');
mru1_gps = gps_data_cl('Time',idx_raw_obj.time_dg(idx_mru1)');

fid = fopen(filename,'r','l',enc);

str_disp=sprintf('Opening File %s',filename);
if ~isempty(load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(idx_raw_obj.type_dg), 'Value',0);
    load_bar_comp.progress_bar.setText(str_disp);
else
    disp(str_disp);
end

dg_type_keep={'XML0','CON0','CON1','NME0','RAW0','RAW3','RAW4','FIL1','MRU0','MRU1'};

if gps_only>0
    dg_type_keep={'XML0','CON0','NME0','RAW0','RAW3','RAW4','FIL1','CON1','MRU1'};
end

if p.Results.DataOnly>0
    dg_type_keep={'XML0','CON0','RAW0','RAW3','RAW4','FIL1','CON1'};
end

idx_keep=ismember(idx_raw_obj.type_dg,dg_type_keep)&(isnan(idx_raw_obj.chan_dg)|ismember(idx_raw_obj.chan_dg,channels));


props=properties(idx_raw_obj);
for iprop=1:numel(props)
    if numel(idx_raw_obj.(props{iprop}))==numel(idx_keep)
        idx_raw_obj.(props{iprop})(~idx_keep)=[];
    end
end

nb_dg=length(idx_raw_obj.type_dg);

% idg_time=idx_raw_obj.time_dg();
% [~,idg_sort]=sort(idg_time);
raw0_pow_conv = (10 * log10(2) / 256);

ek80_file_fmt_version = 1.01;
str = '';
for idg=1:nb_dg
    pos=ftell(fid);

    try
        if (idx_raw_obj.pos_dg(idg)-pos+HEADER_LEN)<0
            continue;
        end

        dgTime=idx_raw_obj.time_dg(idg);

        if ~isempty(load_bar_comp)&&(rem(idg,50)==0||idg ==nb_dg)
            set(load_bar_comp.progress_bar,'Value',idg, 'Maximum',length(idx_raw_obj.type_dg));
        elseif (rem(idg,50)==0||idg ==nb_dg)
            nstr = numel(str);
            str = sprintf('%2.0f%%',floor(idg/length(idx_raw_obj.type_dg)*100));
            fprintf([repmat('\b',1,nstr) '%s'],str);
        end

        switch  idx_raw_obj.type_dg{idg}

            case 'XML0'

                fseek(fid,idx_raw_obj.pos_dg(idg)-pos+HEADER_LEN,'cof');

                t_line=(fread(fid,idx_raw_obj.len_dg(idg)-HEADER_LEN,'char=>char'))';
                t_line=deblank(t_line);
                if contains(t_line,'<Configuration>')&&conf_dg==1
                    if conf_dg==1
                        fread(fid, 1, 'int32');
                        continue;
                    end

                elseif contains(t_line,'<Environment>')&&env_dg==1
                    fread(fid, 1, 'int32');
                    continue;
                elseif contains(t_line,'<Parameter>')
                    idx = find(strcmp(t_line,param_str_init));
                    idx_over = find(strcmp(t_line,param_str_init_over), 1);
                    if ~isempty(idx)
                        dgTime=idx_raw_obj.time_dg(idg);
                        fread(fid, 1, 'int32');
                        continue;
                    elseif ~isempty(idx_over)
                        continue;
                    end

                elseif strcmpi(t_line,'')
                    continue;
                end

                [header,output,type]=read_xml0(t_line); %50% faster than the old version!

                switch type

                    case'Configuration'

                        config_temp=output;
                        if isfield(header,'FileFormatVersion')
                            ek80_file_fmt_version = str2double(header.FileFormatVersion);
                        end

                        for iout=1:length(config_temp)
                            idx = find(contains(CIDs_freq,deblank(config_temp{iout}.ChannelID)));
                            %idx = find(idx_raw_obj.chan_dg(idg)==channels);
                            for id  =idx
                                trans_obj(id).Config = config_obj_from_EK80_xml_struct(config_temp{iout},t_line,trans_obj(id).Config);
                                trans_obj(id).Config.ChannelID = CIDs_freq{id};
                            end
                        end
                    case 'Environment'
                        if ~isempty(output)
                            props=fieldnames(output);
                            if isempty(envdata)
                                envdata=env_data_cl();
                            end

                            for iii=1:length(props)
                                idx_prop  = find(strcmpi(prop_env,props{iii}),1);
                                if  ~isempty(idx_prop)
                                    envdata.(prop_env{idx_prop})=output.(props{iii});
                                else
                                    if ~isdeployed
                                        fprintf('New parameter in Environment XML: %s\n', props{iii});
                                    end
                                end
                            end

                        end
                    case 'Parameter'
                        params_temp=output;
                        idx = find(contains(deblank(CIDs_freq),deblank(params_temp.ChannelID)));
                        idx_over = find(contains(deblank(CIDs),deblank(params_temp.ChannelID)));
                        %idx = find(idx_raw_obj.chan_dg(idg)==channels);
                        %idx_over = find(idx_raw_obj.chan_dg(idg)==channels_tot);
                        if ~isempty(idx_over)
                            param_str_init_over{idx_over}=t_line;
                        end
                        i_params(idx) = i_params(idx)+1;
                        dgTime=idx_raw_obj.time_dg(idg);
                        fields_params=fieldnames(params_temp);

                        if ~isempty(idx)
                            param_str_init{idx}=t_line;

                            for jj=1:length(fields_params)
                                switch fields_params{jj}
                                    case 'PulseDuration'
                                        params_cl_init(idx).PulseLength=params_temp.(fields_params{jj});
                                    otherwise
                                        if ismember(fields_params{jj},prop_params)
                                            params_cl_init(idx).(fields_params{jj})=params_temp.(fields_params{jj});
                                        else
                                            if ~isdeployed && ~ismember(fields_params{jj},{'ChannelID'})
                                                fprintf('New parameter in Parameters XML: %s\n', fields_params{jj});
                                            end
                                        end
                                end
                            end

                            if ~isfield(params_temp,'Frequency') && isfield(params_temp,'FrequencyStart') && isfield(params_temp,'FrequencyEnd')
                                params_cl_init(idx).Frequency=1/2*(params_temp.FrequencyStart+params_temp.FrequencyEnd);
                            end

                            if ~isfield(params_temp,'FrequencyStart') && isfield(params_temp,'Frequency')
                                params_cl_init(idx).FrequencyStart=params_temp.Frequency;
                            end

                            if ~isfield(params_temp,'FrequencyEnd') && isfield(params_temp,'Frequency')
                                params_cl_init(idx).FrequencyEnd=params_temp.Frequency;
                            end

                            if iscell(trans_obj(idx).TransducerImpedance)
                                if i_ping(idx)==1
                                    trans_obj(idx).TransducerImpedance=cell(trans_obj(idx).Config.NbQuadrants,nb_pings(idx));
                                end
                            end

                            for jj=1:length(prop_params)
                                if ~isempty(params_cl_init(idx).(prop_params{jj}))&&~strcmpi(prop_params{jj},'BeamNumber')
                                    trans_obj(idx).Params.(prop_params{jj})(i_params(idx))=(params_cl_init(idx).(prop_params{jj}));
                                    trans_obj(idx).Params.PingNumber(i_params(idx)) = i_ping(idx);
                                else
                                    if ~isdeployed
                                        fprintf('Parameter not found in Parameters XML: %s for channel %s\n', prop_params{jj},params_temp.ChannelID);
                                    end
                                end
                            end



                        end
                end

            case 'CON1'
                fseek(fid,idx_raw_obj.pos_dg(idg)-pos+HEADER_LEN,'cof');
            case 'CON0'
                %header = readEKRaw_ReadConfigHeader(fid);
                dgTime=idx_raw_obj.time_dg(idg);
            case 'NME0'
                if  gps_only<=1
                    fseek(fid,idx_raw_obj.pos_dg(idg)-pos+HEADER_LEN,'cof');
                    i_nmea=i_nmea+1;
                    NMEA.string{i_nmea}=fread(fid,idx_raw_obj.len_dg(idg)-HEADER_LEN,'char=>char')';
                    if numel(NMEA.string{i_nmea})>=6
                        idx=strfind(NMEA.string{i_nmea},',');
                        if ~isempty(idx)
                            NMEA.type{i_nmea}=NMEA.string{i_nmea}(4:idx(1)-1);
                            NMEA.ori{i_nmea}=NMEA.string{i_nmea}(2:3);
                        else
                            NMEA.type{i_nmea}='';
                            NMEA.ori{i_nmea}='';
                        end
                    else
                        NMEA.type{i_nmea}='';
                        NMEA.ori{i_nmea}='';
                    end
                end
            case 'FIL1'

                fseek(fid,idx_raw_obj.pos_dg(idg)-pos+HEADER_LEN,'cof');
                stage=fread(fid,1,'int16');
                tmp = fread(fid,2,'int8');
                if ek80_file_fmt_version >= 1.21
                    filter_coeff_temp.FilterType = tmp(2);
                end
                filter_coeff_temp.channelID = (fread(fid,128,'char=>char')');
                filter_coeff_temp.NoOfCoefficients=fread(fid,1,'int16');
                filter_coeff_temp.DecimationFactor=fread(fid,1,'int16');
                filter_coeff_temp.Coefficients=fread(fid,2*filter_coeff_temp.NoOfCoefficients,'single');
                idx = find(contains(deblank(CIDs_freq),deblank(filter_coeff_temp.channelID)));
                %idx = find(idx_raw_obj.chan_dg(idg)==channels);
                if isempty(idx)
                    idx = find(~cellfun(@isempty,(cellfun(@(x) find(contains(deblank(filter_coeff_temp.channelID),x)),deblank(CIDs_freq),'un',0))));
                end

                if ~isempty(idx)
                    props=fieldnames(filter_coeff_temp);
                    for iii=1:length(props)
                        if isprop(filter_cl(), (props{iii}))
                            trans_obj(idx).Filters(stage).(props{iii})=filter_coeff_temp.(props{iii});
                        end
                    end
                end

            case {'RAW3';'RAW0';'RAW4'}

                switch idx_raw_obj.type_dg{idg}
                    case 'RAW4'
                        continue;
                        fseek(fid,idx_raw_obj.pos_dg(idg)-pos+HEADER_LEN,'cof');
                        channelID = (fread(fid,128,'char=>char')');
                        %idx = find(contains(deblank(CIDs_freq),deblank(channelID)));
                        idx = find(idx_raw_obj.chan_dg(idg)==channels);
                        if isempty(idx)
                            continue;
                        end


                    case 'RAW3'
                        %disp(dgType);
                        % read channel ID
                        fseek(fid,idx_raw_obj.pos_dg(idg)-pos+HEADER_LEN,'cof');

                        channelID = (fread(fid,128,'char=>char')');
                        %idx = find(contains(deblank(CIDs_freq),deblank(channelID)));
                        idx = find(idx_raw_obj.chan_dg(idg)==channels);

                        if isempty(idx)||i_ping(idx)>nb_pings(idx)
                            continue;
                        end

                        datatype=fread(fid,1,'int16');
                        fread(fid,1,'int16');

                        data.pings(idx).datatype=fliplr(dec2bin(datatype,11));

                        temp=fread(fid,2,'int32');
                        %  store sample number if required/valid
                        number=i_ping(idx);

                        data.pings(idx).channelID=channelID;

                        data.pings(idx).offset(i_ping(idx))=temp(1);
                        data.pings(idx).sampleCount(i_ping(idx))=temp(2);
                        data.pings(idx).number(i_ping(idx))=number;
                        data.pings(idx).time(i_ping(idx))=dgTime;
                        sampleCount=temp(2);

                        if data.pings(idx).datatype(1)==dec2bin(1)
                            array_type='single';
                            if (sampleCount > 0)
                                if block_i(idx)==1
                                    data_tmp{idx}.power=-999*ones(nb_samples_per_block{idx}(block_nb(idx)),min(block_len,nb_pings(idx)-i_ping(idx)+1,'omitnan'),array_type);
                                    if data.pings(idx).datatype(2)==dec2bin(1)
                                        data_tmp{idx}.AcrossPhi=zeros(nb_samples_per_block{idx}(block_nb(idx)),min(block_len,nb_pings(idx)-i_ping(idx)+1,'omitnan'),array_type);
                                        data_tmp{idx}.AlongPhi=zeros(nb_samples_per_block{idx}(block_nb(idx)),min(block_len,nb_pings(idx)-i_ping(idx)+1,'omitnan'),array_type);
                                    end
                                end


                                if data.pings(idx).datatype(2)==dec2bin(1)

                                    if sampleCount*4==idx_raw_obj.len_dg(idg)-HEADER_LEN-12-128
                                        data_tmp{idx}.power(1:sampleCount,block_i(idx))=raw0_pow_conv*(fread(fid,sampleCount,'int16'));
                                        angles=fread(fid,[2 sampleCount],'int8');
                                        sampleCount=size(angles,2);
                                        data_tmp{idx}.AcrossPhi(1:sampleCount,block_i(idx))=angles(1,:);
                                        data_tmp{idx}.AlongPhi(1:sampleCount,block_i(idx))=angles(2,:);
                                    end

                                else
                                    data_tmp{idx}.power(1:sampleCount,block_i(idx))=raw0_pow_conv*(fread(fid,sampleCount,'int16'));
                                end


                            end
                        else
                            array_type='double';
                            nb_cplx_per_samples=bin2dec(fliplr(data.pings(idx).datatype(8:end)));

                            if data.pings(idx).datatype(4)==dec2bin(1)
                                fmt='float32';
                            elseif data.pings(idx).datatype(3)==dec2bin(1)
                                fmt='int16';
                            end

                            if (sampleCount > 0)
                                temp = fread(fid,[nb_cplx_per_samples sampleCount],sprintf('%s',fmt));
                            else
                                temp=[];
                            end

                            if mod(numel(temp),nb_cplx_per_samples)~=0
                                sampleCount=0;
                            else
                                sampleCount= numel(temp)/(nb_cplx_per_samples);
                            end

                            if (sampleCount > 0)
                                if block_i(idx)==1
                                    for isig=1:nb_cplx_per_samples/2
                                        data_tmp{idx}.(sprintf('comp_sig_%1d',isig))=zeros(nb_samples_per_block{idx}(block_nb(idx)),min(block_len,nb_pings(idx)-i_ping(idx)+1,'omitnan'),array_type);
                                    end
                                end
                                id=find(trans_obj(idx).Params.PulseLength>0,1,'last');
                                Np=2*round(trans_obj(idx).Params.PulseLength(id)/trans_obj(idx).Params.SampleInterval(id));
                                %                             idx_reshuffle=[3 4 1 2];
                                %                             polarity=[-1 1 -1 1];
                                for isig=1:nb_cplx_per_samples/2
                                    %                                 switch trans_obj(idx).Config.TransducerSerialNumber
                                    %                                     case '28332'
                                    %                                         if polarity(idx)>=1
                                    %                                             data_tmp{idx}.(sprintf('comp_sig_%1d',idx_reshuffle(isig)))(1:sampleCount,block_i(idx))=(temp(1+2*(isig-1),:)+1i*temp(2+2*(isig-1),:));
                                    %                                         else
                                    %                                             data_tmp{idx}.(sprintf('comp_sig_%1d',idx_reshuffle(isig)))(1:sampleCount,block_i(idx))=conj(temp(1+2*(isig-1),:)+1i*temp(2+2*(isig-1),:));
                                    %                                         end
                                    %                                     otherwise
                                    %                                         data_tmp{idx}.(sprintf('comp_sig_%1d',isig))(1:sampleCount,block_i(idx))=temp(1+2*(isig-1),:)+1i*temp(2+2*(isig-1),:);
                                    %                                 end
                                    data_tmp{idx}.(sprintf('comp_sig_%1d',isig))(1:sampleCount,block_i(idx))=temp(1+2*(isig-1),:)+1i*temp(2+2*(isig-1),:);

                                    if iscell(trans_obj(idx).TransducerImpedance)
                                        tmp_real=temp(1+2*(isig-1),1:Np);
                                        tmp_imag=temp(2+2*(isig-1),1:Np);
                                        trans_obj(idx).TransducerImpedance{isig,i_ping(idx)}=tmp_real+1i*tmp_imag;
                                    end
                                end
                            end

                        end
                    case 'RAW0'
                        chan=idx_raw_obj.chan_dg(idg);
                        idx=find(chan==channels);

                        if isempty(idx)||i_ping(idx)>nb_pings(idx)
                            continue;
                        end

                        %fseek(fid,idx_raw_obj.pos_dg(idg),'bof');
                        fseek(fid,idx_raw_obj.pos_dg(idg)-pos+HEADER_LEN,'cof');
                        data.pings(idx).time(i_ping(idx))=idx_raw_obj.time_dg(idg);

                        temp=fread(fid,2,'int16');

                        if ~isempty(temp)

                            data.pings(idx).mode(i_ping(idx))=temp(1);
                            data.pings(idx).datatype=fliplr(dec2bin(temp(2),11));

                            if block_i(idx)==1
                                data_tmp{idx}.power=-999*ones(nb_samples_per_block{idx}(block_nb(idx)),min(block_len,nb_pings(idx)-i_ping(idx)+1,'omitnan'),array_type);

                                if data.pings(idx).datatype(2)==dec2bin(1)
                                    data_tmp{idx}.AcrossPhi=zeros(nb_samples_per_block{idx}(block_nb(idx)),min(block_len,nb_pings(idx)-i_ping(idx)+1,'omitnan'),array_type);
                                    data_tmp{idx}.AlongPhi=zeros(nb_samples_per_block{idx}(block_nb(idx)),min(block_len,nb_pings(idx)-i_ping(idx)+1,'omitnan'),array_type);
                                end
                            end

                            [data,power_tmp,angles]=readRaw0(data,idx,i_ping(idx),fid);


                            data_tmp{idx}.power(1:numel(power_tmp),block_i(idx))=raw0_pow_conv*power_tmp;
                            if data.pings(idx).datatype(2)==dec2bin(1)
                                data_tmp{idx}.AcrossPhi(1:size(angles,2),block_i(idx))=angles(1,:);
                                data_tmp{idx}.AlongPhi(1:size(angles,2),block_i(idx))=angles(2,:);
                            end

                        else
                            if i_ping(idx)>1
                                data.pings(idx).transducerdepth(i_ping(idx)) = data.pings(idx).transducerdepth(i_ping(idx)-1) ;
                                data.pings(idx).frequency(i_ping(idx)) = data.pings(idx).frequency(i_ping(idx)-1) ;
                                data.pings(idx).transmitpower(i_ping(idx)) = data.pings(idx).transmitpower(i_ping(idx)-1) ;
                                data.pings(idx).pulselength(i_ping(idx)) = data.pings(idx).pulselength(i_ping(idx)-1) ;
                                data.pings(idx).bandwidth(i_ping(idx)) = data.pings(idx).bandwidth(i_ping(idx)-1) ;
                                data.pings(idx).sampleinterval(i_ping(idx)) = data.pings(idx).sampleinterval(i_ping(idx)-1) ;
                                data.pings(idx).soundvelocity(i_ping(idx)) = data.pings(idx).soundvelocity(i_ping(idx)-1) ;
                                data.pings(idx).absorptioncoefficient(i_ping(idx)) = data.pings(idx).absorptioncoefficient(i_ping(idx_chan)-1) ;
                            end
                        end
                end


                if block_i(idx)==block_len||i_ping(idx)==nb_pings(idx)
                    idx_ping=(block_len*(block_nb(idx)-1)+1):i_ping(idx);

                    if block_nb(idx)==1
                        switch ftype
                            case 'EK80'

                            case {'EK60'}
                                [trans_obj(idx).Config,trans_obj(idx).Params]=config_from_ek60(data.pings(idx),config_EK60(idx_freq(idx)),ftype);
                                envdata.SoundSpeed=data.pings(1).soundvelocity(1);
                            case {'ME70' 'MS70'}
                                [trans_obj(idx).Config,~]=config_from_ek60(data.pings(idx),config_EK60(idx_freq(idx)),ftype);
                                if isfield(data.pings,'soundvelocity')
                                    envdata.SoundSpeed=data.pings(1).soundvelocity(1);
                                end
                        end
                    end
                    trans_obj(idx).Mode=get_mode(trans_obj(idx),data.pings(idx).datatype);
                    if gps_only == 0
                        write_data(data.pings(idx).datatype,trans_obj(idx),data_tmp{idx},(1:nb_samples_per_block{idx}(block_nb(idx))),idx_ping,gpu_comp,p.Results.Keep_complex_data);
                        % fc = trans_obj(idx).get_center_frequency(1);
                        % %f_max = max(trans_obj(idx).get_params_value('FrequencyStart',1),trans_obj(idx).get_params_value('FrequencyEnd',1));
                        % fs = 1/trans_obj(idx).Params.SampleInterval(1);
                        % f_fact = floor(fc/fs);
                        % switch trans_obj(idx).Mode
                        %     case 'FM'
                        %         plot_quadrant_spectrum(data_tmp{idx},fc,1500,255,256,fs,[0 50],[-10 10],f_fact);
                        %     case'CW'
                        %         plot_quadrant_spectrum(data_tmp{idx},fc,1500,255,256,fs,[0 50],[-5 5],f_fact);
                        % end
                    end

                    block_i(idx)=0;
                    block_nb(idx)=block_nb(idx)+1;
                end

                i_ping(idx) = i_ping(idx) + 1;
                block_i(idx)=block_i(idx)+1;

            case 'MRU0'
                id_mru0 = id_mru0+1;
                fseek(fid,idx_raw_obj.pos_dg(idg)-pos+HEADER_LEN,'cof');
                tmp=fread(fid,4,'float32');
                if~isempty(tmp)
                    mru0_att.Heave(id_mru0) = tmp(1);
                    mru0_att.Roll(id_mru0) = tmp(2);
                    mru0_att.Pitch(id_mru0) = tmp(3);
                    mru0_att.Heading(id_mru0) = tmp(4);
                end
            case 'MRU1'
                id_mru1 = id_mru1+1;
                fseek(fid,idx_raw_obj.pos_dg(idg)-pos+HEADER_LEN,'cof');
                id = fread(fid,4,'*char')';%#KMB
                dglen =  fread(fid,1,'uint16');
                dg_ver =  fread(fid,1,'uint16');
                UTC_sec_nanosec =  fread(fid,2,'uint32');

                mru1_att.Time(id_mru1) = datenum(datetime(UTC_sec_nanosec(1) + UTC_sec_nanosec(2).*10^-9,'ConvertFrom','posixtime'));
                mru1_att.Time(id_mru1) = datenum(datetime(UTC_sec_nanosec(1) + UTC_sec_nanosec(2).*10^-9,'ConvertFrom','posixtime'));
                Status =  fread(fid,1,'uint32');
                mru1_gps.Lat(id_mru1) =  fread(fid,1,'double');
                mru1_gps.Long(id_mru1) =  fread(fid,1,'double');
                ElHeight = fread(fid,1,'single');
                mru1_att.Roll(id_mru1) = fread(fid,1,'single');
                mru1_att.Pitch(id_mru1) = fread(fid,1,'single');
                mru1_att.Heading(id_mru1) = fread(fid,1,'single');
                mru1_att.Heave(id_mru1) = fread(fid,1,'single');
                %                 other_data =  fread(fid,16,'single');
                %                 UTC_sec_nanosec_delayed_heave = fread(fid,2,'uint32');
                %                 delayed_heave = fread(fid,1,'single');
        end
    catch err
        print_errors_and_warnings([],'warning',sprintf('Issues trying to read %s datagram at position %d', idx_raw_obj.type_dg{idg},idx_raw_obj.pos_dg(idg)))
        print_errors_and_warnings([],'error',err);
    end
end

if id_mru1 > 1
    mru1_gps.Long(mru1_gps.Long<0)=mru1_gps.Long(mru1_gps.Long<0)+360;
    mru1_gps = mru1_gps.compute_dist_and_speed();
end

idx_rem_nmea=cellfun(@isempty,NMEA.string);
NMEA.string(idx_rem_nmea)=[];
NMEA.type(idx_rem_nmea)=[];
NMEA.time(idx_rem_nmea)=[];

%Complete Params if necessary

for idx=1:nb_trans
    nn = size(trans_obj(idx).Params.PulseLength,2);
    idx_nan=trans_obj(idx).Params.PulseLength==0;
    for jj=1:length(prop_params)
        if size(trans_obj(idx).Params.(prop_params{jj}),2) == nn
            trans_obj(idx).Params.(prop_params{jj})(idx_nan)=[];
        end
    end
end



if~isempty(envdata_def)
    props=properties(envdata_def);
    for ipp=1:numel(props)
        if isnumeric(envdata_def.(props{ipp}))
            if ~isnan(envdata_def.(props{ipp}))
                envdata.(props{ipp})=envdata_def.(props{ipp});
            end
        else
            envdata.(props{ipp})=envdata_def.(props{ipp});
        end
    end
end

for itr=1:nb_trans
    switch ftype
        case 'EK80'

        case {'EK60'}

            [trans_obj(itr).Config,trans_obj(itr).Params]=config_from_ek60(data.pings(itr),config_EK60(idx_freq(itr)),ftype);
            envdata.SoundSpeed=data.pings(1).soundvelocity(1);
        case {'ME70' 'MS70'}
            [trans_obj(itr).Config,ptemp]=config_from_ek60(data.pings(itr),config_EK60(idx_freq(itr)),ftype);

            if isempty(param_str_init{itr})
                trans_obj(itr).Params = ptemp;
            end

            if isfield(data.pings,'soundvelocity')
                envdata.SoundSpeed=data.pings(1).soundvelocity(1);
            end
    end
    trans_obj(itr).Config.MotionCompBool = [false false false false];
    
    switch ftype
        case {'ME70'}
            trans_obj(itr).Config.MotionCompBool = [true true false false];
        case {'MS70'}
            trans_obj(itr).Config.MotionCompBool = [true false false false];
    end

    trans_obj(itr).Mode=get_mode(trans_obj(itr),data.pings(itr).datatype);
    if block_i(itr)>1 && ~isempty(data_tmp{itr})
        idx_ping=(block_len*(block_nb(itr)-1)+1):i_ping(itr);
        if gps_only ==0
            write_data(data.pings(itr).datatype,trans_obj(itr),data_tmp{itr},(1:nb_samples_per_block{itr}(block_nb(itr))),idx_ping,gpu_comp,p.Results.Keep_complex_data);
        end
    end
end


id_rem=[];


for itr =1:nb_trans

    trans_obj(itr).reset_transceiver_depth();

    trans_obj(itr).Params=trans_obj(itr).Params.reduce_params();

    if gps_only==0
        trans_obj(itr).set_transceiver_time(data.pings(itr).time);
    else
        trans_obj(itr).set_transceiver_time([data.pings(itr).time dgTime]);
    end

    %trans_obj(itr).Config.SounderType = 'Split-beam (Simrad)';
    if gps_only ==0
        [~,range_t]=trans_obj(itr).compute_soundspeed_and_range(envdata);
        trans_obj(itr).set_transceiver_range(range_t);
        if ~isnan(alpha_file(itr))
            trans_obj(itr).set_absorption(alpha_file(itr));
        else
            trans_obj(itr).set_absorption(envdata);
        end
    end
end
trans_obj(id_rem)=[];

fclose(fid);
if PROF
    profile off;
    profile viewer;
end
end


function mode = get_mode(trans_obj,datatype)
if datatype(1)==dec2bin(1)
    mode='CW';
else
    if (trans_obj.Params.FrequencyStart(1)~=trans_obj.Params.FrequencyEnd(1))
        mode = 'FM';
    else
        mode ='CW';
    end
end
end

function write_data(datatype,trans_obj,data_tmp,idx_r,idx_ping,gpu_comp,Keep_complex_data)
mode = trans_obj.Mode;

switch datatype(1)
    case dec2bin(1)
        if datatype(2)==dec2bin(1)||datatype(1)==dec2bin(0)&&trans_obj.is_split_beam()

            [AlongAngle,AcrossAngle]=computesPhasesAngles_v3(data_tmp,...
                trans_obj.Config.AngleSensitivityAlongship,...
                trans_obj.Config.AngleSensitivityAthwartship,...
                datatype(2)==dec2bin(1),...
                trans_obj.Config.TransducerName,...
                trans_obj.Config.AngleOffsetAlongship,...
                trans_obj.Config.AngleOffsetAthwartship);
        end

        trans_obj.Data.replace_sub_data_v2(db2pow_perso(data_tmp.power),'power','idx_r',idx_r,'idx_ping',idx_ping);

        if  datatype(2)==dec2bin(1)&&trans_obj.is_split_beam()
            trans_obj.Data.replace_sub_data_v2(AlongAngle,'alongangle','idx_r',idx_r,'idx_ping',idx_ping)
            trans_obj.Data.replace_sub_data_v2(AcrossAngle,'acrossangle','idx_r',idx_r,'idx_ping',idx_ping)
        end

    otherwise

        switch mode
            case 'FM'

                [~,y_tx_matched,~]=trans_obj.get_pulse();
                Np=numel(y_tx_matched);
                ddr = floor(Np/2);
                data_tmp  = structfun(@(x) circshift(x,-ddr,1),data_tmp,'un',0);
                ff=fieldnames(data_tmp);

                for uif=1:numel(ff)
                    data_tmp.(ff{uif})(end-ddr:end,:)=0;
                end

            case 'CW'
                y_tx_matched = [];

        end

        [~,powerunmatched]=compute_PwEK80(trans_obj.Config.Impedance,trans_obj.Config.Ztrd,data_tmp);

        trans_obj.Config.NbQuadrants=sum(contains(fieldnames(data_tmp),'comp_sig'));

        data_tmp=match_filter_data(data_tmp,y_tx_matched,gpu_comp);
        nb_chan=sum(contains(fieldnames(data_tmp),'comp_sig'));
        
        if Keep_complex_data
            for ic=1:nb_chan
                s=data_tmp.(sprintf('comp_sig_%1d',ic));
                trans_obj.Data.replace_sub_data_v2(complex_single_to_double(s),sprintf('comp_sig_%1d',ic),'idx_r',idx_r,'idx_ping',idx_ping);
            end
        end

        if datatype(2)==dec2bin(1)||datatype(1)==dec2bin(0)&&trans_obj.is_split_beam()

            [AlongAngle,AcrossAngle]=computesPhasesAngles_v3(data_tmp,...
                trans_obj.Config.AngleSensitivityAlongship,...
                trans_obj.Config.AngleSensitivityAthwartship,...
                datatype(2)==dec2bin(1),...
                trans_obj.Config.TransducerName,...
                trans_obj.Config.AngleOffsetAlongship,...
                trans_obj.Config.AngleOffsetAthwartship);
        end

        switch mode
            case 'FM'
                [y,pow]=compute_PwEK80(trans_obj.Config.Impedance,trans_obj.Config.Ztrd,data_tmp);
                trans_obj.Data.replace_sub_data_v2(powerunmatched,'powerunmatched','idx_r',idx_r,'idx_ping',idx_ping)
                trans_obj.Data.replace_sub_data_v2(complex_single_to_double(y),'y','idx_r',idx_r,'idx_ping',idx_ping);
            case 'CW'
                pow=powerunmatched;
        end

        trans_obj.Data.replace_sub_data_v2(pow,'power','idx_r',idx_r,'idx_ping',idx_ping);
        if trans_obj.is_split_beam()
            trans_obj.Data.replace_sub_data_v2(AlongAngle,'alongangle','idx_r',idx_r,'idx_ping',idx_ping)
            trans_obj.Data.replace_sub_data_v2(AcrossAngle,'acrossangle','idx_r',idx_r,'idx_ping',idx_ping)
        end

end
end



