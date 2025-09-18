classdef esp3_cl < handle

    properties
        main_figure        = [];
        layers             = layer_cl.empty();
        current_layer_id   = '';
        app_path           = app_path_create();
        process            = process_cl.empty();
        curr_disp          = curr_state_disp_cl();
        echo_disp_obj      = echo_disp_cl.empty();
        echo_3D_obj        = echo_3D_cl.empty();
        logbook_fig_obj    = logbook_fig_cl.empty();
        scm_obj            = scattering_model_cl.empty();
        bpool              = [];
        %bpool              = backgroundPool
        ppool              = [];
        future_op_obj      = parallel.FevalFuture.empty();
        w_h                = files_open_waitbar_cl.empty();
        %echoint_result_disp_obj  = echoint_result_disp_cl();

        %         progress_bar_obj    = progress_bar_panel_cl.empty();
        %         opt_figure         = [];
        %         main_figure        = [];
        %         sec_figure         = [];

        %currently in main_figure appdata
        %         iptPointerManager: [1×1 struct]
        %            SelectArea: [1×1 struct]
        %       ExternalFigures: [1×0 Figure]
        %           Loading_bar: [1×1 struct]
        %            Info_panel: [1×1 struct]
        %        echo_tab_panel: [1×1 TabGroup]
        %      option_tab_panel: [1×1 TabGroup]
        %        algo_tab_panel: [1×1 TabGroup]
        %             main_menu: [1×1 struct]
        %              esp3_tab: [1×1 struct]
        %              file_tab: [1×1 struct]
        %           EchoInt_tab: [1×1 struct]
        %        Secondary_freq: [1×1 struct]
        %      Cursor_mode_tool: [1×1 struct]
        %           Display_tab: [1×1 struct]
        %             Lines_tab: [1×1 struct]
        %       Calibration_tab: [1×1 struct]
        %               Env_tab: [1×1 struct]
        %        Processing_tab: [1×1 struct]
        %        Layer_tree_tab: [1×1 struct]
        %           Reglist_tab: [1×1 struct]
        %               Map_tab: [1×1 struct]
        %             ST_Tracks: [1×1 struct]
        %                  sv_f: [1×1 struct]
        %                  ts_f: [1×1 struct]
        %           Algo_panels: [1×11 algo_panel_cl]
        %           Denoise_tab: [1×1 struct]
        %        multi_freq_tab: [1×1 struct]
        %       interactions_id: [1×1 struct]
        %            javaWindow: [1×1 com.mathworks.hg.peer.FigureFrameProxy$FigureFrame]
        %                Dndobj: [1×1 dndcontrol]
        %            ListenersH: [1×25 event.proplistener]
        %            Axes_panel: [1×1 struct]
        %             Mini_axes: [1×1 struct]
        %           LinkedProps: [1×1 struct]
    end



    methods (Access = private)
        function initialise(obj,varargin)

            %% Checking and parsing input variables
            p = inputParser;
            addRequired(p,'obj',@(x) isa(x,'esp3_cl'));
            addParameter(p,'nb_esp3_instances',0,@isnumeric);
            addParameter(p,'files_to_load',{},@iscell);
            addParameter(p,'scripts_to_run',{},@iscell);
            addParameter(p,'nodisplay',false,@islogical);
            addParameter(p,'SaveEcho',0,@isnumeric);
            parse(p,obj,varargin{1}{:});

            nb_esp3_instances=p.Results.nb_esp3_instances;

            if ~isdeployed && isappdata(groot,'esp3_obj')
                old_obj = getappdata(groot,'esp3_obj');
                if ~isempty(old_obj.main_figure) && ishandle(old_obj.main_figure)
                    delete(old_obj.main_figure);
                end
            end

            setappdata(groot,'esp3_obj',obj);

            try
                main_path = whereisEcho();
                main_figure_userData.logFile=fullfile(fullfile(main_path,'logs',string(datetime,'yyyyMMddhhmmss')+"_esp3.log"));
                if ~isfolder(fullfile(main_path,'logs'))
                    mkdir(fullfile(main_path,'logs'));
                    disp('Log Folder Created')
                end
                diary(main_figure_userData.logFile);
                fprintf('ESP3 is starting, it is %s,  %s.\n',string(datetime,'HH:mm:SS'),string(datetime,'dd MMM yyyy'));
                hh = hour(datetime);
                if hh<6
                    fprintf('It is early, you should consider having a coffee.\n');
                end
                if hh>20
                    fprintf('It is late, you should consider having a beer.\n');
                end
            catch
                disp('Could not start log...');
            end

            if ~p.Results.nodisplay
                %% Get monitor's dimensions
                [size_fig,units]=get_init_fig_size([]);
                %% Defining the app's main window
                obj.main_figure = new_echo_figure([],...
                    'Units',units,...
                    'Position',size_fig,...
                    'Name','ESP3',...
                    'Tag','ESP3',...
                    'Resize','on',...
                    'MenuBar','none',...
                    'Toolbar','none',...
                    'Visible','off',...
                    'CloseRequestFcn',@obj.close_esp3);


                obj.main_figure.ResizeFcn = @resize_echo;
                obj.main_figure.Interruptible = 'off';
                obj.main_figure.BusyAction='cancel';

            end

            %% Software version
            online = new_version_figure(obj.main_figure);

            %% Check if GPU computation is available %%
            [gpu_comp,~]=get_gpu_comp_stat();
            if gpu_comp
                disp_perso(obj.main_figure,'GPU computation Available');
                disp('GPU computation Available');
            else
                disp_perso(obj.main_figure,'GPU computation Unavailable');
                disp('GPU computation Unavailable');
            end

            %obj.connect_parpool();

            %% Read ESP3 config file
            [obj.app_path,obj.curr_disp,~,~] = load_config_from_xml(1,1,1);
            obj.curr_disp.Online=online;

            if ~p.Results.nodisplay
                disp_perso(obj.main_figure,'Listing available basemaps');
                [basemap_list,~,~,~]=list_basemaps(1,obj.curr_disp.Online);
                obj.curr_disp.Basemaps=basemap_list;
                if ~ismember(obj.curr_disp.Basemap,basemap_list)
                    obj.curr_disp.Basemap='darkwater';
                end
            end

            %% Create temporary data folder
            try
                if ~isfolder(obj.app_path.data_temp.Path_to_folder)
                    mkdir(obj.app_path.data_temp.Path_to_folder);
                    disp_perso(obj.main_figure,'Data Temp Folder Created')
                    disp_perso(obj.main_figure,obj.app_path.data_temp.Path_to_folder)
                end
            catch
                disp_perso(obj.main_figure,'Creating new config_path.xml file with standard path and options')
                [~,path_config_file,~]=get_config_files();
                delete(path_config_file);
                [obj.app_path,~,~,~] = load_config_from_xml(1,0,0);
            end

            %% Managing existing files in temporary data folder
            if ~p.Results.nodisplay
                if nb_esp3_instances<=1
                    files_in_temp=dir(fullfile(obj.app_path.data_temp.Path_to_folder,'**','*.bin'));

                    idx_old=1:numel(files_in_temp);%check all temp files...
                    if ~isempty(idx_old)

                        % by default, don't delete
                        delete_files=0;

                        choice=question_dialog_fig(obj.main_figure,'Delete files?','There are files in your ESP3 temp folder, do you want to delete them?','timeout',10,'default_answer',2);

                        switch choice
                            case 'Yes'
                                delete_files = 1;
                            case 'No'
                                delete_files = 0;
                        end

                        if isempty(choice)
                            delete_files = 0;
                        end
                        if delete_files
                            obj.clean_temp_files();
                        end
                    end
                end

                select_area.patch_h=[];
                select_area.uictxt_menu_h=[];
                setappdata(obj.main_figure,'SelectArea',select_area);

                setappdata(obj.main_figure,'ExternalFigures',matlab.ui.Figure.empty());

                obj.main_figure.Alphamap=obj.curr_disp.get_alphamap();

                %% Initialize the display and the interactions with the user
                initialize_display(obj);
                initialize_interactions_v2(obj.main_figure);
                drawnow;
                if isdeployed
                    init_java_fcn(obj.main_figure);
                end
                update_cursor_tool(obj.main_figure);
                init_listeners(obj);

                obj.main_figure.UserData = main_figure_userData;
                obj.main_figure.UserData.timer=[];
            end

            %% If files were loaded in input, load them now
            if ~isempty(p.Results.files_to_load)
                obj.open_file('file_id',p.Results.files_to_load);
            end

            if ~isempty(p.Results.scripts_to_run)
                obj.run_scripts(p.Results.scripts_to_run,'discard_loaded_layers',p.Results.SaveEcho==0) ;
            end

            if p.Results.SaveEcho>0
                for uil = 1:numel(obj.layers)
                    filepath=fileparts(obj.layers(uil).Filename{1});
                    obj.curr_disp.update_curr_disp(filepath,obj.layers(uil).Transceivers(1).Config.SounderType);
                    obj.set_layer(obj.layers(uil));
                    for uic = 1:numel(obj.layers(uil).ChannelID)
                        save_echo('vis','off','cid',obj.layers(uil).ChannelID{uic});
                    end
                end
                obj.cleanup_esp3();
            end

        end


        function closed=close_esp3(obj,~,~)
            closed=1;
            %%% Check if there are unsaved bottom and regions
            if ~isvalid(obj)
                return;
            end
            check_saved_bot_reg(obj.main_figure);

            %%% Open Close dialog box

            selection=question_dialog_fig(obj.main_figure,'Close?','Close ESP3?','timeout',10,'default_answer',2);

            if isempty(selection)
                closed=0;
                return;
            end

            %%% Handle answer
            switch selection
                case 'Yes'
                    obj.cleanup_esp3();
                case 'No'
                    closed=0;
                    return;
            end

            diary off;

        end

        function cleanup_esp3(obj)
            if ~isempty(obj.main_figure)&&isvalid(obj.main_figure)
                close_figures_callback([],[],obj.main_figure);
            end
            
            obj.delete();

            if isdeployed()
                ff=findobj(groot,'Type','Figure');
                if ~isempty(ff)
                    delete(ff);
                end
            end
        end
    end

    methods (Static)
        function update_java_path()
            main_path = whereisEcho();
            if ~isdeployed
                jpath=fullfile(main_path,'java');
                jars=dir(jpath);
                java_dyn_path=javaclasspath('-dynamic');

                for ij=length(jars):-1:1
                    if ~jars(ij).isdir
                        [~,~,fileext]=fileparts(jars(ij).name);
                        if ~any(strcmp(java_dyn_path,fullfile(jpath,jars(ij).name)))&&isfile(fullfile(jpath,jars(ij).name))
                            if strcmpi(fileext,'.jar')
                                javaaddpath(fullfile(jpath,jars(ij).name));
                                fprintf('%s added to java path\n',jars(ij).name);
                            end
                        end
                    end
                end
            end

        end

        function [col_from_xml,tags_from_xml,descr_from_xml] = get_reg_colors_from_xml()
            main_path = whereisEcho();

            xml_file = fullfile(main_path,'config','tag_colors.xml');
            if ~isfile(xml_file)
                docNode = com.mathworks.xml.XMLUtils.createDocument('regions_tag_colors');
                reg_tag_col_file = docNode.getDocumentElement;
                tag_node = docNode.createElement('regions_tag_color');
                tag_node.setAttribute('Tag','Example');
                tag_node.setAttribute('Color', strjoin(cellfun(@(x) num2str(x),num2cell(randi(255,1,3)),'UniformOutput',false),';'));
                tag_node.setAttribute('Description','This is an example. A very good one.');
                reg_tag_col_file.appendChild(tag_node);
                xmlwrite(xml_file,docNode);
            end
            xml_struct = parseXML(xml_file);
            childs  = get_childs(xml_struct,'regions_tag_color');
            col_from_xml = cell(1,numel(childs));
            tags_from_xml = cell(1,numel(childs));
            descr_from_xml = cell(1,numel(childs));
            for uic = 1:numel(childs)
                tmp_ori = get_att(childs(uic),'Color');
                if ~isempty(tmp_ori)
                    tmp = str2double(strsplit(tmp_ori,';'))/256;
                    if numel(tmp) ~=3 || any(isnan(tmp))
                        tmp = tmp_ori;
                    end
                    col_from_xml{uic} = tmp;
                end
                tags_from_xml{uic} = get_att(childs(uic),'Tag');
                descr_from_xml{uic} = get_att(childs(uic),'Description');
            end
        end
    end

    methods
        function obj = esp3_cl(varargin)
            try
                setdbprefs('DataReturnFormat','Table');
                esp3_cl.update_java_path();
                obj.initialise(varargin);

                obj.connect_parpool();
            catch err
                dlg_perso([],'Fatal Error','Failed to start ESP3');
                delete(obj.main_figure);
                if ~isdeployed
                    rethrow(err);
                end
            end
        end


        function set.layers(obj,layers)
            obj.layers=layers;
            if ~isempty(obj.layers)
                obj.layers(~isvalid(obj.layers))=[];
            end
        end

        function add_echo_disp_obj(obj,echo_disp_obj_vec)
            for ui = 1:numel(echo_disp_obj_vec)
                edisp_obj = echo_disp_obj_vec(ui);
                if ~isempty(obj.echo_disp_obj)
                    tags = {obj.echo_disp_obj(:).Tag};
                    idx = strfind(edisp_obj.Tag,tags);
                    if isempty(idx)
                        obj.echo_disp_obj = [obj.echo_disp_obj edisp_obj];
                    else
                        delete(obj.echo_disp_obj);
                        obj.echo_disp_obj(idx) = edisp_obj;
                    end
                else
                    obj.echo_disp_obj = edisp_obj;
                end
            end
        end


        function delete(obj)

            if  isdebugging
                c = class(obj);
                disp(['ML object destructor called for class ',c]);
            end

            nb_l=length(obj.layers);
            while nb_l>=1
                str_cell=list_layers(obj.layers(nb_l),'nb_char',80);
                try
                    fprintf('Deleting temp files from %s\n',str_cell{1});
                    obj.layers.delete_layers(obj.layers(nb_l).Unique_ID);
                catch
                    fprintf('Could not clean files from %s\n',str_cell{1});
                end
                nb_l=nb_l-1;
            end
            obj.clean_temp_files();
            
            if ~isempty(obj.logbook_fig_obj)
                if isvalid(obj.logbook_fig_obj)
                    delete(obj.logbook_fig_obj);
                end
            end

            for uip = 1:numel(obj.future_op_obj)
                switch obj.future_op_obj(uip)
                    case 'running'
                        cancel(obj.future_op_obj(uip));
                end
            end
            obj.disconnect_parpool();
            if ~isempty(obj.scm_obj)
                if isvalid(obj.scm_obj)
                    delete(obj.scm_obj);
                end
            end

            if ~isempty(obj.main_figure)&&ishandle(obj.main_figure)
                dndobj=getappdata(obj.main_figure,'Dndobj');
                delete(dndobj);

                appdata = get(obj.main_figure,'ApplicationData');
                fns = fieldnames(appdata);

                for ii = 1:numel(fns)
                    rmappdata(obj.main_figure,fns{ii});
                end
                delete(obj.main_figure);
            end

            if isappdata(groot,'esp3_obj')
                rmappdata(groot,'esp3_obj');
            end

        end

        function [lay,lay_idx]=get_layer(obj)
            lay=layer_cl.empty();
            lay_idx = [];
            if ~isvalid(obj)||isempty(obj.layers)
                return;
            end
            lay_idx=find(strcmpi({obj.layers(:).Unique_ID},obj.current_layer_id));
            if ~isempty(lay_idx)
                lay=obj.layers(lay_idx);
            elseif ~isempty(obj.layers)
                lay_idx=1;
                lay=obj.layers(1);
                obj.current_layer_id=obj.layers(1).Unique_ID;
            else
                lay=layer_cl.empty();
            end
        end
        function load_scm_obj(esp3_obj)

            esp3_obj.scm_obj = scattering_model_cl(esp3_obj.main_figure);
        end

        function set_layer(obj,lay_obj)
            if ~isempty({obj.layers(:).Unique_ID})
                if ismember(lay_obj.Unique_ID,{obj.layers(:).Unique_ID})
                    obj.current_layer_id=lay_obj.Unique_ID;
                end
            end
        end

    end
end
