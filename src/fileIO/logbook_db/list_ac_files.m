%% list_ac_file.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-05-17: first version (Yoann Ladroit). TODO: complete date and comment
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function

function [files,ftype]=list_ac_files(datapath,listonly)

list_files = dir(datapath);

list_files([list_files(:).isdir])=[];

[~,idx_keep]= filter_ac_files({list_files.name});

list_files=list_files(idx_keep);

files={list_files.name};

ftype=cell(1,numel(files));

if listonly == 0 && ~isempty(list_files)
    esp3_obj=getappdata(groot,'esp3_obj');
    esp3_obj.connect_parpool();

    f_obj = cellfun(@(y) parfeval(@(x) get_ftype(fullfile(datapath,x)),1,y),files);%From 2x to 10x faster than the non-parallel option...
    
    wait(f_obj);
    ftype = fetchOutputs(f_obj,'UniformOutput',false);

    idx_rem=strcmpi('unknown',ftype);
    ftype(idx_rem) = [];
    files(idx_rem) = [];


end

end



