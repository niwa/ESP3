function remove_sub_data(data,fields)

if nargin<2
    fields=data.Fieldname;
end

if ~iscell(fields)
    fields={fields};
end

fname = {};
for ii=1:length(fields)
    fieldname=fields{ii};
    [idx,found]=find_field_idx(data,fieldname);

    if found==0
        continue;
    else
        fname_tmp=cell(1,length(data.SubData(idx).Memap));

        for icell=1:length(data.SubData(idx).Memap)
            if isprop(data.SubData(idx).Memap{icell},'Filename')||isfield(data.SubData(idx).Memap{icell},'Filename')
                fname_tmp{icell}=data.SubData(idx).Memap{icell}.Filename;
            else
                fname_tmp{icell} = '';
            end
        end

        %data.SubData(idx).delete();
        data.SubData(idx)=[];
        data.Type(idx)=[];
        data.Fieldname(idx)=[];
        fname = union(fname_tmp,fname);
    end
end

folders  = fileparts(fname);
folders = unique(folders);

for ic=1:length(folders)
    tmp = strsplit(folders{ic},filesep);
    if isfolder(folders{ic}) && ~strcmpi(tmp{end},'data_echo')
        try
            fprintf('Deleting temp folder %s\n',folders{ic});
            rmdir(folders{ic},'s');  
        catch
            fprintf('Could not remove folder %s\n',folders{ic});
        end
        
    end
end

for ic=1:length(fname)
    if isfile(fname{ic})
        try
            fprintf('Deleting temp file %s\n',fname{ic});
            delete(fname{ic});
        catch
            fprintf('Could not remove file %s\n',fname{ic});
        end
    end
end


end


