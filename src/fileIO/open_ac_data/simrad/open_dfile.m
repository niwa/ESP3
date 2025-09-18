function  [new_layers,found_raw_file]=open_dfile(Filename_cell,varargin)
p = inputParser;

if ~iscell(Filename_cell)
    Filename_cell={Filename_cell};
end

if ~iscell(Filename_cell)
    Filename_cell={Filename_cell};
end

if isempty(Filename_cell)
    new_layers=[];
    return;
end

def_path_m = fullfile(tempdir,'data_echo');

addRequired(p,'Filename_cell',@(x) ischar(x)||iscell(x));
addParameter(p,'CVScheck',1,@isnumeric);
addParameter(p,'CVSroot','',@ischar);
addParameter(p,'PathToMemmap',def_path_m,@ischar);
addParameter(p,'EsOffset',[]);
addParameter(p,'load_bar_comp',[]);


parse(p,Filename_cell,varargin{:});

found_raw_file = true(1,numel(Filename_cell));

new_layers=[];

for uu=1:length(Filename_cell)
    
    
    FileName=Filename_cell{uu};
    [path_f,~,~]=fileparts(FileName);
    ifileInfo = parse_ifile(FileName);
    RawFilename=ifileInfo.rawFileName;
    
    if strcmp(RawFilename,'')||isempty(RawFilename)
        warning('Could not find associated .*raw file to %s, will try to open original d-file instead',FileName);
        found_raw_file(uu) = false;
        continue;
    end
    
    survey_data=survey_data_cl('Snapshot',ifileInfo.snapshot,'Stratum',ifileInfo.stratum,'Transect',ifileInfo.transect);
    origin=FileName;
    
    [~,PathToRawFile]=find_file_recursive(path_f,RawFilename);
    
    if isempty(PathToRawFile)
        found_raw_file(uu) = false;
        warning('Could not find associated .*raw file to %s, will try to open original d-file instead',FileName);
        continue;
    end
    
    lay_temp=open_EK_file_stdalone(fullfile(PathToRawFile{1},RawFilename),...
        'PathToMemmap',p.Results.PathToMemmap,'load_bar_comp',p.Results.load_bar_comp,'EsOffset',p.Results.EsOffset);
    lay_temp.OriginCrest=origin;
    
    lay_temp.set_survey_data(survey_data);
    
    if p.Results.CVScheck
        lay_temp.CVS_BottomRegions(p.Results.CVSroot);
        lay_temp(uu).write_bot_to_bot_xml('overwrite',false);
        lay_temp(uu).write_reg_to_reg_xml('overwrite',false);
    end
    new_layers=[new_layers lay_temp];
end



