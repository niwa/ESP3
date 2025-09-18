function [line_xml,ver]=parse_line_xml(xml_file)

xml_struct=parseXML(xml_file);


if ~strcmpi(xml_struct.Name,'line_file')
    warning('XML file not describing lines');
    line_xml=[];
    return;
end
ver=num2str(xml_struct.Attributes(1).Value,'%.1f');
lines_node=get_childs(xml_struct,'line');

nb_lines=length(lines_node);
if isempty(lines_node)
    warning('No line definitions in the file');
    line_xml=[];
    return;
end

line_xml=cell(1,nb_lines);

for il=1:nb_lines
    line_xml{il}.att=get_node_att(xml_struct.Children(il));
    switch ver
        case '0.1'
            line_xml{il}.line=get_line_node(xml_struct.Children(il));

        case {'0.2' '0.3'}
            line_xml{il}.line=get_line_node_2(xml_struct.Children(il));
    end
end

end


function line=get_line_node(line_node)

    line=struct('range',[],'time',[]);
   
    time_node=get_childs(line_node,'time');
    
    range_node=get_childs(line_node,'range');
    
    range=textscan(range_node.Data,'%f');
    line.range=range{1};
    
    time=textscan(time_node.Data,'%s');
    line.time=datenum(time{1},'yyyymmddHHMMSSFFF');
    

end

function line=get_line_node_2(line_node)

    line=struct('range',[],'time',[],'data',[]);
   
    time_node=get_childs(line_node,'time');
    
    range_node=get_childs(line_node,'range');
    data_node=get_childs(line_node,'data');


    range=textscan(range_node.Data,'%f');
    line.range=range{1};
    data=textscan(data_node.Data,'%f');
    line.data=data{1};
    
    time=textscan(time_node.Data,'%s');
    line.time=datenum(time{1},'yyyymmddHHMMSSFFF');
    

end
