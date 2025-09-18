function folders=folders_list(path_src)

% folders{1}=fullfile(path_src,'external_toolboxes');
% folders{2}=fullfile(path_src, 'processing');
% folders{3}=fullfile(path_src, 'classes');
% folders{4}=fullfile(path_src, 'algos');
% folders{5}=fullfile(path_src, 'display');
% folders{6}=fullfile(path_src, 'ressources');
% folders{7}=fullfile(path_src, 'fileIO');
% folders{8}=fullfile(path_src, 'mapping');

folders{1}=fullfile(path_src, 'src');
folders{2}=fullfile(path_src, 'java');

folders(cellfun(@isempty, folders))=[];

end