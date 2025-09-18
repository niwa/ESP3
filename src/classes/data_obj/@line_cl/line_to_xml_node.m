function docNode=line_to_xml_node(lines,docNode,varargin)

p = inputParser;
addRequired(p,'lines',@(obj) isa(obj,'line_cl'));
addRequired(p,'docNode',@(docnode) isa(docNode,'org.apache.xerces.dom.DocumentImpl'));
addParameter(p,'et',inf,@isnumeric);
addParameter(p,'st',0,@isnumeric);
addParameter(p,'file_ori','',@ischar);

parse(p,lines,docNode,varargin{:});


for il=1:length(lines)
    idx_t=lines(il).Time>=p.Results.st&lines(il).Time<=p.Results.et;
    
    if all(~idx_t)
        return;
    end
    
    line_xml.Tag=lines(il).Tag;
    line_xml.Time=lines(il).Time(idx_t);
    line_xml.Type=lines(il).Type;
    line_xml.UTC_diff=lines(il).UTC_diff;
    line_xml.Dist_diff=lines(il).Dist_diff;
    line_xml.File_origin={p.Results.file_ori};
    line_xml.Dr=lines(il).Dr;
    line_xml.Range=lines(il).Range(idx_t);
    line_xml.ID=lines(il).ID;
    line_xml.Data = lines(il).Data;
    line_xml.Units = lines(il).Units;
    docNode=create_line_xml_node(docNode,line_xml);
end

end

