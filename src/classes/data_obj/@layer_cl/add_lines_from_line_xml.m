function add_lines_from_line_xml(layers_obj,varargin)

p = inputParser;

addRequired(p,'layers_obj',@(obj) isa(obj,'layer_cl'));
addParameter(p,'xml_file','',@ischar);


parse(p,layers_obj,varargin{:});


for ilay=1:numel(layers_obj)
    try
        layer_obj=layers_obj(ilay);
        if isempty(p.Results.xml_file)
            [path_xml,line_file_str]=layer_obj.create_files_line_str();
            xml_file=fullfile(path_xml,line_file_str);
        else
            xml_file={p.Results.xml_file};
        end

        for ix=1:length(xml_file)

            line= line_from_line_xml(xml_file{ix});
            if isempty(line)
                continue;
            end
            layer_obj.add_lines(line);
            if strcmpi(line.Tag,'offset')
                disp('Using Line as transducer offset');
                for i=1:length(layer_obj.Transceivers)
                    layer_obj.Transceivers(i).set_transducer_depth_from_line(line);
                end
            end
        end


    catch err
        disp_perso([],err.message);
        laystr=list_layers(layer_obj,'nb_char',80);
        disp_perso([],sprintf('Could not load lines for layer %s',laystr{1}));
    end
end
end



