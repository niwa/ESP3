
function freq_response_reg_callback(~,~,select_plot,main_figure,field,sliced)
layer_obj=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer_obj.get_trans(curr_disp);

load_bar_comp=getappdata(main_figure,'Loading_bar');

switch class(select_plot)
    case 'region_cl'
        reg_obj=trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
    otherwise
        idx_ping=round(min(select_plot.XData,[],'omitnan')):round(max(select_plot.XData,[],'omitnan'));
        idx_r=round(min(select_plot.YData,[],'omitnan')):round(max(select_plot.YData,[],'omitnan'));        
        reg_obj=region_cl('Name','Select Area','Idx_r',idx_r,'Idx_ping',idx_ping,'Unique_ID','select_area');
end


show_status_bar(main_figure);
for ireg=1:length(reg_obj)    
    if~isempty(layer_obj.Curves)
        layer_obj.Curves(cellfun(@(x) strcmp(x,reg_obj(ireg).Unique_ID),{layer_obj.Curves(:).Unique_ID}))=[];
    end
    %update_multi_freq_disp_tab(main_figure,'ts_f',0);
    switch(field)
        case {'sp','spdenoised','spunmatched'}
            update_algos('algo_name',{'SingleTarget'});
            layer_obj.TS_freq_response_func('reg_obj',reg_obj(ireg),'load_bar_comp',load_bar_comp,'idx_freq',idx_freq);
            update_multi_freq_disp_tab(main_figure,'ts_f',0);
        case {'sv','svdenoised','svunmatched'}
            layer_obj.Sv_freq_response_func('reg_obj',reg_obj(ireg),'sliced',sliced,'load_bar_comp',...
                load_bar_comp,'idx_freq',idx_freq);
            update_multi_freq_disp_tab(main_figure,'sv_f',0);
        otherwise
            update_algos('algo_name',{'SingleTarget'});
            layer_obj.TS_freq_response_func('reg_obj',reg_obj(ireg),'lbar',true,'load_bar_comp',load_bar_comp,'idx_freq',idx_freq);
            update_multi_freq_disp_tab(main_figure,'ts_f',0);
    end
end
hide_status_bar(main_figure);

end