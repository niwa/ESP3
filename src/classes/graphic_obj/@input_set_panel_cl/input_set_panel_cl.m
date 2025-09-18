classdef input_set_panel_cl < dynamicprops

    properties
        Title char
        Input_param_obj_vec = [];
        Input_uigl_h matlab.ui.container.GridLayout
    end

    methods
        function obj = input_set_panel_cl(varargin)
            p = inputParser;

            addParameter(p,'Title','',@(x) ischar(x));
            addParameter(p,'Input_param_obj_vec',[],@(x) isempty(x)||isa(x,'input_param_cl'));
            addParameter(p,'container_h',[],...
                @(x) isa(x,'matlab.ui.Figure')||isa(x,'matlab.ui.container.Panel')||...
                isa(x,'matlab.ui.container.Tab')||isa(x,'matlab.ui.container.GridLayout'));
            addParameter(p,'input_struct_h',[],@(x) isstruct(x)||isempty(x));
            addParameter(p,'layout_size',[],@isnumeric);
            addParameter(p,'Scrollable','on',@isnumeric);
            addParameter(p,'esp3_obj',[],@(x) isempty(x)||isa(x,'esp3_cl'))
            addParameter(p,'std_rowheight',26,@isnumeric);
            addParameter(p,'std_colwidth',90,@isnumeric);
            parse(p,varargin{:});

            obj.Title = p.Results.Title;
            obj.Input_param_obj_vec = p.Results.Input_param_obj_vec;

            for ui = 1:numel(p.Results.Input_param_obj_vec)
                addprop(obj,p.Results.Input_param_obj_vec(ui).Name);
            end

            nb_inputs = numel(obj.Input_param_obj_vec);
            if nb_inputs == 0
                return;
            end


            param_names = obj.Input_param_obj_vec.get_name();
            params_class = obj.Input_param_obj_vec.get_class();
            str_disp = obj.Input_param_obj_vec.to_string();
            nb_cell_params=sum(strcmpi(params_class,'cell'));
            %nb_bool_params=sum(strcmpi(params_class,'logical'));

            nb_slots = nb_cell_params*2+(nb_inputs-nb_cell_params+1);

            sz = p.Results.layout_size;

            if isempty(sz)||all(isnan(sz))
                sz = [ceil(nb_slots/2) 4];
            else
                sz = sz.*[1 2];

                if isnan(sz(1))
                    sz(1) = ceil(nb_slots/(sz(2)/2));
                end

                if isnan(sz(2))
                    sz(2) = ceil(nb_slots/sz(1))*2;
                end
            end

            container_h = p.Results.container_h;
            esp3_obj = p.Results.esp3_obj;


            if ~isempty(esp3_obj)
                ff = esp3_obj.main_figure;
            else
                ff = [];
            end

            if isempty(container_h)
                container_h = new_echo_figure(ff,'UiFigureBool',true,'Name',p.Results.Title);
            end
            
            if isprop(container_h,'Title')
                container_h.Title = p.Results.Title;
            end

            if isprop(container_h,'Scrollable')
                container_h.Scrollable  = 'on';
            end

            obj.Input_uigl_h = uigridlayout(container_h,sz,'Scrollable','on');

            obj.Input_uigl_h.RowHeight = repmat(p.Results.std_rowheight,1,sz(1));
            obj.Input_uigl_h.ColumnWidth = repmat({'1x',p.Results.std_colwidth},1,round(sz(2)/2));

            ic = 1;
            ir = 1;

            for ui = 1:numel(obj.Input_param_obj_vec)

                if isempty(p.Results.input_struct_h) || ~isfield(p.Results.input_struct_h,param_names{ui})
                    if ic+1 > sz(2)
                        ic = 1;
                        ir = ir +1;
                    end
                    
                    switch params_class{ui}
                        case {'cell' 'single' 'double' 'int8' 'int16' 'int32' 'int64' 'uint8' 'uint16' 'uint32' 'uint64'}
                            if ~isempty(obj.Input_param_obj_vec(ui).Disp_name)
                                tmp_label = uilabel(obj.Input_uigl_h);
                                tmp_label.HorizontalAlignment = 'right';
                                tmp_label.Layout.Row = ir;
                                tmp_label.Layout.Column = ic;
                                tmp_label.Text = obj.Input_param_obj_vec(ui).Disp_name;
                                tmp_label.Tooltip = obj.Input_param_obj_vec(ui).Tooltipstring;
                                iadd = 1;
                            else
                                iadd = 0;
                            end
                    end

                    switch params_class{ui}
                        case 'cell'
                           
                            obj.(param_names{ui})=uidropdown(obj.Input_uigl_h,...
                                'Items',obj.Input_param_obj_vec(ui).Value_range);
                            obj.(param_names{ui}).Layout.Row = ir;
                            obj.(param_names{ui}).Layout.Column = ic+iadd;

                        case {'single' 'double' 'int8' 'int16' 'int32' 'int64' 'uint8' 'uint16' 'uint32' 'uint64'}
                            if numel(obj.Input_param_obj_vec(ui).Value)>1
                                continue;
                            end

                            if numel(obj.Input_param_obj_vec(ui).Value_range) > 2

                                obj.(param_names{ui})=uidropdown(obj.Input_uigl_h,...
                                    'Items',cellfun(@(xx) sprintf('%.0f %s',xx,obj.Input_param_obj_vec(ui).Units),num2cell(obj.Input_param_obj_vec(ui).Value_range),'UniformOutput',false),...
                                    'ItemsData',obj.Input_param_obj_vec(ui).Value_range);
                            else

                                obj.(param_names{ui}) =  uieditfield(obj.Input_uigl_h,'numeric');
                                obj.(param_names{ui}).ValueDisplayFormat = sprintf('%s %s',obj.Input_param_obj_vec(ui).Precision,obj.Input_param_obj_vec(ui).Units);
                                obj.(param_names{ui}).Limits  = obj.Input_param_obj_vec(ui).Value_range;
                            end
                            obj.(param_names{ui}).Layout.Row = ir;
                            obj.(param_names{ui}).Layout.Column = ic+iadd;

                        case 'logical'

                            obj.(param_names{ui}) = uicheckbox(obj.Input_uigl_h, 'Text',str_disp{ui});
                            obj.(param_names{ui}).Layout.Row = ir;
                            obj.(param_names{ui}).Layout.Column = [ic ic+1];

                    end
                else
                    obj.(param_names{ui})=p.Results.input_struct_h.(param_names{ui});

                end
                
                if isprop(obj.(param_names{ui}),'Items') && ismember(obj.Input_param_obj_vec(ui).Value,obj.(param_names{ui}).Items)
                    obj.(param_names{ui}).Value = obj.Input_param_obj_vec(ui).Value;
                end
                obj.(param_names{ui}).ValueChangedFcn = @update_input_param_fcn;
                obj.(param_names{ui}).Tooltip = obj.Input_param_obj_vec(ui).Tooltipstring;
                obj.(param_names{ui}).Tag = (param_names{ui});

                ic = ic+2;

            end

            function update_input_param_fcn(src,~)

                idx_input = find(strcmpi({obj.Input_param_obj_vec(:).Name},src.Tag));
                if ~isempty(idx_input)
                    obj.Input_param_obj_vec(idx_input).set_value(src.Value);
                end


            end

        end

        function outputArg = method1(obj,inputArg)
            outputArg = obj.title + inputArg;
        end
    end
end