function [att_struct,dataset_names] = get_att_values_and_dataset_names(fname,group,att_struct,dataset_names,struct_bool,read_all_bool)

if isempty(group)
    group = h5info(fname);
end

if struct_bool
    new_struct = [];
else
    new_struct = att_struct;
end

for uiatt = 1:numel(group.Attributes)

    if struct_bool
        ff = clean_str(group.Attributes(uiatt).Name);
    else
        ff = clean_str(sprintf('%s_%s',group.Name,group.Attributes(uiatt).Name),false);
    end
    new_struct.(ff) = group.Attributes(uiatt).Value;
end


if ~isempty(group.Datasets)

    tmp_names = ...
        cellfun(@(x) sprintf('%s/%s',group.Name,x),{group.Datasets(:).Name},'un',false);
    for uidat = 1:numel(group.Datasets)
        if struct_bool
            ff = clean_str(group.Datasets(uidat).Name);
        else
            ff = clean_str(tmp_names{uidat});
        end

        if numel(group.Datasets(uidat).ChunkSize) <= 1 || read_all_bool
            new_struct.(ff) = h5read(fname,tmp_names{uidat});
        else
            %disp('nope');
        end
    end
    dataset_names = union(dataset_names,tmp_names);

end

for uig = 1:numel(group.Groups)
    [new_struct,dataset_names] = get_att_values_and_dataset_names(fname,group.Groups(uig),new_struct,dataset_names,struct_bool,read_all_bool);
end

if struct_bool
    ff = '';
    idx_last  =strfind(group.Name,'/');
    if ~isempty(idx_last)
        ff = (clean_str(group.Name(idx_last(end)+1:end)));
    end

    if isempty(ff)
        att_struct = new_struct;
    else
        att_struct.(ff) = new_struct;
    end
else
    att_struct = new_struct;
end


end