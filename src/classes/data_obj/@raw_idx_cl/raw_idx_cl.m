classdef raw_idx_cl < dynamicprops
    properties
        filename   = '';
        raw_type   = '';
        nb_samples = [];
        time_dg    = [];
        type_dg    = {};
        pos_dg     = [];%bytes from start of the file
        len_dg     = [];
        chan_dg    = [];
        b_ordering = 'b';
        Version    = -1;
    end

    methods(Static)
        function ver  =  get_curr_raw_idx_cl_version()
            ver = 1.0;
        end
    end

    methods
        function raw_idx_obj = raw_idx_cl(filename,varargin)

            str = '';
            if length(varargin)>=1
                load_bar_comp=varargin{1};

            else
                load_bar_comp=[];
            end

            if ~isfile(filename)
                return;
            end

            raw_idx_obj.Version = raw_idx_cl.get_curr_raw_idx_cl_version();
            [raw_idx_obj.raw_type,raw_idx_obj.b_ordering] = get_ftype(filename,true);
            [~,fileN,ext]=fileparts(filename);

            raw_idx_obj.filename=[fileN ext];

            if isfile(filename)
                s=dir(filename);
                filesize=s.bytes;
            else
                return;
            end

            if ~isempty(load_bar_comp)
                set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',filesize, 'Value',0);
                load_bar_comp.progress_bar.setText(sprintf('Indexing File %s',filename));
            else
                fprintf('Indexing File %s:\n',filename);
            end

            switch raw_idx_obj.raw_type

                case{'EK80' 'EK60' 'ME70' 'MS70'}
                    fid=fopen(filename,'r',raw_idx_obj.b_ordering,'US-ASCII');
                    HEADER_LEN=12;
                    if fid==-1
                        return;
                    end


                    switch raw_idx_obj.raw_type
                        case 'EK80'
                            [~,config]=read_EK80_config(filename);
                            freq=nan(1,length(config));
                            CIDs=cell(1,length(config));
                            for uif=1:length(freq)
                                freq(uif)=config{uif}.Frequency;
                                CIDs{uif}=config{uif}.ChannelID;
                            end
                        case {'EK60' 'ME70' 'MS70'}
                            
                            [tmp, ~] = readEKRaw_ReadHeader(fid);
                            if isempty(tmp)
                                frewind(fid);
                                [~,config]=read_EK80_config(fid);
                                [tmp, ~] = readEKRaw_ReadHeader(fid);
                            end

                            freq=nan(1,length(tmp.transceiver));
                            CIDs=cell(1,length(tmp.transceiver));
                            for uif=1:length(freq)
                                freq(uif)=tmp.transceiver(uif).frequency;
                                CIDs{uif}=tmp.transceiver(uif).channelid;
                            end
                            frewind(fid);

                    end

                    kk = 0;
                    dgTime_ori = datenum(1601, 1, 1, 0, 0, 0);

                    id  =0;
                    while 1

                        pos   = ftell(fid);

                        if pos>=filesize
                            break;
                        end
                        kk = kk+1;
                        len=fread(fid,1,'int32');

                        [dgType,ntSecs]=readEK60Header_v2(fid);

                        if (feof(fid))||isempty(deblank(dgType))
                            break;
                        end


                        switch dgType
                            case 'RAW0'
                                raw_idx_obj.chan_dg(kk)=fread(fid,1,'int16=>int16');
                                fseek(fid,66,'cof');
                                raw_idx_obj.nb_samples(kk) = fread(fid,1,'int32');

                            case {'RAW3','RAW4'}
                                channelID = deblank(fread(fid,128,'*char')');
                                fseek(fid,8,'cof');
                                if contains(channelID,'ADCP')
                                    id_num = strfind(channelID,'#');
                                    if ~isempty(id_num)
                                        channelID = channelID(1:id_num-1);
                                    end
                                end
                                id_chan=find(contains(deblank(CIDs),deblank(channelID)));
                                if ~isempty(id_chan)
                                    raw_idx_obj.chan_dg(kk)=id_chan;
                                    raw_idx_obj.nb_samples(kk) = fread(fid,1,'int32');
                                end

                            otherwise
                                raw_idx_obj.chan_dg(kk)=nan;
                                raw_idx_obj.nb_samples(kk) = nan;

                        end
                        %new_pos  =ftell(fid);
                        raw_idx_obj.len_dg(kk) = len;
                        raw_idx_obj.pos_dg(kk) = pos+4;
                        raw_idx_obj.type_dg{kk} = dgType;

                        raw_idx_obj.time_dg(kk)=dgTime_ori+ntSecs/(24*60*60);
                        fseek(fid,raw_idx_obj.pos_dg(kk)+raw_idx_obj.len_dg(kk)+4,'bof');
                        new_pos = raw_idx_obj.pos_dg(kk)+raw_idx_obj.len_dg(kk)+4;

                        if ~isempty(load_bar_comp)
                            if ceil(new_pos/filesize*100)>id
                                set(load_bar_comp.progress_bar,'Value',new_pos, 'Maximum',filesize);
                                id = ceil(new_pos/filesize*100);
                            end
                        else
                            nstr = numel(str);
                            str = sprintf('%2.0f%%',floor(new_pos/filesize*100));
                            fprintf([repmat('\b',1,nstr) '%s'],str);
                        end

                    end

                    fclose(fid);

                case 'KEM'
                    HEADER_LEN = 4;
                    [fid,~] = fopen(filename, 'r',raw_idx_obj.b_ordering);
                    kk = 0;

                    id = 0;

                    while 1
                        pos   = ftell(fid);
                        if pos>=filesize
                            break;
                        end

                        header_struct  = read_kem_header(fid);
                        

                        if feof(fid)|| isempty(header_struct.dgSize) ||header_struct.dgSize == 0
                            break
                        end

                        if ~checkKEMheader(header_struct)
                            fseek(fid,pos+4+header_struct.dgSize,-1);
                            continue;
                        end

                        kk = kk + 1;

                        raw_idx_obj.nb_samples(kk) = nan;
                        raw_idx_obj.len_dg(kk)=header_struct.dgSize;
                        raw_idx_obj.pos_dg(kk)=pos;
                        raw_idx_obj.chan_dg(kk) = header_struct.systemID;
                        raw_idx_obj.time_dg(kk) = header_struct.time;
                        raw_idx_obj.type_dg{kk} = header_struct.dgmType;

                        new_pos = pos+header_struct.dgSize;

                        fseek(fid,new_pos,'bof');

                        if ~isempty(load_bar_comp)
                            if ceil(new_pos/filesize*100)>id
                                set(load_bar_comp.progress_bar,'Value',new_pos, 'Maximum',filesize);
                                id = ceil(new_pos/filesize*100);
                            end
                        else
                            nstr = numel(str);
                            str = sprintf('%2.0f%%',floor(new_pos/filesize*100));
                            fprintf([repmat('\b',1,nstr) '%s'],str);
                        end
                    end

                    fclose(fid);
                case 'EM'
                    HEADER_LEN  = 8;
                    [fid,~] = fopen(filename, 'r',raw_idx_obj.b_ordering);
                    kk = 0;

                    id = 0;

                    while 1
                        pos   = ftell(fid);
                        if pos>=filesize
                            break;
                        end

                        header_struct  = read_em_header(fid);

                        if feof(fid)|| isempty(header_struct.dgSize) ||header_struct.dgSize == 0
                            break
                        end
                        if header_struct.stx~=2
                            fseek(fid,pos+4+header_struct.dgSize,-1);
                            continue;
                        end

                        kk = kk + 1;

                        raw_idx_obj.nb_samples(kk) = nan;
                        raw_idx_obj.len_dg(kk)=header_struct.dgSize;
                        raw_idx_obj.pos_dg(kk)=pos;
                        raw_idx_obj.chan_dg(kk) = header_struct.systemSerialNumber;
                        raw_idx_obj.time_dg(kk) = header_struct.time;
                        raw_idx_obj.type_dg{kk} = header_struct.dgNumber;

                        new_pos = pos+4+header_struct.dgSize;

                        fseek(fid,new_pos,'bof');

                        if ~isempty(load_bar_comp)
                            if ceil(new_pos/filesize*100)>id
                                set(load_bar_comp.progress_bar,'Value',new_pos, 'Maximum',filesize);
                                id = ceil(new_pos/filesize*100);
                            end
                        else
                            nstr = numel(str);
                            str = sprintf('%2.0f%%',floor(new_pos/filesize*100));
                            fprintf([repmat('\b',1,nstr) '%s'],str);
                        end
                    end

                    fclose(fid);


                otherwise

                    return;

            end


            idx_rem=diff(raw_idx_obj.pos_dg)-raw_idx_obj.len_dg(1:end-1)~=(HEADER_LEN-4);

            switch raw_idx_obj.raw_type
                case {'EK60' 'EK80' 'ME70' 'MS70'}
                    type_dg_unique=unique(raw_idx_obj.type_dg);
                    for idg=1:length(type_dg_unique)
                        if ~ismember(type_dg_unique{idg},{'NME0'})
                            idx_dg_type=find(strcmp(raw_idx_obj.type_dg,type_dg_unique{idg}));
                            idx_rem_type=find(diff(raw_idx_obj.time_dg(idx_dg_type))<0)+1;
                            idx_rem(idx_dg_type(idx_rem_type))=1;
                        end
                    end
            end
            raw_idx_obj.rem_idx(idx_rem);

        [pathsave,name,ext] = fileparts(filename);
        fsave = append(pathsave,'\',"TimeCorrection.mat");
        if isfile(fsave)
            TimeCorrection = load(fsave);
            filenames = TimeCorrection.TimeCorrection.File_names;
            fname=strcat(name,ext);
            if all(ismember(fname, filenames))
                t_offset = seconds(TimeCorrection.TimeCorrection.Time_offset{3}*3600+TimeCorrection.TimeCorrection.Time_offset{2}*60+TimeCorrection.TimeCorrection.Time_offset{1});   
                ttc = raw_idx_obj.time_dg;
                raw_idx_obj.time_dg = datenum(ttc+t_offset);
            end
        end

        end

        function rem_idx(raw_idx_obj,idx_rem)
            raw_idx_obj.nb_samples(idx_rem)=[];
            raw_idx_obj.time_dg(idx_rem)=[];
            raw_idx_obj.type_dg(idx_rem)=[];
            raw_idx_obj.pos_dg(idx_rem)=[];
            raw_idx_obj.len_dg(idx_rem)=[];
            raw_idx_obj.chan_dg(idx_rem)=[];
        end

        function [nb_pings,channels]=get_nb_pings_per_channels(idx_obj)
            channels=unique(idx_obj.chan_dg(~isnan(idx_obj.chan_dg)));
            nb_transceivers=length(channels);

            nb_pings=nan(1,nb_transceivers);

            [G,idg,idt] = findgroups(idx_obj.chan_dg,idx_obj.type_dg);

            nb_pings_temp = splitapply(@numel,idx_obj.chan_dg,G);

            for itr=1:nb_transceivers
                nb_pings(itr) = max(nb_pings_temp(idg==channels(itr)));
            end

        end

        function time_cell=get_time_per_channels(idx_obj)
            channels=unique(idx_obj.chan_dg(~isnan(idx_obj.chan_dg)));
            nb_transceivers=length(channels);
            time_cell=cell(1,nb_transceivers);

            [G,idg,idt] = findgroups(idx_obj.chan_dg,idx_obj.type_dg);

            for itr=1:nb_transceivers
                ii = find(idg == channels(itr),1);
                time_cell{itr} = idx_obj.time_dg(G == ii);
            end

        end

        function nb_samples=get_nb_samples_per_channels(idx_obj)
            channels=unique(idx_obj.chan_dg(~isnan(idx_obj.chan_dg)));
            nb_transceivers=length(channels);
            nb_samples=nan(1,nb_transceivers);

            for itr=1:nb_transceivers
                nb_samples(itr)=max(idx_obj.nb_samples(idx_obj.chan_dg==channels(itr)),[],'omitnan');
            end

        end

        function nb_samples=get_nb_samples_per_block_per_channels(idx_obj,block_size)
            nb_pings=idx_obj.get_nb_pings_per_channels();
            nb_blocks=ceil(nb_pings/block_size);
            channels=unique(idx_obj.chan_dg(~isnan(idx_obj.chan_dg)));
            nb_transceivers=length(channels);
            nb_samples=cell(1,nb_transceivers);

            [G,idg,idt] = findgroups(idx_obj.chan_dg,idx_obj.type_dg);

            for itr=1:nb_transceivers
                idg_t = idg(idg == channels(itr));
                if numel(idg_t) > 1
                    id=idx_obj.chan_dg==channels(itr) & ismember(idx_obj.type_dg,{'RAW0','RAW3'});
                else
                    id=idx_obj.chan_dg==channels(itr);
                end

                nb_samples_tmp=idx_obj.nb_samples(id);

                if block_size >1
                    nb_samples{itr}=accumarray(ceil((1:numel(nb_samples_tmp))/block_size)',nb_samples_tmp',[nb_blocks(itr) 1],@(x) max(x,[],'omitnan'))';
                else
                    nb_samples{itr} = nb_samples_tmp;
                end
                nb_samples{itr}(nb_samples{itr}==0)=1;
            end

        end

        function nb_nmea_dg=get_nb_nmea_dg(idx_obj)
            nb_nmea_dg=sum(strcmp(idx_obj.type_dg,'NME0'));
        end

        function time_dg=get_time_dg(idx_obj,type)
            time_dg=idx_obj.time_dg(strcmp(idx_obj.type_dg,type));
        end

        function time_dg=get_time_by_chan_dg(idx_obj,type,chan)
            time_dg=idx_obj.time_dg(strcmp(idx_obj.type_dg,type)&&idx_obj.chan_dg==chan);
        end



        function delete(obj)
            if  isdebugging
                c = class(obj);
                disp(['ML object destructor called for class ',c])
            end
        end

    end
end
