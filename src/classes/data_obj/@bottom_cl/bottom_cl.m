classdef bottom_cl
    
    properties (Access = public, Constant = true)
        % IMPORTANT: This value is the format of this class. Update this
        % value if you modify or add the properties of this class
             Fmt_version = '0.4';
    end
    
    properties
        
        Origin = '';     % Origin of this bottom (XML, or algorithm, etc.)
        Sample_idx = []; % Sample corresponding to bottom (int)
        Tag = [];        % 0 if bad ping, 1 if good ping
        Bottom_params = [];
        
        % Version of the bottom: -1 is copy from the current XML file
        % (default), 0 is latest version in database file, any n>0 is
        % closest version to version n from database.
        Version = []; 
        
    end

    
    methods
        
        %% constructor %%
        function obj = bottom_cl(varargin)
            
            % object gets constructed with default class values set above.
            % This section is to overwrite these values if provided in
            % input.
            
            % input parser
            % default values are that of class
            % NOTE: can't overwrite class version Fmt_version
            p = inputParser;
            addParameter(p,'Origin',    obj.Origin,     @ischar);
            addParameter(p,'Sample_idx',obj.Sample_idx, @isnumeric);
            addParameter(p,'Tag',       obj.Tag,        @(x) isnumeric(x)||islogical(x));
            addParameter(p,'Version',   obj.Version,    @isnumeric);
            parse(p,varargin{:});
            
            % overwrite object properties with input values
            props = fieldnames(p.Results);
            
            for iprop = 1:length(props)
                obj.(props{iprop}) = p.Results.(props{iprop});
            end
            
            if isempty(obj.Tag)
                obj.Tag = ones(1,size(obj.Sample_idx,2));
            end

            obj.Bottom_params = bot_params_cl('N',size(obj.Sample_idx,2));

        end
        
        function line_obj = bottom_to_line(obj,r_trans,time_trans)
            r_line = nan(1,size(obj.Sample_idx,2));
            r_line(~isnan(obj.Sample_idx)) = r_trans(mean(obj.Sample_idx(~isnan(obj.Sample_idx)),1,'omitnan'));
            line_obj = line_cl('Time',time_trans,...
                                'Range',r_line,...
                                'Reference','Surface',...
                                'File_origin',{'Bottom Line'}...
                                );
        end

        %%
        function bot_out = concatenate_Bottom(bot_1,bot_2)
            
            % in case any of the two are empty, simply output the other
            if isempty(bot_1)
                bot_out = bot_2;
                return;
            elseif isempty(bot_2)
                bot_out = bot_1;
                return;
            end
            
            % otherwise, generate a new bottom
            if strcmp(bot_1.Origin,bot_2.Origin)
                bot_out = bottom_cl('Origin',bot_1.Origin);
            else
                bot_out = bottom_cl('Origin',['Concatenated ' bot_1.Origin ' and ' bot_2.Origin]);
            end
            
            % and in it, concatenate all concatenable fields
            props = fieldnames(bot_1);
            for ip = 1:length(props)
                if ~any(strcmpi(props{ip}, {'Origin','Fmt_version','Version','Bottom_params'}))
                    bot_out.(props{ip}) = [bot_1.(props{ip}) bot_2.(props{ip})];
                end
            end
           bot_out.Bottom_params = concatenate_Bottom_param(bot_1.Bottom_params,bot_2.Bottom_params);
            
        end

        %%
        function bottom_section = get_bottom_idx_section(bottom_obj,idx)
            
            % create new bottom section
            bottom_section = bottom_cl('Origin',bottom_obj.Origin,'Version',bottom_obj.Version);
            
            % save subset of data from original bottom into bottom section
            props = fieldnames(bottom_obj);
            for ip = 1:length(props)
                if ~any(strcmpi(props{ip}, {'Origin','Fmt_version','Version','Bottom_params'}))
                    bottom_section.(props{ip}) = bottom_obj.(props{ip})(:,idx);
                end
            end
            bottom_section.Bottom_params = bottom_obj.Bottom_params.get_bottom_param_idx_section(idx);  
        end
        
        %%
        function Sample_idx = get.Sample_idx(bot_obj)
            
            Sample_idx = bot_obj.Sample_idx;
            
        end
        
        %%
        function delete(obj)
            
            c = class(obj);
            if  isdebugging
                disp(['ML object destructor called for class ',c])
            end
            
        end
        
    end
end

