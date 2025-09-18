classdef survey_options_cl < matlab.mixin.Copyable
    properties
        Feature_bool  = init_input_params({'Feature_bool'});
        SvThr  = init_input_params({'SvThr'});
        Use_exclude_regions = init_input_params({'Use_exclude_regions'});
        Es60_correction = init_input_params({'Es60_correction'});
        Motion_correction = init_input_params({'Motion_correction'});
        Shadow_zone = init_input_params({'Shadow_zone'});
        Shadow_zone_height = init_input_params({'Shadow_zone_height'});
        Vertical_slice_size = init_input_params({'Vertical_slice_size'});
        Vertical_slice_units = init_input_params({'Vertical_slice_units'});
        Horizontal_slice_size = init_input_params({'Horizontal_slice_size'});
        IntType = init_input_params({'IntType'});
        IntRef = init_input_params({'IntRef'});
        Remove_tracks = init_input_params({'Remove_tracks'});
        Remove_ST = init_input_params({'Remove_ST'});
        Export_ST = init_input_params({'Export_ST'});
        Export_TT= init_input_params({'Export_TT'});
        Denoised = init_input_params({'Denoised'});
        Frequency = init_input_params({'Frequency'});
        Channel = init_input_params({'Channel'});
        FrequenciesToLoad = init_input_params({'FrequenciesToLoad'});
        FrequenciesMinToEI_FMmode = init_input_params({'FrequenciesMinToEI_FMmode'});
        FrequenciesMaxToEI_FMmode = init_input_params({'FrequenciesMaxToEI_FMmode'});
        ChannelsToLoad = init_input_params({'ChannelsToLoad'});
        Absorption = init_input_params({'Absorption'});
        CopyBottomFromFrequency = init_input_params({'CopyBottomFromFrequency'});
        CTD_profile = init_input_params({'CTD_profile'});
        CTD_profile_fname = init_input_params({'CTD_profile_fname'});
        SVP_profile= init_input_params({'SVP_profile'});
        Temperature = init_input_params({'Temperature'});
        Salinity  = init_input_params({'Salinity'});
        SoundSpeed = init_input_params({'Soundspeed'});
        BadTransThr = init_input_params({'BadTransThr'});
        ShiftBot = init_input_params({'ShiftBot'});
        SaveBot = init_input_params({'SaveBot'});
        SaveReg = init_input_params({'SaveReg'});
        DepthMin  = init_input_params({'DepthMin'});
        DepthMax = init_input_params({'DepthMax'});
        RangeMin = init_input_params({'RangeMin'});
        RangeMax = init_input_params({'RangeMax'});
        RefRangeMin = init_input_params({'RefRangeMin'});
        RefRangeMax = init_input_params({'RefRangeMax'});
        AngleMin = init_input_params({'AngleMin'});
        AngleMax= init_input_params({'AngleMax'});
        ExportSlicedTransects = init_input_params({'ExportSlicedTransects'});
        ExportRegions  = init_input_params({'ExportRegions'});
        RunInt = init_input_params({'RunInt'});
    end

    methods
        function obj=survey_options_cl(varargin)
            default_abs = [2.7 9.8 22.8 37.4 52.7];
            default_abs_f = [18000 38000 70000 120000 200000];
            p = inputParser;
            addParameter(p,'Options',[],@(x) isstruct(x)||isempty(x)||isa(x,'survey_options_cl'));
            parse(p,varargin{:});
            
            res_opts=p.Results.Options;
            field_options = {};

            if isstruct(res_opts)
                field_options=fieldnames(res_opts);
            elseif isa(res_opts,'survey_options_cl')
                field_options=properties(res_opts);
                res_opts = surv_options_struct(res_opts);
            end

            prop_options = properties(obj);

            for ifi=1:length(field_options)
                idx_same = find(strcmpi(field_options{ifi},prop_options));
                if ~isempty(idx_same)
                    obj.(prop_options{idx_same}).set_value(res_opts.(field_options{ifi}));
                end
            end

            if isfield(res_opts,'Frequency')
                obj.FrequenciesToLoad.set_value(union(obj.FrequenciesToLoad.Value,res_opts.Frequency));
            end
            
            abs_ori=obj.Absorption.Value;
            abs_temp = nan(1,length(obj.FrequenciesToLoad.Value));
    
            if isscalar(abs_ori)
                abs_temp(obj.FrequenciesToLoad.Value == obj.Frequency.Value)=abs_ori;
            elseif length(abs_ori) == length(obj.FrequenciesToLoad.Value)
                abs_temp = abs_ori;
            end

            for ifi=1:length(obj.FrequenciesToLoad.Value)
                idx_f=find(default_abs_f==obj.FrequenciesToLoad.Value(ifi));
                if isnan(abs_temp(ifi))
                    if ~isempty(idx_f)
                        abs_temp(ifi)=default_abs(idx_f);
                    end
                end
            end
            abs_calc = arrayfun(@(x) seawater_absorption(x, obj.Salinity.Value, obj.Temperature.Value, 100,'fandg'),obj.FrequenciesToLoad.Value/1e3);
            abs_temp(isnan(abs_temp)) = abs_calc(isnan(abs_temp));
            obj.Absorption.set_value(abs_temp);
        end

        function obj_cp = copy_survey_option(obj)
            obj_cp=copy(obj);
            props = properties(obj);

            for ip = 1:numel(props)
                obj.(props{ip}) = copy(obj.(props{ip}));
            end

        end

        function obj=update_options(obj,struct_opt)
            
            if ~isempty(struct_opt)
                f_options=fieldnames(struct_opt);
                for ifi=1:length(f_options)
                    if isprop(obj,f_options{ifi})
                        if ischar(struct_opt.(f_options{ifi})) && isnumeric(obj.(f_options{ifi}).Value)
                            struct_opt.(f_options{ifi}) = str2num(string(regexprep(struct_opt.(f_options{ifi}),'[;]',' ')));
                        end
                        obj.(f_options{ifi}).set_value(struct_opt.(f_options{ifi}));
                    end
                end

            end
        end

        function str = print_survey_options(obj)
            props = properties(obj);
            str = [];
            for ui = 1:numel(props)
                obj_p = obj.(props{ui});
                params_class=obj_p.get_class();
                str_disp=obj_p.to_string();
                switch params_class{1}
                    case {'single' 'double' 'int8' 'int16' 'int32' 'int64' 'uint8' 'uint16' 'uint32' 'uint64' 'boolean' 'logical'}
                        str = [str sprintf('- %s [%s]: %s\n',...
                            obj_p.Name,str_disp{1},sprintf([obj_p.Precision ' ' obj_p.Units ' '], obj_p.Value))];
                end
            end

        end
            

        function surv_options_struct = surv_options_to_struct(obj)
            props = properties(obj);
            surv_options_struct = struct();
            for ip = 1:numel(props)
                surv_options_struct.(props{ip}) = obj.(props{ip}).Value;
            end
        end

    end

end