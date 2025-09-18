function display_in_3D_callback(~,~,IDs,tt)

% get current layers
layers = get_esp3_prop('layers');
esp3_obj = getappdata(groot,'esp3_obj');

if isempty(layers)
    return;
end

% find layers to export
if ~iscell(IDs)
    IDs = {IDs};
end

if isempty(IDs{1})
    % empty IDs means do all layers
    layers_to_disp = layers;
else
    % else, find the layers with input IDs
    idx = [];
    for id = 1:length(IDs)
        [idx_temp,found] = find_layer_idx(layers,IDs{id});

        if found == 0
            continue;
        end
        idx = union(idx,idx_temp);
    end
    layers_to_disp = layers(idx);
end

curr_disp = get_esp3_prop('curr_disp');

echo_3D_obj = init_echo_3D();
load_bar_comp = show_status_bar(esp3_obj.main_figure);
curr_lay = get_current_layer;
[trans_obj,idx_chan]=curr_lay.get_trans(curr_disp);

curr_reg = trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);

if isempty(curr_reg)
    timeBounds = [0 inf];
else
    reg = curr_reg.merge_regions('overlap_only',0);
    timeBounds = [min(trans_obj.Time(reg.Idx_ping))  max(trans_obj.Time(reg.Idx_ping))];
end


switch tt
    case'curtain'
        for ilay = 1:numel(layers_to_disp)
            [trans_obj,idxt]=layers_to_disp(ilay).get_trans(curr_disp);

            if isempty(idxt)
                trans_obj = layers_to_disp(ilay).Transceivers(1);
            end

            if ~isempty(layers_to_disp(ilay).SurveyData)
                for is=1:length(layers_to_disp(ilay).SurveyData)
                    survd=layers_to_disp(ilay).get_survey_data('Idx',is);
                    echo_3D_obj.add_surface(trans_obj,'surv_data',survd,'cax',curr_disp.getCaxField('sv'),'BeamAngularLimit',curr_disp.BeamAngularLimit);
                end
            else
                echo_3D_obj.add_surface(trans_obj,'cax',curr_disp.getCaxField('sv'),'BeamAngularLimit',curr_disp.BeamAngularLimit);
                
            end
        end
    case 'bathy'
        echo_3D_obj.add_bathy(layers_to_disp,'tag','bathy','load_bar_comp',load_bar_comp,'timeBounds',timeBounds,'full_bathy_extract',false);
    case 'highres-bathy'
        echo_3D_obj.add_bathy(layers_to_disp,'tag','bathy','load_bar_comp',load_bar_comp,'timeBounds',timeBounds,'full_bathy_extract',true);

    case {'feature_ID_scatter' 'feature_sv_scatter' 'feature_sv_griddded_scatter'}  
        disp_gridded_data = false;
        switch tt
            case 'feature_ID_scatter'
                ff = 'feature_id';
                ax_ff = 'feature_id';
            case 'feature_sv_scatter'
                ff = 'feature_sv';
                ax_ff = 'sv';
            case 'feature_sv_griddded_scatter'
                ff = 'feature_sv';
                ax_ff = 'sv';
                disp_gridded_data = true;
        end
        for ilay = 1:numel(layers_to_disp)
            [trans_obj,idxt]=layers_to_disp(ilay).get_trans(curr_disp);

            if isempty(idxt)
                trans_obj = layers_to_disp(ilay).Transceivers(1);
            end

            cax=curr_disp.getCaxField(ax_ff);

            echo_3D_obj.add_feature(trans_obj,'fieldname',ff,'cax',cax,'disp_gridded_data',disp_gridded_data);
        end
    case {'sv' 'sp' 'TS'}
        for ilay = 1:numel(layers_to_disp)
            [trans_obj,~]=layers_to_disp(ilay).get_trans(curr_disp);
            active_regs = trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
            cax=curr_disp.getCaxField(tt);
            
            if ~isempty(active_regs)
                echo_3D_obj.add_feature(trans_obj,'fieldname',tt,'cax',cax,'regs',active_regs,'BeamAngularLimit',curr_disp.BeamAngularLimit,'disp_gridded_data',false);
            end
        end  
end
hide_status_bar(esp3_obj.main_figure);