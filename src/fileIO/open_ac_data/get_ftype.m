function [ftype,b_ordering]=get_ftype(filename,varargin)
ftype='Unknown';
b_ordering = 'b';
enc = 'UTF-8';
detailed_ek_bool = true;
if nargin>2
    detailed_ek_bool = varargin{2};
end

disp_perso([],sprintf('Getting file type of file %s',filename));
if isfile(filename)
    try
        [~,fname,end_file]=fileparts(filename);

        switch end_file
            case '.nc'

                finfo = h5info(filename);
                if ~isempty(finfo.Groups)||all(ismember({'/Top-level','/Platform','/Sonar','/Environment','/Annotation'},{finfo.Groups(:).Name}))
                    ftype='NETCDF4';
                end
                return;
            case '.db'
                ftype='db';
                return;

            case '.xtf'
                ftype='XTF';
                return;
            case {'.lst' '.ini'}
                ftype='FCV-30';
                return;


            case '.ddf'
                ftype='DIDSON';
                return;
            case {'.slg','.sl1','.sl2','.sl3'}
                ftype = 'SLG';
                return;
            case '.oculus'
                ftype='OCULUS';
                return;

            case '.raw'
                enc = 'US-ASCII';b_ordering = 'l';
                fid = fopen(filename,'r',b_ordering,enc);
                if fid==-1
                    disp_perso([],sprintf('Cannot open file %s',filename));
                    return;
                end

                fread(fid,1, 'int32');

                [dgType, ~] =readEK60Header_v2(fid);

                fclose(fid);

                if isempty(deblank(dgType))
                    disp_perso([],sprintf('Cannot open file %s',filename));
                    return;
                end

                switch dgType
                    case 'XML0'
                        ftype='EK80';
                        b_ordering = 'l';
                        if detailed_ek_bool

                            [tmp,~] = read_EK80_config(filename,false);
                            tmpname  = deblank(tmp.ApplicationName);

                            switch tmpname
                                case {'ME70' 'MS70'}
                                    ftype = tmpname;
                            end
                        end

                    case 'CON0'
                        b_ordering = 'l';
                        fid = fopen(filename,'r',b_ordering,enc);
                        fread(fid,1, 'int32');

                        [~, ~] =readEK60Header_v2(fid);
                        configheader = readEKRaw_ReadConfigHeader(fid);
                        fclose(fid);

                        switch deblank(configheader.soundername)
                            case {'ME70'  'MBES'}
                                ftype = 'ME70';
                            case {'MS70' 'MBS'}
                                ftype = 'MS70';
                            otherwise
                                ftype='EK60';
                        end

                    otherwise
                        enc = 'UTF-8';
                        b_ordering = 'b';
                        fid = fopen(filename,'r','b',enc);
                        tmp = fread(fid,9,'int16');
                        filePingNumber = tmp(1);
                        TOPASformat = tmp(2);
                        yr = tmp(3);
                        mo = tmp(4);
                        dy = tmp(5);
                        hr = tmp(6);
                        mi = tmp(7);
                        sc = tmp(8);
                        msc = tmp(8);

                        pingTime = datenum(yr,mo,dy,hr,mi,sc+msc/1000);
                        origFilename = fread(fid,16,'*char')';
                        [~,origFilename,~]=fileparts(origFilename);
                        fclose(fid);

                        if contains(filename,origFilename)
                            ftype='TOPAS';
                        end
                end

            case {'.kmall' '.kmwcd'}
                %s=dir(filename);
                %f_size=s.bytes;
                b_ordering = 'l';
                [fid,~] = fopen(filename, 'r','l',enc);

                header_struct  = read_kem_header(fid);
                fclose(fid);

                if checkKEMheader(header_struct)
                    ftype = 'KEM';
                else
                    return;
                end


            case {'.all' '.wcd'}
                s=dir(filename);
                f_size=s.bytes;
                [fid,~] = fopen(filename, 'r','n',enc);

                nbDatagL = fread(fid,1,'uint32','l'); % number of bytes in datagram

                if isempty(nbDatagL)
                    return;
                end

                frewind(fid); % come back to re-read in b
                nbDatagB        = fread(fid,1,'uint32','b'); % number of bytes in datagram
                stxDatag        = fread(fid,1,'uint8');      % STX (always H02)
                datagTypeNumber = fread(fid,1,'uint8');      % SIMRAD type of datagram
                emNumberL       = fread(fid,1,'uint16','l'); % EM Model Number
                fseek(fid,-2,0); % come back to re-read in b
                emNumberB       = fread(fid,1,'uint16','b'); % EM Model Number

                % trying to read ETX
                if nbDatagL+1<f_size
                    fseek(fid,nbDatagL+1,-1);
                    etxDatagL = fread(fid,1,'uint8'); % ETX (always H03)
                else
                    etxDatagL = NaN;
                end

                if nbDatagB+1<f_size
                    fseek(fid,nbDatagB+1,-1);
                    etxDatagB = fread(fid,1,'uint8'); % ETX (always H03)
                else
                    etxDatagB = NaN;
                end
                fclose(fid);
                % test for the byte ordering of the datagram size field
                if etxDatagL == 3
                    b_ordering = 'l';
                    ftype = 'EM';
                elseif etxDatagB == 3
                    b_ordering = 'b';
                    ftype = 'EM';
                else
                    return;
                end


            otherwise
                fid = fopen(filename,'r','b',enc);
                dgType=fread(fid,1,'uint16');
                fclose(fid);

                if hex2dec('FD02')==dgType
                    ftype='ASL';
                else
                    if fname(1)=='d'&&isempty(end_file)
                        ftype='CREST';
                    end
                end

        end

    catch err
        print_errors_and_warnings([],'warning',err);
    end

end