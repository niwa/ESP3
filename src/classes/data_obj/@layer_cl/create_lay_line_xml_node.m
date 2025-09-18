function docNode=create_lay_line_xml_node(layer_obj,docNode,st,et,file_ori)

p = inputParser;
addRequired(p,'layer_obj',@(obj) isa(obj,'layer_cl'));
addRequired(p,'docNode',@(docnode) isa(docNode,'org.apache.xerces.dom.DocumentImpl'));

parse(p,layer_obj,docNode);

docNode=layer_obj.Lines.line_to_xml_node(docNode,'st',st,'et',et,'file_ori',file_ori);

end

