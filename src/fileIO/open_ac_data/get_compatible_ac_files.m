function Filename=get_compatible_ac_files(file_path)

% dialog box
[ftypes,ext,~] = get_ftypes_and_extensions();

[Filename,path_f] = uigetfile( {fullfile(file_path,strjoin(ext,';'))}, sprintf('Pick a %s  file',strjoin(ftypes,'/')),'MultiSelect','on');

% nothing opened
if isempty(Filename)
    return;
end

% single file is char. Turn to cell
if ~iscell(Filename)
    if (Filename==0)
        return;
    end
    Filename = {Filename};
end

% keep only supported files, exit if none

logbook_file=strcmpi(Filename,'echo_logbook.db');

[Filename,~]=filter_ac_files(Filename);

if any(logbook_file)
    Filename=union(Filename,{'echo_logbook.db'});
end

if isempty(Filename)
    return;
end

% add path to filenames

Filename=fullfile(path_f,Filename);