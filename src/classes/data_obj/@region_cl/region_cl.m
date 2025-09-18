
classdef region_cl

    properties (Access = public, Constant = true)
        % IMPORTANT: This value is the format of this class. Update this
        % value if you modify or add the properties of this class
        Fmt_version = '0.3';
    end

    properties
        Name
        ID
        Tag
        Origin
        Version=-1;
        Unique_ID
        Remove_ST
        Line_ID=[]
        Type
        Idx_ping
        Idx_r
        Shape
        MaskReg
        Poly
        Reference
        Cell_w
        Cell_w_unit
        Cell_h
        Cell_h_unit
        
    end
    
    
    methods
        function obj = region_cl(varargin)
            p = inputParser;
            
            check_type=@(type) ~isempty(strcmpi(type,{'Data','Bad Data'}));
            check_shape=@(shape) ~isempty(strcmpi(shape,{'Rectangular','Polygon'}));
            check_reference=@(ref) ~isempty(strcmpi(ref,list_echo_int_ref));
            check_w_unit=@(unit) ~isempty(strcmpi(unit,{'pings','meters'}));
            check_h_unit=@(unit) ~isempty(strcmpi(unit,{'meters'}));
            
            
            addParameter(p,'Name','',@ischar);
            addParameter(p,'ID',0,@isnumeric);
            addParameter(p,'Version',-1,@isnumeric);
            addParameter(p,'Unique_ID',generate_Unique_ID([]),@ischar);
            addParameter(p,'Tag','',@ischar);
            addParameter(p,'Origin','',@ischar);
            addParameter(p,'Type','Data',check_type);
            addParameter(p,'X_cont',[],@(x) isnumeric(x)||iscell(x));
            addParameter(p,'Y_cont',[],@(x) isnumeric(x)||iscell(x));
            addParameter(p,'Idx_r',[],@isnumeric);
            addParameter(p,'Idx_ping',[],@isnumeric);
            addParameter(p,'Poly',[],@(x) isempty(x)||isa(x,'polyshape'));
            addParameter(p,'MaskReg',[],@(x) isnumeric(x)||islogical(x));
            addParameter(p,'Shape','Rectangular',check_shape);
            addParameter(p,'Remove_ST',0,@(x) isnumeric(x)||islogical(x));
            addParameter(p,'Reference','Surface',check_reference);
            addParameter(p,'Cell_w',10,@isnumeric);
            addParameter(p,'Cell_h',10,@isnumeric);
            addParameter(p,'Cell_w_unit','pings',check_w_unit);
            addParameter(p,'Cell_h_unit','meters',check_h_unit);
            
            parse(p,varargin{:});
            
            results=p.Results;
            props=properties(obj);
            
            for i=1:length(props)
                if isfield(results,props{i})
                    obj.(props{i})=results.(props{i});
                end
            end
            
            switch lower(obj.Shape)
                case 'rectangular'
                    if ~isempty(obj.Idx_ping)
                        x_reg_rect=([obj.Idx_ping(1) obj.Idx_ping(end) obj.Idx_ping(end) obj.Idx_ping(1) obj.Idx_ping(1)]);
                        y_reg_rect=([obj.Idx_r(end) obj.Idx_r(end) obj.Idx_r(1) obj.Idx_r(1) obj.Idx_r(end)]);
                        x_reg_rect(x_reg_rect==0)=1;
                        y_reg_rect(y_reg_rect==0)=1;
                        
                        obj.Poly=polyshape(x_reg_rect,y_reg_rect,'Simplify',false);
                        
                        if ~obj.Poly.issimplified()
                            obj.Poly.simplify();
                        end
                    elseif ~isempty(results.Poly)
                        [xlim,ylim]=obj.Poly.boundingbox;
                        obj.Idx_ping=xlim(1):xlim(end);
                        obj.Idx_r=ylim(1):ylim(end);
                    end
                otherwise 
                    if ~isempty(results.Poly)&&~isempty(obj.Poly.boundingbox)
                        obj.Poly=results.Poly;
                        obj.MaskReg=mask_from_poly(obj.Poly);
                        [xlim,ylim]=obj.Poly.boundingbox;
                        obj.Idx_ping=xlim(1):xlim(end);
                        obj.Idx_r=ylim(1):ylim(end);
                    elseif ~isempty(results.X_cont)
                        obj.Poly=polyshape(results.X_cont,results.Y_cont,'Simplify',false);                         
                        obj.MaskReg=mask_from_poly(obj.Poly);
                        
                        [xlim,ylim]=obj.Poly.boundingbox;
                        obj.Idx_ping=xlim(1):xlim(2);
                        obj.Idx_r=ylim(1):ylim(2);                         
                    elseif ~isempty(results.MaskReg)
                        [x,y]=cont_from_mask(results.MaskReg);
                        [x,y]=reduce_reg_contour(x,y,10);
                        obj.Poly=polyshape(cellfun(@(u) u+results.Idx_ping(1), x,'un',0),cellfun(@(u) u+results.Idx_r(1), y,'un',0),'Simplify',true);
                        obj.Idx_ping=results.Idx_ping;
                        obj.Idx_r=results.Idx_r;
                    elseif ~isempty(results.Idx_ping)
                        x_reg_rect=([obj.Idx_ping(1) obj.Idx_ping(end) obj.Idx_ping(end) obj.Idx_ping(1) obj.Idx_ping(1)]);
                        y_reg_rect=([obj.Idx_r(end) obj.Idx_r(end) obj.Idx_r(1) obj.Idx_r(1) obj.Idx_r(end)]);
                        x_reg_rect(x_reg_rect==0)=1;
                        y_reg_rect(y_reg_rect==0)=1;
                        
                        obj.Poly=polyshape(x_reg_rect,y_reg_rect,'Simplify',false);

                        if ~obj.Poly.issimplified()
                            obj.Poly.simplify();
                        end
                        obj.Shape = 'Rectangular';
                    end
                    
            end
            obj.Idx_r(obj.Idx_r==0)=1;
            obj.Idx_ping(obj.Idx_ping==0)=1;
            obj.Idx_ping=obj.Idx_ping(:)';
            obj.Idx_r=obj.Idx_r(:);
        end
        
        function str=print(obj)
            str=sprintf('Region %s %d %s Type: %s Reference: %s ',obj.Name,obj.ID,obj.Tag,obj.Type,obj.Reference);
        end
        
        function str=tag_str(obj)
            str=sprintf('Region %s',obj.Unique_ID);
        end
        
        function str=disp_str(obj)
            str=sprintf('%s(%.0f)',obj.Tag,obj.ID);
        end
        
        
        function mask=get_sub_mask(obj,idx_r,idx_p)
            
            
            nb_pings=length(idx_p);
            nb_samples=length(idx_r);
            mask=ones(nb_samples,nb_pings);
            
            switch obj.Shape
                case 'Polygon'
                    mask=obj.MaskReg(idx_r,idx_p);
            end
            
        end
      
              
        function mask=get_mask(obj)
               
            nb_pings=length(obj.Idx_ping);
            nb_samples=length(obj.Idx_r);
            mask=ones(nb_samples,nb_pings);
            
            switch obj.Shape
                case 'Polygon'
                    mask=obj.MaskReg;
            end
            
        end
        function delete(obj)
            if  isdebugging
                c = class(obj);
                disp(['ML object destructor called for class ',c])
            end
        end
        
        
        h_fig = display_region(reg_obj,trans_obj,varargin)
    end
end

