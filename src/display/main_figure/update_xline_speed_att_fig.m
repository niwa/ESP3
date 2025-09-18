function update_xline_speed_att_fig(main_figure,xval)

    hfigs=getappdata(main_figure,'ExternalFigures');
    if ~isempty(hfigs)
        hfigs(~isvalid(hfigs))=[];
    end
    
    if ~isempty(hfigs)
        idx_fig_att=find(ismember({hfigs(:).Tag},{'attitude','speed'}));
        
        if ~isempty(idx_fig_att)
           ax_h = findall(hfigs(idx_fig_att),'Tag','xline');
            set(ax_h,'Value',xval);
        end
    end

end