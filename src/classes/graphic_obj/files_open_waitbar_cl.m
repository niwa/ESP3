classdef files_open_waitbar_cl < handle
    properties
        waitbar_fig matlab.ui.Figure
        waitbar_dlg matlab.ui.dialog.ProgressDialog
        file_img matlab.ui.control.Lamp
        general_label matlab.ui.control.Label
        file_label matlab.ui.control.Label
        cancel_button matlab.ui.control.Button
        progaxes matlab.ui.control.UIAxes
        progpatch matlab.graphics.primitive.Patch
        progtext  matlab.graphics.primitive.Text
        f_obj = [];
        file_list = {};
    end

    methods
        function obj = files_open_waitbar_cl(varargin)
            p=inputParser;

            addParameter(p,'Name','',@ischar);
            addParameter(p,'CancelText','Cancel',@islogical);
            addParameter(p,'file_list',{},@iscell);
            addParameter(p,'general_label','',@ischar);
            addParameter(p,'f_obj',[]);
            addParameter(p,'main_figure',[]);
            addParameter(p,'cmap','GMT_ocean',@ischar)

            parse(p,varargin{:});
            gui_fmt=init_gui_fmt_struct();
            nb_files = numel(p.Results.file_list);

            h_files = 1.65*gui_fmt.txt_h*(nb_files+1);
            h_tot = h_files + gui_fmt.txt_h*4;
            size_max = get(groot, 'MonitorPositions');
            h_tot = min(h_tot,max(size_max(:,4))-100);
            h_files = h_tot - + gui_fmt.txt_h*4;
            w_tot = gui_fmt.txt_w*3.5 + gui_fmt.box_w;

            
            obj.waitbar_fig  = new_echo_figure(p.Results.main_figure,...
                'Name',p.Results.Name,...
                'Position',[100 100 w_tot h_tot],...
                'tag','waitbar',...
                'visible','on',...
                'resize','off',...
                'UiFigureBool',true,...
                'Cmap',p.Results.cmap);
            obj.waitbar_fig.CloseRequestFcn = @obj.close_fig;

            uig_tot = uigridlayout(obj.waitbar_fig,[3,1],'BackgroundColor',obj.waitbar_fig.Color);
            uig_tot.RowHeight = {gui_fmt.txt_h,h_tot-h_files-gui_fmt.txt_h,h_files};
            uig_tot.Padding = [uig_tot.Padding(1) 0 uig_tot.Padding(3) 0];

            obj.general_label = uilabel(uig_tot,'Text',p.Results.general_label,'HorizontalAlignment','center');

            uig_bar= uigridlayout(uig_tot,[1,2],'BackgroundColor',obj.waitbar_fig.Color);
            %uig_bar.Padding = [0 0 0 0];
            uig_bar.ColumnWidth = {'4x' '1x'};
            obj.progaxes = uiaxes( uig_bar,...
                'XLim', [0 1], ...
                'YLim', [0 1], ...
                'Box', 'on', ...
                'visible','on',...
                'ytick', [], ...
                'xtick', [],...
                'CLim',[0 1]);
             disableDefaultInteractivity(obj.progaxes);


            obj.progpatch = patch( obj.progaxes,...
                'XData', [0 0 0 0], ...
                'visible','on',...
                'YData', [0 0 1 1],...
                'CData', [1 1 1 1],...
                'FaceAlpha',0.8,...
                'FaceColor','interp');

            obj.progtext = text(obj.progaxes,...
                0.5, 0.5, '0%', ...
                'HorizontalAlignment', 'Center', ...
                'VerticalAlignment','middle',...
                'visible','on',...
                'FontUnits', 'Normalized', ...
                'FontSize', 0.6 ,'Interpreter','none',...
                'tag','progtext');

            obj.cancel_button = uibutton(uig_bar,'push','Text',p.Results.CancelText);
            obj.cancel_button.ButtonPushedFcn = @obj.cancel_process;

            uig_files= uigridlayout(uig_tot,[nb_files,2],'BackgroundColor',obj.waitbar_fig.Color,'Scrollable','on');
            uig_files.ColumnWidth = {'5x' '1x'};
             uig_files.RowHeight = ones(1,nb_files)*1*gui_fmt.txt_h;
            obj.file_list = p.Results.file_list;
            obj.f_obj = p.Results.f_obj;

            [~,file_list,ext] = cellfun(@fileparts,p.Results.file_list,'UniformOutput',false);
            if isempty(p.Results.f_obj)
                IDs = 1:numel(file_list);
            else
                IDs = [p.Results.f_obj(:).ID];
            end

            for uif = 1:numel(file_list)
                obj.file_label(uif) = uilabel(uig_files,"Text",sprintf('Reading %s...',[file_list{uif} ext{uif}]),'UserData',[file_list{uif} ext{uif}]);
                obj.file_img(uif) = uilamp(uig_files,'Color','Red','UserData',IDs(uif));
            end

        end


        function set_value(obj,val)
            obj.progpatch.XData=[0 val val 0];
            obj.progpatch.CData=[1 1-val 1-val 1];
            str_disp=sprintf('%.0f%%',val*100);
            %disp(str_disp);
            obj.progtext.String=str_disp;
        end

        function delete(obj)
            delete(obj.waitbar_fig);
        end
        function close_fig(obj,~,~)
            cancel_process(obj);
            delete(obj.waitbar_fig);
        end

        function cancel_process(obj,~,~)
            idx = find({obj.f_obj.State} ~= "finished");
            obj.general_label.Text = 'Cancelling...';
            if ~isempty(idx)
                fprintf('Cancelling\n');
                for uid = idx
                    cancel(obj.f_obj(uid));
                end
            end
        end

        function update_waitbar(obj,ff)
            %profile on;
            if isvalid(obj.waitbar_fig)
                id_green = find({obj.f_obj.State} == "finished");
                %id_green = 1;
                if isempty(ff)
                    idx = id_green;
                else
                    idx = find(ff.ID == [obj.f_obj.ID]);
                end

                for uid = idx
                    if ~isempty(obj.f_obj(uid).Error)
                        col = [1 0.65 0];
                        str = 'Cancelled';
                    else
                        col = 'green';
                        str = 'Done';
                    end

                    obj.file_img(uid).Color =  col;
                    obj.file_label(uid).Text =  sprintf('Reading %s... %s.',obj.file_label(uid).UserData,str);
                    %fprintf('Read file %s (%s)\n',obj.file_label(uid).UserData,str);
                end

                obj.set_value(numel(id_green)/numel(obj.f_obj));

            end
            drawnow;
            %profile off;profile viewer;
        end

        function increment_waitbar(obj)
            %profile on;
            if isvalid(obj.waitbar_fig)
                n_tot = numel(obj.file_label);
                val = obj.progpatch.XData(2);
                obj.set_value(min(val + 1/n_tot,1));
            end
            
            drawnow;
            %profile off;profile viewer;
        end


    end
end