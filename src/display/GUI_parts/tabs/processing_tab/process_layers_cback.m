function process_layers_cback(~,~,main_figure,mode,Filenames)

update_process_list([],[],main_figure);

layer_curr          = get_current_layer();
esp3_obj            = getappdata(groot,'esp3_obj');
layers              = get_esp3_prop('layers');
process_list        = get_esp3_prop('process');
app_path            = get_esp3_prop('app_path');
load_bar_comp       = getappdata(main_figure,'Loading_bar');
processing_tab_comp = getappdata(main_figure,'Processing_tab');

show_status_bar(main_figure);

switch mode
    case 0
        % "Apply to current layer"
        layer_to_proc = layer_curr;

    case 1
        % "Apply to all loaded layers"
        layer_to_proc = layers;

    case 2
        % "Select *.raw files"

        % Get a default path for the file selection dialog box
        if ~isempty(layer_curr)
            [path_lay,~] = layer_curr.get_path_files();
            if ~isempty(path_lay)
                % if file(s) already loaded, same path as first one in list
                file_path = path_lay{1};
            else
                % config default path if none
                file_path = app_path.data.Path_to_folder;
            end
        else
            % config default path if none
            file_path = app_path.data.Path_to_folder;
        end
        Filename=get_compatible_ac_files(file_path);

        if isempty(Filename)
            return;
        end

        % single file is char. Turn to cell
        if ~iscell(Filename)
            if (Filename==0)
                return;
            end
            Filename = {Filename};
        end


        % fullfile to all layers
        layer_to_proc = Filename;

    case 3
        layer_to_proc = Filenames;

end

show_status_bar(main_figure);
[old_files,~]=layers.list_files_layers();
new_layers = [];
% process per layer
for ii = 1:length(layer_to_proc)
    idx_already_open = 1;
    % get layer
    switch mode
        case {0,1}
            layer = layer_to_proc(ii);
        case {2,3}
            % file may still need to be opened
              
            idx_already_open=find(strcmpi(layer_to_proc{ii},old_files));
            if isempty(idx_already_open)
                [layer,multi_lay_mode] = open_file_standalone(layer_to_proc{ii},'','PathToMemmap',app_path.data_temp.Path_to_folder,'load_bar_comp',load_bar_comp);
            else
                layer = layers(idx_already_open(1));
            end
    end
    layers_Str_comp=list_layers(layer);
    load_bar_comp.progress_bar.setText(sprintf('Processing %s',layers_Str_comp{1}));

    % process per frequency with algos to apply
    for kk = 1:length(process_list)

        if isempty(process_list(kk).Algo)
            continue;
        end

        % get transceiver object
        [trans_obj,idx_chan] = layer.get_trans(process_list(kk).CID);

        if isempty(trans_obj)
            fprintf('Could not find channel %s on this layer\n',process_list(kk).CID);
            continue;
        end

        algo_names = list_algos();

        for ui = 1:numel(algo_names)
            [~,idx_algo,found] = find_process_algo(process_list,process_list(kk).CID,process_list(kk).Freq,algo_names{ui});
            if found
                layer.add_algo(process_list(kk).Algo(idx_algo),'idx_chan',idx_chan);
                layer.apply_algo(algo_names{ui},'idx_chan',idx_chan,'load_bar_comp',load_bar_comp);
            end
        end
    end

    if processing_tab_comp.save_results.Value>0 || isempty(idx_already_open) && processing_tab_comp.load_new_lays.Value == 0
        load_bar_comp.progress_bar.setText('Saving Resulting Bottom and regions');
        layer.write_reg_to_reg_xml();
        layer.write_bot_to_bot_xml();
        %write_line_to_line_xml(layer);
    end

    if isempty(idx_already_open)
        if  processing_tab_comp.load_new_lays.Value>0
            new_layers = [new_layers layer];
        else
            layer.rm_memaps([]);
            delete(layer);
        end
    end
end

if ~isempty(new_layers)
    esp3_obj.add_layers_to_esp3(new_layers,multi_lay_mode);
end

hide_status_bar(main_figure);
set_esp3_prop('layers',layers);

update_display(main_figure,1,1);

end