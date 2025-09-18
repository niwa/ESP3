classdef oculus_read_functions

    methods (Static)

        function [oculusLogHeader_struct,fid] = read_OculusLogHeader(fid)

            if (ischar(fid)||isstring(fid))&&isfile(fid)
                fid = fopen(fid,'r','l','US-ASCII');
            end

            oculusLogHeader_struct = oculus_read_functions.oculusLogHeader_def_struct();

            if fid ==-1
                return;
            end

            pos_start = ftell(fid);
            oculusLogHeader_struct.fileHeader = fread(fid,1,'uint32')';
            oculusLogHeader_struct.sizeHeader = fread(fid,1,'uint32');
            oculusLogHeader_struct.source = fread(fid,16,'*char')';
            oculusLogHeader_struct.version = fread(fid,1,'uint16');
            oculusLogHeader_struct.encryption = fread(fid,1,'uint16');
            oculusLogHeader_struct.key = fread(fid,1,'uint64');
            oculusLogHeader_struct.spare1 = fread(fid,1,'uint32')';
            oculusLogHeader_struct.time_unix = fread(fid,1,'double');
            oculusLogHeader_struct.time = oculusLogHeader_struct.time_unix / 86400 + datenum(1970, 1, 1);
            pos_end = ftell(fid);
            if oculusLogHeader_struct.sizeHeader>0 && oculusLogHeader_struct.sizeHeader-pos_end-pos_start > 0
                oculusLogHeader_struct.spare2 = fread(fid,oculusLogHeader_struct.sizeHeader-pos_end-pos_start,'uint8');
            end

        end

        function oculusLogHeader_struct = oculusLogHeader_def_struct()
            oculusLogHeader_struct.fileHeader = [];
            oculusLogHeader_struct.sizeHeader = [];
            oculusLogHeader_struct.source = 'Oculus';
            oculusLogHeader_struct.version = 1;
            oculusLogHeader_struct.encryption = 0;
            oculusLogHeader_struct.key = 0;
            oculusLogHeader_struct.time = [];
        end


        function oculusLogItem_struct = read_OculusLogItem(fid)
            pos_start = ftell(fid);

            oculusLogItem_struct.itemHeader = fread(fid,1,'uint32')';
            oculusLogItem_struct.sizeHeader = fread(fid,1,'uint32');
            oculusLogItem_struct.messageType = fread(fid,1,'uint16')';
            oculusLogItem_struct.version = fread(fid,1,'uint16');
            oculusLogItem_struct.spare1 = fread(fid,4,'uint8')';
            oculusLogItem_struct.time_unix = fread(fid,1,'double');
            oculusLogItem_struct.time = oculusLogItem_struct.time_unix / 86400 + datenum(1970, 1, 1);
            oculusLogItem_struct.compression = fread(fid,1,'uint16');
            oculusLogItem_struct.spare2 = fread(fid,2,'uint8');
            oculusLogItem_struct.rawSize = fread(fid,1,'uint32');
            oculusLogItem_struct.payloadSize = fread(fid,1,'uint32');
            oculusLogItem_struct.payload = [];

            pos_end = ftell(fid);

            if ~isempty(oculusLogItem_struct.sizeHeader) && oculusLogItem_struct.sizeHeader>0 && oculusLogItem_struct.sizeHeader-(pos_end-pos_start) > 0
                oculusLogItem_struct.spare3 = fread(fid,oculusLogItem_struct.sizeHeader-(pos_end-pos_start),'uint8');
            elseif isempty(oculusLogItem_struct.sizeHeader) || oculusLogItem_struct.sizeHeader ==0
                return;
            end
            oculusLogItem_struct = oculus_read_functions.read_message(fid,oculusLogItem_struct);
        end

        function oculusLogItem_struct = read_message(fid,oculusLogItem_struct)

            pos_start_payload = ftell(fid);

            msgRead = false;
            oculusLogItem_struct.payload = [];
            oculusLogItem_struct.sonarData = [];

            switch oculusLogItem_struct.messageType

                case 1 %rt_settings          = 1,             % RmSettingsLogger packet
                case 2 %rt_serialPort        = 2,             % Raw serial string - version contains the port number
                case 10 %rt_oculusSonar       = 10,            % Raw oculus sonar data
                    oculusLogItem_struct = oculus_read_functions.read_OculusMessageHeader(fid,oculusLogItem_struct);

                    switch oculusLogItem_struct.msgId
                        case 21%         messageSimpleFire         = 0x15, 21
                            fprintf('Reading messageSimpleFire not implemented yet...\n');
                            return;
                        case {35,34}%         messageSimplePingResult   = 0x23, 35
                            switch oculusLogItem_struct.msgId
                                case 34
                                    oculusLogItem_struct = oculus_read_functions.read_OculusPingResult(fid,oculusLogItem_struct);
                                    oculusLogItem_struct.nRanges = oculusLogItem_struct.ping_params.nRangeLinesBfm;
                                    oculusLogItem_struct.nBeams = oculusLogItem_struct.ping_config.nBeams;
                                    oculusLogItem_struct.imageOffset = oculusLogItem_struct.ping_params.imageOffset;
                                    oculusLogItem_struct.imageSize = oculusLogItem_struct.ping_params.imageSize;
                                    oculusLogItem_struct.dataSize = oculusLogItem_struct.imageSize/(oculusLogItem_struct.nBeams*oculusLogItem_struct.nRanges)-1;
                                    oculusLogItem_struct.speedOfSoundUsed = oculusLogItem_struct.ping_params.d10;
                                    oculusLogItem_struct.speedOfSound = oculusLogItem_struct.ping_params.d10;
                                    oculusLogItem_struct.frequency = oculusLogItem_struct.ping_params.d2;
                                    oculusLogItem_struct.temperature = oculusLogItem_struct.ping_params.d11;
                                    oculusLogItem_struct.pressure = oculusLogItem_struct.ping_params.d12;
                                    oculusLogItem_struct.rangeResolution = oculusLogItem_struct.ping_params.d8;
                                    oculusLogItem_struct.masterMode = oculusLogItem_struct.ping_config.b5;
                                case 35
                                    switch oculusLogItem_struct.msgVersion
                                        case 2 %OculusSimplePingResult2
                                            oculusLogItem_struct = oculus_read_functions.read_OculusSimplePingResult2(fid,oculusLogItem_struct);
                                        otherwise %OculusSimplePingResult
                                            oculusLogItem_struct = oculus_read_functions.read_OculusSimplePingResult(fid,oculusLogItem_struct);
                                    end

                            end
                            fpos = ftell(fid);
                            if pos_start_payload+oculusLogItem_struct.imageOffset ~=fpos
                                fseek(fid,pos_start_payload+oculusLogItem_struct.imageOffset,'bof');
                            end

                            oculusLogItem_struct.gain = ones(oculusLogItem_struct.nRanges,1);
                            if isfield(oculusLogItem_struct,'flags')
                                flags = bitget(uint8(oculusLogItem_struct.flags),1:8);
                                % bit 0: 0 = interpret range as percent, 1 = interpret range as meters
                                % bit 1: 0 = 8 bit data, 1 = 16 bit data
                                % bit 2: 0 = wont send gain, 1 = send gain
                                % bit 3: 0 = send full return message, 1 = send simple return message
                            end

                            switch oculusLogItem_struct.dataSize
                                case 0
                                    fmt = 'uint8';
                                case 1
                                    fmt = 'uint16';
                                case 2
                                    fmt = 'bit24=>int32';
                                case 3
                                    fmt = 'uint32';
                            end
                            tmp = fread(fid,[oculusLogItem_struct.imageSize*(oculusLogItem_struct.dataSize+1)/oculusLogItem_struct.nRanges  oculusLogItem_struct.nRanges] ,"uint8=>uint8")';

                            if oculusLogItem_struct.imageSize*(oculusLogItem_struct.dataSize+1) ~= oculusLogItem_struct.nBeams*oculusLogItem_struct.nRanges
                                g = (tmp(:,1:4)');
                                d = tmp(:,5:end)';
                                oculusLogItem_struct.gain = single(typecast(g(:),'uint32'));
                                switch oculusLogItem_struct.dataSize
                                    case 0
                                        oculusLogItem_struct.sonarData = single(d');
                                    otherwise
                                        oculusLogItem_struct.sonarData = reshape(typecast(d(:),fmt),[oculusLogItem_struct.nBeams oculusLogItem_struct.nRanges]);
                                end
                            else
                                oculusLogItem_struct.gain = ones(1,oculusLogItem_struct.nRanges,'single');
                                switch oculusLogItem_struct.dataSize
                                    case 0
                                        oculusLogItem_struct.sonarData = tmp;
                                    otherwise
                                        oculusLogItem_struct.sonarData = resahape(typecast(tmp(:),fmt),[oculusLogItem_struct.nBeams oculusLogItem_struct.nRanges]);
                                end
                            end

                            msgRead = true;
                        case 85%         messageUserConfig			= 0x55, 85
                            fprintf('Reading messageUserConfig not implemented yet...\n');
                        case 255%         messageDummy              = 0xff,255
                            fprintf('Reading messageDummy not implemented yet...\n');
                    end
                case 11 %rt_blueviewSonar     = 11,            % Blueview data log image (raw)
                case 12 %rt_rawVideo          = 12,            % Raw video logg
                case 13 %rt_h264Video         = 13,            % H264 compresses video log
                case 14 %rt_apBattery         = 14,            % ApBattery structure
                case 15 %rt_apMissionProgress = 15,            % ApMissionProgress structure
                case 16 %rt_nortekDVL         = 16,            % The complete Nortek DVL structure
                case 17 %rt_apNavData         = 17,            % ApNavData structures
                case 18 %rt_apDvlData         = 18,            % ApDvlData structures
                case 19 %rt_apAhrsData        = 19,            % ApAhrsData structure
                case 20 %rt_apSonarHeader     = 20,            % ApSonarHeader followed by image
                case 21 %rt_rawSonarImage     = 21,            % Raw sonar image
                case 22 %rt_ahrsMtData2       = 22,            % XSens MtData2 message
                case 23 %rt_apVehicleInfo     = 23,            % Artemis ApVehicleInfo structures
                case 24 %rt_apMarker          = 24,            % ApMarker structure
                case 25 %rt_apGeoImageHeader  = 25,            % ApGeoImageHeader
                case 26 %rt_apGeoImageData    = 26,            % ApGeoImage data of image
                case 30 %rt_sbgData           = 30,            % SBG compass data message
                case 500 %rt_ocViewInfo		 = 500			  % Oculus view information

            end


            if isempty(oculusLogItem_struct.payloadSize)&& oculusLogItem_struct.payloadSize>0 && ~msgRead
                oculusLogItem_struct.payload = fread(fid,oculusLogItem_struct.payloadSize,'uint8');
            end
            pos_end_payload = ftell(fid);
            if ~pos_end_payload == pos_start_payload+oculusLogItem_struct.payloadSize
                fseek(fid,pos_start_payload+oculusLogItem_struct.payloadSize,'bof');
            end

        end

        function oculus_struct = read_OculusMessageHeader(fid,oculus_struct)
            oculus_struct.oculusID = fread(fid,1,'uint16'); % Fixed ID 0x4f53 (20307)
            oculus_struct.srcDeviceID = fread(fid,1,'uint16');
            oculus_struct.dstDeviceId = fread(fid,1,'uint16');
            oculus_struct.msgId = fread(fid,1,'uint16');
            %         messageSimpleFire         = 0x15, 21
            %         messagePingResult         = 0x22, 34
            %         messageSimplePingResult   = 0x23, 35
            %         messageUserConfig			= 0x55, 85
            %         messageDummy              = 0xff,255
            oculus_struct.msgVersion= fread(fid,1,'uint16');
            oculus_struct.payloadSize = fread(fid,1,'uint32');
            oculus_struct.partNumber= fread(fid,1,'uint16');
        end


        function oculus_struct = read_OculusSimpleFireMessage(fid,oculus_struct)
            %oculus_struct = read_OculusMessageHeader(fid,oculus_struct);
            oculus_struct.masterMode=fread(fid,1,'uint8');% mode 0 is flexi mode, needs full fire message (not available for third party developers)
            % mode 1 - Low Frequency Mode (wide aperture, navigation)
            % mode 2 - High Frequency Mode (narrow aperture, target identification)
            oculus_struct.pingRate=fread(fid,1,'uint8');       % Sets the maximum ping rate.
            oculus_struct.networkSpeed=fread(fid,1,'uint8');         % Used to reduce the network comms speed (useful for high latency shared links)
            oculus_struct.gammaCorrection=fread(fid,1,'uint8');      % 0 and 0xff = gamma correction = 1.0
            % Set to 127 for gamma correction = 0.5
            oculus_struct.flags=fread(fid,1,'uint8');
            % bit 0: 0 = interpret range as percent, 1 = interpret range as meters
            % bit 1: 0 = 8 bit data, 1 = 16 bit data
            % bit 2: 0 = wont send gain, 1 = send gain
            % bit 3: 0 = send full return message, 1 = send simple return message
            oculus_struct.range=fread(fid,1,'double');                 % The range demand in percent or m depending on flags
            oculus_struct.gainPercent=fread(fid,1,'double');           % The gain demand
            oculus_struct.speedOfSound=fread(fid,1,'double');          % ms-1, if set to zero then internal calc will apply using salinity
            oculus_struct.salinity=fread(fid,1,'double');              % ppt, set to zero if we are in fresh water
        end

        function oculus_struct = read_OculusSimpleFireMessage2(fid,oculus_struct)
            %oculus_struct = read_OculusMessageHeader(fid,oculus_struct);
            oculus_struct.masterMode=fread(fid,1,'uint8');% mode 0 is flexi mode, needs full fire message (not available for third party developers)
            % mode 1 - Low Frequency Mode (wide aperture, navigation)
            % mode 2 - High Frequency Mode (narrow aperture, target identification)
            oculus_struct.pingRate=fread(fid,1,'uint8');       % Sets the maximum ping rate.
            oculus_struct.networkSpeed=fread(fid,1,'uint8');         % Used to reduce the network comms speed (useful for high latency shared links)
            oculus_struct.gammaCorrection=fread(fid,1,'uint8');      % 0 and 0xff = gamma correction = 1.0
            % Set to 127 for gamma correction = 0.5
            oculus_struct.flags=fread(fid,1,'uint8');
            % bit 0: 0 = interpret range as percent, 1 = interpret range as meters
            % bit 1: 0 = 8 bit data, 1 = 16 bit data
            % bit 2: 0 = wont send gain, 1 = send gain
            % bit 3: 0 = send full return message, 1 = send simple return message
            oculus_struct.range=fread(fid,1,'double');                 % The range demand in percent or m depending on flags
            oculus_struct.gainPercent=fread(fid,1,'double');           % The gain demand
            oculus_struct.speedOfSound=fread(fid,1,'double');          % ms-1, if set to zero then internal calc will apply using salinity
            oculus_struct.salinity=fread(fid,1,'double');              % ppt, set to zero if we are in fresh water
            oculus_struct.extFlags=fread(fid,1,'uint32');
            oculus_struct.reserved=fread(fid,8,'uint32');
        end

        function oculus_struct = read_OculusSimplePingResult(fid,oculus_struct)
            oculus_struct = oculus_read_functions.read_OculusSimpleFireMessage(fid,oculus_struct);

            oculus_struct.pingId= fread(fid,1,'uint32'); 		% An incrementing number
            oculus_struct.status= fread(fid,1,'uint32');
            oculus_struct.frequency=fread(fid,1,'double');	% The acoustic frequency (Hz)
            oculus_struct.temperature=fread(fid,1,'double');		% The external temperature (deg C)
            oculus_struct.pressure=fread(fid,1,'double');		% The external pressure (bar)
            oculus_struct.speedOfSoundUsed=fread(fid,1,'double');	% The actual used speed of sound (m/s)
            oculus_struct.pingStartTime=fread(fid,1,'float32');		% In seconds from sonar powerup (to microsecond resolution)
            oculus_struct.dataSize = fread(fid,1,'uint8'); 		% The size of the individual data entries
            oculus_struct.rangeResolution=fread(fid,1,'double');		% The range in metres corresponding to a single range line
            oculus_struct.nRanges=fread(fid,1,'uint16');	% The number of range lines in the image
            oculus_struct.nBeams=fread(fid,1,'uint16');		% The number of bearings in the image
            oculus_struct.imageOffset= fread(fid,1,'uint32'); 	% The offset in bytes of the image data from the start
            oculus_struct.imageSize= fread(fid,1,'uint32'); 		% The size in bytes of the image data
            oculus_struct.messageSize= fread(fid,1,'uint32'); 	% The total size in bytes of the network message
            oculus_struct.bearings = fread(fid,oculus_struct.nBeams,'int16')*0.01; % The brgs of the formed beams in 0.01 degree resolution
        end

        function oculus_struct = read_OculusSimplePingResult2(fid,oculus_struct)
            oculus_struct = oculus_read_functions.read_OculusSimpleFireMessage2(fid,oculus_struct);

            oculus_struct.pingId= fread(fid,1,'uint32'); 		% An incrementing number
            oculus_struct.status= fread(fid,1,'uint32');
            oculus_struct.frequency=fread(fid,1,'double');	% The acoustic frequency (Hz)
            oculus_struct.temperature=fread(fid,1,'double');		% The external temperature (deg C)
            oculus_struct.pressure=fread(fid,1,'double');		% The external pressure (bar)
            oculus_struct.heading=fread(fid,1,'double');			% The heading (degrees)
            oculus_struct.pitch=fread(fid,1,'double');			% The pitch (degrees)
            oculus_struct.roll=fread(fid,1,'double');			% The roll (degrees)
            oculus_struct.speedOfSoundUsed=fread(fid,1,'double');	% The actual used speed of sound (m/s)
            oculus_struct.pingStartTime=fread(fid,1,'double');		% In seconds from sonar powerup (to microsecond resolution)
            oculus_struct.dataSize = fread(fid,1,'uint8'); 		% The size of the individual data entries
            oculus_struct.rangeResolution=fread(fid,1,'double');		% The range in metres corresponding to a single range line
            oculus_struct.nRanges=fread(fid,1,'uint16');	% The number of range lines in the image
            oculus_struct.nBeams=fread(fid,1,'uint16');		% The number of bearings in the image
            oculus_struct.spare00=fread(fid,4,'uint32');
            oculus_struct.imageOffset= fread(fid,1,'uint32'); 	% The offset in bytes of the image data from the start
            oculus_struct.imageSize= fread(fid,1,'uint32'); 		% The size in bytes of the image data
            oculus_struct.messageSize= fread(fid,1,'uint32'); 	% The total size in bytes of the network message
            oculus_struct.bearings = fread(fid,oculus_struct.nBeams,'int16')*0.01; % The brgs of the formed beams in 0.01 degree resolution

        end

        function oculus_struct = read_OculusPingResult(fid,oculus_struct)
            %oculus_struct = read_OculusMessageHeader(fid,oculus_struct);
            oculus_struct.ping_config = oculus_read_functions.read_OculusPingConfig(fid);
            for is = 0:12
                oculus_struct.(sprintf('s%d',is)) = oculus_read_functions.read_Oculus_si(fid,is);
            end
            oculus_struct.ping_params = oculus_read_functions.read_OculusPingParameters(fid);
            oculus_struct.bearings = fread(fid,oculus_struct.ping_config.nBeams,'int16')*0.01;
        end

        function ping_config_struct = read_OculusPingConfig(fid)
            ping_config_struct.b0 = fread(fid,1,'uint8');
            ping_config_struct.d0 = fread(fid,1,'double');
            ping_config_struct.range = fread(fid,1,'double');
            ping_config_struct.d2 = fread(fid,1,'double');
            ping_config_struct.d3 = fread(fid,1,'double');
            ping_config_struct.d4 = fread(fid,1,'double');
            ping_config_struct.d5 = fread(fid,1,'double');
            ping_config_struct.d6 = fread(fid,1,'double');
            ping_config_struct.nBeams = fread(fid,1,'uint16');
            ping_config_struct.d7 = fread(fid,1,'double');
            ping_config_struct.b1 = fread(fid,1,'uint8');
            ping_config_struct.b2 = fread(fid,1,'uint8');
            ping_config_struct.b3 = fread(fid,1,'uint8');
            ping_config_struct.b4 = fread(fid,1,'uint8');
            ping_config_struct.b5 = fread(fid,1,'uint8');
            ping_config_struct.b6 = fread(fid,1,'uint8');
            ping_config_struct.u0 = fread(fid,1,'uint16');
            ping_config_struct.b7 = fread(fid,1,'uint8');
            ping_config_struct.b8 = fread(fid,1,'uint8');
            ping_config_struct.b9 = fread(fid,1,'uint8');
            ping_config_struct.b10 = fread(fid,1,'uint8');
            ping_config_struct.b11 = fread(fid,1,'uint8');
            ping_config_struct.b12 = fread(fid,1,'uint8');
            ping_config_struct.b13 = fread(fid,1,'uint8');
            ping_config_struct.b14 = fread(fid,1,'uint8');
            ping_config_struct.b15 = fread(fid,1,'uint8');
            ping_config_struct.b16 = fread(fid,1,'uint8');
            ping_config_struct.u1 = fread(fid,1,'uint16');
        end



        function ping_params_struct = read_OculusPingParameters(fid)

            ping_params_struct.u0 = fread(fid,1,'uint32');
            ping_params_struct.u1 = fread(fid,1,'uint32');
            ping_params_struct.d1 = fread(fid,1,'double');
            ping_params_struct.d2 = fread(fid,1,'double');
            ping_params_struct.u2 = fread(fid,1,'uint32');
            ping_params_struct.u3 = fread(fid,1,'uint32');
            ping_params_struct.d3 = fread(fid,1,'double');
            ping_params_struct.d4 = fread(fid,1,'double');
            ping_params_struct.d5 = fread(fid,1,'double');
            ping_params_struct.d6 = fread(fid,1,'double');
            ping_params_struct.d7 = fread(fid,1,'double');
            ping_params_struct.d8 = fread(fid,1,'double');
            ping_params_struct.d9 = fread(fid,1,'double');
            ping_params_struct.d10 = fread(fid,1,'double');
            ping_params_struct.d11 = fread(fid,1,'double');
            ping_params_struct.d12 = fread(fid,1,'double');
            ping_params_struct.d13 = fread(fid,1,'double');
            ping_params_struct.d14 = fread(fid,1,'double');
            ping_params_struct.d15 = fread(fid,1,'double');
            ping_params_struct.d16 = fread(fid,1,'double');
            ping_params_struct.d17 = fread(fid,1,'double');
            ping_params_struct.d18 = fread(fid,1,'double');
            ping_params_struct.d19 = fread(fid,1,'double');
            ping_params_struct.d20 = fread(fid,1,'double');
            ping_params_struct.u4 = fread(fid,1,'uint32');
            ping_params_struct.nRangeLinesBfm = fread(fid,1,'uint32');
            ping_params_struct.u5 = fread(fid,1,'uint16');
            ping_params_struct.u6 = fread(fid,1,'uint16');
            ping_params_struct.u7 = fread(fid,1,'uint16');
            ping_params_struct.u8 = fread(fid,1,'uint32');
            ping_params_struct.u9 = fread(fid,1,'uint32');
            ping_params_struct.b0 = fread(fid,1,'uint8');
            ping_params_struct.b1 = fread(fid,1,'uint8');
            ping_params_struct.b2 = fread(fid,1,'uint8');
            ping_params_struct.imageOffset = fread(fid,1,'uint32');              % The offset in bytes of the image data (CHN, CQI, BQI or BMG) from the start of the buffer
            ping_params_struct.imageSize = fread(fid,1,'uint32');                % The size in bytes of the image data (CHN, CQI, BQI or BMG)
            ping_params_struct.messageSize = fread(fid,1,'uint32');              % The total size in bytes of the network message
            % *** NOT ADDITIONAL VARIABLES BEYOND THIS POINT ***
            % There will be an array of bearings (shorts) found at the end of the message structure
            % Allocated at run time
            % ping_params_struct.bearings = fread(fid,ping_params_struct.nRangeLinesBfm,'int16')*0.01; % The brgs of the formed beams in 0.01 degree resolution
            % The bearings to each of the beams in 0.01 degree resolution
        end


        function si_struct = read_Oculus_si(fid,is)

            switch is
                case 0
                    si_struct.b0 = fread(fid,1,'uint8');
                    si_struct.d0 = fread(fid,1,'double');
                    si_struct.u0 = fread(fid,1,'uint16');
                    si_struct.u1 = fread(fid,1,'uint16');
                case 2
                    si_struct.b0 = fread(fid,1,'uint8');
                case 7
                    si_struct.b0 = fread(fid,1,'uint8');
                    si_struct.b1 = fread(fid,1,'uint8');
                case 9
                    si_struct.i0 = fread(fid,1,'int');
                    si_struct.i1 = fread(fid,1,'int');
                    si_struct.i2 = fread(fid,1,'int');
                    si_struct.i3 = fread(fid,1,'int');
                    si_struct.i4 = fread(fid,1,'int');
                    si_struct.i5 = fread(fid,1,'int');
                case 8
                    si_struct.b0 = fread(fid,1,'uint8');
                    si_struct.d0 = fread(fid,1,'double');
                    si_struct.d1 = fread(fid,1,'double');
                case 1
                    si_struct.b0 = fread(fid,1,'uint8');
                    si_struct.u0 = fread(fid,1,'uint16');
                    si_struct.b1 = fread(fid,1,'uint8');
                    si_struct.d0 = fread(fid,1,'double');
                case 3
                    si_struct.b0 = fread(fid,1,'uint8');
                    si_struct.b1 = fread(fid,1,'uint8');
                    si_struct.b2 = fread(fid,1,'uint8');
                    si_struct.b3 = fread(fid,1,'uint8');
                    si_struct.b4 = fread(fid,1,'uint8');
                    si_struct.b5 = fread(fid,1,'uint8');
                    si_struct.b6 = fread(fid,1,'uint8');
                    si_struct.b7 = fread(fid,1,'uint8');
                    si_struct.b8 = fread(fid,1,'uint8');
                    si_struct.b9 = fread(fid,1,'uint8');
                    si_struct.b10 = fread(fid,1,'uint8');
                    si_struct.b11 = fread(fid,1,'uint8');
                    si_struct.b12 = fread(fid,1,'uint8');
                    si_struct.b13 = fread(fid,1,'uint8');
                    si_struct.b14 = fread(fid,1,'uint8');
                    si_struct.b15 = fread(fid,1,'uint8');
                    si_struct.u0 = fread(fid,1,'uint16');
                    si_struct.b16 = fread(fid,1,'uint8');
                    si_struct.d0 = fread(fid,1,'double');
                    si_struct.d1 = fread(fid,1,'double');
                case 4
                    si_struct.b0 = fread(fid,1,'uint8');
                    si_struct.b1 = fread(fid,1,'uint8');
                    si_struct.d0 = fread(fid,1,'double');
                    si_struct.d1 = fread(fid,1,'double');
                    si_struct.d2 = fread(fid,1,'double');
                case 5
                    si_struct.b0 = fread(fid,1,'uint8');
                    si_struct.b1 = fread(fid,1,'uint8');
                    si_struct.u0 = fread(fid,1,'uint16');
                    si_struct.u1 = fread(fid,1,'uint16');
                    si_struct.u2 = fread(fid,1,'uint16');
                    si_struct.u3 = fread(fid,1,'uint16');
                    si_struct.u4 = fread(fid,1,'uint16');
                    si_struct.u5 = fread(fid,1,'uint16');
                case 6
                    si_struct.d0 = fread(fid,1,'double');
                    si_struct.d1 = fread(fid,1,'double');
                case 10
                    si_struct.i0 = fread(fid,1,'int');
                    si_struct.i1 = fread(fid,1,'int');
                    si_struct.i2 = fread(fid,1,'int');
                    si_struct.i3 = fread(fid,1,'int');
                case 11
                    si_struct.d0 = fread(fid,1,'double');
                    si_struct.d1 = fread(fid,1,'double');
                    si_struct.d2 = fread(fid,1,'double');
                    si_struct.d3 = fread(fid,1,'double');
                    si_struct.d4 = fread(fid,1,'double');
                case 12
                    si_struct.d0 = fread(fid,1,'double');
                    si_struct.d1 = fread(fid,1,'double');
                    si_struct.d2 = fread(fid,1,'double');
                    si_struct.d3 = fread(fid,1,'double');
                    si_struct.d4 = fread(fid,1,'double');
                    si_struct.d5 = fread(fid,1,'double');
                    si_struct.d6 = fread(fid,1,'double');
            end
        end

    end
end