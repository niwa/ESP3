

%% open_file.m
%
% ESP3 main function to open new file(s)
%
%% Help
%
% *USE*
%
% TODO
%
% *INPUT VARIABLES*
%
% * |file_id| File ID (Required. Valid options: char for a single filename,
% cell for one or several filenames, |0| to open dialog box to prompt user
% for file(s), |1| to open next file in folder or |2| to open previous file
% in folder.
% * |main_figure|: Handle to main ESP3 window (Required).
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% * Could upgrade input variables management to input parser
% * Update if new files format to be supported
% * Not sure why the ~,~ at the beginning?
%
% *NEW FEATURES*
%
% * 2017-03-22: header and comments updated according to new format (Alex Schimel)
% * 2017-03-17: reformatting comment and header for compatibility with publish (Alex Schimel)
% * 2017-03-02: Comments and header (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit)
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function output=open_file(esp3_obj,varargin)

p  =  inputParser;

addRequired(p,'esp3_obj',@(obj) isa(obj,'esp3_cl'));
addParameter(p,'file_id',1,@(x) isnumeric(x)||iscell(x)||ischar(x));
addParameter(p,'parallel_process',false,@islogical);

parse(p,esp3_obj,varargin{:});

%profile on;
%%% Grab current layer (files data) and paths
layer = esp3_obj.get_layer();
layers = esp3_obj.layers;
app_path = esp3_obj.app_path;
main_figure = esp3_obj.main_figure;

output=[];
%%% Check if there are unsaved new bottom and regions
check_saved_bot_reg(main_figure);

%%% Exit if input file was bad
% (put this at beginning and through input parser)
file_id = p.Results.file_id;

if isempty(file_id)
    return;
end
up_disp=0;

%%% Get a default path for the file selection dialog box
if ~isempty(layer)
    [path_lay,~] = layer.get_path_files();
    if ~isempty(path_lay)
        % if file(s) already loaded, same path as first one in list
        file_path = path_lay{1};
    else
        % config default path if none
        file_path = app_path.data.Path_to_folder;
    end
else
    % config default path if none
    file_path = app_path.data.Path_to_folder;
end


if p.Results.parallel_process && isempty(esp3_obj.ppool)
    dlg_perso(esp3_obj.main_figure,'Background process pool unavailable','Background processe pool unavailable. Not too sure why...');
    return;
end

if ~isempty(esp3_obj.ppool) && esp3_obj.ppool.Connected && (~isempty(esp3_obj.ppool.FevalQueue.RunningFutures) || ~isempty(esp3_obj.ppool.FevalQueue.QueuedFutures))
    dlg_perso(esp3_obj.main_figure,'Background processes already runnning','Files being openned in the background processes. Please wait till they are completed to open more...');
    return;
end


%%% Grab filename(s) to open
if ischar(file_id) || iscell( file_id) || isstring(file_id)% if input variable is the filename(s) itself
    
    Filename = file_id;
    
else
    Filename = [];
    switch file_id
        case 0 % if requesting opening a selection dialog box
            
            Filename = get_compatible_ac_files(file_path);
            
        case {1 2} % if requesting to open next or previous file in folder
            
            % Grab filename(s) in current layer
            if ~isempty(layer)
                [~,Filenames] = layer.get_path_files();
            else
                return;
            end
            
            % find all files in path
            
            file_list = list_ac_files(file_path,1);
            %[~,file_list,~] = fileparts(file_list);
            
            % find the next file in folder after current file
            idx_f=find(ismember(file_list,Filenames));
            
            if ~isempty(idx_f)
                if file_id==1
                    id_open=idx_f(end)+1;
                else
                    id_open=idx_f(1)-1;
                end
            else
                return;
            end
            
            if id_open>0&&id_open<=numel(file_list)
                Filename=fullfile(file_path,file_list{id_open});
            end
            
            
    end
    
end

%%% Exit if still no file at this point
if isempty(Filename)
    return;
end
if isequal(Filename, 0)
    return;
end

%%% Turn filename to cell if still not done at this point
if ~iscell(Filename)
    Filename_tot = {Filename};
else
    Filename_tot = Filename;
end

if ~isempty(layers)
    [old_files,~]=layers.list_files_layers();
    idx_already_open=find(cellfun(@(x) any(strcmpi(x,old_files)),Filename_tot));
    
    if ~isempty(idx_already_open)
        dlg_perso(main_figure,'',sprintf('File(s) already open in existing layer:\n %s ',strjoin(Filename_tot(idx_already_open),'\n')));
    end
    Filename_tot(idx_already_open)=[];
    
    [~,files_lay_old]=layers.get_path_files();
    [~,files_lay_old,~] = fileparts(files_lay_old);
    
    idx_same_name=find(cellfun(@(x) any(contains(x,files_lay_old)),Filename_tot));
    idx_same_name=setdiff(idx_same_name,idx_already_open);
    
    if ~isempty(idx_same_name)
        dlg_perso(main_figure,'',sprintf('File(s) with same name  already open in existing layer:\n %s ',strjoin(Filename_tot(idx_same_name),'\n')));
    end
    
    Filename_tot(idx_same_name)=[];
else
    old_files={};
end


%%% Get types of files to open

ftype_cell = cellfun(@get_ftype,Filename_tot,'un',0);

if isempty(ftype_cell)
    hide_status_bar(main_figure);
    return;
end

%%% Find each ftypes in list to batch process the opening
[ftype_unique,~,ic] = unique(ftype_cell);

[load_bar_comp,~]=show_status_bar(main_figure);
output=zeros(1,numel(Filename_tot));
new_layers_tot=[];
try

    f_obj = [];
    ff_n = {};
    if p.Results.parallel_process        
        war_dlg = dlg_perso(esp3_obj.main_figure,'Initialising background process','Initialising the files to be loaded in the background... Please wait...','Timeout',0);
    end

    %%% File opening section, by type of file
    for itype = 1:length(ftype_unique)
        
        % Grab filenames for this ftype
        Filename = Filename_tot(ic==itype);
        ftype = ftype_unique{itype};
        CVSCheck=0;
        dfile=0;
        % Figure if the files requested to be open are part of a transect that
        % include other files not requested to be opened. This functionality is
        % not available for all types of files
        SvCorr =1;
        switch ftype
            
            case {'ME70' 'MS70' 'EK60','EK80','FCV-30' 'NETCDF4' 'OCULUS' 'XTF' 'ASL' 'EM' 'KEM' 'SLG'}
                missing_files = find_survey_data_db(Filename);
                idx_miss=cellfun(@(x)~any(strcmpi(x,old_files)),missing_files);
                missing_files=missing_files(idx_miss);
                if ~isempty(missing_files)
                    % If there are, prompt user if they want them added to the
                    % list of files to open
                    war_str=sprintf('It looks like you are trying to open incomplete transects (%.0f missing files)... Do you want load the rest as well?',numel(missing_files));
                    choice=question_dialog_fig(main_figure,'',war_str,'timeout',10);
                    
                    switch choice
                        case 'Yes'
                            Filename = union(Filename,missing_files);
                        case 'No'
                            
                        otherwise
                            
                    end
                end
            case {'TOPAS' 'DIDSON'}

            case 'CREST'
                
                % Prompt user on opening raw or original and handle the answer
                war_str='Do you want to open associated Raw File or original d-file?';
                choice=question_dialog_fig(main_figure,'d-file/raw_file',war_str,'opt',{'raw file','d-file'},'timeout',10);
                switch choice
                    case 'raw file'
                        dfile = 0;
                    case 'd-file'
                        dfile = 1;
                end
                if isempty(choice)
                    continue;
                end
                CVSCheck = 1;
                
                
            case 'db'
                for ifi=1:length(Filename)
                    load_logbook_fig(main_figure,false,true,Filename{ifi});
                end
                continue;
                
            case 'Unknown'
                
                for ifi=1:length(Filename)
                    disp_perso(main_figure,sprintf('Unknown file type for %s',Filename{ifi}));
                end
                continue;
            otherwise
                continue;
                
        end
        %profile on
        %freq_to_open=[];
        
        if isempty(layer)
            chan={};
        else
            chan=layer.ChannelID;
        end
        
        [pathtofile,~,~] = cellfun(@fileparts,Filename,'UniformOutput',false);
        pathtofile = unique(pathtofile);

        for uif = 1:numel(pathtofile)
            fileN=fullfile(pathtofile{uif},'echo_logbook.db');

            if ~isfile(fileN)
                dbconn = initialize_echo_logbook_dbfile(pathtofile{uif},0);
                if ~isempty(dbconn)
                    dbconn.close();
                end
            end
        end
        
        if ~p.Results.parallel_process
            [new_layers,multi_lay_mode]=open_file_standalone(Filename,ftype,...
                'already_opened_files',old_files,...
                'Channels',chan,...
                'PathToMemmap',app_path.data_temp.Path_to_folder,...
                'load_bar_comp',load_bar_comp,...
                'LoadEKbot',1,...
                'CVSCheck',CVSCheck,...
                'SvCorr',SvCorr,...
                'CVSroot',app_path.cvs_root.Path_to_folder,...
                'dfile',dfile);
        else
            

            esp3_obj.connect_parpool();
            
            for uif = 1:numel(Filename)
                F=parfeval(@open_file_standalone,2,Filename{uif},ftype,...
                    'already_opened_files',old_files,...
                    'Channels',chan,...
                    'PathToMemmap',app_path.data_temp.Path_to_folder,...
                    'load_bar_comp',load_bar_comp,...
                    'LoadEKbot',1,...
                    'CVSCheck',CVSCheck,...
                    'SvCorr',SvCorr,...
                    'CVSroot',app_path.cvs_root.Path_to_folder,...
                    'parallel_process',true,...
                    'open_all_channels',true,...
                    'dfile',dfile);
                f_obj = [f_obj F];
                ff_n = [ff_n Filename(uif)];
            end
            continue;
        end

        if isempty(new_layers)
            continue;
        end

        % Open the files. Different behavior per type of file
        
        new_layers_tot=[new_layers_tot new_layers];
        
    end
    
    if ~isempty(f_obj)
        esp3_obj.clear_future_op_obj();
        esp3_obj.w_h = files_open_waitbar_cl('Name','Reading files in the background',...
            'general_label','Reading files',...
            'file_list',ff_n,...
            'f_obj',f_obj);
        afterEach_fcn = @(~) increment_waitbar(esp3_obj.w_h);
        afterAll_fcn = @(ff) load_layers_from_future_obj(esp3_obj,ff);
        %afterEach_fcn = @(~) disp('I HAVE FINISHED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        B_e = afterEach(f_obj,afterEach_fcn,0,PassFuture=true);
        B_a = afterAll(f_obj,afterAll_fcn,0,PassFuture=true);
        esp3_obj.add_future_op_obj(f_obj);
        hide_status_bar(main_figure);
        if isvalid(war_dlg)
            delete(war_dlg);
        end
        drawnow;        
        return;
    end


    if isempty(new_layers_tot)
        hide_status_bar(main_figure);
        return;
    end
    
    [filenames_openned,~]=new_layers_tot.list_files_layers();
    files_lay=new_layers_tot(1).Filename;
    output=ismember(Filename_tot,filenames_openned);

    esp3_obj.add_layers_to_esp3(new_layers_tot,multi_lay_mode);
    
    if ~(isempty(esp3_obj.layers)||~exist('files_lay','var'))
        [idx,~]=esp3_obj.layers.find_layer_idx_files(files_lay);
        esp3_obj.set_layer(esp3_obj.layers(idx(1)));
        up_disp=1;
    end
    
    
catch err
    print_errors_and_warnings(1,'error',err);
end

%%% Update display
if up_disp>0
    loadEcho(main_figure);
end
% if stop_process
%     main_figure.CurrentCharacter='a';
% end
hide_status_bar(main_figure);


%  profile off;
%  profile viewer;




end