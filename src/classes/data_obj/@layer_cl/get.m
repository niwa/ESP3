function varargout=get(obj,varargin)

varargout = cell(1,length(varargin));
idx_rem = [];
for ivar=1:length(varargin)
    
    if  isprop(obj,varargin{ivar})
        varargout{ivar}=obj(varargin{ivar});
    else
        w = sprintf('layer_cl : Property %s does not exist', varargin{ivar});
        idx_rem = union(idx_rem,ivar);
        dlg_perso([],w,[]);
    end
    
end
varargout(idx_rem) = [];

end