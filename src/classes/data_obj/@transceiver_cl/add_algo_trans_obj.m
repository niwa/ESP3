
function add_algo_trans_obj(trans_obj,algo_obj,varargin)

p = inputParser;

addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addRequired(p,'algo_obj',@(obj) isempty(algo_obj)||isa(algo_obj,'algo_cl'));
addParameter(p,'reset_range',false,@islogical);

parse(p,trans_obj,algo_obj,varargin{:});

if p.Results.reset_range
    algo_obj.reset_range(trans_obj.get_samples_range());
end

for ial=1:length(algo_obj)
    nb_algos=length(trans_obj.Algo);
    [idx_alg,alg_found]=find_algo_idx(trans_obj,algo_obj(ial).Name);

    if alg_found==0
        trans_obj.Algo(nb_algos+1)=copy_algo(algo_obj(ial));
    else
        trans_obj.Algo(idx_alg)=copy_algo(algo_obj(ial));
    end
end