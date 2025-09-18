classdef feature_3D_cl < handle
    properties
        Name = '3D Feature';
        ID = 1;
        Tag = '';
        Unique_ID = generate_Unique_ID(1);
        E = [];
        N = [];
        H = [];
        Time = [];
        dE = [];
        dN = [];
        dH = [];
        E_grid = [];
        N_grid = [];
        H_grid = [];
        Zone = [];
        Alongdist = [];
        Acrossdist = [];
        Idx_r = [];
        Idx_beam = [];
        Idx_ping = [];
        Sv = [];
        Sv_grid = [];
        ConvHull = [];
        Volume = [];

    end


    methods
        function obj = feature_3D_cl(varargin)
            p = inputParser;


            addParameter(p,'Name','',@ischar);
            addParameter(p,'ID',0,@isnumeric);
            addParameter(p,'Unique_ID',generate_Unique_ID([]),@ischar);
            addParameter(p,'Tag','',@ischar);
            addParameter(p,'Idx_r',[],@isnumeric);
            addParameter(p,'Idx_ping',[],@isnumeric);
            addParameter(p,'Idx_beam',[],@isnumeric);
            addParameter(p,'Alongdist',[],@isnumeric);
            addParameter(p,'Acrossdist',[],@isnumeric);
            addParameter(p,'Range',[],@isnumeric);
            addParameter(p,'Time',[],@isnumeric);
            addParameter(p,'E',[],@isnumeric);
            addParameter(p,'N',[],@isnumeric);
            addParameter(p,'H',[],@isnumeric);
            addParameter(p,'Zone',[],@isnumeric);
            addParameter(p,'dE',[],@isnumeric);
            addParameter(p,'dN',[],@isnumeric);
            addParameter(p,'dH',[],@isnumeric);
            addParameter(p,'Sv',[],@isnumeric);
            addParameter(p,'dr',1/2,@isnumeric);


            parse(p,varargin{:});

            results=p.Results;
            props=properties(obj);

            for iprop=1:length(props)
                if isfield(results,props{iprop})
                    obj.(props{iprop})=results.(props{iprop});
                end
            end

            [obj,res] = obj.compute_Convhull();

            if ~res
                obj = feature_3D_cl.empty();
            end

        end

        function obj = grid_feature(obj,n,sc)

            %creating full grid
            E_ori = min(obj.E,[],'all','omitnan');
            N_ori = min(obj.N,[],'all','omitnan');
            H_ori = min(obj.H,[],'all','omitnan');

            Nn = numel(obj.E);
            K = (Nn/n)^(1/3)*sc;

            obj.dE = range(obj.E)/K;
            obj.dN = range(obj.N)/K;
            obj.dH = range(obj.H)/K;

            N_E = ceil(range(obj.E)/obj.dE);
            E_vec = (0:N_E-1)*obj.dE+E_ori;
            N_N = ceil(range(obj.N)/obj.dN);
            N_vec = (0:N_N-1)*obj.dN+N_ori;
            N_H = ceil(range(obj.H)/obj.dH);
            H_vec = (0:N_H-1)*obj.dH+H_ori;
   
            [obj.E_grid,obj.N_grid,obj.H_grid] = meshgrid(E_vec,N_vec,H_vec);

            e_idx = floor((obj.E-E_ori)/obj.dE)+1;
            n_idx = floor((obj.N-N_ori)/obj.dN)+1;
            h_idx = floor((obj.H-H_ori)/obj.dH)+1;

            sv_lin_grid = accumarray([e_idx(:) n_idx(:) h_idx(:)],db2pow(obj.Sv(:)),[],@mean,nan);

            obj.Sv_grid = pow2db(sv_lin_grid);
        end

        
        function [obj,res] = compute_Convhull(obj)
            res = true;
            try
                [obj.ConvHull,obj.Volume] = convhull([obj.E(:),obj.N(:),obj.H(:)],'Simplify',true);
            catch
                fprintf('Colinear feature %d\n',obj.ID);
                res = false;
                return;
            end
        end


        function out = get_lim(obj,varargin)
            p  =  inputParser;
            addRequired(p,'obj',@(obj) isa(obj,'feature_3D_cl'));
            addParameter(p,'Idx_ping',[],@isnumeric);
            addParameter(p,'Idx_beam',[],@isnumeric);
            addParameter(p,'Idx_r',[],@isnumeric);
            parse(p,obj,varargin{:});

            out = [];
            ff = {'E' 'N' 'H' 'Idx_ping' 'Idx_beam' 'Idx_r' 'Alongdist' 'Acrossdist'};
            idx_rem = false(size([obj(:).Idx_r]));
            fff = {'Idx_r' 'Idx_ping' 'Idx_beam'};
            for uif = 1:numel(fff)
                if ~isempty(p.Results.(fff{uif}))
                    idx_rem = idx_rem |~ismember([obj(:).(fff{uif})],p.Results.(fff{uif}));
                end
            end
       
            for uit = 1:numel(ff)
                tmp = [obj(:).(ff{uit})];
                out.(ff{uit}) = [min(tmp(~idx_rem),[],'omitmissing') max(tmp(~idx_rem),[],'omitmissing')];
            end
        end
    end
end