function [layers,id_rem] = open_NETCDF4_file_stdalone(Filename_cell,varargin)
id_rem = [];
layers = layer_cl.empty();

p = inputParser;

if ~iscell(Filename_cell)
    Filename_cell = {Filename_cell};
end

if ~iscell(Filename_cell)
    Filename_cell = {Filename_cell};
end

if isempty(Filename_cell)
    return;
end

def_path_m = fullfile(tempdir,'data_echo');

if ischar(Filename_cell)
    def_gps_only_val = 0;
else
    def_gps_only_val = zeros(1,numel(Filename_cell));
end

addRequired(p,'Filename_cell',@(x) ischar(x)||iscell(x));
addParameter(p,'PathToMemmap',def_path_m,@ischar);
addParameter(p,'Calibration',[]);
addParameter(p,'Frequencies',[]);
addParameter(p,'Channels',{});
addParameter(p,'GPSOnly',def_gps_only_val);
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
addParameter(p,'load_bar_comp',[]);

parse(p,Filename_cell,varargin{:});

nb_files = numel(Filename_cell);
load_bar_comp = p.Results.load_bar_comp;

if ~isempty(load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_files,'Value',0);
end

layers(length(Filename_cell)) = layer_cl();
id_rem = [];

block_len = get_block_len(50,'cpu',p.Results.block_len);

for uu = 1:nb_files

    if ~isempty(load_bar_comp)
        str_disp=sprintf('Opening File %d/%d : %s',uu,nb_files,Filename_cell{uu});
        load_bar_comp.progress_bar.setText(str_disp);
    end

    Filename = Filename_cell{uu};
    if ~isfile(Filename)
        id_rem = union(id_rem,uu);
        continue;
    end

    [att_struct,all_dataset_names] = get_att_values_and_dataset_names(Filename,[],[],{},true,true);

    if ~isfield(att_struct,'Sonar')
        print_errors_and_warnings([],'Warning',sprintf('No Sonar data/group in file %s',Filename));
        continue;
    end

    fields_to_complete = {'sonar_manufacturer' 'sonar_model' 'sonar_software_version' 'sonar_serial_number'};

    for uif = 1:numel(fields_to_complete)
        if ~isfield(att_struct.Sonar,fields_to_complete{uif})
            print_errors_and_warnings([],'warning',sprintf('%s fields not filled in NetCDF file\n',fields_to_complete{uif}));
            att_struct.Sonar.(fields_to_complete{uif}) = 'unknown';
        end
    end
      
    env_data_obj = env_data_cl();

    if isfield(att_struct,'Environment') && att_struct.Environment.sound_speed_indicative < 1600
        env_data_obj.SoundSpeed = double(att_struct.Environment.sound_speed_indicative);
    end

    sonar_group_names = fieldnames(att_struct.Sonar);
    is_beam_group  =false(1,numel(sonar_group_names));
    for uif = 1:numel(sonar_group_names)
        is_beam_group(uif) = isstruct(att_struct.Sonar.(sonar_group_names{uif}));
    end
  
    sonar_group_names = sonar_group_names(is_beam_group);
    nb_sonar_groups = numel(sonar_group_names);

    dataset_names_n = cellfun(@(x) regexprep(x,'/(\d*)/','/x$1/'),all_dataset_names,'un',false);
    dataset_names_n = cellfun(@(x) strrep(x,'/','.'),dataset_names_n,'un',false);

    idx_position = find(contains(dataset_names_n,'.latitude'),1);
    if ~isempty(idx_position)
        idx_tmp = strfind(dataset_names_n{idx_position},'.');
        dataset_pos = dataset_names_n{idx_position}(1:idx_tmp(end)-1);
        idx_tmp  = find(contains(dataset_names_n,sprintf('%s.time',dataset_pos)),1);
        dataset_pos_time = dataset_names_n{idx_tmp};
        gps_data_struct = get_struct_data(att_struct,dataset_pos);
        gps_data_struct.time =  datenum(1601, 1, 1, 0, 0, double(get_struct_data(att_struct,dataset_pos_time)/1e9));
    end

    idx_attitude = find(contains(dataset_names_n,'.pitch'),1);

    if ~isempty(idx_attitude)
        idx_tmp = strfind(dataset_names_n{idx_attitude},'.');
        dataset_att = dataset_names_n{idx_attitude}(1:idx_tmp(end)-1);
        idx_tmp  = find(contains(dataset_names_n,sprintf('%s.time',dataset_att)),1);
        dataset_att_time = dataset_names_n{idx_tmp};
        att_data_struct = get_struct_data(att_struct,dataset_att);
        att_data_struct.time =  datenum(1601, 1, 1, 0, 0, double(get_struct_data(att_struct,dataset_att_time)/1e9));
    end
        

gps_data_tot = gps_data_cl.empty();
    if ~isempty(idx_position)

        switch att_struct.Sonar.sonar_model
            case {'FCV-38'}
                lat_deg = sign(gps_data_struct.latitude).*floor(abs(gps_data_struct.latitude));
                lat_min_dec = (gps_data_struct.latitude-lat_deg)/0.6;
                gps_data_struct.latitude =lat_deg+lat_min_dec;

                lon_deg = sign(gps_data_struct.longitude).*floor(abs(gps_data_struct.longitude));
                lon_min_dec = (gps_data_struct.longitude-lon_deg)/0.6;
                gps_data_struct.longitude = lon_deg+lon_min_dec;
        end
        num_elt = min([numel(gps_data_struct.latitude) numel(gps_data_struct.longitude) numel(gps_data_struct.time)]);
        num_elt = min(num_elt(num_elt>0));
        if num_elt > 0
            gps_data_tot = gps_data_cl(...
                'Lat',gps_data_struct.latitude(1:num_elt),...
                'Long',gps_data_struct.longitude(1:num_elt),...
                'Time',gps_data_struct.time(1:num_elt));
        end
    end

    att_data_tot = attitude_nav_cl.empty();
    if ~isempty(idx_attitude)
        num_elt = min([numel(att_data_struct.heading) numel(att_data_struct.pitch) numel(att_data_struct.roll) numel(att_data_struct.time)]);
        num_elt = min(num_elt(num_elt>0));
        if num_elt > 0
            att_data_tot =attitude_nav_cl(...
                'Heading',att_data_struct.heading(1:num_elt),...
                'Pitch',att_data_struct.pitch(1:num_elt),...
                'Roll', att_data_struct.roll(1:num_elt),...
                'Time',att_data_struct.time(1:num_elt));
        end

    end
    trans_obj_tot = [];

    data_to_write = ...
        {'backscatter_r'  'backscatter_i' ...
        'echoangle_minor' 'echoangle_major' 'correlation'...
        'ADCP/velocity',...
        'ADCP/current_velocity_geographical_down' ...
        'ADCP/current_velocity_geographical_east' ...
        'ADCP/current_velocity_geographical_north'};

    for itr = 1:nb_sonar_groups

%         dataset_names  = all_dataset_names(contains(cellfun(@clean_str,all_dataset_names,'un',0),sonar_group_names{itr}));
% 
%         dataset_names = dataset_names(contains(dataset_names,data_to_write));
%         
        data_fields = fieldnames( att_struct.Sonar.(sonar_group_names{itr}));
       
        ek60_format = true;
        
        if all(ismember({'backscatter_r' 'backscatter_i'},data_fields)) && ~isempty(att_struct.Sonar.(sonar_group_names{itr}).backscatter_i)
            ek60_format = false;
        end

        %along is major, across is minor

        nb_beams  = size(att_struct.Sonar.(sonar_group_names{itr}).beam,1);
        nb_elt_per_beams  = size(att_struct.Sonar.(sonar_group_names{itr}).backscatter_r,1)/nb_beams;
        nb_elt_tot  = size(att_struct.Sonar.(sonar_group_names{itr}).backscatter_r,1);
        nb_chan = nb_beams;
        adcp_bool = false;
        
        if isfield(att_struct.Sonar.(sonar_group_names{itr}),'ADCP')
            nb_chan = nb_chan+1;
            adcp_bool = true;
        end

        for uib = 1:nb_chan
            
            if (uib <= nb_beams && adcp_bool) || ~adcp_bool
                id_beam = uib:nb_elt_tot/nb_elt_per_beams:nb_elt_tot;

                if isfield(att_struct.Sonar.(sonar_group_names{itr}),'backscatter_r')
                    backscatter_r = att_struct.Sonar.(sonar_group_names{itr}).backscatter_r(id_beam,:);
                end

                if isfield(att_struct.Sonar.(sonar_group_names{itr}),'echoangle_minor')
                    echoangle_minor =  att_struct.Sonar.(sonar_group_names{itr}).echoangle_minor(id_beam,:);
                    echoangle_major =  att_struct.Sonar.(sonar_group_names{itr}).echoangle_major(id_beam,:);
                end

                if isfield(att_struct.Sonar.(sonar_group_names{itr}),'backscatter_i')
                    backscatter_i = att_struct.Sonar.(sonar_group_names{itr}).backscatter_i(id_beam,:);
                end

                if adcp_bool && isfield(att_struct.Sonar.(sonar_group_names{itr}).ADCP,'velocity')
                    velocity = att_struct.Sonar.(sonar_group_names{itr}).ADCP.velocity(id_beam,:);
                end

                if adcp_bool && isfield(att_struct.Sonar.(sonar_group_names{itr}).ADCP,'correlation')
                    correlation = att_struct.Sonar.(sonar_group_names{itr}).ADCP.correlation(id_beam,:);
                end

            else
                id_beam = 1:nb_beams;
                backscatter_r = att_struct.Sonar.(sonar_group_names{itr}).backscatter_r;
                backscatter_i = att_struct.Sonar.(sonar_group_names{itr}).backscatter_i;
                correlation = att_struct.Sonar.(sonar_group_names{itr}).ADCP.correlation;
                current_velocity_geographical_down = att_struct.Sonar.(sonar_group_names{itr}).ADCP.current_velocity_geographical_down';
                current_velocity_geographical_east = att_struct.Sonar.(sonar_group_names{itr}).ADCP.current_velocity_geographical_east';
                current_velocity_geographical_north = att_struct.Sonar.(sonar_group_names{itr}).ADCP.current_velocity_geographical_north';
            end

            nb_samples_per_pings = max(cellfun(@numel,backscatter_r),[],1)/nb_beams;
            nb_pings  = size(nb_samples_per_pings,2);

            params_obj = params_cl(nb_pings,1);
            params_obj.BeamNumber = 1;

            params_obj.Frequency  = (att_struct.Sonar.(sonar_group_names{itr}).transmit_frequency_start(:)+att_struct.Sonar.(sonar_group_names{itr}).transmit_frequency_stop(:))'/2;
            params_obj.FrequencyStart  = att_struct.Sonar.(sonar_group_names{itr}).transmit_frequency_start(:)';
            params_obj.FrequencyEnd  = att_struct.Sonar.(sonar_group_names{itr}).transmit_frequency_stop(:)';
            params_obj.BeamAngleAlongship = zeros(1,nb_pings);
            params_obj.BeamAngleAthwartship = zeros(1,nb_pings);
            params_obj.ChannelMode = ones(1,nb_pings);
            params_obj.PulseLength = att_struct.Sonar.(sonar_group_names{itr}).transmit_duration_nominal(:)';
            params_obj.TeffCompPulseLength = att_struct.Sonar.(sonar_group_names{itr}).transmit_duration_nominal(:)';

            if isfield(att_struct.Sonar.(sonar_group_names{itr}),'transmit_duration_equivalent')
                params_obj.TeffPulseLength = att_struct.Sonar.(sonar_group_names{itr}).transmit_duration_equivalent(:)';
            else
                params_obj.TeffPulseLength = att_struct.Sonar.(sonar_group_names{itr}).receive_duration_effective(:)';
            end

            params_obj.BandWidth = att_struct.Sonar.(sonar_group_names{itr}).transmit_bandwidth(:)';
            params_obj.BandWidth(isnan(params_obj.BandWidth)) = 0;
            params_obj.PulseForm;
            params_obj.SampleInterval = att_struct.Sonar.(sonar_group_names{itr}).sample_interval(:)';
            %params_obj.Slope = nan(1,nb_pings);
            params_obj.TransmitPower  = (att_struct.Sonar.(sonar_group_names{itr}).transmit_power(:)');

            if all(params_obj.TransmitPower == 0) && strcmpi(att_struct.Sonar.sonar_model,'FCV-38')
                params_obj.TransmitPower = 3.5*1e3*ones(size(params_obj.TransmitPower));
                print_errors_and_warnings([],'Warning','Transmit power not stored in .nc file, we will use 3.5kW per default, but this data is not usable quantitatively');
            end

            config_obj = config_cl();

            config_obj.EthernetAddress = '';
            config_obj.IPAddress = '';
            config_obj.SerialNumber = att_struct.Sonar.sonar_serial_number;
            config_obj.TransceiverName = sprintf('%s_%s',att_struct.Sonar.sonar_manufacturer,att_struct.Sonar.sonar_model);
            config_obj.TransceiverNumber = itr;
            config_obj.TransceiverSoftwareVersion = att_struct.Sonar.sonar_software_version;
            config_obj.TransceiverType = att_struct.Sonar.sonar_model;
            config_obj.Frequency = min(params_obj.Frequency);
            config_obj.FrequencyMaximum = max(min(params_obj.FrequencyStart),min(params_obj.FrequencyEnd));
            config_obj.FrequencyMinimum = min(max(params_obj.FrequencyStart),max(params_obj.FrequencyEnd));

            if (uib<nb_chan && adcp_bool) || ~adcp_bool
                config_obj.ChannelID = char(att_struct.Sonar.(sonar_group_names{itr}).beam(uib,:));
                if isempty(config_obj.ChannelID)
                    config_obj.ChannelID = sprintf('%s_%s_%s_%.0fkHz_beam_%d',att_struct.Sonar.sonar_manufacturer,att_struct.Sonar.sonar_model,att_struct.Sonar.sonar_serial_number,config_obj.Frequency/1e3,uib);
                end
            else
                 config_obj.ChannelID = sprintf('%s_%s_%s_%.0fkHz_ADCP',att_struct.Sonar.sonar_manufacturer,att_struct.Sonar.sonar_model,att_struct.Sonar.sonar_serial_number,config_obj.Frequency/1e3);
            end

            config_obj.ChannelNumber = itr;
            config_obj.MaxTxPowerTransceiver = 0;
            config_obj.PulseLength = mean(att_struct.Sonar.(sonar_group_names{itr}).transmit_duration_nominal);
            config_obj.AngleOffsetAlongship = 0;
            config_obj.AngleOffsetAthwartship = 0;


            switch att_struct.Sonar.(sonar_group_names{itr}).beam_type{1}
                case 'split_aperture'
                    config_obj.BeamType = 'split-beam';
                case 'single'
                    config_obj.BeamType = 'single-beam';
                otherwise
                    config_obj.BeamType = 'split-beam';
            end

            config_obj.SoundSpeedNominal = env_data_obj.SoundSpeed;
            if att_struct.Sonar.(sonar_group_names{itr}).equivalent_beam_angle(1)>0
                config_obj.EquivalentBeamAngle = pow2db(mean(att_struct.Sonar.(sonar_group_names{itr}).equivalent_beam_angle,'all'));
            else
                config_obj.EquivalentBeamAngle = pow2db(mean(db2pow(att_struct.Sonar.(sonar_group_names{itr}).equivalent_beam_angle),'all'));
            end
            config_obj.BeamWidthAlongship = mean(att_struct.Sonar.(sonar_group_names{itr}).beamwidth_receive_major,'all');
            config_obj.BeamWidthAthwartship = mean(att_struct.Sonar.(sonar_group_names{itr}).beamwidth_receive_minor,'all');
            %config_obj.EquivalentBeamAngle = estimate_eba(config_obj.BeamWidthAlongship,config_obj.BeamWidthAthwartship);

            if isfield(att_struct.Sonar.(sonar_group_names{itr}),'transducer_gain')
                config_obj.Gain = att_struct.Sonar.(sonar_group_names{itr}).transducer_gain(1);
            elseif isfield(att_struct.Sonar.(sonar_group_names{itr}),'transmitter_and_receiver_coefficient')
                config_obj.Gain = att_struct.Sonar.(sonar_group_names{itr}).transmitter_and_receiver_coefficient(1);
            else
                config_obj.Gain = 0;
            end

            config_obj.Impedance = 1000;
            config_obj.Ztrd = 75;
            config_obj.MaxTxPowerTransducer = 4000;
            config_obj.SaCorrection = 0;
            config_obj.TransducerName = ...
                sprintf('Transducer_%s_%s_%s',...
                att_struct.Sonar.sonar_manufacturer,att_struct.Sonar.sonar_model,att_struct.Sonar.sonar_serial_number);
            config_obj.XML_string;
            config_obj.Cal_FM;
            config_obj.TransducerMounting = 'Hull';
            
            if numel(att_struct.Platform.transducer_rotation_x) >= itr
                itr_pos  = itr;
            else
                itr_pos = 1;
            end

            config_obj.TransducerAlphaX = att_struct.Platform.transducer_rotation_x(itr_pos);
            config_obj.TransducerAlphaY = att_struct.Platform.transducer_rotation_y(itr_pos);
            config_obj.TransducerAlphaZ = att_struct.Platform.transducer_rotation_z(itr_pos);
            config_obj.TransducerOffsetX = att_struct.Platform.transducer_offset_x(itr_pos);
            config_obj.TransducerOffsetY= att_struct.Platform.transducer_offset_y(itr_pos);
            config_obj.TransducerOffsetZ = att_struct.Platform.transducer_offset_z(itr_pos);
            config_obj.TransducerOrientation = 'Downward-looking';
            config_obj.TransducerSerialNumber = att_struct.Sonar.sonar_serial_number;
            config_obj.Version = att_struct.Sonar.sonar_software_version;
            config_obj.EsOffset = 0;
            config_obj.NbQuadrants = numel(att_struct.Sonar.(sonar_group_names{itr}).beam);
            config_obj.RXArrayShape = 'flat';
            config_obj.TXArrayShape = 'flat';

            if isfield(att_struct.Sonar.(sonar_group_names{itr}),'echoangle_minor_sensitivity')
                config_obj.AngleSensitivityAthwartship = mean(att_struct.Sonar.(sonar_group_names{itr}).echoangle_major_sensitivity);
                config_obj.AngleSensitivityAlongship  = mean(att_struct.Sonar.(sonar_group_names{itr}).echoangle_minor_sensitivity);
            end

            switch att_struct.Sonar.sonar_model
                case 'FCV-38'
                    config_obj.BeamWidthAlongship = sqrt(mean(att_struct.Sonar.(sonar_group_names{itr}).beamwidth_transmit_major(3:4))*mean(att_struct.Sonar.(sonar_group_names{itr}).beamwidth_receive_major(3:4)));
                    config_obj.BeamWidthAthwartship = sqrt(mean2(att_struct.Sonar.(sonar_group_names{itr}).beamwidth_transmit_minor(1:2))*mean(att_struct.Sonar.(sonar_group_names{itr}).beamwidth_receive_minor(1:2)));
                    config_obj.EquivalentBeamAngle = estimate_eba(config_obj.BeamWidthAlongship,config_obj.BeamWidthAthwartship);
                    L0 =  0.1469;
                    a = 0.1795;

                    TR_G = 24 + config_obj.Gain+10*log10(params_obj.TransmitPower/3500);

                    lambda  = env_data_obj.SoundSpeed./params_obj.Frequency;

                    AG = 10*log10(params_obj.TransmitPower.*lambda.^2/(16*pi^2));

                    config_obj.EquivalentBeamAngle = 10*log10(5.78/(2*pi*params_obj.Frequency(1)/env_data_obj.SoundSpeed*a).^2);

                    config_obj.AngleSensitivityAlongship   = 1/(env_data_obj.SoundSpeed/(2*pi*params_obj.Frequency(1)*L0));
                    config_obj.AngleSensitivityAthwartship = 1/(env_data_obj.SoundSpeed/(2*pi*params_obj.Frequency(1)*L0));
            end

            time_tr = datenum(1601, 1, 1, 0, 0, double(att_struct.Sonar.(sonar_group_names{itr}).ping_time)/1e9);

            [~,curr_filename,~]=fileparts(tempname);
            curr_data_name_t=fullfile(p.Results.PathToMemmap,curr_filename,'ac_data');
            nb_samples = max(nb_samples_per_pings,[],'all');
            if nb_samples==0
                continue;
            end
            nb_pings = size(nb_samples_per_pings,2);

            [nb_samples_s,~,~,bid]= group_pings_per_samples(max(nb_samples_per_pings,[],1),1:numel(nb_samples_per_pings));
            

            ac_data_temp = ac_data_cl('SubData',[],...
                'Nb_samples', nb_samples_s,...
                'Nb_pings',   nb_pings,...
                'BlockId', bid,...
                'Nb_beams',   ones(size(nb_samples_s)),...
                'MemapName',  curr_data_name_t);

            ac_data_temp.init_sub_data('power','DefaultValue',0);
            
            if isfield(att_struct.Sonar.(sonar_group_names{itr}),'echoangle_minor') || numel(id_beam)>1
                ac_data_temp.init_sub_data('acrossangle','DefaultValue',0);
                ac_data_temp.init_sub_data('alongangle','DefaultValue',0);
            end


            num_ite = ceil(nb_pings/block_len);

            switch att_struct.Sonar.(sonar_group_names{itr}).transmit_type{1}
                case {'LFM' 'HFM' 'FM'}
                    pulse_type = 'FM';
                    ac_data_temp.init_sub_data('powerunmatched','DefaultValue',0);
                    ac_data_temp.init_sub_data('y','DefaultValue',0);
                otherwise
                    pulse_type = 'CW';
            end
            trans_obj=transceiver_cl('Data',ac_data_temp,...
                'Time',time_tr,...
                'Config',config_obj,...
                'Mode',pulse_type,...
                'Params',params_obj);

            switch config_obj.BeamType
                case 'single-beam'
                    config_obj.SounderType = sprintf('Single-beam (%s, %s)',att_struct.Sonar.sonar_manufacturer,att_struct.Sonar.sonar_model);
                case 'split-beam'
                    config_obj.SounderType = sprintf('Split-beam (%s, %s)',att_struct.Sonar.sonar_manufacturer,att_struct.Sonar.sonar_model);
            end

            %num_ite = 1;
            if ~isempty(load_bar_comp)
                set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite,'Value',0);
            end
            idx_ping_tot = 1:nb_pings;

            for ui = 1:num_ite
                idx_ping_t = idx_ping_tot((ui-1)*block_len+1:min(ui*block_len,nb_pings));
                nb_samples_tmp = max(nb_samples_per_pings(:,idx_ping_t),[],1);
                id_sep = find(abs(diff(nb_samples_tmp))>0);

                if isempty(id_sep)
                    id_start = idx_ping_t(1);
                    id_end = idx_ping_t(end);
                else

                    id_start = idx_ping_t([1 id_sep+1]);
                    id_end = idx_ping_t([id_sep numel(idx_ping_t)]);
                end

                for iit = 1:numel(id_start)
                    idx_ping = id_start(iit):id_end(iit);
                    data_tmp = [];

                    if ~ek60_format && isfield(att_struct.Sonar.(sonar_group_names{itr}),'backscatter_i')

                        for uis = 1:size(backscatter_r,1)
                            data_tmp.(sprintf('comp_sig_%d',uis))=(cell2mat(backscatter_r(uis,idx_ping))+1i*cell2mat(backscatter_i(uis,idx_ping)));
                        end

                    else
                        % raw0_pow_conv = (10 * log10(2) / 256);
                        % 
                        % data_tmp.power = db2pow_perso(raw0_pow_conv * double(cell2mat(backscatter_r(1,idx_ping)));

                        data_tmp.power = double(cell2mat(backscatter_r(1,idx_ping)));
                        if isfield(att_struct.Sonar.(sonar_group_names{itr}),'echoangle_minor')
                            data_tmp.echoangle_minor = double(cell2mat(echoangle_minor(1,idx_ping)));
                            data_tmp.echoangle_major = double(cell2mat(echoangle_major(1,idx_ping)));
                        end
                    end
                    
                    if adcp_bool
                        for uipp = idx_ping
                        if uib <= nb_beams
                            
                            if adcp_bool&&isfield(att_struct.Sonar.(sonar_group_names{itr}).ADCP,'velocity')
                                    trans_obj.Data.replace_sub_data_v2(cell2mat(velocity(1,uipp)),'velocity','idx_ping',uipp)
                            end

                            if isfield(att_struct.Sonar.(sonar_group_names{itr}).ADCP,'correlation')
                                trans_obj.Data.replace_sub_data_v2(single(cell2mat(correlation(1,uipp))),'correlation','idx_ping',uipp)
                            end
                        else
                            if isfield(att_struct.Sonar.(sonar_group_names{itr}).ADCP,'correlation')
                                tmp = double(cell2mat(correlation(id_beam,uipp)));
                                tmp_2 = zeros(size(tmp,1)/nb_beams,size(tmp,2));
                                nn = size(tmp_2,1);
                                for uit = 1:nb_beams
                                    tmp_2 = tmp_2+tmp((1:nn)+(uit-1)*nn,:);
                                end
                                trans_obj.Data.replace_sub_data_v2(tmp_2/nb_beams,'correlation','idx_ping',uipp)
                            end

                            if isfield(att_struct.Sonar.(sonar_group_names{itr}).ADCP,'current_velocity_geographical_down')
                                trans_obj.Data.replace_sub_data_v2(cell2mat(current_velocity_geographical_down(1,uipp)),'velocity_down','idx_ping',uipp)
                            end

                            if isfield(att_struct.Sonar.(sonar_group_names{itr}).ADCP,'current_velocity_geographical_east')
                                    trans_obj.Data.replace_sub_data_v2(cell2mat(current_velocity_geographical_east(1,uipp)),'velocity_east','idx_ping',uipp)
                            end

                            if isfield(att_struct.Sonar.(sonar_group_names{itr}).ADCP,'current_velocity_geographical_north')
                                trans_obj.Data.replace_sub_data_v2(cell2mat(current_velocity_geographical_north(1,uipp)),'velocity_north','idx_ping',uipp)
                            end
                        end
                        end
                    end

                    switch att_struct.Sonar.sonar_model

                        case {'TBD:sonar_model' 'unknown'}
                            switch pulse_type
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
                            config_obj.NbQuadrants = sum(contains(fieldnames(data_tmp),'comp_sig'));
                            if ~ ek60_format
                                [~,powerunmatched]=compute_PwEK80(config_obj.Impedance,config_obj.Ztrd,data_tmp);
                                config_obj.NbQuadrants=sum(contains(fieldnames(data_tmp),'comp_sig'));

                                data_tmp=match_filter_data(data_tmp,y_tx_matched,0);

                                if trans_obj.is_split_beam()

                                    [data_tmp.echoangle_minor,data_tmp.echoangle_major]=computesPhasesAngles_v3(data_tmp,...
                                        config_obj.AngleSensitivityAlongship,...
                                        config_obj.AngleSensitivityAthwartship,...
                                        false,...
                                        config_obj.TransducerName,...
                                        config_obj.AngleOffsetAlongship,...
                                        config_obj.AngleOffsetAthwartship);
                                end

                                switch trans_obj.Mode
                                    case 'FM'
                                        [y,data_tmp.power]=compute_PwEK80(config_obj.Impedance,config_obj.Ztrd,data_tmp);
                                        trans_obj.Data.replace_sub_data_v2(powerunmatched,'powerunmatched','idx_ping',idx_ping);
                                        trans_obj.Data.replace_sub_data_v2(complex_single_to_double(y),'y','idx_ping',idx_ping);
                                    case 'CW'
                                        data_tmp.power=powerunmatched;
                                end
                            end
                        case 'FCV-38'
                            %                 stbd =s1;
                            %                 port =s2;
                            %                 fore=s3;
                            %                 aft =s4;

                            switch pulse_type
                                case 'FM'

                                    [~,y_tx_matched,~]=trans_obj.get_pulse();
                                    Np=numel(y_tx_matched);
                                    data_tmp  = structfun(@(x) circshift(x,-Np,1),data_tmp,'un',0);
                                    ff=fieldnames(data_tmp);
                                    for uif=1:numel(ff)
                                        data_tmp.(ff{uif})(end-Np:end,:)=0;
                                    end

                                case 'CW'
                                    y_tx_matched = [];

                            end

                            config_obj.NbQuadrants=sum(contains(fieldnames(data_tmp),'comp_sig'));

                            A_square  = 16*(((real(data_tmp.comp_sig_1)+real(data_tmp.comp_sig_2)).^2+(imag(data_tmp.comp_sig_1)+imag(data_tmp.comp_sig_2)).^2))/(2^32-1).^2 ;
                            data_tmp.power =  (A_square/2).* db2pow(AG(idx_ping))./ db2pow(TR_G(idx_ping));

                            if ~isempty(y_tx_matched)
                                ac_data_temp.replace_sub_data_v2(data_tmp.power,'powerunmatched','idx_ping',idx_ping);
                                y = data_tmp.comp_sig_1 + data_tmp.comp_sig_2;%Just a wild guess to make it somehow work for FCV-38
                                trans_obj.Data.replace_sub_data_v2(complex_single_to_double(y),'y','idx_ping',idx_ping);
                                data_tmp=match_filter_data(data_tmp,y_tx_matched,0);

                                A_square  = 16*(((real(data_tmp.comp_sig_1)+real(data_tmp.comp_sig_2)).^2+(imag(data_tmp.comp_sig_1)+imag(data_tmp.comp_sig_2)).^2))/(2^32-1).^2 ;
                                data_tmp.power =  (A_square/2).* db2pow(AG(idx_ping))./ db2pow(TR_G(idx_ping));
                            end

                            alongphi= angle(data_tmp.comp_sig_3.*conj(data_tmp.comp_sig_4));
                            acrossphi = angle(data_tmp.comp_sig_1.*conj(data_tmp.comp_sig_2));

                            data_tmp.echoangle_minor=asind(alongphi/config_obj.AngleSensitivityAthwartship)-config_obj.AngleOffsetAlongship;
                            data_tmp.echoangle_major=asind(acrossphi/config_obj.AngleSensitivityAthwartship)-config_obj.AngleOffsetAthwartship;

                        otherwise
                            dlg_perso([],'Sounder not supported.','Sounder %s not supported yet. Please contact the developers, send them a file and they will add it.',att_struct.Sonar.sonar_model);
                            id_rem = union(id_rem,uu);
                            continue;
                    end
                    trans_obj.Data.replace_sub_data_v2(data_tmp.power,'power','idx_ping',idx_ping);
                    if trans_obj.is_split_beam()
                        trans_obj.Data.replace_sub_data_v2(data_tmp.echoangle_minor,'alongangle','idx_ping',idx_ping)
                        trans_obj.Data.replace_sub_data_v2(data_tmp.echoangle_major,'acrossangle','idx_ping',idx_ping)
                    end
                end

                if ~isempty(load_bar_comp)
                    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite,'Value',ui);
                end
            end

            [~,range_t]=trans_obj.compute_soundspeed_and_range(env_data_obj);
            trans_obj.set_transceiver_range(range_t);

            trans_obj.set_pulse_Teff();
            trans_obj.set_pulse_comp_Teff();
            if isfield(att_struct,'Environment')
                [~,idf] = min(abs(att_struct.Environment.frequency - config_obj.Frequency));
                trans_obj.set_absorption(att_struct.Environment.absorption_indicative(idf));
            else

            end
            trans_obj_tot = [trans_obj_tot trans_obj];
        end



    end
    freqs = 1:numel(trans_obj_tot);

    for uit = 1:numel(freqs)
        freqs(uit) = trans_obj_tot(uit).Config.Frequency;
    end
    [~,id_sort] = sort(freqs);

    layers(uu)=layer_cl('Filename',{Filename},...
        'Filetype','NETCDF4',...
        'Transceivers',trans_obj_tot(id_sort),...
        'GPSData',gps_data_tot,...
        'AttitudeNav',att_data_tot,...
        'EnvData',env_data_obj);

    if ~isempty(load_bar_comp)
        set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(Filename_cell),'Value',uu);
    end
end
end




