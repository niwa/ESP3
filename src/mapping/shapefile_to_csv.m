function shapefile_to_csv(folders,fields_to_export_ori)
shape_f={};

for ifold=1:numel(folders)
    if isfolder(folders{ifold})
        tmp=dir(fullfile(folders{ifold},'*.shp'));
        tmp([tmp(:).isdir]) =[];
        shape_f=union(shape_f,cellfun(@(x) fullfile(folders{ifold},x),{tmp(:).name},'un',0));
    elseif isfile(folders{ifold})
        shape_f=union(shape_f,folders{ifold});
    end
end


for ui = 1:numel(shape_f)
    tmp = shaperead(shape_f{ui});
    %tmp_info = shapeinfo(shape_f{ui});


    csv_name = strrep(shape_f{ui},'.shp','.csv');
    fields_to_export = {};
    if ~isempty(fields_to_export_ori)
        fields_to_export = intersect(fields_to_export_ori,fieldnames(tmp));
    end
    tmp = struct2table(tmp);
    if ~isempty(fields_to_export)
        tmp = tmp(:,fields_to_export);
    end

    varout = [];

    if ismember('X',tmp.Properties.VariableNames)&&(iscell(tmp.X)||size(tmp.X,2)>1)
        varout = tmp.X;
    end

    if ismember('lat',tmp.Properties.VariableNames)&&(iscell(tmp.lat)||size(tmp.lat,2)>1)
        varout = tmp.lat;
    end

    if ~isempty(varout)
        struct_out = [];
        for uip = 1:numel(tmp.Properties.VariableNames)
            struct_out.(tmp.Properties.VariableNames{uip}) = [];
        end
        st = size(tmp);
        nb_entries = st(1);
        for uit = 1:nb_entries
            if iscell(varout)
                var = varout{uit};
            else
                var = varout(uit,:);
            end
            nb_r = numel(var(~isnan(var)));
            for uip = 1:numel(tmp.Properties.VariableNames)
                if iscell(tmp.(tmp.Properties.VariableNames{uip}))
                    tt = tmp.(tmp.Properties.VariableNames{uip}){uit};
                else
                    tt = tmp.(tmp.Properties.VariableNames{uip})(uit,:);
                end
                if ischar(tt)
                    struct_out.(tmp.Properties.VariableNames{uip}) = ...
                        [struct_out.(tmp.Properties.VariableNames{uip}); repmat({tt},nb_r,1)];
                else
                    if numel(tt(~isnan(tt))) == nb_r
                        ttt = tt(~isnan(tt));
                        struct_out.(tmp.Properties.VariableNames{uip}) = ...
                            [struct_out.(tmp.Properties.VariableNames{uip}); ttt(:)];
                    else
                        struct_out.(tmp.Properties.VariableNames{uip}) = ...
                            [struct_out.(tmp.Properties.VariableNames{uip}); repmat(tt(1),nb_r,1)];
                    end
                end
            end
        end
        tmp = struct2table(struct_out);
    end


    writetable(tmp,csv_name);
end

end