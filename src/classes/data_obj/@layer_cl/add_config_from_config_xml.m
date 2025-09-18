function add_config_from_config_xml(layers_obj,varargin)

p = inputParser;

addRequired(p,'layers_obj',@(obj) isa(obj,'layer_cl'));
addParameter(p,'xml_file','',@ischar);
addParameter(p,'overwrite_config',true,@islogical);

parse(p,layers_obj,varargin{:});
config_file = p.Results.xml_file;

for ilay=1:numel(layers_obj)

    lay_obj = layers_obj(ilay);
    if isempty(lay_obj.Transceivers)
        continue;
    end
    [files,~] = lay_obj.list_files_layers();

    [path_f,fileN,~] =  cellfun(@fileparts,files,'UniformOutput',false);


    config_files_to_load=cellfun(@(x,y) fullfile(x,[y '_config.xml']),path_f,fileN,'UniformOutput',false);
    config_exist = cellfun(@isfile,config_files_to_load);

    config_obj = [lay_obj.Transceivers(:).Config];

    ff = '';
    config_file_existing = config_files_to_load(config_exist);
    if isfile(config_file)
        ff = config_file;
        idf = 0;
    else
        if any(config_exist)
            ff = config_file_existing{1};
            idf = 1;
        end
        config_files_missing = config_files_to_load(~config_exist);
    end
    done = false;
    if ~isempty(ff)

        while ~done && idf <= numel(config_file_existing)
            try
                config_obj = config_obj.update_config_obj_from_xml(ff);
                for uit = 1:numel(config_obj)
                    idx_config = find(strcmp(lay_obj.ChannelID,config_obj(uit).ChannelID));
                    if ~isempty(idx_config)
                        lay_obj.Transceivers(idx_config).Config = config_obj(uit);
                    end
                end
                done = true;
            catch
                    fprintf('Could not read Config for file %s\n',ff);
                    config_files_missing = union(config_files_missing,{ff});
                    idf = idf+1;
                    if numel(config_file_existing)>=idf
                        ff = config_file_existing{idf};
                    else
                        done = true;
                    end
            end
        end
    end

    if ~isempty(config_files_missing)
        [tmp,~] = fileparts(config_files_missing);
        if isfolder(tmp)
            config_obj.config_obj_to_xml(config_files_missing);
        end
    end



end



