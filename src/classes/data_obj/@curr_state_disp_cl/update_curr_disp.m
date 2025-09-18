function update_curr_disp(curr_disp_obj,filepath,stype)

lim_att = get_lim_config_att();
[display_config_file,~,~]=get_config_files();
[~,fname,fext]=fileparts(display_config_file);

disp_config_file=fullfile(filepath,[fname fext]);
curr_disp_obj.CurrFolder = filepath;
if isfile(disp_config_file)
    curr_disp_new=read_config_display_xml(disp_config_file);
    props=properties(curr_disp_obj);
    
    for i=1:numel(props)
        if ismember((props{i}),lim_att)
            curr_disp_obj.(props{i})=curr_disp_new.(props{i});
        end
    end
    curr_disp_obj.setCax(curr_disp_obj.Cax);
else
    curr_disp_obj.Cmap  = get_cmap_for_sounder_type(stype);
end
end

function cmap = get_cmap_for_sounder_type(stype)

switch lower(stype)
    case 'multi-beam'
        cmap = 'EK60';
    case 'imaging multi-beam'
        cmap = 'copper';
    case {'single-beam' 'single-beam (simrad)'}
        cmap = 'EK60';
    case 'single-beam (asl)'
        cmap = 'ASL';
    case 'single-beam (furuno)'
        cmap = 'EK60_night';
    case 'side-scan sonar'
        cmap = 'copper';
    case 'sub-bottom profiler'
        cmap = 'Seismic';
    case 'single-beam (crest)'
        cmap = 'esp2';
    otherwise
        cmap = 'EK60';
end
end