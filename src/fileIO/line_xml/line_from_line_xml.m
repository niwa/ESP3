function lines = line_from_line_xml(xml_file)
lines = [];
if exist(xml_file,'file')==0
    return;
end

[line_xml_tot,ver]=parse_line_xml(xml_file);

if isempty(line_xml_tot)
    fprintf('Cannot parse line for %s\n',xml_file);
    return;
end

for iline=1:length(line_xml_tot)


    line_xml=line_xml_tot{iline};
    switch ver
        case '0.1'
            line=line_cl();
            line.Tag=line_xml.att.tag;
            line.Time=line_xml.line.time;
            line.Type=line_xml.att.type;
            line.UTC_diff=line_xml.att.utc_diff;
            line.Dist_diff=line_xml.att.dist_diff;
            line.File_origin={line_xml.att.file_origin};
            line.Dr=line_xml.att.dr;
            line.Range=line_xml.line.range;
            if isnumeric(line_xml.att.id)
                id=num2str(line_xml.att.id);
            else
                id=line_xml.att.id;
            end
            line.ID=id;
        case '0.2'
            line=line_cl();
            line.Tag=line_xml.att.tag;
            line.Time=line_xml.line.time;
            line.Type=line_xml.att.type;
            line.UTC_diff=line_xml.att.utc_diff;
            line.Dist_diff=line_xml.att.dist_diff;
            line.File_origin={line_xml.att.file_origin};
            line.Dr=line_xml.att.dr;
            line.Range=line_xml.line.range;
            line.Data=line_xml.line.data;
            if isnumeric(line_xml.att.id)
                id=num2str(line_xml.att.id);
            else
                id=line_xml.att.id;
            end
            line.ID=id;

        case '0.3'
            line=line_cl();
            line.Tag=line_xml.att.tag;
            line.Time=line_xml.line.time;
            line.Type=line_xml.att.type;
            line.UTC_diff=line_xml.att.utc_diff;
            line.Dist_diff=line_xml.att.dist_diff;
            line.File_origin={line_xml.att.file_origin};
            line.Dr=line_xml.att.dr;
            line.Range=line_xml.line.range;
            line.Data=line_xml.line.data;
            line.Units=line_xml.att.units;
            if isnumeric(line_xml.att.id)
                id=num2str(line_xml.att.id);
            else
                id=line_xml.att.id;
            end
            line.ID=id;
            
           
    end
     lines = [lines line];
end