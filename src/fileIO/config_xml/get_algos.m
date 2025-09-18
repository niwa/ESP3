%% get_algos.m
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
% * 2017-07-06: start commenting and header (Alex Schimel).
% * YYYY-MM-DD: first version (Author). TODO: complete date and comment
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function algo_cell = get_algos(algo_node)

% number of algorithms
nb_algos = length(algo_node.Children);

% initialize output
algo_cell = cell(1,nb_algos);

al_names = list_algos();

% get each algo details
for ial = 1:nb_algos

    % ignore comments
    if ~ismember(algo_node.Children(ial).Name,al_names)
        if strcmp(algo_node.Children(ial).Name,'#comment')
            print_errors_and_warnings([],'war',sprintf('Algorithm %s not recognised',algo_node.Children(ial).Name))
        end
        continue;
    end

    % record algo name
    al_struct_tmp.Name = algo_node.Children(ial).Name;
    att_names = {algo_node.Children(ial).Attributes(:).Name};

    if ~ismember('savename',att_names)
        al_struct_tmp.Varargin.savename = '--';
    end

    % record each attribute
    for jat = 1:length(algo_node.Children(ial).Attributes)
        al_struct_tmp.Varargin.(algo_node.Children(ial).Attributes(jat).Name) = algo_node.Children(ial).Attributes(jat).Value;
    end

    % special record for frequencies if this field exists
    if isfield(al_struct_tmp.Varargin,'Frequencies')
        if ischar(al_struct_tmp.Varargin.Frequencies)
            al_struct_tmp.Varargin.Frequencies = str2double(strsplit(al_struct_tmp.Varargin.Frequencies,';'));
            if isnan(al_struct_tmp.Varargin.Frequencies)
                al_struct_tmp.Varargin.Frequencies = [];
            end
        end
    else
        al_struct_tmp.Varargin.Frequencies = [];
    end
    
    algo_cell{ial} = al_struct_tmp;
    
end

% remove empty algorithms (comments)
algo_cell(cellfun(@isempty,algo_cell)) = [];



end