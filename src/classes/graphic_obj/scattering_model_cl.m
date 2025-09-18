classdef scattering_model_cl < handle

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        ModeTGroup                    matlab.ui.container.TabGroup
        MainTGroup                    matlab.ui.container.TabGroup
        GeneralTab                    matlab.ui.container.Tab
        AddButton                     matlab.ui.control.Button
        RemoveButton                  matlab.ui.control.Button
        EqualratioCheckBox            matlab.ui.control.CheckBox
        GroupByRegions                matlab.ui.control.CheckBox
        VariableDropDown              matlab.ui.control.DropDown
        DepthmEditField               matlab.ui.control.NumericEditField
        TempCEditField                matlab.ui.control.NumericEditField
        SalPSUEditField               matlab.ui.control.NumericEditField
        FminkHzEditField              matlab.ui.control.NumericEditField
        FmaxkHzEditField              matlab.ui.control.NumericEditField
        FwinkHzEditField              matlab.ui.control.NumericEditField
        FilterDropDown               matlab.ui.control.DropDown
        NewmodeDropDown               matlab.ui.control.DropDown
        FrefkHzEditField              matlab.ui.control.NumericEditField
        NormalisationDropDown         matlab.ui.control.DropDown
        OptimTab                      matlab.ui.container.Tab
        UITable                       matlab.ui.control.Table
        BSDax                         matlab.ui.control.UIAxes
        BSDPlot                       matlab.graphics.chart.primitive.Line
        Scatax                        matlab.ui.control.UIAxes
        ScatPlot                      matlab.graphics.chart.primitive.Line
        rmin                          matlab.ui.control.NumericEditField
        rmax                          matlab.ui.control.NumericEditField
        Nb_bins                       matlab.ui.control.NumericEditField
        N                             matlab.ui.control.NumericEditField
        MaxIter                       matlab.ui.control.NumericEditField
        TolFun                        matlab.ui.control.NumericEditField
        TolX                          matlab.ui.control.NumericEditField
        OptimType                     matlab.ui.control.DropDown
        OptimWeight                   matlab.ui.control.DropDown
        OptimPlotFcn                  matlab.ui.control.DropDown
        OptimRunning                  matlab.ui.control.Lamp
        mode_tab_obj                  mode_tab_cl
        curves_obj                    curve_cl
        curves_metadata               struct
        scat_optim_obj                scat_optim_cl
        model_func                    function_handle
        params_struct                 struct
        result_table                  table
        ResTable                      matlab.ui.control.Table
        ModeTable                     matlab.ui.control.Table
        AxResMean                     matlab.ui.control.UIAxes
        AxResDensity                  matlab.ui.control.UIAxes
    end

    methods (Static)
        function yD = norm_scat(xD,yD,f_ref)
            if f_ref>0
                id_val = isnan(yD)|isinf(yD);
                xD(id_val) = inf;
                [~,id_ref] = min(abs(xD-f_ref),[],'all','omitnan');
                yD=yD-yD(id_ref);
            elseif f_ref<0
                yD=yD-pow2db_perso(sqrt(sum(db2pow_perso(yD).^2,'all','omitnan')));
            end
            if all(yD==0)||all(isnan(yD))
                yD(:) = inf;
            end
        end
    end



    % App creation and deletion
    methods (Access = public)

        % Construct app
        function scm_obj = scattering_model_cl(varargin)

            % Create UIFigure and hide until all components are created
            scm_obj.UIFigure = new_echo_figure(varargin{1},'UiFigureBool',true,'Visible', 'off');
            scm_obj.UIFigure.Position = [100 100 1200 850];
            scm_obj.UIFigure.Name = 'BSD fitting';
            scm_obj.UIFigure.Scrollable = 'on';

            pad = [10 5 10 5];
            tab_w = 400;
            tab_h = 400;

            % Create MainGridLayout
            MainGridLayout = uigridlayout(scm_obj.UIFigure,'Scrollable','on');
            MainGridLayout.ColumnWidth = {tab_w, '1x'};
            MainGridLayout.RowHeight = {tab_h, '1x'};
            MainGridLayout.Padding = pad;

            % Create ModeTGroup
            scm_obj.ModeTGroup = uitabgroup(MainGridLayout);
            scm_obj.ModeTGroup.Layout.Row = 2;
            scm_obj.ModeTGroup.Layout.Column = 1;

            % Create MainTGroup
            scm_obj.MainTGroup = uitabgroup(MainGridLayout);
            scm_obj.MainTGroup.Layout.Row = 1;
            scm_obj.MainTGroup.Layout.Column = 1;

            % Create MainTGroup
            Disp_TabGroup = uitabgroup(MainGridLayout);
            Disp_TabGroup.Layout.Row = [1 2];
            Disp_TabGroup.Layout.Column = 2;


            % Create GeneralTab
            scm_obj.GeneralTab = uitab(scm_obj.MainTGroup);
            scm_obj.GeneralTab.Title = 'General';
            %scm_obj.GeneralTab.Scrollable = 'on';

            % Create GenTabGridLayout

            t_w = scm_obj.GeneralTab.Position(3)+pad(1)*2;
            t_h = scm_obj.GeneralTab.Position(4)+pad(2)*2;

            GenTabGridLayout = uigridlayout(scm_obj.GeneralTab,'Scrollable','on');
            GenTabGridLayout.Padding = pad;
            nb_c = 4;
            GenTabGridLayout.ColumnWidth = t_w/nb_c*ones(1,nb_c);
            nb_r = 9;
            GenTabGridLayout.RowHeight = t_h/nb_r*ones(1,nb_r);

            rlim = [0 inf];
            rmin = 1e-6;
            rmax = 1e-2;

            % Create rminLabel
            tmp_label = uilabel(GenTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 7;
            tmp_label.Layout.Column = 1;
            tmp_label.Text = 'Rmin(mm)';

            sc = 1e-3;

            % Create rmin
            scm_obj.rmin = uieditfield(GenTabGridLayout, 'numeric');
            scm_obj.rmin.Layout.Row = 7;
            scm_obj.rmin.Layout.Column = 2;
            scm_obj.rmin.Limits = rlim/sc;
            scm_obj.rmin.Value = rmin/sc;
            scm_obj.rmin.Tag = 'rmin';
            scm_obj.rmin.UserData.ScalingFactor = sc;
            scm_obj.rmin.ValueChangedFcn  =@scm_obj.update_mode_tab_obj;

            % Create rmaxLabel
            tmp_label = uilabel(GenTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 7;
            tmp_label.Layout.Column = 3;
            tmp_label.Text = 'Rmax(mm)';

            % Create rmax
            scm_obj.rmax = uieditfield(GenTabGridLayout, 'numeric');
            scm_obj.rmax.Layout.Row = 7;
            scm_obj.rmax.Layout.Column = 4;
            scm_obj.rmax.Limits = rlim/sc;
            scm_obj.rmax.Value = rmax/sc;
            scm_obj.rmax.Tag = 'rmax';
            scm_obj.rmax.UserData.ScalingFactor = sc;
            scm_obj.rmax.ValueChangedFcn  = @scm_obj.update_mode_tab_obj;


            tmp_label = uilabel(GenTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 8;
            tmp_label.Layout.Column = 1;
            tmp_label.Text = 'Density';
            nlim = [1e-6 1e9];
            nd = 10;
            scm_obj.N = uieditfield(GenTabGridLayout, 'numeric');
            scm_obj.N.Layout.Row = 8;
            scm_obj.N.Layout.Column = 2;
            scm_obj.N.Limits = nlim;
            scm_obj.N.Value = nd;
            scm_obj.N.ValueChangedFcn  = @scm_obj.updateThPlots;

            % Create Nb_binsLabel
            tmp_label = uilabel(GenTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 8;
            tmp_label.Layout.Column = 3;
            tmp_label.Text = 'Nb Bins';


            % Create Nb_bins
            scm_obj.Nb_bins = uieditfield(GenTabGridLayout, 'numeric');
            scm_obj.Nb_bins.Limits = [0 100000000];
            scm_obj.Nb_bins.Layout.Row = 8;
            scm_obj.Nb_bins.Layout.Column = 4;
            scm_obj.Nb_bins.Value = 1000;
            scm_obj.Nb_bins.Tag = 'Nb_bins';
            scm_obj.Nb_bins.ValueChangedFcn  = @scm_obj.update_mode_tab_obj;

            % Create AddButton
            scm_obj.AddButton = uibutton(GenTabGridLayout, 'push');
            scm_obj.AddButton.Layout.Row = 9;
            scm_obj.AddButton.Layout.Column = 3;
            scm_obj.AddButton.Text = 'Add';
            scm_obj.AddButton.ButtonPushedFcn  = @scm_obj.AddModeFcn;

            % Create RemoveButton
            scm_obj.RemoveButton = uibutton(GenTabGridLayout, 'push');
            scm_obj.RemoveButton.Layout.Row = 9;
            scm_obj.RemoveButton.Layout.Column = 4;
            scm_obj.RemoveButton.Text = 'Remove';
            scm_obj.RemoveButton.ButtonPushedFcn  = @scm_obj.RmModeFcn;

            % Create EqualratioCheckBox
            scm_obj.EqualratioCheckBox = uicheckbox(GenTabGridLayout);
            scm_obj.EqualratioCheckBox.Text = 'Equal ratio';
            scm_obj.EqualratioCheckBox.Layout.Row = 6;
            scm_obj.EqualratioCheckBox.Layout.Column = [1 2];
            scm_obj.EqualratioCheckBox.ValueChangedFcn  = @scm_obj.updateThPlots;

            tmp_label = uilabel(GenTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 1;
            tmp_label.Layout.Column = 1;
            tmp_label.Text = 'Variable';

            % Create VariableDropDown
            scm_obj.VariableDropDown = uidropdown(GenTabGridLayout);
            scm_obj.VariableDropDown.Items = {'Sv', 'TS'};
            scm_obj.VariableDropDown.Layout.Row = 1;
            scm_obj.VariableDropDown.Layout.Column = 2;
            scm_obj.VariableDropDown.Value = 'Sv';
            scm_obj.VariableDropDown.ValueChangedFcn  = @scm_obj.change_ac_var;

            tmp_label = uilabel(GenTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 2;
            tmp_label.Layout.Column = 1;
            tmp_label.Text = {'Depth (m)'; ''};

            % Create DepthmEditField
            scm_obj.DepthmEditField = uieditfield(GenTabGridLayout, 'numeric');
            scm_obj.DepthmEditField.Layout.Row = 2;
            scm_obj.DepthmEditField.Layout.Column = 2;
            scm_obj.DepthmEditField.Value = 100;
            scm_obj.DepthmEditField.ValueChangedFcn  = @scm_obj.updateThPlots;

            % Create TempCEditField
            scm_obj.TempCEditField = uieditfield(GenTabGridLayout, 'numeric');
            scm_obj.TempCEditField.Layout.Row = 3;
            scm_obj.TempCEditField.Layout.Column = 2;
            scm_obj.TempCEditField.Value = 15;
            scm_obj.TempCEditField.Limits = [-4 50];
            scm_obj.TempCEditField.ValueChangedFcn  = @scm_obj.updateThPlots;

            tmp_label = uilabel(GenTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 3;
            tmp_label.Layout.Column = 1;
            tmp_label.Text = 'Temp.(°C)';


            scm_obj.SalPSUEditField = uieditfield(GenTabGridLayout, 'numeric');
            scm_obj.SalPSUEditField.Layout.Row = 4;
            scm_obj.SalPSUEditField.Layout.Column = 2;
            scm_obj.SalPSUEditField.Value = 35;
            scm_obj.SalPSUEditField.Limits = [0 70];
            scm_obj.SalPSUEditField.ValueChangedFcn  = @scm_obj.updateThPlots;

            tmp_label = uilabel(GenTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 4;
            tmp_label.Layout.Column = 1;
            tmp_label.Text = 'Sal.(PSU)';


            tmp_label = uilabel(GenTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 2;
            tmp_label.Layout.Column = 3;
            tmp_label.Text = 'Fmin(kHz)';

            % Create FminkHzEditField
            scm_obj.FminkHzEditField = uieditfield(GenTabGridLayout, 'numeric');
            scm_obj.FminkHzEditField.Limits = [0 500];
            scm_obj.FminkHzEditField.ValueDisplayFormat = '%.2f';
            scm_obj.FminkHzEditField.Layout.Row = 2;
            scm_obj.FminkHzEditField.Layout.Column = 4;
            scm_obj.FminkHzEditField.Value = 1;
            scm_obj.FminkHzEditField.ValueChangedFcn  = {@scm_obj.updateCurves,true,false,true};

            tmp_label = uilabel(GenTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 3;
            tmp_label.Layout.Column = 3;
            tmp_label.Text = 'Fmax(kHz)';

            % Create FmaxkHzEditField
            scm_obj.FmaxkHzEditField = uieditfield(GenTabGridLayout, 'numeric');
            scm_obj.FmaxkHzEditField.Limits = [0 500];
            scm_obj.FmaxkHzEditField.ValueDisplayFormat = '%.2f';
            scm_obj.FmaxkHzEditField.Layout.Row = 3;
            scm_obj.FmaxkHzEditField.Layout.Column = 4;
            scm_obj.FmaxkHzEditField.Value = 200;
            scm_obj.FmaxkHzEditField.ValueChangedFcn  = {@scm_obj.updateCurves,true,false,true};

            % Create NewmodeDropDown
            [distr_list,distr_names,~,~,~,~,~] = scat_distrib_cl.list_distrib();
            scm_obj.NewmodeDropDown = uidropdown(GenTabGridLayout);
            scm_obj.NewmodeDropDown.Items = distr_names;
            scm_obj.NewmodeDropDown.ItemsData = distr_list;
            scm_obj.NewmodeDropDown.Layout.Row = 9;
            scm_obj.NewmodeDropDown.Layout.Column = 2;
            scm_obj.NewmodeDropDown.Value = distr_list{1};


            tmp_label = uilabel(GenTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 9;
            tmp_label.Layout.Column = 1;
            tmp_label.Text = 'New mode';


            tmp_label = uilabel(GenTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 4;
            tmp_label.Layout.Column = 3;
            tmp_label.Text = 'Fref(kHz)';

            % Create FrefkHzEditField
            scm_obj.FrefkHzEditField = uieditfield(GenTabGridLayout, 'numeric');
            scm_obj.FrefkHzEditField.Limits = [0 500];
            scm_obj.FrefkHzEditField.ValueDisplayFormat = '%.2f';
            scm_obj.FrefkHzEditField.Layout.Row = 4;
            scm_obj.FrefkHzEditField.Layout.Column = 4;
            scm_obj.FrefkHzEditField.Value = 38;
            scm_obj.FrefkHzEditField.ValueChangedFcn  = {@scm_obj.updateCurves,true,true,true};

            tmp_label = uilabel(GenTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 5;
            tmp_label.Layout.Column = 1;
            tmp_label.Text = 'Fwin(kHz)';

            scm_obj.FwinkHzEditField = uieditfield(GenTabGridLayout, 'numeric');
            scm_obj.FwinkHzEditField.Limits = [0 500];
            scm_obj.FwinkHzEditField.ValueDisplayFormat = '%.2f';
            scm_obj.FwinkHzEditField.Layout.Row = 5;
            scm_obj.FwinkHzEditField.Layout.Column = 2;
            scm_obj.FwinkHzEditField.Value = 5;
            scm_obj.FwinkHzEditField.ValueChangedFcn  = {@scm_obj.updateCurves,false,true,false};


            scm_obj.FilterDropDown = uidropdown(GenTabGridLayout);
            scm_obj.FilterDropDown.Items = {'None' 'Linear regression' 'Quadratic Regression' 'Savitzky-Golay' 'Moving average' 'Moving Gaussian'};
            scm_obj.FilterDropDown.Layout.Row = 5;
            scm_obj.FilterDropDown.Layout.Column = [3 4];
            scm_obj.FilterDropDown.ItemsData = {'none' 'rlowess' 'rloess' 'sgolay' 'movmean' 'gaussian'};
            scm_obj.FilterDropDown.Value = 'none';

            scm_obj.FilterDropDown.ValueChangedFcn  = {@scm_obj.updateCurves,false,true,false};


            tmp_label = uilabel(GenTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 6;
            tmp_label.Layout.Column = 3;
            tmp_label.Text = 'Normalisation';

            % Create NormalisationDropDown
            scm_obj.NormalisationDropDown = uidropdown(GenTabGridLayout);
            scm_obj.NormalisationDropDown.Items = {'None', 'Norm 2', 'Fref'};
            scm_obj.NormalisationDropDown.Layout.Row = 6;
            scm_obj.NormalisationDropDown.Layout.Column = 4;
            scm_obj.NormalisationDropDown.Value = 'None';
            scm_obj.NormalisationDropDown.ValueChangedFcn  = {@scm_obj.updateCurves,true,true,true};


            % Create OptimTab
            scm_obj.OptimTab = uitab(scm_obj.MainTGroup,'Scrollable','on');
            scm_obj.OptimTab.Title = 'Optimisation';
            scm_obj.OptimTab.Scrollable = true;

            % Create OptimTabGridLayout
            OptimTabGridLayout = uigridlayout(scm_obj.OptimTab,'Scrollable','on');


            OptimTabGridLayout.ColumnWidth = {'1x', t_w/4, t_w/4};
            nb_r = 10;
            OptimTabGridLayout.RowHeight = t_h/nb_r*ones(1,nb_r);
            OptimTabGridLayout.Padding = pad;


            % Create UITable
            scm_obj.UITable = uitable(OptimTabGridLayout);
            scm_obj.UITable.Layout.Row = [1 10];
            scm_obj.UITable.Layout.Column = 1;
            scm_obj.UITable.ColumnName = {'Type';'Name'; 'Depth(m)';'Done'};
            scm_obj.UITable.RowName = {};
            scm_obj.UITable.CellSelectionCallback = @scm_obj.cellSelectFcn;
            scm_obj.UITable.UserData = 1;


            tmp_label = uilabel(OptimTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 2;
            tmp_label.Layout.Column = 2;
            tmp_label.Text = 'MaxIter';


            scm_obj.MaxIter = uieditfield(OptimTabGridLayout, 'numeric');
            scm_obj.MaxIter.Limits = [1 1e6];
            scm_obj.MaxIter.ValueDisplayFormat = '%.0f';
            scm_obj.MaxIter.Layout.Row = 2;
            scm_obj.MaxIter.Layout.Column = 3;
            scm_obj.MaxIter.Value = 1e3;


            tmp_label = uilabel(OptimTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 3;
            tmp_label.Layout.Column = 2;
            tmp_label.Text = 'TolFun';


            scm_obj.TolFun = uieditfield(OptimTabGridLayout, 'numeric');
            scm_obj.TolFun.Limits = [1e-6 1];
            scm_obj.TolFun.Layout.Row = 3;
            scm_obj.TolFun.Layout.Column = 3;
            scm_obj.TolFun.Value = 1e-3;

            tmp_label = uilabel(OptimTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 4;
            tmp_label.Layout.Column = 2;
            tmp_label.Text = 'TolX';


            scm_obj.TolX = uieditfield(OptimTabGridLayout, 'numeric');
            scm_obj.TolX.Limits = [1e-6 1];
            scm_obj.TolX.Layout.Row = 4;
            scm_obj.TolX.Layout.Column = 3;
            scm_obj.TolX.Value = 1e-3;


            tmp_label = uilabel(OptimTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 7;
            tmp_label.Layout.Column = 2;
            tmp_label.Text = 'Type:';

            scm_obj.OptimType = uidropdown(OptimTabGridLayout);
            scm_obj.OptimType.Items = {'Unconstrained', 'Constrained'};
            scm_obj.OptimType.ItemsData = {'unconstrained', 'constrained'};
            scm_obj.OptimType.Layout.Row = 7;
            scm_obj.OptimType.Layout.Column = 3;
            scm_obj.OptimType.Value = 'unconstrained';

            tmp_label = uilabel(OptimTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 5;
            tmp_label.Layout.Column = 2;
            tmp_label.Text = 'OptimPlotFcn:';

            scm_obj.OptimPlotFcn = uidropdown(OptimTabGridLayout);
            scm_obj.OptimPlotFcn.Items = {'None', 'Value','Current point'};
            scm_obj.OptimPlotFcn.ItemsData = {[], @optimplotfval,@optimplotx};
            scm_obj.OptimPlotFcn.Layout.Row = 5;
            scm_obj.OptimPlotFcn.Layout.Column = 3;
            scm_obj.OptimPlotFcn.Value = [];

            tmp_label = uilabel(OptimTabGridLayout);
            tmp_label.HorizontalAlignment = 'right';
            tmp_label.Layout.Row = 6;
            tmp_label.Layout.Column = 2;
            tmp_label.Text = 'Weight:';

            scm_obj.OptimWeight = uidropdown(OptimTabGridLayout);
            scm_obj.OptimWeight.Items = {'None', 'Ac.Var (lin)', 'Ac.Var (dB)'};
            scm_obj.OptimWeight.ItemsData = {'none', 'lin', 'dB'};
            scm_obj.OptimWeight.Layout.Row = 6  ;
            scm_obj.OptimWeight.Layout.Column = 3;
            scm_obj.OptimWeight.Value = 'none';

            ImportButton = uibutton(OptimTabGridLayout, 'push');
            ImportButton.Layout.Row = 1;
            ImportButton.Layout.Column = 2;
            ImportButton.Text = 'Import';
            ImportButton.Tooltip = 'Import Curves from ESP3 (current layer)';
            ImportButton.ButtonPushedFcn = {@scm_obj.ImportCurves,'curr'};

            ImportButton = uibutton(OptimTabGridLayout, 'push');
            ImportButton.Layout.Row = 1;
            ImportButton.Layout.Column = 3;
            ImportButton.Text = 'Import all';
            ImportButton.Tooltip = 'Import Curves from ESP3 (all layers)';
            ImportButton.ButtonPushedFcn = {@scm_obj.ImportCurves,'all'};


            
            RunButton = uibutton(OptimTabGridLayout, 'push');
            RunButton.Layout.Row = 8;
            RunButton.Layout.Column = 2;
            RunButton.Text = 'Run';
            RunButton.Tag = 'run';
            RunButton.ButtonPushedFcn  = @scm_obj.RunOptimisation;

            RunButton = uibutton(OptimTabGridLayout, 'push');
            RunButton.Layout.Row = 8;
            RunButton.Layout.Column = 3;
            RunButton.Text = 'Run grouped';
            RunButton.Tag = 'run_grouped';
            RunButton.ButtonPushedFcn  = @scm_obj.RunOptimisation;

            
            SaveButton = uibutton(OptimTabGridLayout, 'push');
            SaveButton.Layout.Row = 10;
            SaveButton.Layout.Column = 2;
            SaveButton.Text = 'Save';
            SaveButton.Tag = 'save';
            SaveButton.ButtonPushedFcn  = @scm_obj.RunOptimisation;

            RemButton = uibutton(OptimTabGridLayout, 'push');
            RemButton.Layout.Row = 9;
            RemButton.Layout.Column = 2;
            RemButton.Text = 'Rem.';
            RemButton.Tag = 'rem';
            RemButton.ButtonPushedFcn  = @scm_obj.RunOptimisation;


            scm_obj.OptimRunning = uilamp(OptimTabGridLayout,'Tooltip','Red: Busy; Green: all done!');
            scm_obj.OptimRunning.Layout.Row = 9 ;
            scm_obj.OptimRunning.Layout.Column = 3;

            AxTab = uitab(Disp_TabGroup);
            AxTab.Title = 'BSD and scattering Plots';
            AxGridLayout = uigridlayout(AxTab);

            AxGridLayout.ColumnWidth = {'1x'};
            AxGridLayout.RowHeight = {'1x' '2x'};
            AxGridLayout.Padding = pad;

            % Create BSDax
            scm_obj.BSDax = uiaxes(AxGridLayout,'nextplot','add');
            title(scm_obj.BSDax, 'Resulting BSD')
            xlabel(scm_obj.BSDax, 'Bubble radius (mm)')
            ylabel(scm_obj.BSDax, 'PDF')
            scm_obj.BSDax.XGrid = 'on';
            scm_obj.BSDax.YGrid = 'on';
            scm_obj.BSDax.Box = 'on';
            scm_obj.BSDax.Layout.Row = 1;
            scm_obj.BSDax.Layout.Column = 1;

            % Create Scatax
            scm_obj.Scatax = uiaxes(AxGridLayout,'nextplot','add');
            title(scm_obj.Scatax, 'Scattering model')
            xlabel(scm_obj.Scatax, 'Frequency(kHz)')
            ylabel(scm_obj.Scatax, 'Sv(dB)')
            scm_obj.Scatax.XGrid = 'on';
            scm_obj.Scatax.YGrid = 'on';
            scm_obj.Scatax.Box = 'on';
            scm_obj.Scatax.Layout.Row = 2;
            scm_obj.Scatax.Layout.Column = 1;


            ResTab = uitab(Disp_TabGroup);
            ResTab.Title = 'Results';
            ResGridLayout = uigridlayout(ResTab);

            ResGridLayout.ColumnWidth = {'1x' '1x' '1x' '1x'};
            ResGridLayout.RowHeight = {'1x' '2x'};
            ResGridLayout.Padding = pad;


            scm_obj.AxResMean = uiaxes(ResGridLayout,'nextplot','add','YDir','reverse');
            xlabel(scm_obj.AxResMean, 'Mean radius(mm)');
            ylabel(scm_obj.AxResMean, 'Depth(m)');
            scm_obj.AxResMean.XGrid = 'on';
            scm_obj.AxResMean.YGrid = 'on';
            scm_obj.AxResMean.Box = 'on';
            scm_obj.AxResMean.Layout.Row = 2;
            scm_obj.AxResMean.Layout.Column = [1 2];


            scm_obj.AxResDensity = uiaxes(ResGridLayout,'nextplot','add','YDir','reverse');
            xlabel(scm_obj.AxResDensity, 'Density(m^{-3})');
            scm_obj.AxResDensity.XGrid = 'on';
            scm_obj.AxResDensity.YGrid = 'on';
            scm_obj.AxResDensity.Box = 'on';
            scm_obj.AxResDensity.Layout.Row = 2;
            scm_obj.AxResDensity.Layout.Column = [3 4];


            % Create UITable
            scm_obj.ResTable = uitable(ResGridLayout);
            scm_obj.ResTable.Layout.Row = 1;
            scm_obj.ResTable.Layout.Column = [1 3];
            scm_obj.ResTable.ColumnName = {};
            scm_obj.ResTable.RowName = {};
            %scm_obj.ResTable.CellSelectionCallback = @scm_obj.cellSelectFcn;
            %scm_obj.ResTable.UserData = 1;
            scm_obj.ResTable.Visible = 'off';

            %             scm_obj.ModeTable = uitable(ResGridLayout);
            %             scm_obj.ModeTable.Layout.Row = 1;
            %             scm_obj.ModeTable.Layout.Column = 4;
            %             %scm_obj.ModeTable.CellSelectionCallback = @scm_obj.cellSelectFcn;
            %             %scm_obj.ModeTable.UserData = 1;
            %             scm_obj.ModeTable.Visible = 'off';

            ResPanel = uipanel(ResGridLayout);
            ResPanel.Layout.Row = 1;
            ResPanel.Layout.Column = 4;

            ResPanelGridLayout = uigridlayout(ResPanel);
            ResPanelGridLayout.ColumnWidth = {'1x' '1x'};
            ResPanelGridLayout.RowHeight = {'1x' 22 22 22};
            ResPanelGridLayout.Padding = pad;

            
            scm_obj.GroupByRegions = uicheckbox(ResPanelGridLayout);
            scm_obj.GroupByRegions.Text = 'Group by regions';
            scm_obj.GroupByRegions.Layout.Row = 3;
            scm_obj.GroupByRegions.Layout.Column = [1 2];
            scm_obj.GroupByRegions.ValueChangedFcn  = @scm_obj.updateResTab;

            SaveRes = uibutton(ResPanelGridLayout, 'push');
            SaveRes.Layout.Row = 4;
            SaveRes.Layout.Column = 2;
            SaveRes.Text = 'Save';
            SaveRes.Tag = 'save';
            SaveRes.ButtonPushedFcn  = @scm_obj.SaveResults;

            % Show the figure after all components are created
            scm_obj.UIFigure.Visible = 'on';

        end

        % Code that executes before app deletion
        function delete(scm_obj)
            % Delete UIFigure when app is deleted
            delete(scm_obj.UIFigure)
        end

    end

    methods (Access = private)

        %         function varargout = display_optim_res(scm_obj,src,evt)
        %             disp('Done');
        %         end
        %
        function RunOptimisation(scm_obj,src,~)

            if numel(scm_obj.curves_obj) < max(scm_obj.UITable.UserData,[],'omitnan')||isempty(scm_obj.UITable.UserData)
                return;
            end

            scm_obj.OptimRunning.Color = [1 0 0];
            pause(0.1);
            id_rem = [];
            ui_rem = [];
            optim_obj_ref = [];
            rid = {};
            for ui = scm_obj.UITable.UserData'
                curve_obj = scm_obj.curves_obj(ui);
                curve_metadata = scm_obj.curves_metadata(ui);
                
                id = find(strcmpi({scm_obj.scat_optim_obj(:).uid},curve_obj.Unique_ID),1);

                switch src.Tag
                    case {'run' 'run_grouped'}
                        type = scm_obj.OptimType.Value;
                    case 'save'
                        type = 'none';
                    case 'rem'
                        id_rem = [id_rem id];
                        ui_rem = [ui_rem ui];
                        continue;
                end

                if isempty(scm_obj.model_func)
                    continue;
                end

                switch curve_obj.Type
                    case 'sv_f'
                        [optim_model_fcn,optim_scat_inputs] = scm_obj.compute_model_func('Sv');
                    case 'ts_f'
                        [optim_model_fcn,optim_scat_inputs] = scm_obj.compute_model_func('TS');
                end

                if isempty(optim_model_fcn)
                    continue;
                end


                switch scm_obj.NormalisationDropDown.Value
                    case 'None'
                        f_ref = 0;
                        switch curve_obj.Type
                            case 'sv_f'
                                optim_scat_inputs.N = scm_obj.N.Value;
                        end
                    case 'Fref'
                        f_ref = scm_obj.FrefkHzEditField.Value*1e3;
                    case 'Norm 2'
                        f_ref = -1;
                end
                ref_idx = [];
                if strcmpi(src.Tag,'run_grouped')
                    ref_idx = find(strcmpi(curve_metadata.RegionUniqueID,rid));
                else
                    if ~isempty(optim_obj_ref)
                        ref_idx = 1;
                    end
                end

                if ~isempty(ref_idx)
                    optim_scat_inputs.distr_params_val = optim_obj_ref(ref_idx).optim_results.results(1:numel(optim_scat_inputs.distr_params_val));
                    if numel(optim_obj_ref(ref_idx).optim_results.results)>optim_scat_inputs.distr_params_val & strcmpi(curve_obj.Type,'sv_f')
                        optim_scat_inputs.N = optim_obj_ref(ref_idx).optim_results.results(end);
                    end
                end

                optim_obj = scat_optim_cl(optim_model_fcn,curve_obj,optim_scat_inputs,'optim_type',type,...
                    'optim_data_wval_str',scm_obj.OptimWeight.Value,...
                    'f_ref',f_ref,...
                    'optim_data_filter',struct('smethod',scm_obj.FilterDropDown.Value,'swin',scm_obj.FwinkHzEditField.Value),...
                    'optim_options',...
                    optimset('PlotFcns',scm_obj.OptimPlotFcn.Value,'MaxIter',scm_obj.MaxIter.Value,'TolFun',scm_obj.TolFun.Value,'TolX',scm_obj.TolX.Value,'Display','final'));

                optim_obj.run_optimisation();

                if optim_obj.optim_results.fval<10 && isempty(ref_idx)
                    optim_obj_ref = [optim_obj_ref optim_obj];
                    rid = [rid {curve_metadata.RegionUniqueID}];
                end

                if isempty(id)
                    scm_obj.scat_optim_obj = [scm_obj.scat_optim_obj optim_obj];
                else
                    scm_obj.scat_optim_obj(id) = optim_obj;
                end

                if optim_obj.optim_results.exit>=0
                    scm_obj.UITable.Data.("Done")(ui)=true;
                end

            end

            scm_obj.scat_optim_obj(id_rem)=[];
            scm_obj.curves_obj(ui_rem) = [];
            scm_obj.curves_metadata(ui_rem) = [];
            scm_obj.UITable.Data(ui_rem,:) = [];
            scm_obj.populate_curves_table();
            scm_obj.updateThPlots([],[]);
            scm_obj.display_curve(true,true);
            scm_obj.OptimRunning.Color = [0 1 0];
            scm_obj.set_result_table();
            scm_obj.updateResTab();
        end

        function SaveResults(scm_obj,~,~)
            if isempty(scm_obj.result_table)||~any(contains(scm_obj.result_table.("Curve Type"),lower(scm_obj.VariableDropDown.Value)))
                scm_obj.ResTable.Data = [];
                scm_obj.ResTable.Visible = 'off';
                return;
            end

            id  = find(contains(scm_obj.result_table.("Curve Type"),lower(scm_obj.VariableDropDown.Value)));

            nb_res = numel(id);

            if nb_res ==0
                scm_obj.ResTable.Data = [];
                scm_obj.ResTable.Visible = 'off';
                return;
            end
            sub_res = scm_obj.result_table(id,:);

            app_path = get_esp3_prop('app_path');

            if ~isempty(app_path)
                fold = app_path.data_root.Path_to_folder;
            else
                fold = pwd;
            end

            if ~isfolder(fold)
                mkdir(fold);
            end

            ff = generate_valid_filename(sprintf('BSD_%s_results.csv',lower(scm_obj.VariableDropDown.Value)));
            [fileN, pathname] = uiputfile({'*.xlsx'},...
                'Save regions to file',...
                fullfile(fold,ff));

            if isequal(pathname,0)||isequal(fileN,0)
                return;
            end

            writetable(sub_res,fullfile(pathname,fileN));

        end

        function ImportCurves(scm_obj,~,~,imp_str)
            switch imp_str
                case'curr'
                    lay = get_current_layer();
                case 'all'
                    lay = get_esp3_prop('layers');
                case 'refresh'
                    lay = layer_cl.empty();
            end


            curves_tmp = curve_cl.empty();
            mdata_tmp = [];

            for ilay = 1:numel(lay)
                cc = lay(ilay).get_curves_per_type('');

                if ~isempty(cc)
                    curves_tmp = [curves_tmp cc];
                    mdata_tmp = [mdata_tmp scattering_model_cl.get_curves_metadata(lay(ilay),cc)];
                end

            end

            if ~isempty(curves_tmp)
                [~,ids] = sortrows(table({mdata_tmp(:).RegionUniqueID}',[curves_tmp(:).Depth]'));
                scm_obj.curves_obj = curves_tmp(ids);
                scm_obj.curves_metadata = mdata_tmp(ids);                
            end

            if ~isempty(scm_obj.result_table)&&~isempty(scm_obj.curves_obj)
                uid_c = {scm_obj.curves_obj(:).Unique_ID};
                uid_s = {scm_obj.scat_optim_obj(:).uid};
                uid_t = scm_obj.result_table.uid;
                scm_obj.scat_optim_obj(~ismember(uid_s,uid_c)) = [];
                scm_obj.result_table(~ismember(uid_t,uid_c),:) = [];
            end

            switch imp_str
                case 'refresh'
                otherwise
                    scm_obj.populate_curves_table();
                    scm_obj.updateThPlots([],[]);
                    scm_obj.display_curve(true,true);
                    scm_obj.updateResTab([],[]);
            end
        end

        function updateCurves(scm_obj,src,evt,up_th,up_scat,up_mod)
            if up_th
                scm_obj.updateThPlots(src,evt);
            end
            scm_obj.display_curve(up_scat,up_mod);
        end

        function updateResTab(scm_obj,~,~)

            h = findobj(scm_obj.AxResMean,'Tag','newplots');
            delete(h);
            h = findobj(scm_obj.AxResDensity,'Tag','newplots');
            delete(h);
            h = [];

            if isempty(scm_obj.result_table)||~any(contains(scm_obj.result_table.("Curve Type"),lower(scm_obj.VariableDropDown.Value)))
                scm_obj.ResTable.Data = [];
                scm_obj.ResTable.Visible = 'off';
                return;
            end

            id  = find(contains(scm_obj.result_table.("Curve Type"),lower(scm_obj.VariableDropDown.Value)));

            nb_res = numel(id);
            if nb_res ==0
                scm_obj.ResTable.Data = [];
                scm_obj.ResTable.Visible = 'off';
                return;
            end
            sub_res = scm_obj.result_table(id,:);
            [~,iid_s] = sort(scm_obj.result_table.Depth(id));

            tmp = cellfun(@(x) strsplit(x,'_'),scm_obj.result_table.uid(iid_s),'UniformOutput',false);
            tmp = [tmp{:}];
            regid = tmp(1:2:end);

            switch scm_obj.VariableDropDown.Value
                case 'Sv'
                    data_res = sub_res(iid_s,["Curve Name" "Depth" "Distribution" "Mode Name" "Mean" "Std" "Density" "Ratio" "uid"]);
                    xlabel(scm_obj.AxResDensity,'Density (n/m^{-3})');
                    ls = '--';
                    ls_m = 'o-';
                case 'TS'
                    data_res = sub_res(iid_s,["Curve Name" "Depth" "Mode Name" "Mean" "Ratio" "uid"]);
                    xlabel(scm_obj.AxResDensity,'Density (n/m^{-3})');
                    ls = 'none';
                    ls_m = 'o';
            end

            nb_col = size(data_res,2);
            w = cell(1,nb_col);
            w(:) = {'1x'};
            w{end} = 0;
            scm_obj.ResTable.ColumnName = data_res.Properties.VariableNames;
            scm_obj.ResTable.ColumnWidth = w;
            scm_obj.ResTable.Data = data_res;
            scm_obj.ResTable.Visible = 'on';

            switch scm_obj.GroupByRegions.Value
                case true
                    gg = findgroups([sub_res(iid_s,["Distribution" "Mode Name"]) regid']);
            
                case false
                    gg = findgroups(sub_res(iid_s,["Distribution" "Mode Name"]));
            end

            ug = unique(gg);
            legend_str = {};


            for uig = 1:numel(ug)
                id = find(ug(uig) ==gg);
                r_5 = nan(size(id));
                r_95 = nan(size(id));
                
                switch scm_obj.VariableDropDown.Value
                    case 'Sv'
                        for uir = 1:numel(r_5)
                            id_m = find(strcmpi(sub_res.uid{iid_s(id(uir))},{scm_obj.scat_optim_obj(:).uid}));
                            [r_model,BSD_model,~] = scm_obj.scat_optim_obj(id_m).get_bsd_result(linspace(scm_obj.rmin.Value*scm_obj.rmin.UserData.ScalingFactor,scm_obj.rmax.Value*scm_obj.rmax.UserData.ScalingFactor,scm_obj.Nb_bins.Value));
                            [~,id_5] = min(abs(cumsum(BSD_model.*gradient(r_model))-0.05));
                            [~,id_95] = min(abs(cumsum(BSD_model.*gradient(r_model))-0.95));
                            r_5(uir) = r_model(id_5)*1e3;
                            r_95(uir) = r_model(id_95)*1e3;
                        end
                end

                mean_t = sub_res.Mean(iid_s(id))*1e3;
                dens_t = sub_res.Density(iid_s(id));
                d_t = sub_res.Depth(iid_s(id));
                [~,ido] = sort(d_t);
                h_tmp = plot(scm_obj.AxResMean,mean_t(ido),d_t(ido),ls_m,'Tag','newplots');
                plot(scm_obj.AxResMean,r_5,d_t(ido),'Marker','x','Linestyle',ls,'Tag','newplots','color',h_tmp.Color);
                plot(scm_obj.AxResMean,r_95,d_t(ido),'Marker','x','Linestyle',ls,'Tag','newplots','color',h_tmp.Color);
                plot(scm_obj.AxResDensity,dens_t(ido),d_t(ido),ls_m,'Tag','newplots','color',h_tmp.Color);
                h = [h h_tmp];
                legend_str = [legend_str sprintf('%s %s', sub_res.("Distribution"){iid_s(id(1))} ,sub_res.("Mode Name"){iid_s(id(1))})];
            end

            if ~isempty(h)
                legend(h,legend_str);
            end

        end




        function  populate_curves_table(scm_obj)

            tt=table('Size',[numel(scm_obj.curves_obj) numel(scm_obj.UITable.ColumnName)],'VariableTypes',{'cellstr' 'cellstr' 'double' 'logical'},...
                'VariableNames',scm_obj.UITable.ColumnName);


            tt.("Type")(contains({scm_obj.curves_obj(:).Type},'ts')) = {'TS(f)'};
            tt.("Type")(contains({scm_obj.curves_obj(:).Type},'sv')) = {'Sv(f)'};
            tt.("Name") = {scm_obj.curves_obj(:).Name}';
            tt.("Depth(m)") = [scm_obj.curves_obj(:).Depth]';

            scm_obj.UITable.Data  = tt;
            if numel(tt.("Depth(m)")) < scm_obj.UITable.UserData
                scm_obj.UITable.UserData = 1;
            end
        end

        function AddModeFcn(scm_obj,~,~)
            r = scm_obj.compute_r();
            scm_obj.mode_tab_obj = [scm_obj.mode_tab_obj mode_tab_cl(scm_obj.ModeTGroup,scm_obj.NewmodeDropDown.Value,scm_obj.VariableDropDown.Value,numel(scm_obj.mode_tab_obj)+1,r)];
            scm_obj.ModeTGroup.SelectedTab = scm_obj.mode_tab_obj(end).Mode1Tab;

            addlistener(scm_obj.mode_tab_obj(end),'hasBeenModified',@scm_obj.mode_listen_fcn);
            scm_obj.mode_tab_obj(end).notify('hasBeenModified');
        end

        function mode_listen_fcn(scm_obj,src,evt)
            scm_obj.updateCurves(src,evt,true,true,true)
        end

        function r=compute_r(scm_obj)
            r = linspace(scm_obj.rmin.Value*scm_obj.rmin.UserData.ScalingFactor,scm_obj.rmax.Value*scm_obj.rmax.UserData.ScalingFactor,scm_obj.Nb_bins.Value);
        end

        function cellSelectFcn(scm_obj,src,evt)
            id_disp = unique(evt.Indices(:,1));
            src.UserData  =id_disp;
            if numel(id_disp)>=1
                scm_obj.DepthmEditField.Value = scm_obj.UITable.Data.("Depth(m)")(id_disp(1));
                scm_obj.updateThPlots([],[]);
            end
            scm_obj.display_curve(false,false);
        end

        function set_result_table(scm_obj)
            rest = table.empty;

            for id = 1:numel(scm_obj.scat_optim_obj)
                [~,~,bsd_stats] = scm_obj.scat_optim_obj(id).get_bsd_result(linspace(scm_obj.rmin.Value*scm_obj.rmin.UserData.ScalingFactor,scm_obj.rmax.Value*scm_obj.rmax.UserData.ScalingFactor,scm_obj.Nb_bins.Value));
                rest = [rest;bsd_stats];
            end

            scm_obj.result_table = rest;
        end


        function [h_out,h_out_bsd,names] = display_curve(scm_obj,up_scat_curves,up_model_curves)


            h_scat = findobj(scm_obj.Scatax,'Tag',lower(scm_obj.VariableDropDown.Value));

            h_bsd = findobj(scm_obj.BSDax,'Tag',lower(scm_obj.VariableDropDown.Value));


            h_out = [];
            h_out_bsd = [];
            names = {};

            if isempty(scm_obj.UITable.UserData)||numel(scm_obj.curves_obj)<max(scm_obj.UITable.UserData,[],'all','omitnan')
                delete(h_scat);
                delete(h_bsd);
                return;
            end

            curve_obj = scm_obj.curves_obj(scm_obj.UITable.UserData);
            idc  = find(contains({curve_obj(:).Type},lower(scm_obj.VariableDropDown.Value)));

            if isempty(idc)
                delete(h_scat);
                delete(h_bsd);
                return;
            else
                uid = {curve_obj(idc).Unique_ID};

                usrdt = [cellfun(@(x) sprintf('data_%s',x),uid,'un',0) cellfun(@(x) sprintf('model_%s',x),uid,'un',0)];

                if ~isempty(h_scat)
                    tmp = {h_scat(:).UserData};
                    tmp(~cellfun(@ischar,tmp)) = {''};
                    delete(h_scat(~ismember(tmp,usrdt)));
                end

                if ~isempty(h_bsd)
                    tmp = {h_bsd(:).UserData};
                    tmp(~cellfun(@ischar,tmp)) = {''};
                    delete(h_bsd(~ismember(tmp,usrdt)));
                end
            end

            curve_obj = curve_obj(idc);


            for ui = 1:numel(curve_obj)


                id = find(strcmpi({scm_obj.scat_optim_obj(:).uid},curve_obj(ui).Unique_ID),1);

                h_tmp_scat = findobj(scm_obj.Scatax,'UserData',sprintf('data_%s',curve_obj(ui).Unique_ID));
                h_tmp_model = findobj(scm_obj.Scatax,'UserData',sprintf('model_%s',curve_obj(ui).Unique_ID));
                h_bsd_tmp = findobj(scm_obj.BSDax,'UserData',sprintf('model_%s',curve_obj(ui).Unique_ID));

                xD = curve_obj(ui).XData;

                if up_scat_curves||isempty(h_tmp_scat)
                    yD = curve_obj(ui).filter_curve(scm_obj.FilterDropDown.Value,scm_obj.FwinkHzEditField.Value);
                else
                    yD = nan(size(xD));
                end

                if ~isempty(id)&&(up_model_curves||isempty(h_tmp_model))
                    [xD_model,yD_model] =  scm_obj.scat_optim_obj(id).get_scat_curve_result(scm_obj.get_f_vec());
                    xD_model = xD_model/1e3;
                else
                    xD_model = nan(size(xD));
                    yD_model = nan(size(xD));
                end

                if ~isempty(id)&&(up_model_curves||isempty(h_bsd_tmp))
                    [r_model,BSD_model,~] = scm_obj.scat_optim_obj(id).get_bsd_result(linspace(scm_obj.rmin.Value*scm_obj.rmin.UserData.ScalingFactor,scm_obj.rmax.Value*scm_obj.rmax.UserData.ScalingFactor,scm_obj.Nb_bins.Value));
                    r_model = r_model * 1e3;
                else
                    r_model = nan(size(xD));
                    BSD_model = nan(size(xD));
                end



                switch scm_obj.NormalisationDropDown.Value
                    case 'None'
                        f_ref = 0;
                    case 'Fref'
                        f_ref = scm_obj.FrefkHzEditField.Value;
                    case 'Norm 2'
                        f_ref = -1;
                end


                if isempty(h_tmp_scat)||up_scat_curves
                    yD = scattering_model_cl.norm_scat(xD,yD,f_ref);
                end

                if isempty(h_tmp_model)||up_model_curves
                    yD_model = scattering_model_cl.norm_scat(xD_model,yD_model,f_ref);
                end

                if isempty(h_tmp_scat)
                    h_tmp_scat = plot(scm_obj.Scatax,xD,yD,'-o','markersize',3,'Tag',lower(scm_obj.VariableDropDown.Value),'UserData',sprintf('data_%s',curve_obj(ui).Unique_ID));
                    h_tmp_scat.MarkerFaceColor = h_tmp_scat.Color;
                elseif up_scat_curves
                    set(h_tmp_scat,'XData',xD,'YData',yD);
                end

                if isempty(h_tmp_model)
                    plot(scm_obj.Scatax,xD_model,yD_model,'Color',h_tmp_scat.Color,'Tag',lower(scm_obj.VariableDropDown.Value),'UserData',sprintf('model_%s',curve_obj(ui).Unique_ID));
                elseif up_model_curves
                    set(h_tmp_model,'XData',xD_model,'YData',yD_model);
                end



                if isempty(h_bsd_tmp)
                    h_bsd_tmp = plot(scm_obj.BSDax,r_model,BSD_model,'Color',h_tmp_scat.Color,'Tag',lower(scm_obj.VariableDropDown.Value),'UserData',sprintf('model_%s',curve_obj(ui).Unique_ID));
                elseif up_model_curves
                    set(h_bsd_tmp,'XData',r_model,'YData',BSD_model);
                end

                h_out = [h_out h_tmp_scat];
                h_out_bsd = [h_out_bsd h_bsd_tmp];
                names = [names curve_obj(ui).Name];

            end

            if ~isempty(scm_obj.ScatPlot)
                legend([scm_obj.ScatPlot h_out],[{'Manual Fit'} names]);
            elseif ~isempty(h_out)
                legend(h_out,names);
            end
        end

        function RmModeFcn(scm_obj,src,evt)
            if numel(scm_obj.mode_tab_obj)==0
                return;
            end
            id_rem =[];
            for ui = 1:numel(scm_obj.mode_tab_obj)
                if scm_obj.mode_tab_obj(ui).Mode1Tab == scm_obj.ModeTGroup.SelectedTab
                    id_rem = ui;
                end
            end

            if ~isempty(id_rem)
                delete(scm_obj.mode_tab_obj(id_rem));
                scm_obj.mode_tab_obj(id_rem) = [];
            end

            for ui = 1:numel(scm_obj.mode_tab_obj)
                scm_obj.mode_tab_obj(ui).Mode1Tab.Title = sprintf('%s mode %d',scm_obj.mode_tab_obj(ui).acoustic_var,ui);
            end
            scm_obj.updateThPlots(src,evt);

        end

        function update_mode_tab_obj(scm_obj,~,~)
            r = scm_obj.compute_r();
            for ui = 1:numel(scm_obj.mode_tab_obj)
                scm_obj.mode_tab_obj(ui).scat_distrib_obj.r = r;
            end
        end

        function updateThPlots(scm_obj,~,~)
            if  isdebugging
                disp('Update plots');
            end
            f_vec = scm_obj.get_f_vec();

            switch scm_obj.VariableDropDown.Value
                case 'TS'
                    h = findobj(scm_obj.Scatax,'Tag','sv');
                    delete(h);
                    h = findobj(scm_obj.BSDax,'Tag','sv');
                    delete(h);
                case 'Sv'
                    h = findobj(scm_obj.Scatax,'Tag','ts');
                    delete(h);
                    h = findobj(scm_obj.BSDax,'Tag','ts');
                    delete(h);
            end

            r_vec=scm_obj.compute_r();
            bubbles_pdf = zeros(size(r_vec));
            ac_var = scm_obj.VariableDropDown.Value;
            mt_obj = scm_obj.get_mode_tab_obj(ac_var);
            h = findobj(scm_obj.BSDax,'Tag','bsds');
            delete(h);
            ratio = ones(1,numel(mt_obj));

            for ui = 1:numel(mt_obj)
                if ~scm_obj.EqualratioCheckBox.Value
                    ratio(ui) = mt_obj(ui).RatioEditField.Value;
                end
            end



            for ui = 1:numel(mt_obj)
                [r_vec,p] = mt_obj(ui).scat_distrib_obj.get_pdf();

                if ~scm_obj.EqualratioCheckBox.Value
                    ratio(ui) = mt_obj(ui).RatioEditField.Value;
                end

                plot(scm_obj.BSDax,r_vec*1e3,p*ratio(ui)./sum(ratio),'--k','Tag','bsds');

                bubbles_pdf = bubbles_pdf + p*ratio(ui);
            end


            bubbles_pdf = bubbles_pdf./(sum(bubbles_pdf,'omitnan'));


            mu = sum(bubbles_pdf.*r_vec,'omitnan')/sum(bubbles_pdf,'omitnan');
            sigma = sqrt(sum((r_vec-mu).^2.*bubbles_pdf,'omitnan')/sum(bubbles_pdf,'omitnan'));
            mu  = mu*1e3;
            sigma = sigma*1e3;
            if ~isnan(mu)
                xline(scm_obj.BSDax,mu,'k',sprintf('%.2fmm',mu),'LabelVerticalAlignment','bottom','Tag','bsds');
                xline(scm_obj.BSDax,mu-2*sigma,'--k','Tag','bsds');
                xline(scm_obj.BSDax,mu+2*sigma,'--k','Tag','bsds');
            end

            if isempty(scm_obj.BSDPlot)||~isvalid(scm_obj.BSDPlot)
                scm_obj.BSDPlot = plot(scm_obj.BSDax,r_vec*1e3,bubbles_pdf,'k','linewidth',1);
            else
                scm_obj.BSDPlot.XData = r_vec*1e3;
                scm_obj.BSDPlot.YData = bubbles_pdf;
            end

            [scm_obj.model_func,scm_obj.params_struct]=scm_obj.compute_model_func(scm_obj.VariableDropDown.Value);

            if isempty(scm_obj.params_struct)
                delete(scm_obj.ScatPlot);
                scm_obj.ScatPlot =matlab.graphics.chart.primitive.Line.empty;
                return;
            end
            init_var = scm_obj.params_struct.distr_params_val;

            switch scm_obj.NormalisationDropDown.Value
                case 'None'
                    f_ref = 0;
                    init_var = [init_var scm_obj.N.Value];
                case 'Fref'
                    f_ref = scm_obj.FrefkHzEditField.Value;
                case 'Norm 2'
                    f_ref = -1;
            end


            modelinit = scm_obj.model_func(init_var,f_vec,scm_obj.DepthmEditField.Value);

            modelinit = scattering_model_cl.norm_scat(f_vec,pow2db_perso(modelinit),f_ref*1e3);

            if isempty(scm_obj.ScatPlot)||~isvalid(scm_obj.ScatPlot)
                scm_obj.ScatPlot = plot(scm_obj.Scatax,f_vec/1e3,modelinit,'k','linewidth',1);
            else
                scm_obj.ScatPlot.XData = f_vec/1e3;
                scm_obj.ScatPlot.YData = modelinit;
            end
        end

        function  f_vec = get_f_vec(scm_obj)
            if scm_obj.FminkHzEditField.Value>=scm_obj.FmaxkHzEditField.Value
                scm_obj.FminkHzEditField.Value =scm_obj.FminkHzEditField.Limits(1);
                scm_obj.FmaxkHzEditField.Value =scm_obj.FmaxkHzEditField.Limits(end);
            end
            f_vec = scm_obj.FminkHzEditField.Value*1e3:100:scm_obj.FmaxkHzEditField.Value*1e3;
        end

        function  mode_tab_obj = get_mode_tab_obj(scm_obj,ac_var)
            mode_tab_obj =[];
            if isempty(scm_obj.mode_tab_obj)
                return;
            end

            mode_tab_obj = scm_obj.mode_tab_obj(strcmpi({scm_obj.mode_tab_obj(:).acoustic_var},ac_var));

        end


        function [model_func,params_struct] = compute_model_func(scm_obj,ac_var)

            mt_obj = scm_obj.get_mode_tab_obj(ac_var);

            nb_modes = numel(mt_obj);
            model_func = function_handle.empty();
            params_struct = [];

            if nb_modes ==0
                return;
            end

            params_struct = mt_obj.get_params_struct(~scm_obj.EqualratioCheckBox.Value && nb_modes>1);

            params_struct.N = nan;
            params_struct.T = scm_obj.TempCEditField.Value;
            params_struct.S = scm_obj.SalPSUEditField.Value;


            r_min = scm_obj.rmin.Value*scm_obj.rmin.UserData.ScalingFactor;
            r_max = scm_obj.rmax.Value*scm_obj.rmax.UserData.ScalingFactor;

            eq = scm_obj.EqualratioCheckBox.Value || nb_modes==1;

            nb_bins = scm_obj.Nb_bins.Value;

            model_func= @(xx,yy,d) compute_scattering_model(...
                'distr_params',xx,...
                'distrib',params_struct.distr,...
                'theta',params_struct.theta,...
                'e_fact',params_struct.e_fact,...
                'f',yy,...
                'Nb_bins',nb_bins,...
                'T', params_struct.T,...
                'S', params_struct.S,...
                'z',d,...
                'rmin',r_min,...
                'rmax',r_max,...
                'tau',params_struct.tau,...
                'ac_var',ac_var,...
                'modes_conc',params_struct.conc,...
                'equal_ratio',eq ...
                );

        end

        function change_ac_var(scm_obj,~,~)
            [distr_list,distr_names,~,~,~,~,~] = scat_distrib_cl.list_distrib();

            switch scm_obj.VariableDropDown.Value
                case 'TS'
                    id = strcmpi(distr_list,'mono');
                    scm_obj.NewmodeDropDown.Items = distr_names(id);
                    scm_obj.NewmodeDropDown.ItemsData = distr_list(id);
                    scm_obj.NewmodeDropDown.Value = distr_list{id};
                case 'Sv'
                    scm_obj.NewmodeDropDown.Items = distr_names;
                    scm_obj.NewmodeDropDown.ItemsData = distr_list;
                    scm_obj.NewmodeDropDown.Value = distr_list{1};
            end

            scm_obj.Scatax.YAxis.Label.String = sprintf('%s(dB)',scm_obj.VariableDropDown.Value);
            scm_obj.updateThPlots([],[]);
            scm_obj.display_curve(true,true);
            scm_obj.updateResTab([],[]);
        end
    end

    methods (Static)
        function curve_metadata = init_curve_metadata()
            curve_metadata.Lat = 0;
            curve_metadata.Long = 0;
            curve_metadata.Time = '';
            curve_metadata.Filename = '';
            curve_metadata.SurveyDataString = '';
            curve_metadata.Depth = 0;
            curve_metadata.RegionUniqueID = '';
            curve_metadata.RegionTag = '';
            curve_metadata.RegionName = '';
            curve_metadata.RegionID = '';
            curve_metadata.RegionChannelID = '';
        end

        function cmdta = get_curves_metadata(layer_obj,cc)
            cmdta = [];

            for ic = 1:numel(cc)
                curve_metadata = scattering_model_cl.init_curve_metadata();
                curve_metadata.Depth = cc(ic).Depth;
                C = strsplit(cc(ic).Unique_ID,'_');
                reg_id = C{1};
                reg = region_cl.empty();
                for itr = 1:numel(layer_obj.Transceivers)
                    trans_obj = layer_obj.Transceivers(itr);
                    reg  = trans_obj.get_region_from_Unique_ID(reg_id);
                    if ~isempty(reg)
                        break;
                    end
                end

                if ~isempty(reg)
                    iping = round(mean(reg.Idx_ping));
                    iFile=trans_obj.Data.FileId(iping);
                    tt = trans_obj.GPSDataPing.Time(iping);
                    i_str='';

                    if length(layer_obj.SurveyData)>=1
                        for is=1:length(layer_obj.SurveyData)
                            surv_temp=layer_obj.get_survey_data('Idx',is);
                            if ~isempty(surv_temp)
                                if tt>=surv_temp.StartTime&&tt<=surv_temp.EndTime
                                    i_str=surv_temp.print_survey_data();
                                end
                            end
                        end
                    end

                    curve_metadata.Lat = trans_obj.GPSDataPing.Lat(iping);
                    curve_metadata.Long = trans_obj.GPSDataPing.Long(iping);
                    curve_metadata.Time = datestr(tt);
                    curve_metadata.Filename = layer_obj.Filename{iFile};
                    curve_metadata.SurveyDataString = i_str;
                    curve_metadata.RegionUniqueID = reg.Unique_ID;
                    curve_metadata.RegionTag = reg.Tag;
                    curve_metadata.RegionName = reg.Name;
                    curve_metadata.RegionID = reg.ID;
                    curve_metadata.RegionChannelID = trans_obj.Config.ChannelID;
                end
                cmdta = [cmdta curve_metadata];
            end

        end
    end
end


