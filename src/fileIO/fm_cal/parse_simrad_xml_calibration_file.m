function calibration_results = parse_simrad_xml_calibration_file(fname)
xml_struct = parseXML(fname);
calibration_results = [];
fm_fields = get_cal_fm_fields();

for ifif = 1:numel(fm_fields)
    calibration_results.(fm_fields{ifif})= [];
end

try
    
    idx_cal =find(strcmpi({xml_struct.Children(:).Name},'Calibration'),1);
    
    if isempty(idx_cal)
        print_errors_and_warnings([],'warning',sprintf('No Calibration node in XML calibration file %s. Using default values',fname));
        return;
    end
    
    cal_node = xml_struct.Children(idx_cal);
    
    idx_cal_res =find(strcmpi({cal_node.Children(:).Name},'CalibrationResults'),1);
    
    if isempty(idx_cal_res)
        print_errors_and_warnings([],'warning',sprintf('No CalibratioResults node  XML calibration file %s. Using default values',fname));
        return;
    end
    
    cal_res_node = cal_node.Children(idx_cal_res);
    
    fields = {cal_res_node.Children(:).Name};
    for ifi =1:numel(fields)
        calibration_results.(fields{ifi}) = cellfun(@str2double,strsplit(cal_res_node.Children(ifi).Data,';'));
    end
    
    non_pop_fields = setdiff(fm_fields,fields);
    
   for uif = 1:numel(non_pop_fields)
       disp_perso([],'Field %s not defined in XML calibration file %s.',non_pop_fields{uif},fname);
       calibration_results.(non_pop_fields{uif}) = nan(size(calibration_results.Frequency));
   end

   idx_btr =find(strcmpi({xml_struct.Children(:).Name},'BandToRemove'),1);

   if ~isempty(idx_btr)
       btr_node = xml_struct.Children(idx_btr);
       fields = {btr_node.Children(:).Name};
       for ifi =1:numel(fields)
           btr_struct.(fields{ifi}) = cellfun(@str2double,strsplit(btr_node.Children(ifi).Data,';'));
       end
       ff = calibration_results.Frequency;
       for uif  = 1:numel(btr_struct.FreqStart)  
           calibration_results = structfun(@(x) rmbtr(x,ff,btr_struct.FreqStart(uif),btr_struct.FreqEnd(uif)),calibration_results,'UniformOutput',false);
           calibration_results.Frequency = ff;
       end
   end


catch
    print_errors_and_warnings([],'warning',sprintf('Could not parse XML calibration file %s. Using default values',fname));
end


end

function data = rmbtr(data,ff,fs,fe)
    data(ff>=fs & ff<=fe) = nan;
end