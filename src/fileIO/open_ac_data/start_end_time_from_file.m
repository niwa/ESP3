function [start_time,end_time,ftype,survey_data_obj]=start_end_time_from_file(filename,varargin)

if nargin==1
    ftype=get_ftype(fullfile(filename));
else
    ftype=varargin{1};
end
survey_data_obj = survey_data_cl.empty();
start_time=0;
end_time=1;
try
    switch lower(ftype)
        case {'ek60','ek80', 'me70','ms70'}
            [start_time,end_time]=start_end_time_from_raw_file(filename);
        case 'asl'
            [start_time,end_time]=start_end_time_from_asl_file(filename);
        case 'netcdf4'
            [start_time,end_time] = start_end_time_from_netcdf4_file(filename);
        case 'crest'
            ifileInfo=parse_ifile(filename);
            if ~isfield(ifileInfo,'start_date')
                start_time = ifileInfo.start_date;
                end_time = ifileInfo.finish_date;
                survey_data_obj = survey_data_cl();
                survey_data_obj.Snapshot = ifileInfo.snapshot;
                survey_data_obj.Stratum = ifileInfo.stratum;
                survey_data_obj.Transect = ifileInfo.transect;
                survey_data_obj.StartTime = ifileInfo.start_date;
                survey_data_obj.EndTime = ifileInfo.finish_date;
            end
        case 'kem'
            [start_time,end_time] = start_end_time_from_kem_file(filename);
        case 'em'
            [start_time,end_time] = start_end_time_from_all_wcd_file(filename);
            
%         case 'slg'
%             
%             fid=fopen(filename,'r','l');
%             SL_data_struct = [];
%             header_struct = read_sl_header(fid);
%             switch header_struct.format
%                 case 1
%                     %read_sl1_frame_header(fid,header_struct.version,header_struct.framesize);
%                 case {2,3}
%                     %header_length = 168;
%                     [SL_data_struct,fsize] = read_slg_frame_header(fid,SL_data_struct,header_struct.format,header_struct.version,header_struct.framesize);
%                     
%             end
%             fclose(fid);
%             start_time = datenum(datetime(SL_data_struct.posixTime(1), 'ConvertFrom', 'posixtime'));

    end
    
catch err
    fprintf('Error reading start and end time for file %s\n',filename);
    print_errors_and_warnings([],'error',err);
    
end