function [layers,id_rem] = open_oculus_file_stdalone(Filename_cell,varargin)
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
addParameter(p,'load_bar_comp',[]);

parse(p,Filename_cell,varargin{:});

nb_files = numel(Filename_cell);
load_bar_comp = p.Results.load_bar_comp;

if ~isempty(load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_files,'Value',0);
end

layers = [];
id_rem = [];

%     f=figure();
%     ax = axes(f);
%     imh = imagesc(ax,0);
ilay  = 0;
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

    fid_tmp = fopen(Filename,'r','l','US-ASCII');
    tmp  =fread(fid_tmp,7,'*char')';
    fclose(fid_tmp);

    if contains(tmp,'SQLite')
        dbconn = connect_to_db(Filename);
    else
        dbconn = [];
    end



    if isempty(dbconn)%if if the file is not a database, it is the old format

        ip = 1;
        s=dir(Filename);
        f_size_bytes=s.bytes;
        [~,fid]  = oculus_read_functions.read_OculusLogHeader(Filename);
        oculus_ping_struct = [];

        while  ~feof(fid)
            tmp  = oculus_read_functions.read_OculusLogItem(fid);

            if ~isempty(load_bar_comp)
                fpos = ftell(fid);
                set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',f_size_bytes,'Value',fpos);
            end

            if tmp.messageType ==10
                ip = ip+1;
                oculus_ping_struct = [oculus_ping_struct tmp];
            elseif ~isempty(tmp.messageType)
                fprintf('Message type %d not read\n',tmp.messageType);
            end
        end

        fclose(fid);

    else

        SQL_init = 'SELECT entryId, timestamp, type, dataSourceId, length FROM data';
        data = dbconn.fetch(SQL_init);

        nb_pings = numel(data.entryId);
        fname_temp = tempname;
        tmp = [];
        oculus_ping_struct = [];
        cbool = false;
        for iping = 1:nb_pings
            try

                if ~isempty(load_bar_comp)
                    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_pings,'Value',iping);
                end
                tmp.messageType = 10;
                tmp.time_unix = data.timestamp(iping);
                tmp.time = tmp.time_unix / 86400 + datenum(1970, 1, 1);
                sql_cmd = sprintf('SELECT payload FROM data WHERE entryId = %d', data.entryId(iping));
                tt = dbconn.fetch(sql_cmd);

                input = tt.payload{1}(5:end);

                buffer = java.io.ByteArrayOutputStream();
                zlib = java.util.zip.InflaterOutputStream(buffer);

                zlib.write(input, 0, numel(input));
                zlib.close();

                output = typecast(buffer.toByteArray(), 'uint8')';

                cbool =false;
                fid = fopen(fname_temp,'w+');

                fwrite(fid,output);

                frewind(fid);

                tmp = oculus_read_functions.read_message(fid,tmp);

                fclose(fid);
                cbool =true;

                oculus_ping_struct = [oculus_ping_struct tmp];
            catch err
                print_errors_and_warnings([],'err',sprintf('Could not read payload %d from Oculus SQLite file %s\n',iping,Filename));
                print_errors_and_warnings([],'err',err);
                if ~cbool
                    fclose(fid);
                end
                continue;
            end
        end
        delete(fname_temp);


        dbconn.close();
    end

    if isempty(oculus_ping_struct)
        continue;
    end

    nb_pings = numel(oculus_ping_struct);
    %nb_samples = max([oculus_ping_struct(:).nRanges]);
    nb_beams = max([oculus_ping_struct(:).nBeams]);

    if nb_pings<=1
        continue;
    end


    freq = [oculus_ping_struct(:).frequency];
    dr = [oculus_ping_struct(:).rangeResolution];
    drr = [oculus_ping_struct(:).nRanges];
    nb = [oculus_ping_struct(:).nBeams];
    bb = mean(reshape([oculus_ping_struct(:).bearings],nb_beams,nb_pings));

    gg = findgroups(freq,dr,nb,bb,drr);

    idx_change = find(abs(diff(gg))>0);

    idg_start = [1 idx_change+1];
    idg_end = [idx_change numel(gg)];

    for idg = 1:numel(idg_start)

        ipings = idg_start(idg):idg_end(idg);

        nb_pings = numel(ipings);
        nb_samples = max([oculus_ping_struct(ipings).nRanges]);
        nb_beams = max([oculus_ping_struct(ipings).nBeams]);

        if nb_pings<=1
            continue;
        end
        [~,curr_filename,~]=fileparts(tempname);
        curr_data_name_t=fullfile(p.Results.PathToMemmap,curr_filename,'ac_data');

        ac_data_temp = ac_data_cl('SubData',[],...
            'Nb_samples', nb_samples,...
            'Nb_pings',   nb_pings,...
            'Nb_beams',   nb_beams,...
            'MemapName',  curr_data_name_t);
        c = mean([oculus_ping_struct(ipings).speedOfSoundUsed]);

        params_obj = params_cl(nb_pings,nb_beams);
        time_f = [oculus_ping_struct(ipings).time];


        PN = oculus_ping_struct(ipings(1)).partNumber;
        Master_mode = oculus_ping_struct(ipings(1)).masterMode;

        PNN = get_oculus_model(PN);
        config_obj = config_cl();
        config_obj.SerialNumber = num2str(oculus_ping_struct(ipings(1)).srcDeviceID);
        config_obj.ChannelID = sprintf('OCULUS_%s_%d',PNN,oculus_ping_struct(ipings(1)).srcDeviceID);
        config_obj.TransceiverName = sprintf('OCULUS_%s_%d',PNN,oculus_ping_struct(ipings(1)).srcDeviceID);
        config_obj.TransducerName = sprintf('OCULUS_%s_%d',PNN,oculus_ping_struct(ipings(1)).srcDeviceID);
        config_obj.TransceiverType = 'OCULUS';
        config_obj.ChannelNumber = 1;


        config_obj.Frequency = mean([oculus_ping_struct(ipings).frequency]);
        config_obj.FrequencyMinimum = mean([oculus_ping_struct(ipings).frequency]);
        config_obj.FrequencyMaximum = mean([oculus_ping_struct(ipings).frequency]);
        %TODO

        if PN ==0 %0 %Unknown part
            if config_obj.Frequency < 400*1e3
                PN = 1041;
            elseif config_obj.Frequency < 800*1e3 || config_obj.Frequency < 1500*1e3 && Master_mode == 2
                PN =1032;
            else
                PN = 1042;
            end
        end

        switch PN
            case {1041,1217,1229,1209,1218} %M370s ; M373s
                config_obj.BeamWidthAlongship = 20;
                config_obj.BeamWidthAthwartship = 2;
            case {1032,1134,1135} %M750d
                if Master_mode == 2
                    config_obj.BeamWidthAlongship = 12;
                    config_obj.BeamWidthAthwartship = 0.6;
                else
                    config_obj.BeamWidthAlongship = 20;
                    config_obj.BeamWidthAthwartship = 1;
                end
            case {1042, 1219, 1228,1220,1221} %M1200d, M1200s
                if Master_mode == 2
                    config_obj.BeamWidthAlongship = 12;
                    config_obj.BeamWidthAthwartship = 0.4;
                else
                    config_obj.BeamWidthAlongship = 20;
                    config_obj.BeamWidthAthwartship = 0.6;
                end
        end


        config_obj.BeamType = 'single-beam';%single beam (in each of the beams)

        params_obj.BeamAngleAlongship=zeros(nb_beams,nb_pings);
        params_obj.BeamAngleAthwartship=reshape([oculus_ping_struct(ipings).bearings],nb_beams,nb_pings);

        params_obj.SampleInterval=2*repmat([oculus_ping_struct(ipings).rangeResolution]/c,nb_beams,1);
        params_obj.PulseLength=ones(nb_beams,nb_pings)*10*mean(params_obj.SampleInterval,'all');
        params_obj.TransmitPower=10*ones(nb_beams,nb_pings);
        params_obj.Frequency = repmat([oculus_ping_struct(ipings).frequency],nb_beams,1);
        params_obj.FrequencyStart = repmat([oculus_ping_struct(ipings).frequency],nb_beams,1);
        params_obj.FrequencyEnd = repmat([oculus_ping_struct(ipings).frequency],nb_beams,1);

        mm = mode([oculus_ping_struct(ipings).dataSize]);
        switch mm
            case 0
                fmt_ori = 'uint8';
            case 1
                fmt_ori = 'uint16';
        end

        gg = [oculus_ping_struct(ipings).gain];
        comp_gain = true;

        if any(gg~=1,'all') && comp_gain
            fmt = 'single';
            fff = 'sv';
            ac_data_temp.init_sub_data(fff,'DefaultValue',-999,'Fmt',fmt);
        else
            fmt = fmt_ori;
            fff = 'img_intensity';
            ac_data_temp.init_sub_data(fff,'DefaultValue',0,'Fmt',fmt);
            comp_gain = false;
        end

        %         ff = figure();
        %         tiledlayout(ff,2,1)
        %         nexttile
        %         plot(mean(oculus_ping_struct(ipings(5000)).sonarData,2));
        %         nexttile
        %         plot(mean(gg(:,5000),2))

        for ui = 1:nb_pings

            if ~isempty(load_bar_comp)
                set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_pings,'Value',ui);
            end

            if comp_gain
                dd = permute(20*log10(oculus_ping_struct(ipings(ui)).sonarData./sqrt(oculus_ping_struct(ipings(ui)).gain)/single(intmax(fmt_ori))),[1 3 2]);
            else
                dd = permute(oculus_ping_struct(ipings(ui)).sonarData,[1 3 2]);
            end

            ac_data_temp.replace_sub_data_v2(dd,...
                fff,'idx_ping',ui,...
                'idx_r',1:oculus_ping_struct(ipings(ui)).nRanges,...
                'idx_beam',1:oculus_ping_struct(ipings(ui)).nBeams);
        end
        if all(isfield(oculus_ping_struct(ipings(1)), {'temperature','pitch'}))
            env_data_obj=env_data_cl('SoundSpeed',c,'Temperature',mean([oculus_ping_struct(ipings).temperature]),'Salinity',mean([oculus_ping_struct(ipings).salinity]));
        else
            env_data_obj=env_data_cl('SoundSpeed',c);
        end

        if all(isfield(oculus_ping_struct(ipings(1)), {'heading','pitch','roll'}))
            att = attitude_nav_cl('Time',time_f,...
                'Heading',[oculus_ping_struct(ipings).heading],...
                'Pitch',[oculus_ping_struct(ipings).pitch],...
                'Roll',[oculus_ping_struct(ipings).roll]);
        else
            att = attitude_nav_cl();
        end
        if isfield(oculus_ping_struct(ipings(1)), 'pressure')
            if env_data_obj.Salinity>10
                trans_depth = 1e5*([oculus_ping_struct(ipings).pressure])/(1023.6*9.8065);%seawater
            else
                trans_depth = 1e5*([oculus_ping_struct(ipings).pressure])/(997.04*9.8065);%freshwater
            end
        else
            trans_depth = zeros(1,nb_pings);
        end

        trans_obj=transceiver_cl('Data',ac_data_temp,...
            'Range',oculus_ping_struct(ipings(1)).rangeResolution*(0:nb_samples-1)',...
            'Ping_offset',ipings(1),...
            'Time',time_f,...
            'Config',config_obj,...
            'Mode','CW',...
            'Params',params_obj,...
            'TransceiverDepth',trans_depth);

        trans_obj.Config.SounderType = 'Imaging Multi-beam';

        trans_obj.set_absorption(env_data_obj);
        ilay = ilay +1;

        lay_temp=layer_cl('Filename',{Filename},'Filetype','OCULUS',...
            'AttitudeNav',att,...
            'Transceivers',trans_obj,...
            'EnvData',env_data_obj);

        layers =[layers lay_temp];

        if isfield(oculus_ping_struct(ipings(1)), 'pressure')
            pressure_line = line_cl('Name','OculusDepth from pressure','Range',trans_depth,'Time',time_f,'Tag','offset');
            layers(numel(layers)).add_lines(pressure_line);
        end
    end

    if ~isempty(load_bar_comp)
        set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(Filename_cell),'Value',uu);
    end

end


end




