function att_val = get_att(node,name)
    att_val=[];
    if isempty(node.Attributes)
        return;
    end
    id_att_val = strcmpi({node.Attributes(:).Name},name);
    if any(id_att_val)
        att_val = node.Attributes(id_att_val).Value;
    end
end