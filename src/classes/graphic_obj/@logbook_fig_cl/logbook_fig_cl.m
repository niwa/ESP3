classdef logbook_fig_cl < handle
    properties
        LogbookFigure    matlab.ui.Figure
        LogbookTabGroup  matlab.ui.container.TabGroup
        LogBookPanels = [];
    end
    
    methods
        function obj=logbook_fig_cl(varargin)
            p = inputParser;
            addParameter(p,'dbFile','',@ischar);
            parse(p,varargin{:});
            
            obj.LogbookFigure = new_echo_figure([],'Tag','logbook','Name','Logbook(s)','UifigureBool',true,'visible','off');
            obj.LogbookFigure.CloseRequestFcn = @(src,evt) obj.delete();
            gl = uigridlayout(obj.LogbookFigure,[1,1]);
            gl.Padding = [0 0 0 0];
            obj.LogbookTabGroup = uitabgroup(gl);
            
            if ~isempty(p.Results.dbFile)
                obj.load_logbook_panel(p.Results.dbFile);
            end
            
        end
        
        
        function logbook_panel = load_logbook_panel(obj,dbFile)            
            idx_t = obj.find_logbookPanel(dbFile);
            
            if ~isempty(idx_t)
                logbook_panel = obj.LogBookPanels(idx_t);
                logbook_panel.update_logbook_panel([]);
                obj.LogbookTabGroup.SelectedTab = logbook_panel.LogbookTab;
            else
                logbook_panel = logbook_panel_cl(obj.LogbookTabGroup,dbFile);
                if ~isempty(logbook_panel.LogbookTab)
                    obj.LogBookPanels = [obj.LogBookPanels logbook_panel];
                    obj.LogbookTabGroup.SelectedTab = logbook_panel.LogbookTab;
                end
            end
            figure(obj.LogbookFigure);
        end
        
        function idx_t = find_logbookPanel(obj,dbFile)
            idx_t = [];
            
            if ~isempty(obj.LogBookPanels)
                obj.LogBookPanels(~isvalid([obj.LogBookPanels(:)]))=[];
                idx_t = find(strcmpi({obj.LogBookPanels(:).DbFile},dbFile),1);
            end
        end
        
        function delete(obj)
            
            for ui = 1:numel(obj.LogBookPanels)
                delete(obj.LogBookPanels(ui));
            end
            
            delete(obj.LogbookFigure);
            
            if  isdebugging
                c = class(obj);
                disp(['Destructor called for class ',c])
            end
        end
        
    end
    
end