function [data,units,found] = get_data_from_das_netcdf(folder,varnames,fnames,st,et)

if ~iscell(fnames)
    fnames = {fnames};
end
data = [];
units = {};
found = false(1,numel(fnames));

for ui = 1:numel(fnames)

    tmp = dir(fullfile(folder,fnames{ui}));
    if isempty(tmp)
        tmp = dir(fullfile(folder,sprintf('*.%s',fnames{ui})));
    end

    if isempty(tmp)
        tmp = dir(fullfile(folder,sprintf('*%s*',fnames{ui})));
    end

    if isempty(tmp)
        continue;
    end

    filenames =  fullfile(folder,{tmp(~[tmp(:).isdir]).name});
    [~,fileN,~] = cellfun(@fileparts,filenames,'UniformOutput',false);

    fst = cellfun(@(x) datenum(x(1:15),'yyyymmdd-HHMMSS'),fileN);
    idx_f = fst>=(st-1) & fst<et;
    filenames = filenames(idx_f);

    
    for uif = 1 :numel(filenames)
        filename  = filenames{uif};
        %ffsplit = splitstr(filenames,'-');
        finfo = ncinfo(filename);

        for uivar = 1:numel(finfo.Variables)
            if isempty(varnames)||~ismember((finfo.Variables(uivar).Name),union(varnames,'time'))
                continue;
            end

            d_tmp.(finfo.Variables(uivar).Name)  = ncread(filename,finfo.Variables(uivar).Name);
            idx_unit = find(strcmpi({finfo.Variables(uivar).Attributes(:).Name},'units'),1);
            if ~isempty(idx_unit)
                uu = finfo.Variables(uivar).Attributes(idx_unit).Value;
            else
                uu = '';
            end

            switch finfo.Variables(uivar).Name
                case 'time'
                    d_tmp.(finfo.Variables(uivar).Name)= datetime(d_tmp.(finfo.Variables(uivar).Name),'ConvertFrom','excel');
            end


            if uif>1
                data.(finfo.Variables(uivar).Name) = [data.(finfo.Variables(uivar).Name);d_tmp.(finfo.Variables(uivar).Name)];
            else
                data = d_tmp;
                units.(finfo.Variables(uivar).Name) = uu;
                found(ui) = true;
            end

        end
    end
    clear d_tmp
    if isfield(data,'time')
        idx_t = datenum(data.time)>=st & datenum(data.time)<=et;
        ff = fieldnames(data);
        for uit = 1:numel(ff)
            data.(ff{uit}) = data.(ff{uit})(idx_t);
        end
    end
end