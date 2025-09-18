%compile_echo('..\esp3','EchoAnalysis.m','1.9.6');

function compile_echo(root_folder,nomFunc,ver)
setenv('MCC_USE_DEPFUN', '1');

generate_classes_summary;


f = dir(prefdir);
for index = 1: numel(f)
    if f(index).isdir && ~strcmpi(f(index).name, '.') && ~strcmpi(f(index).name, '..') && contains(f(index).name, 'temp') 
        fprintf('deleting %s ...\n', fullfile(prefdir, f(index).name));
        try
        rmdir(fullfile(prefdir, f(index).name), 's');
        catch 
            fprintf('Could not delete %s ...\n', fullfile(prefdir, f(index).name));
        end
    end
end

folders=folders_list(root_folder);

folder_to_copy=folders_list_copy(root_folder);cd

for ui=1:length(folder_to_copy)
    [~,fold_temp,~]=fileparts(folder_to_copy{ui});
    if exist(fullfile(pwd,fold_temp),'dir')>0
        rmdir(fullfile(pwd,fold_temp),'s');
    end
   copyfile(folder_to_copy{ui},fullfile(pwd,fold_temp),'f'); 
end

files_to_copy={'splash.png','licence.rtf'};
for ui=1:length(files_to_copy)
    if isfile(fullfile(pwd,files_to_copy{ui}))>0
        delete(fullfile(pwd,files_to_copy{ui}));
    end
    copyfile(fullfile(root_folder,files_to_copy{ui}),fullfile(pwd,files_to_copy{ui}),'f');
end

files_to_delete={fullfile(pwd,'config','display_config.xml'),fullfile(pwd,'config','path_config.xml')};

for ui=1:length(files_to_delete)
    if isfile(files_to_delete{ui})>0
        delete(files_to_delete{ui});
    end
end


switch computer
    case {'PCWIN64' 'PCWIN'}
        str{1} = sprintf('!mcc -v -W "main:ESP3,version=%s" -T link:exe %s -N ',ver,fullfile(root_folder,nomFunc));
    case 'GLNX86'
        str{1} = sprintf('!mcc -v -m %s -N ', fullfile(root_folder,nomFunc));
    case 'GLNXA64'
        str{1} = sprintf('!mcc -v -m %s -N ', fullfile(root_folder,nomFunc));
    otherwise
        str{1} = sprintf('!mcc -v -m %s -N ', fullfile(root_folder,nomFunc));
end

for ifold= 1:(length(folders))
    if contains(folders{ifold},'java')
        jars=dir(folders{ifold});
        for ij=length(jars):-1:1
            if ~jars(ij).isdir
                [~,~,fileext]=fileparts(jars(ij).name);
                if isfile(fullfile(folders{ifold},jars(ij).name))
                    if strcmpi(fileext,'.jar')
                        str{end+1}=sprintf('-a "%s" ',fullfile(folders{ifold},jars(ij).name));
                    end
                end
            end
        end
    else
        str{end+1}=sprintf('-a "%s" ',folders{ifold});
    end
end


% MATLAB Toolboxes:
%   Signal Processing Toolbox
%   Mapping Toolbox
%   Statistics and Machine Learning Toolbox
%   Curve Fitting Toolbox
%   Database Toolbox
%   Parallel_Computing_Toolbox
%   Image Processing Toolbox
%   Computer Vision Toolbox
tbx_folders = {...
    fullfile(matlabroot,'toolbox','signal'),...
    fullfile(matlabroot,'toolbox','map'),...
    fullfile(matlabroot,'toolbox','stats'),...
    fullfile(matlabroot,'toolbox','curvefit'),...
    fullfile(matlabroot,'toolbox','database'),...
    fullfile(matlabroot,'toolbox','parallel'),...
    fullfile(matlabroot,'toolbox','images'),...
    fullfile(matlabroot,'toolbox','vision'),...
    };

for ifold= 1:(length(tbx_folders))
 str{end+1}=sprintf('-p "%s" ',tbx_folders{ifold});
end
% str(end+1:end+numel(tbx))=tbx;

str{end+1}=' -o ESP3 -r icons/echoanalysis.ico -w enable';

str{end + 1} = ' -R "-startmsg, This will take no more than a few tens of millions of microseconds... " -R "-completemsg, All Done. We can start."';
str{end + 1} = ' -N';
str_mcc =[str{:}];
disp(str_mcc);
eval(str_mcc);

end