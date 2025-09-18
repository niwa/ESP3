function hfigs_t=find_echo_figures(main_figure,varargin)
p = inputParser;
addRequired(p,'main_figure',@(x) isempty(x)||ishandle(x));
addParameter(p,'Tag','',@(x) ischar(x));
parse(p,main_figure,varargin{:});
hfigs_t = [];

if ~isempty(main_figure)
    hfigs=getappdata(main_figure,'ExternalFigures');
    Tag=p.Results.Tag;
    
    if ~isempty(hfigs)
        hfigs(~isvalid(hfigs))=[];
        idx_tag=strcmpi({hfigs(:).Tag},Tag);
        hfigs_t = hfigs(idx_tag);
    end
    
end

end