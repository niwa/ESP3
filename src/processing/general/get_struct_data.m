function data = get_struct_data(datastruct,fff)

fff_cell = strsplit(fff,'.');

data = datastruct;

for ui = 1:numel(fff_cell)
    if isempty(fff_cell{ui})
        continue;
    end
    data = data.(fff_cell{ui});
end