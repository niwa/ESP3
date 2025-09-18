function reg_output_table=reg_output_to_table(str_obj)
if any(structfun(@istall,str_obj))
    str_obj=structfun(@gather,str_obj,'un',0);
end

data_size=size(str_obj.nb_samples);
str_field=fieldnames(str_obj);

idnan=[];
try
    idnan = [idnan find(isnan(str_obj.Time_S))];
    idnan = [idnan find(isnan(str_obj.Time_E))];
catch
    idnan = [];
end
idnan = unique(idnan);



for ifif=1:numel(str_field)
    tmp=str_obj.(str_field{ifif});

    if any(contains(str_field{ifif},{'_fm' 'Tag_cmap' 'Tag_descr' 'Tag_str'}))
        str_obj = rmfield(str_obj,str_field{ifif});
        continue;
    end

    str_obj_size=size(tmp);

    if idnan
        tmp(:,idnan) = [];
    end

    if contains(lower(str_field{ifif}),'time')
        tmp=cellfun(@(x) datestr(x,'dd/mm/yyyy HH:MM:SS.FFF'),num2cell(tmp),'UniformOutput',0);
    end

    if ~(str_obj_size(1)==data_size(1))
        tmp=repmat(tmp,data_size(1),1);
    end
    
    if ~(str_obj_size(2)==data_size(2))
        tmp=repmat(tmp,1,data_size(2));
    end
    
    str_obj.(str_field{ifif})=tmp(:);
end

if all(data_size==1)
    reg_output_table=struct2table(str_obj,'asarray',1);
else
    disp('')
    try
        reg_output_table=struct2table(str_obj);
    catch
        reg_output_table=struct2table(str_obj,'asarray',1);
    end

end



end