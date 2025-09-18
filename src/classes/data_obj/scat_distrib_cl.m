classdef scat_distrib_cl < handle
    
    
    properties (Access = public)
        distr (:,:) char {ischar} = 'wbl'
        distr_name (:,:) char {ischar} = 'Weibull'
        distri_params
        distri_params_name
        distr_params_val
        distr_params_val_min
        distr_params_val_max
        distr_params_sc
        r
        
    end
    
    events
        update_r
        update_distr_params_val
    end
    
    methods (Static)
        function [distr_list,distr_names,distri_params,distri_params_name,distr_params_val,distr_params_val_min,distr_params_val_max,distr_params_sc] = list_distrib()
            distr_list = {'wbl' 'ray' 'uni' 'lognorm' 'mono'};
            distr_names = {'Weibull', 'Rayleigh', 'Uniform', 'Log-Normal','Mono-Size'};
            distri_params = {{'a' 'b'} {'m'} {'rmin' 'rmax'} {'mu' 'sigma'} {'r'}};
            distri_params_name ={{'Scale(mm)' 'Shape'} {'Mean(mm)'} {'Min. radius(mm)' 'Max. radius(mm)'} {'Mean(mm)' 'Std.(mm)'} {'Radius(mm)'}};
            
            distr_params_val = {[1e-3 2] 1e-3 [1e-4 1e-3] [1e-3 1e-3] 1e-3};
            distr_params_sc = {[1e-3 1] 1e-3 [1e-3 1e-3] [1e-3 1e-3] 1e-3};
            distr_params_val_min = {[1e-6 0.1] 1e-6 [1e-6 21e-6] [1e-6 1e-6] 1e-6};
            distr_params_val_max = {[1e-2 500] 1e-2 [1e-2 1e-2] [1e-2 1e-2] 1e-2};
        end
        
        function [distr,distr_name,distri_params,distri_params_name,distr_params_val,distr_params_val_min,distr_params_val_max,distr_params_sc] = get_distr(distr_in)
            [distr_list,distr_names,distri_params,distri_params_name,distr_params_val,distr_params_val_min,distr_params_val_max,distr_params_sc] = scat_distrib_cl.list_distrib();
            id = find(strcmpi(distr_list,distr_in),1);
            if isempty(id)
                id = 1;
            end
            
            distr = distr_list{id};
            distr_name = distr_names{id};
            distri_params = distri_params{id};
            distri_params_name = distri_params_name{id};
            distr_params_val = distr_params_val{id};
            distr_params_val_min = distr_params_val_min{id};
            distr_params_val_max = distr_params_val_max{id};
            distr_params_sc = distr_params_sc{id};
            
        end
        
    end
    
    
    
    methods (Access = public)
        
        
        function sd_obj = scat_distrib_cl(varargin)
            
            [distr_list,~,~,~,~,~,~] = scat_distrib_cl.list_distrib();
            %r_lim = [1e-6 1e-2];
            p = inputParser;
            r_d = linspace(1e-6,2*1e-3,500);
            addParameter(p,'ac_var','Sv',@(x) ismember(x,{'Sv' 'TS'}));
            addParameter(p,'distr','wbl',@(x) ismember(x,distr_list));
            addParameter(p,'r',r_d,@isnumeric);
            
            parse(p,varargin{:});
            
            switch p.Results.ac_var
                case 'Sv'
                    distr = p.Results.distr;
                case 'TS'
                    distr = 'mono';
            end
            
            [sd_obj.distr,...
                sd_obj.distr_name,....
                sd_obj.distri_params,...
                sd_obj.distri_params_name,....
                sd_obj.distr_params_val,....
                sd_obj.distr_params_val_min,....
                sd_obj.distr_params_val_max,...
                sd_obj.distr_params_sc] = scat_distrib_cl.get_distr(distr);
            
            sd_obj.r = p.Results.r;
            
        end
        
        
        
        function [r,p] = get_pdf(obj)
            r = obj.r;
            
            p = compute_pdf(obj.distr,r,obj.distr_params_val);
            
            
        end
        
        function h = display_pdf(obj,ax,h)
            [r_vec,p] = obj.get_pdf();
            if isempty(h)
                h = plot(ax,r_vec*1e3,p);
            else
                h.XData = r_vec*1e3;
                h.YData = p;   
            end
        end
        
    end
    
    methods
        function  set.r(obj,r)
            obj.r = r;
            obj.notify('update_r');
        end
        
        function set.distr_params_val(obj,distr_params_val)
            obj.distr_params_val = distr_params_val;
            obj.notify('update_distr_params_val');
        end
    end
    
end

