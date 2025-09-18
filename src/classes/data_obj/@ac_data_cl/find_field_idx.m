function [idx,found]=find_field_idx(data_obj,field)
idx=[];
if ~isempty(data_obj)&&~isempty(data_obj.Fieldname)
    idx=find(strcmpi(data_obj.Fieldname,deblank(field)),1);
end

if isempty(idx)
    idx=1;
    found=0;
else
    found=1;
end

end