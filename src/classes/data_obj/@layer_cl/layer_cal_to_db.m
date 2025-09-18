function cal_keys = layer_cal_to_db(layer_obj,varargin)

p = inputParser;
addRequired(p,'layer_obj',@(x) isa(x,'layer_cl'));
addParameter(p,'cal_cw',layer_obj.get_cw_cal(),@isstruct);
addParameter(p,'cal_fm',{},@iscell);
addParameter(p,'save_bool',true(1,numel(layer_obj.Transceivers)),@islogical);
addParameter(p,'idx_trans',1:numel(layer_obj.Transceivers),@isnumeric);
addParameter(p,'calibration_up_or_down_cast','static',@ischar);


parse(p,layer_obj,varargin{:});

if isempty(p.Results.cal_fm)
    [cal_fm,~]=layer_obj.get_fm_cal([]);
else
    cal_fm = p.Results.cal_fm;
end
prec = 1e3;
cal_cw = p.Results.cal_cw;
cal_keys = [];

[pathtofile,~]=layer_obj.get_path_files();
pathtofile=unique(pathtofile);

pathtofile(cellfun(@isempty,pathtofile))=[];

fileN=fullfile(pathtofile{1},'cal_echo.db');
dbconn = connect_to_db(fileN);

if isempty(dbconn)
    file_sql=fullfile(whereisEcho,'config','db','cal_db.sql');
    create_ac_database(fileN,file_sql,1,false);
    dbconn = connect_to_db(fileN);
end

env_table = table(layer_obj.EnvData.Salinity,layer_obj.EnvData.Temperature,layer_obj.EnvData.Depth,...
    'VariableNames',{'environment_salinity','environment_temperature','environment_depth'});

env_pkey=insert_data_controlled(dbconn,'t_environment',...
    table2struct(env_table,'ToScalar',true),table2struct(env_table,'ToScalar',true),'environment_pkey');

cal_comment = sprintf('Calibration recorded on  %s\nProcessed using ESP3 version %s\n',...
    datestr(layer_obj.Transceivers(1).Time(1), 'dd/mm/yyyy HH:MM:SS'),...
    get_ver());

cal_acq_struct.calibration_acquisition_method_type = {'calibration_acquisition_method_type'};
cal_acq_pkey=insert_data_controlled(dbconn,'t_calibration_acquisition_method_type',...
    cal_acq_struct,cal_acq_struct,'calibration_acquisition_method_type_pkey');


[cal_path,~,~]=fileparts(layer_obj.Filename{1});

db_to_params = translate_db_to_params_cell();
file_cal = cell(numel(layer_obj.Transceivers),1);
for uui  = p.Results.idx_trans

    if p.Results.save_bool(uui) == false
        continue;
    end
    trans_obj = layer_obj.Transceivers(uui);
    
    [alpha_curr,~]=trans_obj.get_absorption();


    spp.sound_propagation_absorption = round(mean(alpha_curr,'all','omitnan')*1e3*prec)/prec;
    spp.sound_propagation_velocity = round(layer_obj.EnvData.SoundSpeed*prec)/prec;
    spp.sound_propagation_frequency = trans_obj.get_center_frequency(1);
    spp.sound_propagation_depth = layer_obj.EnvData.Depth;

    spp_pkey=insert_data_controlled(dbconn,'t_sound_propagation',...
        spp,spp,'sound_propagation_pkey');
    params_struct.parameters_pulse_mode = {trans_obj.Mode};

    for uip =1:numel(db_to_params)
        if isprop(trans_obj.Params,db_to_params{uip}{2})
            params_struct.(db_to_params{uip}{1}) = round(trans_obj.get_params_value(db_to_params{uip}{2},'idx_ping',1)*prec)/prec;
        end
    end
    params_pkey=insert_data_controlled(dbconn,'t_parameters',...
        params_struct,params_struct,'parameters_pkey');

    cal_struct = [];
    cal_struct.calibration_parameters_key = params_pkey;
    cal_struct.calibration_acquisition_method_type_key = cal_acq_pkey;
    cal_struct.calibration_environment_key = env_pkey;
    cal_struct.calibration_sound_propagation_key = spp_pkey;
    cal_struct.calibration_up_or_down_cast = p.Results.calibration_up_or_down_cast;
    cal_struct.calibration_date = datestr(floor(trans_obj.Time(1)*24)/(24),'yyyy-mm-dd HH:MM:SS');
    cal_struct.calibration_comments = cal_comment;
    db_to_cal_struct_cell = translate_db_to_cal_cell();

    switch trans_obj.Mode
        case 'CW'
            for uic = 1:numel(db_to_cal_struct_cell)
                if isfield(cal_cw,db_to_cal_struct_cell{uic}{2})
                    if isnumeric(cal_cw.(db_to_cal_struct_cell{uic}{2})(uui))
                         cal_struct.(db_to_cal_struct_cell{uic}{1}) = round(cal_cw.(db_to_cal_struct_cell{uic}{2})(uui)*prec)/prec;
                    else
                        cal_struct.(db_to_cal_struct_cell{uic}{1}) = cal_cw.(db_to_cal_struct_cell{uic}{2})(uui);
                    end
                end
            end
            cal_struct_minus_pkey = cal_struct;
        case 'FM'
            file_cal{uui}=fullfile(cal_path,generate_valid_filename(['Calibration_FM_' layer_obj.ChannelID{uui} '.xml']));
            save_cal_to_xml(cal_fm{uui},file_cal{uui});
            cal_struct.calibration_fm_xml_str = fileread(file_cal{uui});

            for uic = 1:numel(db_to_cal_struct_cell)
                if isfield(cal_fm{uui},db_to_cal_struct_cell{uic}{2})
                    if isnumeric(cal_fm{uui}.(db_to_cal_struct_cell{uic}{2}))
                        cal_struct.(db_to_cal_struct_cell{uic}{1}) = round(mean(cal_fm{uui}.(db_to_cal_struct_cell{uic}{2}),'omitnan')*prec)/prec;
                    else
                        cal_struct.(db_to_cal_struct_cell{uic}{1}) = cal_fm{uui}.(db_to_cal_struct_cell{uic}{2});
                    end
                elseif isfield(cal_cw,db_to_cal_struct_cell{uic}{2})
                    if isnumeric(cal_cw.(db_to_cal_struct_cell{uic}{2})(uui))
                        cal_struct.(db_to_cal_struct_cell{uic}{1}) = round(cal_cw.(db_to_cal_struct_cell{uic}{2})(uui)*prec)/prec;
                    else
                        cal_struct.(db_to_cal_struct_cell{uic}{1}) = cal_cw.(db_to_cal_struct_cell{uic}{2})(uui);
                    end
                end
            end
            cal_struct_minus_pkey = rmfield(cal_struct,{'calibration_fm_xml_str'});
    end
    
    cal_key_tmp = insert_data_controlled(dbconn,'t_calibration',cal_struct,cal_struct_minus_pkey,'calibration_pkey');
    cal_keys = [cal_keys cal_key_tmp];
    %disp(struct2table(cal_struct,'AsArray',false));
end



dbconn.close();

end