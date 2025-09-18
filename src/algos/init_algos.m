function algo_vec=init_algos(name)

name_vec = list_algos();

if nargin==0
    name=name_vec;
end

if~iscell(name)
    name={name};
end
algo_vec(length(name))=algo_cl();

for ial=1:length(name)
    algo_vec(ial)=algo_cl('Name',name{ial});
end

end