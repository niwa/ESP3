function load_echoint_results_cback(~,~)

layer_obj = get_current_layer();
curr_disp = get_esp3_prop('curr_disp');
main_figure = get_esp3_prop('main_figure');
[path_f,~,~]=fileparts(layer_obj.Filename{1});
ext = {'*.csv' '*.xlsx'};

[Filename,path_f] = uigetfile( {fullfile(path_f,strjoin(ext,';'))}, sprintf('Pick a %s  file',strjoin(ext,'/')),'MultiSelect','off');

% nothing opened
if isempty(Filename) || isnumeric(Filename)
    return;
end

output = readtable(fullfile(path_f,Filename));

ff = output.Properties.VariableNames;

if ~ismember('Horz_Slice_Idx',ff)
    %[tt,~,output.Horz_Slice_Idx] = unique(floor(output.Depth_min./mode(diff(output.Depth_min))),'stable');
    output.Horz_Slice_Idx = floor(output.Depth_min./mode(diff(output.Depth_min)));
end

if ~ismember('Vert_Slice_Idx',ff)
    [~,~,output.Vert_Slice_Idx] = unique(datenum(output.Time_S),'sorted');
end

hh = output.Horz_Slice_Idx;
vv = output.Vert_Slice_Idx;

nb_col = numel(unique(vv(vv>0)));

nb_row = numel(unique(hh(hh>0)));


if numel(output.ABC) == nb_row*nb_col
    for uif = 1:numel(ff)
        tmp = reshape(output.(ff{uif}),nb_row,nb_col);
        if contains(ff{uif},'sv','Ignorecase',true)
            output_echo_int.(strrep(ff{uif},'_mean','')) = tmp;
        else
            output_echo_int.(ff{uif}) = tmp;
        end
    end
else
    id_rem = hh == 0 | vv == 0;
    hh(id_rem) = [];
    hh = hh - min(hh) + 1;
    vv(id_rem) = [];
    vv = vv-min(vv) +1;

    for uif = 1:numel(ff)

        if isnumeric(output.(ff{uif})) || isdatetime(output.(ff{uif}))

            switch ff{uif}
                case {'Time_E', 'Time_S', 'date'}
                    tmp = accumarray([hh vv],datenum(output.(ff{uif})),[],@mean,nan);
                    output_echo_int.(ff{uif}) = mean(tmp,1,'omitnan');
                otherwise
                    tmp = accumarray([hh vv],output.(ff{uif}),[],@mode,nan);
                    if contains(ff{uif},'sv','Ignorecase',true)
                        output_echo_int.(strrep(ff{uif},'_mean','')) = tmp;
                    else
                        output_echo_int.(ff{uif}) = tmp;
                    end
            end
        else
            [tags,~,tmp_tag] = unique(output.(ff{uif}));
            tmp = accumarray([hh vv],tmp_tag,[],@mode);
            output_echo_int.(ff{uif}) = strings(size(tmp));
            output_echo_int.(ff{uif})(tmp>0) = tags(tmp(tmp>0))';
        end
    end

end

if ~ismember('Range_ref_min',ff)
    output_echo_int.Range_ref_max = output_echo_int.Depth_max;
    output_echo_int.Range_ref_min = output_echo_int.Depth_min;
    ref = 'Surface';
else
    ref = list_echo_int_ref;
    ref = ref{cellfun(@(x) contains(Filename,x),list_echo_int_ref)};
    if isempty(ref)
        ref = 'Surface';
    end
end

freqs  =curr_disp.SecFreqs;
f_cell = cellfun(@num2str,num2cell(freqs),'UniformOutput',false);
id_f = cellfun(@(x) contains(Filename,x),f_cell);

if any(id_f)
    freq_str = f_cell{id_f};
    freq = str2double(freq_str);
else
    freq =  curr_disp.Freq;
end

id_f = find(freq == freqs,1);
id_echoint = find(id_f == layer_obj.EchoIntStruct.idx_freq_out,1);

if isempty(id_echoint)
    layer_obj.EchoIntStruct.idx_freq_out = [layer_obj.EchoIntStruct.idx_freq_out id_f];
    layer_obj.EchoIntStruct.output_2D_type = [layer_obj.EchoIntStruct.output_2D_type {{ref}}];
    layer_obj.EchoIntStruct.output_2D = [layer_obj.EchoIntStruct.output_2D {{output_echo_int}}];
    id_echoint = numel(layer_obj.EchoIntStruct.idx_freq_out);
    id_ref = 1;
else

    id_ref = find(strcmpi(ref,layer_obj.EchoIntStruct.output_2D_type{id_echoint}));
    if isempty(id_ref)
        layer_obj.EchoIntStruct.output_2D_type{id_echoint} = [layer_obj.EchoIntStruct.output_2D_type{id_echoint} {ref}];
        layer_obj.EchoIntStruct.output_2D{id_echoint} = [layer_obj.EchoIntStruct.output_2D{id_echoint} {output_echo_int}];
        id_ref = numel(layer_obj.EchoIntStruct.output_2D{id_echoint});
    else
        layer_obj.EchoIntStruct.output_2D{id_echoint}{id_ref} = output_echo_int;
    end

end
            
layer_obj.EchoIntStruct.output_2D{id_echoint}{id_ref}.Tag_str = unique(layer_obj.EchoIntStruct.output_2D{id_echoint}{id_ref}.Tags);
layer_obj.EchoIntStruct.output_2D{id_echoint}{id_ref}.Tag_cmap = randi(64,[numel(layer_obj.EchoIntStruct.output_2D{id_echoint}{id_ref}.Tag_str),3])/64;

update_echo_int_tab(main_figure,0);


end