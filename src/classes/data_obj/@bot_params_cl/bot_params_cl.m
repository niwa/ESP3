classdef bot_params_cl

    properties

        % Roxann E1 "hardness"bot_param parameter (energy of the tail of the
        % first echo), and Roxann E2 "roughness"bot_param parameter (total
        % energy of the second echo)
        E1 = [];
        E2 = [];

    end


    methods

        %% constructor %%
        function obj = bot_params_cl(varargin)

            p = inputParser;
            addParameter(p,'N',        [],         @isnumeric);
            parse(p,varargin{:});

            if ~isempty(p.Results.N)
                    obj.E1 = -999.*ones(1,p.Results.N); % undefined
                    obj.E2 = -999.*ones(1,p.Results.N); % undefined
            end

        end

        %%
        function obj_out = concatenate_Bottom_param(obj_1,obj_2)

            % in case any of the two are empty, simply output the other
            if isempty(obj_1)
                obj_out = obj_2;
                return;
            elseif isempty(obj_2)
                obj_out = obj_1;
                return;
            end

            props = fieldnames(obj_1);
            for i = 1:length(props)
                obj_out.(props{i}) = [obj_1.(props{i}), obj_2.(props{i})];
            end
        end



        %%
        function bot_params_section = get_bottom_param_idx_section(bottom_obj,idx)

            bot_params_section = bot_params_cl();


            props = fieldnames(bottom_obj);
            for i = 1:length(props)
                bot_params_section.(props{i}) = bottom_obj.(props{i})(idx);
            end

        end

        function delete(obj)

            c = class(obj);
            if  isdebugging
                disp(['ML object destructor called for class ',c])
            end

        end

    end
end

