classdef scat_optim_cl < handle
    
    properties (Access = public)
        uid
        optim_model_fcn function_handle
        optim_scat_inputs struct
        optim_options struct
        optim_type char
        optim_data_filter struct
        optim_data_curve curve_cl
        optim_data_wval =  'none';
        optim_results struct
        f_ref = 0;
    end
    
    events
        
    end
    
    methods
        function scat_optim_obj = scat_optim_cl(optim_model_fcn,optim_data_curve,optim_scat_inputs,varargin)
            
            p = inputParser;
            
            addRequired(p,'optim_model_fcn',@(x) isa(x,'function_handle'));
            addRequired(p,'optim_data_curve');
            addRequired(p,'optim_scat_inputs',@isstruct);
            addParameter(p,'optim_options',optimset('PlotFcns',@optimplotfval,'MaxIter',1e3,'TolFun',1e-2),@isstruct);
            addParameter(p,'optim_type','unconstrained',@(x) ismember(x,{'unconstrained','constrained','none'}));
            addParameter(p,'optim_data_wval_str','none');
            addParameter(p,'f_ref',0);
            addParameter(p,'optim_data_filter',struct('smethod','none','swin',1));
            
            parse(p,optim_model_fcn,optim_data_curve,optim_scat_inputs,varargin{:});
            
            scat_optim_obj.uid = optim_data_curve.Unique_ID;
            scat_optim_obj.f_ref = p.Results.f_ref;
            scat_optim_obj.optim_model_fcn = optim_model_fcn;
            scat_optim_obj.optim_data_curve = optim_data_curve;

            scat_optim_obj.optim_data_wval = p.Results.optim_data_wval_str;
            
            scat_optim_obj.optim_options = p.Results.optim_options;
            scat_optim_obj.optim_type = p.Results.optim_type;
            scat_optim_obj.optim_scat_inputs = p.Results.optim_scat_inputs;
            scat_optim_obj.optim_model_fcn = p.Results.optim_model_fcn;
            scat_optim_obj.optim_data_filter = p.Results.optim_data_filter;
            scat_optim_obj.optim_results = struct('results',[],'fval',0,'exit',-1);
        end
        
        function model_comp = compute_optim_fcn(scat_optim_obj)
            xD = scat_optim_obj.optim_data_curve.XData*1e3;
            yD = scat_optim_obj.optim_data_curve.filter_curve(scat_optim_obj.optim_data_filter.smethod,scat_optim_obj.optim_data_filter.swin);
            
            %F = griddedInterpolant(xD(~isnan(yD)),yD(~isnan(yD)),'makima');
            F = griddedInterpolant(xD,yD);

            xDD = min(xD):1e2:max(xD);
            yDD = F(xDD);
           
            d = scat_optim_obj.optim_data_curve.Depth;

            yDD_model_func =@(x) scattering_model_cl.norm_scat(xDD,pow2db_perso(scat_optim_obj.optim_model_fcn(x,xDD,d)),scat_optim_obj.f_ref);
            
            %df = gradient(xD);
            df = ones(size(xDD));

            switch scat_optim_obj.optim_data_wval
                case 'lin'
                    data_wval  = db2pow_perso(yDD);
                case 'db'
                    data_wval  = yDD;
                otherwise
                    data_wval = ones(size(yDD));
            end
           
            yDD = scattering_model_cl.norm_scat(xDD,yDD,scat_optim_obj.f_ref);
            
            model_comp = @(x) sum(data_wval.*(yDD-yDD_model_func(x)).^2.*df,'omitnan')/sum(data_wval.*df,'omitnan');
        end
        
        function run_optimisation(scat_optim_obj)
            model_comp = scat_optim_obj.compute_optim_fcn();
            options = scat_optim_obj.optim_options;
            Aeq = scat_optim_obj.optim_scat_inputs.Aeq;
            if ~isnan(scat_optim_obj.optim_scat_inputs.N)
                init_var = [scat_optim_obj.optim_scat_inputs.distr_params_val scat_optim_obj.optim_scat_inputs.N];
                optim_var_min = [scat_optim_obj.optim_scat_inputs.distr_params_val_min 1e-6];
                optim_var_max =[scat_optim_obj.optim_scat_inputs.distr_params_val_max 1e6];
                Aeq = scat_optim_obj.optim_scat_inputs.Aeq;
                if ~isempty(scat_optim_obj.optim_scat_inputs.Aeq)
                    Aeq = [Aeq 0];
                end
            else
                init_var = scat_optim_obj.optim_scat_inputs.distr_params_val;
                optim_var_min = scat_optim_obj.optim_scat_inputs.distr_params_val_min;
                optim_var_max = scat_optim_obj.optim_scat_inputs.distr_params_val_max;
            end
            
            
            switch scat_optim_obj.optim_type
                case 'unconstrained'
                    [scat_optim_obj.optim_results.results,scat_optim_obj.optim_results.fval,scat_optim_obj.optim_results.exit] = fminsearch(model_comp,init_var,options);
                case 'constrained'
%                     options.Algorithm = 'interior-point';
%                     options.Algorithm = 'sqp';
                    options.Algorithm = 'active-set';
                    %options.Algorithm = 'trust-region-reflective';
                    [scat_optim_obj.optim_results.results,scat_optim_obj.optim_results.fval,scat_optim_obj.optim_results.exit] = fmincon(model_comp,init_var,...
                        scat_optim_obj.optim_scat_inputs.A,...
                        scat_optim_obj.optim_scat_inputs.B,...
                        Aeq,...
                        scat_optim_obj.optim_scat_inputs.Beq,...
                        optim_var_min,optim_var_max,[],options);
                case 'none'
                    scat_optim_obj.optim_results.results = init_var;
                    scat_optim_obj.optim_results.fval = 0;
                    scat_optim_obj.optim_results.exit = 1;
            end
            
        end
        
        function [xD,yD] = get_scat_curve_result(scat_optim_obj,xD)
            yD = nan(size(xD));
            if ~isempty(scat_optim_obj.optim_results.results)
                yD = pow2db_perso(scat_optim_obj.optim_model_fcn(scat_optim_obj.optim_results.results,xD,scat_optim_obj.optim_data_curve.Depth));
            end
            
        end
        
        function [xD,yD,bsd_stats] = get_bsd_result(scat_optim_obj,xD)
            yD = zeros(size(xD));
            in_struct = scat_optim_obj.optim_scat_inputs;
            nb_modes = numel(in_struct.distr);
            [distr_list,distr_names,~,~,default_distr_params,~,~] = scat_distrib_cl.list_distrib();
            id_distr = cellfun(@(x) find(strcmpi(x,distr_list),1),in_struct.distr,'un',1);
            nb_params = cellfun(@(x) numel(default_distr_params{strcmpi(x,distr_list)}),in_struct.distr,'un',1);
            nb_params_tot = sum(nb_params,'omitnan');
            if nb_params_tot+double(~isnan(in_struct.N)) == numel(in_struct.distri_params)||nb_modes==1
                equal_ratio =1;
            else
                equal_ratio = 0;
            end
            iparams = 1;
            r_tot = 0;
            vars = {'uid' 'Curve Name' 'Curve Type' 'Mode Name' 'Distribution' 'Parameters' 'Density' 'Ratio','Mean','Std',...
                'Depth' 'Theta' 'E_fact' 'T' 'S' 'Tau' 'Gas Comp(O2,N2,CH4,CO2,Ar)' 'fval','exit'};
            bsd_stats = table('Size',[nb_modes,numel(vars)],...
                'VariableTypes',{'cellstr' 'cellstr' 'cellstr' 'cellstr' 'cellstr' 'cell' 'double' 'double' 'double' 'double' 'double' 'double' 'double' 'double' 'double' 'double' 'cell' 'double' 'double'},...
                'VariableNames',vars);
            
            bsd_stats.Distribution = distr_names(id_distr)';
            bsd_stats.T(:) = in_struct.T;
            bsd_stats.S(:) = in_struct.S;
            bsd_stats.Theta(:) = in_struct.theta;
            bsd_stats.Tau(:) = in_struct.tau;
            bsd_stats.E_fact(:) = in_struct.e_fact;
            bsd_stats.("Gas Comp(O2,N2,CH4,CO2,Ar)")(:)=in_struct.conc;

            for ui = 1:nb_modes
                
                if equal_ratio==0
                    ratio = scat_optim_obj.optim_results.results(iparams+nb_params(ui));
                    dp =1;
                else
                    ratio = 1/nb_modes;
                    dp= 0;
                end
                
                p_temp = compute_pdf(in_struct.distr{ui},xD,scat_optim_obj.optim_results.results(iparams:iparams+nb_params(ui)-1));
                yD = yD + ratio * p_temp;
                r_tot = ratio+r_tot;
                bsd_stats.uid{ui} = scat_optim_obj.optim_data_curve.Unique_ID;
                bsd_stats.("Curve Name"){ui} = scat_optim_obj.optim_data_curve.Name;
                bsd_stats.("Curve Type"){ui} = scat_optim_obj.optim_data_curve.Type;
                bsd_stats.("Mode Name"){ui} = in_struct.mode_name{ui};
                
                bsd_stats.("Parameters"){ui} = scat_optim_obj.optim_results.results(iparams:iparams+nb_params(ui)-1);
                if ~isnan(in_struct.N)
                    bsd_stats.Density(ui) = scat_optim_obj.optim_results.results(end);                    
                else
                    bsd_stats.Density(ui) = nan;
                end
                bsd_stats.Ratio(ui) = ratio;
                bsd_stats.Mean(ui) = sum(p_temp.*xD,'omitnan')/sum(p_temp,'omitnan');
                bsd_stats.Std(ui) = sqrt(sum((xD-bsd_stats.Mean(ui)).^2.*p_temp,'omitnan')/sum(p_temp,'omitnan'));
                bsd_stats.Depth(ui) = scat_optim_obj.optim_data_curve.Depth;
                bsd_stats.exit(ui) = scat_optim_obj.optim_results.exit;
                bsd_stats.fval(ui) = scat_optim_obj.optim_results.fval;
                iparams = iparams+nb_params(ui)+dp;
            end
            yD = yD/r_tot;
            
            
        end
        
        
        
    end
    
    
end