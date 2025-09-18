
classdef config_update_fig_cl < handle
    properties
        config_edit_fig matlab.ui.Figure
        config_table matlab.ui.control.Table
        config_obj config_cl
        prop_to_edit = {};
        config_filenames = {}
    end

    methods
        function obj = config_update_fig_cl(varargin)
            default_prop_to_edit = {'TransducerOffsetX' 'TransducerOffsetY' 'TransducerOffsetZ'...
                'TransducerAlphaX' 'TransducerAlphaY' 'TransducerAlphaZ'};

            p = inputParser;
            addParameter(p,'config_filenames',{},@iscell);
            addParameter(p,'config_obj',config_cl,@(x) isa(x,'config_cl'));
            addParameter(p,'prop_to_edit',default_prop_to_edit,@iscell);

            parse(p,varargin{:});

            obj.config_obj = p.Results.config_obj;
            obj.prop_to_edit = p.Results.prop_to_edit;
            obj.config_filenames= p.Results.config_filenames;

            Frequencies = cell(numel(obj.config_obj),1);
            Channels = cell(numel(obj.config_obj),1);

            for itt=1:length(obj.config_obj)
                Frequencies{itt} = obj.config_obj(itt).Frequency;
                Channels{itt} = obj.config_obj(itt).ChannelID;
                for iprop = 1:numel(obj.prop_to_edit)
                    if ischar(obj.config_obj(itt).(obj.prop_to_edit{iprop}))
                        if itt == 1
                            new_val.(obj.prop_to_edit{iprop}) = cell(numel(obj.prop_to_edit),1);
                        end
                        new_val.(obj.prop_to_edit{iprop}){itt} = obj.config_obj(itt).(obj.prop_to_edit{iprop});
                    else
                        if itt == 1
                            new_val.(obj.prop_to_edit{iprop}) = zeros(numel(obj.config_obj),1);
                        end
                        new_val.(obj.prop_to_edit{iprop})(itt) = obj.config_obj(itt).(obj.prop_to_edit{iprop});
                    end
                end
            end

            t = struct2table(new_val);
            t.Properties.RowNames = Channels;
            tt = rows2vars(t);
            tt.OriginalVariableNames = [];
            %tt.Properties.VariableNames = Channels;
            tt.Properties.RowNames = obj.prop_to_edit;

            obj.config_edit_fig = new_echo_figure([],'UiFigureBool',true,...
                'Name','Change Configuration Parameters','Position',[0  0 30+(length(obj.config_obj)+1)*140 (numel(obj.prop_to_edit)+1)*30+10]);
            uigl = uigridlayout(obj.config_edit_fig,[2,3]);
            uigl.Padding = [5 5 5 5];
            uigl.ColumnWidth = {'1x',140,20};
            uigl.RowHeight = {'1x',20};

            obj.config_table = uitable(uigl,"Data",tt,"RowName",obj.prop_to_edit,"ColumnName",Channels);
            obj.config_table.Layout.Column = [1 3];
            obj.config_table.Layout.Row = 1;
            obj.config_table.Data = tt;
            obj.config_table.ColumnEditable = true;
            obj.config_table.CellEditCallback = @obj.edit_cell_data;
            %obj.config_table.Tooltip = Channels;

            save_button = uibutton(uigl, 'push');
            save_button.Layout.Row = 2;
            save_button.Layout.Column = 2;
            save_button.Text = 'Update Configuration';
            save_button.ButtonPushedFcn  = @obj.update_config;

        end

        function edit_cell_data(obj,src,evt)
            if ~isnan(evt.NewData)
                fprintf('Updating %s for %s to %f\n',obj.prop_to_edit{evt.Indices(1,1)},obj.config_obj(evt.Indices(1,2)).ChannelID,evt.NewData);
                obj.config_obj(evt.Indices(1,2)).(obj.prop_to_edit{evt.Indices(1,1)}) = evt.NewData;
            else
                src.Data(evt.Indices)  =evt.PreviousData;
            end
        end

        function update_config(obj,~,~)
                obj.config_obj.config_obj_to_xml(obj.config_filenames);
                delete(obj.config_edit_fig);
        end
    end
end
