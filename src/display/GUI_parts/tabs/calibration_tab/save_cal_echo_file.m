function save_cal_echo_file()

layer=get_current_layer();
if ~isempty(layer)
    try
        cal_cw = extract_cal_to_apply(layer,layer.get_cw_cal());
    catch err
        print_errors_and_warnings([],'error',err);
        disp_perso([],'Could not read calibration file');
        cal_cw = layer.get_cw_cal();
    end
    [cal_path,~,~]=fileparts(layer.Filename{1});
    
    
    cal_file = fullfile(cal_path,'cal_echo.csv');
    
    cal_f = init_cal_struct(cal_file);
    
    if ~isempty(cal_f)
        idx_add=find(~ismember(cal_f.CID,cal_cw.CID));
    else
        idx_add=[];
    end
    
    writetable(struct2table(cal_cw),cal_file);
    if ~isempty(cal_f)

        cal_f_t = struct2table(cal_f);
        if ~isempty(idx_add)
            writetable(cal_f_t(idx_add,:),cal_file,'WriteMode','append');
        end
    end
    
end