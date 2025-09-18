classdef mode_tab_cl < dynamicprops
    
    % Properties that correspond to app components
    properties
        uid = generate_Unique_ID([]);
        Mode1Tab                      matlab.ui.container.Tab
        ModeTabGridLayout             matlab.ui.container.GridLayout
        CH4EditField                  matlab.ui.control.NumericEditField
        CO2EditField                  matlab.ui.control.NumericEditField
        RatioEditField                matlab.ui.control.NumericEditField
        O2EditField                   matlab.ui.control.NumericEditField
        N2EditField                   matlab.ui.control.NumericEditField
        ArEditField                   matlab.ui.control.NumericEditField
        NameEditField                 matlab.ui.control.EditField
        SurfacetensionEditField       matlab.ui.control.NumericEditField
        ModeBSDax                     matlab.ui.control.UIAxes
        ModeBSDPlot                   matlab.graphics.chart.primitive.Line
        Theta                      matlab.ui.control.NumericEditField
        E_fact                      matlab.ui.control.NumericEditField
        scat_distrib_obj              scat_distrib_cl
        acoustic_var                  char
        
    end
    
    events
        hasBeenModified
    end
    
    
    % App creation and deletion
    methods (Access = public)
        
        % Construct app
        function mode_tab_obj = mode_tab_cl(tab_group,distr_type,ac_var,n,r)
            
            mode_tab_obj.scat_distrib_obj = scat_distrib_cl('ac_var',ac_var,'distr',distr_type,'r',r);
            mode_tab_obj.acoustic_var = ac_var;
            mode_tab_obj.Mode1Tab = uitab(tab_group);
            mode_tab_obj.Mode1Tab.Title = sprintf('%s mode %d',ac_var,n);
            mode_tab_obj.Mode1Tab.Scrollable = 'on';
            mode_tab_obj.Mode1Tab.Tag = mode_tab_obj.uid;
            
            % Create ModeTabGridLayout
            mode_tab_obj.ModeTabGridLayout = uigridlayout(mode_tab_obj.Mode1Tab,'Scrollable','on');
            mode_tab_obj.ModeTabGridLayout.ColumnWidth = {40, 40, 40, 40,40, 40};
            mode_tab_obj.ModeTabGridLayout.RowHeight = {22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22};
            
            nb_params = numel(mode_tab_obj.scat_distrib_obj.distri_params_name);
            
            for uip = 1:nb_params
                if isprop(mode_tab_obj,mode_tab_obj.scat_distrib_obj.distri_params{uip})
                    continue;
                end
                addprop(mode_tab_obj, mode_tab_obj.scat_distrib_obj.distri_params{uip});
                addprop(mode_tab_obj,sprintf('%s_min',mode_tab_obj.scat_distrib_obj.distri_params{uip}));
                addprop(mode_tab_obj,sprintf('%s_max',mode_tab_obj.scat_distrib_obj.distri_params{uip}));
                irow = 2;
                icol = (uip-1)*3+1;
                
                tmp_label = uilabel(mode_tab_obj.ModeTabGridLayout);
                tmp_label.HorizontalAlignment = 'right';
                tmp_label.Layout.Row = irow;
                tmp_label.Layout.Column = icol+[0 1];
                tmp_label.Text = mode_tab_obj.scat_distrib_obj.distri_params_name{uip};
                
                mode_tab_obj.(mode_tab_obj.scat_distrib_obj.distri_params{uip}) = uieditfield(mode_tab_obj.ModeTabGridLayout, 'numeric');
                mode_tab_obj.(mode_tab_obj.scat_distrib_obj.distri_params{uip}).Limits = [mode_tab_obj.scat_distrib_obj.distr_params_val_min(uip) mode_tab_obj.scat_distrib_obj.distr_params_val_max(uip)]/mode_tab_obj.scat_distrib_obj.distr_params_sc(uip);
                mode_tab_obj.(mode_tab_obj.scat_distrib_obj.distri_params{uip}).Layout.Row = irow;
                mode_tab_obj.(mode_tab_obj.scat_distrib_obj.distri_params{uip}).Layout.Column = icol+2;
                mode_tab_obj.(mode_tab_obj.scat_distrib_obj.distri_params{uip}).Value = mode_tab_obj.scat_distrib_obj.distr_params_val(uip)/mode_tab_obj.scat_distrib_obj.distr_params_sc(uip);
                mode_tab_obj.(mode_tab_obj.scat_distrib_obj.distri_params{uip}).UserData.ScalingFactor = mode_tab_obj.scat_distrib_obj.distr_params_sc(uip);
                
                tmp_labell = uilabel(mode_tab_obj.ModeTabGridLayout);
                tmp_labell.HorizontalAlignment = 'right';
                tmp_labell.Layout.Row = irow+1;
                tmp_labell.Layout.Column = icol+[0 1];
                tmp_labell.Text = sprintf('%s min',mode_tab_obj.scat_distrib_obj.distri_params_name{uip});
                
                mode_tab_obj.(sprintf('%s_min',mode_tab_obj.scat_distrib_obj.distri_params{uip})) = uieditfield(mode_tab_obj.ModeTabGridLayout, 'numeric');
                mode_tab_obj.(sprintf('%s_min',mode_tab_obj.scat_distrib_obj.distri_params{uip})).Limits = [mode_tab_obj.scat_distrib_obj.distr_params_val_min(uip) mode_tab_obj.scat_distrib_obj.distr_params_val_max(uip)]/mode_tab_obj.scat_distrib_obj.distr_params_sc(uip);
                mode_tab_obj.(sprintf('%s_min',mode_tab_obj.scat_distrib_obj.distri_params{uip})).Layout.Row = irow+1;
                mode_tab_obj.(sprintf('%s_min',mode_tab_obj.scat_distrib_obj.distri_params{uip})).Layout.Column = icol+2;
                mode_tab_obj.(sprintf('%s_min',mode_tab_obj.scat_distrib_obj.distri_params{uip})).Value = mode_tab_obj.scat_distrib_obj.distr_params_val_min(uip)/mode_tab_obj.scat_distrib_obj.distr_params_sc(uip);
                mode_tab_obj.(sprintf('%s_min',mode_tab_obj.scat_distrib_obj.distri_params{uip})).UserData.ScalingFactor = mode_tab_obj.scat_distrib_obj.distr_params_sc(uip);
                
                
                tmp_label = uilabel(mode_tab_obj.ModeTabGridLayout);
                tmp_label.HorizontalAlignment = 'right';
                tmp_label.Layout.Row = irow+2;
                tmp_label.Layout.Column = icol+[0 1];
                tmp_label.Text = sprintf('%s max',mode_tab_obj.scat_distrib_obj.distri_params_name{uip});
                
                mode_tab_obj.(sprintf('%s_max',mode_tab_obj.scat_distrib_obj.distri_params{uip})) = uieditfield(mode_tab_obj.ModeTabGridLayout, 'numeric');
                mode_tab_obj.(sprintf('%s_max',mode_tab_obj.scat_distrib_obj.distri_params{uip})).Layout.Row = irow+2;
                mode_tab_obj.(sprintf('%s_max',mode_tab_obj.scat_distrib_obj.distri_params{uip})).Layout.Column = icol+2;
                mode_tab_obj.(sprintf('%s_max',mode_tab_obj.scat_distrib_obj.distri_params{uip})).Limits = [mode_tab_obj.scat_distrib_obj.distr_params_val_min(uip) mode_tab_obj.scat_distrib_obj.distr_params_val_max(uip)]/mode_tab_obj.scat_distrib_obj.distr_params_sc(uip);
                mode_tab_obj.(sprintf('%s_max',mode_tab_obj.scat_distrib_obj.distri_params{uip})).Value = mode_tab_obj.scat_distrib_obj.distr_params_val_max(uip)/mode_tab_obj.scat_distrib_obj.distr_params_sc(uip);
                mode_tab_obj.(sprintf('%s_max',mode_tab_obj.scat_distrib_obj.distri_params{uip})).UserData.ScalingFactor = mode_tab_obj.scat_distrib_obj.distr_params_sc(uip);
                mode_tab_obj.(mode_tab_obj.scat_distrib_obj.distri_params{uip}).Tag = mode_tab_obj.scat_distrib_obj.distri_params{uip};
                mode_tab_obj.(mode_tab_obj.scat_distrib_obj.distri_params{uip}).ValueChangedFcn  = {@mode_tab_obj.update_scat_distrib_obj_cback,'val'};
                
                mode_tab_obj.(sprintf('%s_max',mode_tab_obj.scat_distrib_obj.distri_params{uip})).Tag = mode_tab_obj.scat_distrib_obj.distri_params{uip};
                mode_tab_obj.(sprintf('%s_max',mode_tab_obj.scat_distrib_obj.distri_params{uip})).ValueChangedFcn  = {@mode_tab_obj.update_scat_distrib_obj_cback,'max'};
                
                mode_tab_obj.(sprintf('%s_min',mode_tab_obj.scat_distrib_obj.distri_params{uip})).Tag = mode_tab_obj.scat_distrib_obj.distri_params{uip};
                mode_tab_obj.(sprintf('%s_min',mode_tab_obj.scat_distrib_obj.distri_params{uip})).ValueChangedFcn  = {@mode_tab_obj.update_scat_distrib_obj_cback,'min',};
                
                
            end
            
            
            tmp_label = uilabel(mode_tab_obj.ModeTabGridLayout);
            tmp_label.Layout.Row = 8;
            tmp_label.Layout.Column = [1 3];
            tmp_label.Text = 'Gas Composition';
            
            
            % Create CH4EditFieldLabel
            tmp_label = uilabel(mode_tab_obj.ModeTabGridLayout);
            tmp_label.Layout.Row = 9;
            tmp_label.Layout.Column = 1;
            tmp_label.Text = 'CH4';
            
            % Create CH4EditField
            mode_tab_obj.CH4EditField = uieditfield(mode_tab_obj.ModeTabGridLayout, 'numeric');
            mode_tab_obj.CH4EditField.HorizontalAlignment = 'left';
            mode_tab_obj.CH4EditField.Layout.Row = 9;
            mode_tab_obj.CH4EditField.Layout.Column = 2;
            mode_tab_obj.CH4EditField.Value = 0;
            mode_tab_obj.CH4EditField.Limits = [0 100];
            mode_tab_obj.CH4EditField.ValueChangedFcn  = @mode_tab_obj.update_scat_props;
            
            % Create CO2EditFieldLabel
            tmp_label = uilabel(mode_tab_obj.ModeTabGridLayout);
            tmp_label.Layout.Row = 10;
            tmp_label.Layout.Column = 1;
            tmp_label.Text = 'CO2';
            
            
            % Create CO2EditField
            mode_tab_obj.CO2EditField = uieditfield(mode_tab_obj.ModeTabGridLayout, 'numeric');
            mode_tab_obj.CO2EditField.HorizontalAlignment = 'left';
            mode_tab_obj.CO2EditField.Layout.Row = 10;
            mode_tab_obj.CO2EditField.Layout.Column = 2;
            mode_tab_obj.CO2EditField.Value = 0;
            mode_tab_obj.CO2EditField.Limits = [0 100];
            mode_tab_obj.CO2EditField.ValueChangedFcn  = @mode_tab_obj.update_scat_props;
            
            % Create RatioEditField
            mode_tab_obj.RatioEditField = uieditfield(mode_tab_obj.ModeTabGridLayout, 'numeric');
            mode_tab_obj.RatioEditField.Limits = [0 100];
            mode_tab_obj.RatioEditField.Layout.Row = 6;
            mode_tab_obj.RatioEditField.Layout.Column = 3;
            mode_tab_obj.RatioEditField.Value = 50;
            mode_tab_obj.RatioEditField.ValueChangedFcn  = @mode_tab_obj.update_scat_props;
            
            % Create RatioEditFieldLabel
            tmp_label = uilabel(mode_tab_obj.ModeTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 6;
            tmp_label.Layout.Column = 2;
            tmp_label.Text = 'Ratio';
            

            mode_tab_obj.Theta = uieditfield(mode_tab_obj.ModeTabGridLayout, 'numeric');
            mode_tab_obj.Theta.Limits = [0 90];
            mode_tab_obj.Theta.Layout.Row = 5;
            mode_tab_obj.Theta.Layout.Column = 3;
            mode_tab_obj.Theta.Value = 0;
            mode_tab_obj.Theta.ValueChangedFcn  = @mode_tab_obj.update_scat_props;
            
            
            tmp_label = uilabel(mode_tab_obj.ModeTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 5;
            tmp_label.Layout.Column = 2;
            tmp_label.Text = 'Theta';
            
            mode_tab_obj.E_fact = uieditfield(mode_tab_obj.ModeTabGridLayout, 'numeric');
            mode_tab_obj.E_fact.Limits = [1 100];
            mode_tab_obj.E_fact.Layout.Row = 5;
            mode_tab_obj.E_fact.Layout.Column = 6;
            mode_tab_obj.E_fact.Value = 1;
            mode_tab_obj.E_fact.ValueChangedFcn  = @mode_tab_obj.update_scat_props;
            
            
            tmp_label = uilabel(mode_tab_obj.ModeTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 5;
            tmp_label.Layout.Column = 5;
            tmp_label.Text = 'Elong.';
            
            % Create O2EditField
            mode_tab_obj.O2EditField = uieditfield(mode_tab_obj.ModeTabGridLayout, 'numeric');
            mode_tab_obj.O2EditField.HorizontalAlignment = 'left';
            mode_tab_obj.O2EditField.Layout.Row = 11;
            mode_tab_obj.O2EditField.Layout.Column = 2;
            mode_tab_obj.O2EditField.Value = 100;
            mode_tab_obj.O2EditField.Limits = [0 100];
            mode_tab_obj.O2EditField.ValueChangedFcn  = @mode_tab_obj.update_scat_props;
            
            % Create O2EditFieldLabel
            tmp_label = uilabel(mode_tab_obj.ModeTabGridLayout);
            tmp_label.Layout.Row = 11;
            tmp_label.Layout.Column = 1;
            tmp_label.Text = 'O2';
            
            % Create N2EditField
            mode_tab_obj.N2EditField = uieditfield(mode_tab_obj.ModeTabGridLayout, 'numeric');
            mode_tab_obj.N2EditField.HorizontalAlignment = 'left';
            mode_tab_obj.N2EditField.Layout.Row = 12;
            mode_tab_obj.N2EditField.Layout.Column = 2;
            mode_tab_obj.N2EditField.Value = 0;
            mode_tab_obj.N2EditField.Limits = [0 100];
            mode_tab_obj.N2EditField.ValueChangedFcn  = @mode_tab_obj.update_scat_props;
            
            % Create N2EditFieldLabel
            tmp_label = uilabel(mode_tab_obj.ModeTabGridLayout);
            tmp_label.Layout.Row = 12;
            tmp_label.Layout.Column = 1;
            tmp_label.Text = 'N2';
            
            % Create ArEditField
            mode_tab_obj.ArEditField = uieditfield(mode_tab_obj.ModeTabGridLayout, 'numeric');
            mode_tab_obj.ArEditField.HorizontalAlignment = 'left';
            mode_tab_obj.ArEditField.Layout.Row = 13;
            mode_tab_obj.ArEditField.Layout.Column = 2;
            mode_tab_obj.ArEditField.Value = 0;
            mode_tab_obj.ArEditField.Limits = [0 100];
            mode_tab_obj.ArEditField.ValueChangedFcn  = @mode_tab_obj.update_scat_props;
            
            % Create ArEditFieldLabel
            tmp_label = uilabel(mode_tab_obj.ModeTabGridLayout);
            tmp_label.Layout.Row = 13;
            tmp_label.Layout.Column = 1;
            tmp_label.Text = 'Ar';
            
            % Create NameEditFieldLabel
            tmp_label = uilabel(mode_tab_obj.ModeTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 1;
            tmp_label.Layout.Column = [1 2];
            tmp_label.Text = sprintf('%s',mode_tab_obj.scat_distrib_obj.distr_name);
            
            % Create NameEditField
            mode_tab_obj.NameEditField = uieditfield(mode_tab_obj.ModeTabGridLayout, 'text');
            mode_tab_obj.NameEditField.Layout.Row = 1;
            mode_tab_obj.NameEditField.Layout.Column = [3 4];
            mode_tab_obj.NameEditField.Value = '';
            mode_tab_obj.NameEditField.ValueChangedFcn  = @mode_tab_obj.update_scat_props;
            
            
            % Create SurfacetensionEditField
            mode_tab_obj.SurfacetensionEditField = uieditfield(mode_tab_obj.ModeTabGridLayout, 'numeric');
            mode_tab_obj.SurfacetensionEditField.Limits = [0 1000000000];
            mode_tab_obj.SurfacetensionEditField.Layout.Row = 7;
            mode_tab_obj.SurfacetensionEditField.Layout.Column = 3;
            mode_tab_obj.SurfacetensionEditField.Value = 0.075;
            mode_tab_obj.SurfacetensionEditField.ValueChangedFcn  = @mode_tab_obj.update_scat_props;
            
            
            % Create SurfacetensionEditFieldLabel
            tmp_label = uilabel(mode_tab_obj.ModeTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 7;
            tmp_label.Layout.Column = [1 2];
            tmp_label.Text = 'Surface tension';
            
            % Create ModeBSDax
            mode_tab_obj.ModeBSDax = uiaxes(mode_tab_obj.ModeTabGridLayout);
            xlabel(mode_tab_obj.ModeBSDax, 'Radius(mm)')
            ylabel(mode_tab_obj.ModeBSDax, 'PDF')
            zlabel(mode_tab_obj.ModeBSDax, 'Z')
            mode_tab_obj.ModeBSDax.XGrid = 'on';
            mode_tab_obj.ModeBSDax.YGrid = 'on';
            mode_tab_obj.ModeBSDax.Box = 'on';
            mode_tab_obj.ModeBSDax.Layout.Row = [8 14];
            mode_tab_obj.ModeBSDax.Layout.Column = [3 7];
            mode_tab_obj.ModeBSDPlot = mode_tab_obj.scat_distrib_obj.display_pdf(mode_tab_obj.ModeBSDax,mode_tab_obj.ModeBSDPlot);
            
            addlistener(mode_tab_obj.scat_distrib_obj,'update_r',@mode_tab_obj.updateBSDplot);
            addlistener(mode_tab_obj.scat_distrib_obj,'update_distr_params_val',@mode_tab_obj.update_params_edit_fields);
        end
        
        function delete(mode_tab_obj)
            % Delete UIFigure when app is deleted
            delete(mode_tab_obj.Mode1Tab);
        end
    end
    
    
    methods 
        
        function params_struct = get_params_struct(mt_obj,eq)
            nb_modes = numel(mt_obj);
            
            params_struct.tau = nan(1,nb_modes);
            params_struct.conc = cell(1,nb_modes);
            
            params_struct.mode_name = cell(1,nb_modes);
            params_struct.distri_params = {};
            params_struct.distr = {};
            params_struct.distri_params_name = {};
            params_struct.distr_params_val =[];
            params_struct.distr_params_val_min =  [];
            params_struct.distr_params_val_max = [];
            
            params_struct.Aeq = [];
            params_struct.Beq = [];
            
            params_struct.A = [];
            params_struct.B = [];
            
            
            for ui = 1:nb_modes
                params_struct.mode_name{ui} = mt_obj(ui).NameEditField.Value;
                if isempty(params_struct.mode_name{ui})
                    params_struct.mode_name{ui} = num2str(ui);
                end
                
                
                params_struct.distr = [params_struct.distr {mt_obj(ui).scat_distrib_obj.distr}];
                params_struct.distri_params_name =[params_struct.distri_params_name   cellfun(@(x) sprintf('%s_%s',x,params_struct.mode_name{ui}),mt_obj(ui).scat_distrib_obj.distri_params_name,'un',0)];
                params_struct.distri_params=[params_struct.distri_params cellfun(@(x) sprintf('%s_%s',x,params_struct.mode_name{ui}),mt_obj(ui).scat_distrib_obj.distri_params,'un',0)];
                params_struct.distr_params_val=[params_struct.distr_params_val mt_obj(ui).scat_distrib_obj.distr_params_val];
                params_struct.distr_params_val_min =  [params_struct.distr_params_val_min mt_obj(ui).scat_distrib_obj.distr_params_val_min];
                params_struct.distr_params_val_max = [params_struct.distr_params_val_max mt_obj(ui).scat_distrib_obj.distr_params_val_max];
                
                if eq
                    params_struct.distri_params_name = [params_struct.distri_params_name sprintf('Ratio_%s',params_struct.mode_name{ui})];
                    params_struct.distri_params = [params_struct.distri_params sprintf('R_%s',params_struct.mode_name{ui})];
                    params_struct.distr_params_val = [params_struct.distr_params_val mt_obj(ui).RatioEditField.Value];
                    params_struct.distr_params_val_min =  [params_struct.distr_params_val_min 0];
                    params_struct.distr_params_val_max =  [params_struct.distr_params_val_max 100];
                    params_struct.Aeq(numel(params_struct.distr_params_val_max))=1;
                    params_struct.Beq = 1;
                end
                
                params_struct.theta(ui) = mt_obj(ui).Theta.Value;
                params_struct.e_fact(ui) = mt_obj(ui).E_fact.Value;
                params_struct.tau(ui) = mt_obj(ui).SurfacetensionEditField.Value;
                params_struct.conc{ui} = [...
                    mt_obj(ui).O2EditField.Value...
                    mt_obj(ui).N2EditField.Value...
                    mt_obj(ui).CH4EditField.Value...
                    mt_obj(ui).CO2EditField.Value...
                    mt_obj(ui).ArEditField.Value];%{'O2' 'N2' 'CH4' 'CO2' 'Ar'}
            end
            
        end
        
        function update_scat_distrib_obj_cback(mode_tab_obj,src,event,str)
            switch str
                case 'val'
                    mode_tab_obj.scat_distrib_obj.distr_params_val(strcmpi(mode_tab_obj.scat_distrib_obj.distri_params,(src.Tag))) = src.Value*src.UserData.ScalingFactor;
                case 'min'
                    if src.Value*src.UserData.ScalingFactor<mode_tab_obj.scat_distrib_obj.distr_params_val_max(strcmpi(mode_tab_obj.scat_distrib_obj.distri_params,(src.Tag)))
                        mode_tab_obj.scat_distrib_obj.distr_params_val_min(strcmpi(mode_tab_obj.scat_distrib_obj.distri_params,(src.Tag))) = src.Value*src.UserData.ScalingFactor;
                    else
                        src.Value = event.PreviousValue;
                    end
                case 'max'
                    if src.Value*src.UserData.ScalingFactor>mode_tab_obj.scat_distrib_obj.distr_params_val_min(strcmpi(mode_tab_obj.scat_distrib_obj.distri_params,(src.Tag)))
                        mode_tab_obj.scat_distrib_obj.distr_params_val_max(strcmpi(mode_tab_obj.scat_distrib_obj.distri_params,(src.Tag))) = src.Value*src.UserData.ScalingFactor;
                    else
                        src.Value = event.PreviousValue;
                    end
                otherwise
                    if isprop(mode_tab_obj.scat_distrib_obj,str)
                        mode_tab_obj.scat_distrib_obj.(str) = src.Value*src.UserData.ScalingFactor;
                    end
            end
            mode_tab_obj.ModeBSDPlot = mode_tab_obj.scat_distrib_obj.display_pdf(mode_tab_obj.ModeBSDax,mode_tab_obj.ModeBSDPlot);
            mode_tab_obj.notify('hasBeenModified');
        end
        
        function update_scat_props(mode_tab_obj,~,~)
            mode_tab_obj.notify('hasBeenModified');
        end
        
        function updateBSDplot(mode_tab_obj,~,~)
            
            mode_tab_obj.ModeBSDPlot = mode_tab_obj.scat_distrib_obj.display_pdf(mode_tab_obj.ModeBSDax,mode_tab_obj.ModeBSDPlot);
            mode_tab_obj.notify('hasBeenModified');
        end
        
        function update_params_edit_fields(mode_tab_obj,~,~)
            
            nb_params = numel(mode_tab_obj.scat_distrib_obj.distri_params_name);
            
            for uip = 1:nb_params
                mode_tab_obj.(mode_tab_obj.scat_distrib_obj.distri_params{uip}).Value = mode_tab_obj.scat_distrib_obj.distr_params_val(uip)/mode_tab_obj.scat_distrib_obj.distr_params_sc(uip);
                mode_tab_obj.(sprintf('%s_min',mode_tab_obj.scat_distrib_obj.distri_params{uip})).Value = mode_tab_obj.scat_distrib_obj.distr_params_val_min(uip)/mode_tab_obj.scat_distrib_obj.distr_params_sc(uip);
                mode_tab_obj.(sprintf('%s_max',mode_tab_obj.scat_distrib_obj.distri_params{uip})).Value = mode_tab_obj.scat_distrib_obj.distr_params_val_max(uip)/mode_tab_obj.scat_distrib_obj.distr_params_sc(uip);
            end
        end
        
    end
    
end