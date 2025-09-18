function layers=read_crest(Filename_cell,varargin)

p = inputParser;
if ~iscell(Filename_cell)
    Filename_cell={Filename_cell};
end

[path_to_mem_def,~,~]=fileparts(Filename_cell{1});

addRequired(p,'Filename_cell',@(x) ischar(x)||iscell(x));
addParameter(p,'PathToMemmap',path_to_mem_def);
addParameter(p,'FieldNames',{});
addParameter(p,'CVSCheck',0);
addParameter(p,'CVSroot','');
addParameter(p,'SvCorr',1);
addParameter(p,'SaveTransObj',1);
addParameter(p,'load_bar_comp',[]);
parse(p,Filename_cell,varargin{:});


dir_data=p.Results.PathToMemmap;



machineformat = 'ieee-le'; %IEEE floating point with little-endian byte ordering
enc = 'UTF-8';
precision = 'int16'; %2-byte

load_bar_comp = p.Results.load_bar_comp;
cvs_root=p.Results.CVSroot;

if ~isequal(Filename_cell, 0)

    for uu=1:length(Filename_cell)
        try
           
            FileName=Filename_cell{uu};
            [~,fname,~]  = fileparts(FileName);

%             if p.Results.SaveTransObj
%                 dir_data = fullfile(data_folder);
%             end

            if ~isempty(p.Results.load_bar_comp)
                str_disp=sprintf('Opening File %d/%d : %s',uu,length(Filename_cell),Filename_cell{uu});
                p.Results.load_bar_comp.progress_bar.setText(str_disp);
            end
            
            filenumber=str2double(fname(2:end));
            fid = fopen(FileName,'r',machineformat,enc);
            s=dir(FileName);
            f_size_bytes=s.bytes;

            if fid == -1
                print_errors_and_warnings(1,'warning',sprintf('Unable to open file d%07d',filenumber));
                continue;
            end


            idx_mess=1;
            sample = [];
            type = [];
            ping_num = [];
            spare = [];
            origin = [];
            target = [];
            length_mess = [];
            pos = 0;
            while (true)
                try
                    tmp = fread(fid,6,precision);

                    if (feof(fid))
                        break;
                    end

                    type(idx_mess)=tmp(1);          %type (32="Bundled")
                    ping_num(idx_mess) = tmp(2); %sequence number
                    spare(idx_mess) = tmp(3); %spare
                    origin(idx_mess) = tmp(4); %origin
                    target(idx_mess) = tmp(5); %target
                    length_mess(idx_mess) = tmp(6); %length
                    
                    if ~isempty(load_bar_comp)
                        pos = pos + length_mess(idx_mess);
                        set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',f_size_bytes,'Value',pos);
                    end
                    data_tmp = fread(fid,length_mess(idx_mess)/2,precision);

                    if type(idx_mess)==32
                        nb_echoes = data_tmp(1);
                        id_ech = 1;
                        for u=1:nb_echoes
                            first_sample = data_tmp(1+id_ech);
                            nb_samples = data_tmp(2+id_ech);

                            if first_sample<=0 || nb_samples<=0
                                print_errors_and_warnings(1,'warning',sprintf('Issue reading ping %.0f from file %s',ping_num(idx_mess),FileName));
                                continue;
                            end

                            samples=data_tmp(3+id_ech:min(3+id_ech+2*nb_samples-1,numel(data_tmp)));
                            id_ech = 3+id_ech+numel(samples)-1;

                            if nb_samples==numel(samples)/2
                                sample(first_sample:first_sample+nb_samples-1,idx_mess)=samples(1:2:end)'+1j*samples(2:2:end)';
                            else
                                r_samp=samples(1:2:end)';
                                i_samp=samples(2:2:end)';
                                sample(first_sample:first_sample+numel(r_samp)-1,idx_mess)=r_samp+1j*i_samp;
                            end
                        end
                        idx_mess=idx_mess+1;
                    end

                catch err
                    print_errors_and_warnings(1,'warning',sprintf('Error reading ping %.0f from file %s',ping_num(idx_mess),FileName));
                    print_errors_and_warnings(1,'warning',err);
                    break;
                end

            end
            fclose(fid);

            pings=1:max(ping_num);
            samples_sum=nan(size(sample,1),max(pings));

            ifileinfo=parse_ifile(FileName);

            nb_channel = arrayfun(@(x) sum(x==ping_num),pings);
            if any(nb_channel<4 & nb_channel>1)
                
                if all(nb_channel == 2)||all(nb_channel ==3)
                    print_errors_and_warnings(1,'warning',sprintf('Strange number of channels in file %s',FileName));
                    print_errors_and_warnings(1,'warning',sprintf(['    There are %d channels in there.\n...' ...
                        '   Isn''t that weird? You might want to adjust calibration for this file'],...
                        nb_channel(1),FileName));
                else
                    print_errors_and_warnings(1,'warning',sprintf('Inconsistent number of channels in file %s',FileName));
                end
            end

            cal = ones(1,max(nb_channel));

            if max(nb_channel) == 4
                alongangle=nan(size(sample,1),max(pings));
                acrossangle=nan(size(sample,1),max(pings));
                if type(1)==32
                    cal(1) = ifileinfo.gain_compensation_SE;
                    cal(2) = ifileinfo.gain_compensation_SW;
                    cal(3) = -1.0;% these channels need to be negated see datareader\data\splitbeamdata.C
                    cal(4) = -ifileinfo.gain_compensation_NE;% these channels need to be negated
                end
            end

            for uip=pings
                idx=find(pings(uip)==ping_num);
                if isempty(idx)
                    continue;
                end
                nb_chan = numel(idx);
                id_chan = origin(idx);
                [~,id_s] = sort(id_chan);
                %id_s = 1:nb_chan;
                s_tmp = sample(:,idx(id_s));
                cal_tmp = cal(1:nb_channel(uip));

                id_inv = cal_tmp<0 & real(s_tmp) == intmax('int16') & imag(s_tmp) == intmax('int16');

                s_tmp(id_inv) = -s_tmp(id_inv);

                if nb_chan == 4
                    alongphi  = angle(sum(s_tmp(:,[3 4]).*cal([3 4]),2).*conj(sum(s_tmp(:,[1 2]).*cal([1 2]),2)));
                    acrossphi = angle(sum(s_tmp(:,[3 2]).*cal([3 2]),2).*conj(sum(s_tmp(:,[1 4]).*cal([1 4]),2)));
                    alongangle(1:end,uip)=asind(alongphi/ifileinfo.angle_factor_alongship)-ifileinfo.fore_aft_offset;
                    acrossangle(1:end,uip)=asind(acrossphi/ifileinfo.angle_factor_athwartship)-ifileinfo.port_stbd_offset;
                end
                samples_sum(1:end,uip)=sum(s_tmp.*cal(1:nb_channel(uip)),2);
            end

            %system_calibration=ifileinfo.system_calibration/nb_channel;
            system_calibration=ifileinfo.system_calibration;

            depth_factor=ifileinfo.depth_factor;
            data_offset = 0.0;

            samples_sum_cal=data_offset + samples_sum./system_calibration;

            start_time=ifileinfo.start_date;
            end_time=ifileinfo.finish_date;

            try
                survey_data=survey_data_cl('Snapshot',ifileinfo.snapshot,'Stratum',ifileinfo.stratum,'Transect',ifileinfo.transect);
            catch err
                print_errors_and_warnings([],'Warning',err);
                print_errors_and_warnings([],'Warning',sprintf('Could not import survey data from ifile for file %s',FileName));
            end

            
            samples_num=(1:size(samples_sum_cal,1))';
            trans_range=samples_num/depth_factor;
            number=(1:size(samples_sum_cal,2));
            Time=linspace(start_time,end_time,length(number));

             [gps_data,attitude_data,~]= read_n_file(fullfile(FileName),start_time,end_time);
            
        
            if isempty(gps_data)
                gps_data  = gps_data_cl('Lat',ifileinfo.Lat,'Long',ifileinfo.Lat,'Time',[start_time end_time]);
            end

            if isempty(attitude_data)
                attitude_data  = attitude_nav_cl('Time',Time);
            end

            gps_data_ping=gps_data.resample_gps_data(Time);
            attitude_data_pings=attitude_data.resample_attitude_nav_data(Time);

            power_ori=real(samples_sum_cal).^2+imag(samples_sum_cal).^2;

            corr=0;
            switch ifileinfo.sounder_type
                case {'E60' 'ES70'}
                    corr=-repmat(es60_error((1:size(power_ori,2))-ifileinfo.es60_zero_error_ping_num),size(power_ori,1),1);
            end

            Sv=10*log10(power_ori/p.Results.SvCorr)+10*log10(depth_factor)+corr;
            nb_pings=numel(Time);
            [config_obj,params_obj]=config_from_ifile(ifileinfo,nb_pings);

            pow=convert_Sv_to_pow(Sv,trans_range,ifileinfo.sound_speed,ifileinfo.absorption_coefficient/1000,...
                params_obj.TeffPulseLength,params_obj.PulseLength,...
                params_obj.TransmitPower,ifileinfo.sound_speed./params_obj.Frequency,...
                config_obj.Gain,config_obj.EquivalentBeamAngle,config_obj.SaCorrection,'CREST');

            [~,curr_filename,~]=fileparts(tempname);

            curr_name=fullfile(dir_data,curr_filename,'ac_data');

            sub_ac_data = sub_ac_data_cl('power','memapname',curr_name,'data',pow);

            ac_data_temp=ac_data_cl('SubData',sub_ac_data,...
                'Nb_samples',length(trans_range),...
                'Nb_pings',size(pow,2),...
                'MemapName',curr_name);


            trans_obj=transceiver_cl('Data',ac_data_temp,...
                'Config',config_obj,...
                'Params',params_obj,...
                'Range',trans_range,...
                'Time',Time,...
                'GPSDataPing',gps_data_ping,...
                'Mode','CW',...
                'AttitudeNavPing',attitude_data_pings);

            if max(nb_channel) ==4
                trans_obj.Data.replace_sub_data_v2(alongangle,'alongangle');
                trans_obj.Data.replace_sub_data_v2(acrossangle,'acrossangle');
            end

            trans_obj.set_absorption(ifileinfo.absorption_coefficient/1000);

            envdata=env_data_cl('SoundSpeed',ifileinfo.sound_speed);

            layers(uu)=layer_cl('Filename',{FileName},'Filetype','CREST',...
                'Transceivers',trans_obj,'GPSData',gps_data,...
                'AttitudeNav',attitude_data,...
                'OriginCrest',FileName,'EnvData',envdata);
%             if ~isempty(depth_line)
%                 layers(uu).add_lines(depth_line);
%             end
            layers(uu).set_survey_data(survey_data);

            if p.Results.CVSCheck
                layers(uu).CVS_BottomRegions(cvs_root);
                layers(uu).write_bot_to_bot_xml('overwrite',false);
                layers(uu).write_reg_to_reg_xml('overwrite',false);
            end

        catch err
            print_errors_and_warnings(1,'warning',sprintf('Unable to open file d%07d',filenumber));
            print_errors_and_warnings(1,'error',err);
        end
    end
end
