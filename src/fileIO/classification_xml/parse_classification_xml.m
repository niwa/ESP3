function [Frequencies,Variables,Nodes,Classes,Title,Type,VarName]=parse_classification_xml(xml_file)

xml_struct=parseXML(xml_file);
Title='';
Type='';
Frequencies=[];
Variables={};
Nodes={};
Classes = {};
VarName = '';
if ~strcmpi(xml_struct.Name,'classification_descr')
    warning('XML file not describing a Classification');
    return;
end

Title=get_att(xml_struct,'title');
if isempty(Title)
    Title='';
end

Type=get_att(xml_struct,'type');
if isempty(Type)
    Type='By regions';
end

VarName=get_att(xml_struct,'varname');


nb_child=length(xml_struct.Children);

for ic=1:nb_child
    switch xml_struct.Children(ic).Name
        case 'variables'
           Variables=get_variables(xml_struct.Children(ic));
        case 'classes'
            Classes=get_classes(xml_struct.Children(ic));
        case 'nodes'
           Nodes=get_nodes(xml_struct.Children(ic));
        case 'frequencies'
          Frequencies=str2double(strsplit(xml_struct.Children(ic).Data,';'));
        otherwise
            warning('Unidentified Child in XML');
    end
end

Classes = merge_classes_and_nodes(Nodes,Classes);
if ~isempty(Classes)
    ff = fieldnames(Classes);
    [~,id] = unique(Classes.Class);
    for ifi = 1:numel(ff)
        Classes.(ff{ifi}) = Classes.(ff{ifi})(id);
    end
end


if isempty(VarName)
    switch lower(Type)
        case 'by regions'
            VarName = 'school';
        case 'cell by cell'
            VarName = 'cell';
    end
end

end

function Classes_out = merge_classes_and_nodes(Nodes,Classes)
Classes_out = [];
idx_classes = find(cellfun(@(x) isfield(x,'Class_struct'),Nodes));
class_names = cellfun(@(x) x.Class_struct.Class,Nodes(idx_classes))';
class_colors = cellfun(@(x) x.Class_struct.Class_color,Nodes(idx_classes),'un',0)';
class_descr = cellfun(@(x) x.Class_struct.Class_descr,Nodes(idx_classes))';
class_cluster_thr = cellfun(@(x) x.Class_struct.Class_cluster_thr,Nodes(idx_classes),'UniformOutput',true)';

if isempty(class_names)
    return;
end

[class_names,idd]  = unique(class_names);

Classes_nodes.Class = class_names;
Classes_nodes.Class_color = class_colors(idd);
Classes_nodes.Class_descr = class_descr(idd);
Classes_nodes.Class_cluster_thr = class_cluster_thr(idd);

if isempty(Classes)
    Classes_out = Classes_nodes;
    return;
end

[~,id] = setdiff(Classes_nodes.Class,Classes.Class);
if isempty(id)
    Classes_out = Classes;
    return;
end

ff = fieldnames(Classes);

for ifi = 1:numel(ff)
    Classes_out.(ff{ifi}) = [Classes.(ff{ifi}); Classes_nodes.(ff{ifi})(id)];
end


end

function var_struct=get_variables(var_node)
nb_var=length(var_node.Children);
var_struct.name=strings(nb_var,1);
var_struct.use_for_clustering=true(nb_var,1);

for ivar=1:nb_var
    var_struct.name(ivar)=get_att(var_node.Children(ivar),'name');
    tmp=get_att(var_node.Children(ivar),'use_for_clustering');
    if ~isempty(tmp)&&~isnan(tmp)
        var_struct.use_for_clustering(ivar) = tmp>0;
    end
end
end

function class_struct=get_classes(classes_node)
idx_class = find(strcmpi({classes_node.Children(:).Name},'class'));
nb_class  = numel(idx_class);
class_struct.Class=strings(nb_class,1);
class_struct.Class_color=cell(nb_class,1);
class_struct.Class_descr=strings(nb_class,1);
class_struct.Class_cluster_thr=nan(nb_class,1);
ii= 0 ;
for iclass=idx_class
    ii = ii+1;
    tmp_struct = get_class_node(classes_node.Children(iclass));
    if isempty(tmp_struct)
        continue;
    end
    class_struct.Class(ii)=tmp_struct.Class;
    class_struct.Class_color{ii}=tmp_struct.Class_color;
    class_struct.Class_descr(ii)=tmp_struct.Class_descr;
    class_struct.Class_cluster_thr(ii)=tmp_struct.Class_cluster_thr;
end
end

function class_struct = get_class_node(class_node)
class_struct.Class = strtrim(string(class_node.Data));

if isempty(class_node.Data)
    class_struct.Class_color = [1 1 1];
else
    cols = lines(256);
    col = cols(randi(256),:);
    class_struct.Class_color = col;
end
class_struct.Class_cluster_thr = nan;
class_struct.Class_descr = "";

tmp_ori = get_att(class_node,'rgb');
if ~isempty(tmp_ori)
    tmp = str2double(strsplit(tmp_ori,';'))/255;
    if numel(tmp) ~=3 || any(isnan(tmp))
        tmp = tmp_ori;
    end
    class_struct.Class_color = tmp;
end

tmp = get_att(class_node,'thr_cluster');
if ~isempty(tmp)
    class_struct.Class_cluster_thr = tmp;
end

tmp = get_att(class_node,'descr');
if ~isempty(tmp)
    class_struct.Class_descr = tmp;
end


end

function node_cell=get_nodes(nodes_node)
nb_node=length(nodes_node.Children);
node_cell=cell(1,nb_node);
for inode=1:nb_node
    switch nodes_node.Children(inode).Name
        case '#comment'
        case 'node'
            node_cell{inode}=get_node_att(nodes_node.Children(inode));
            cond_child=get_childs(nodes_node.Children(inode),'condition');
            if ~isempty(cond_child)
                node_cell{inode}.Condition=cond_child.Data;
            end
            
            class_child=get_childs(nodes_node.Children(inode),'class');
            if ~isempty(class_child)
                node_cell{inode}.Class_struct = get_class_node(class_child);
            end
    end
end
node_cell(cellfun(@isempty,node_cell))=[];

end


