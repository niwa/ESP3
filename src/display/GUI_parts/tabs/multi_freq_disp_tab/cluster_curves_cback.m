function cluster_curves_cback(~,~,tag_f)

esp3_obj = getappdata(groot,'esp3_obj');
layer_obj = get_current_layer();
curr_disp = esp3_obj.curr_disp;
curves = layer_obj.get_curves_per_type(tag_f);

if isempty(curves)
    return;
end

multi_freq_disp_tab_comp=getappdata(esp3_obj.main_figure,tag_f);

switch tag_f
    case 'ts_f'
        yl = curr_disp.getCaxField('sp');
        str_disp = 'Clustering on TS(f)';
        val_str = 'TS(dB)';
    case 'sv_f'
        yl = curr_disp.getCaxField('sv');
        str_disp = 'Clustering on Sv(f)';
        val_str = 'Sv(dB)';
end

[answers,cancel]=input_dlg_perso(esp3_obj.main_figure,'Number of classes',{'Number of classes'},{'%.0f'},{3});

if ~cancel
    nb_class = answers{1};
else
    return;
end

nb_class = max(2,nb_class);
nb_class = min(numel(curves)-1,nb_class);

dc = 1;

freq_data = cell(1,numel(curves));

for uic = 1:numel(curves)
    freq_data{uic} = (curves(uic).XData);
end

nb_f = cellfun(@numel,freq_data);

[~,idx] = max(nb_f);

ff = freq_data{idx};
mat_curve_ori =nan(nb_f(idx),numel(numel(curves)));

s_method = multi_freq_disp_tab_comp.filter.UserData{multi_freq_disp_tab_comp.filter.Value};
win_s = multi_freq_disp_tab_comp.win_size.UserData(multi_freq_disp_tab_comp.win_size.Value);

switch multi_freq_disp_tab_comp.fref.String{multi_freq_disp_tab_comp.fref.Value}
    case 'None'
        f_ref = 0;
    case 'Norm 2'
        f_ref = -1;
    otherwise
        f_ref = multi_freq_disp_tab_comp.fref_val.UserData(multi_freq_disp_tab_comp.fref_val.Value)/1e3;
end

for uic = 1:numel(curves)
    yd = curves(uic).filter_curve(s_method,win_s);
    yd = scattering_model_cl.norm_scat(curves(uic).XData,yd,f_ref);

    yd(yd<-160)=nan;
    mat_curve_ori(:,uic) = resample_data_v2(yd,curves(uic).XData,ff,'IgnoreNans',1);
end

mat_curve = mat_curve_ori;
std_curves = std(mat_curve,0,'all','omitnan');
mean_curves = mean(mat_curve,'all','omitnan');

mat_curve = (mat_curve-mean_curves)./std_curves;

idx_keep = find(sum(~isnan(mat_curve),2)==numel(curves));

mat_curve = mat_curve(idx_keep,:);

% idx_keep = find(~any(isnan(mat_curve),1));
% 
% mat_curve  = mat_curve(:,idx_keep);

%curves = curves(idx_keep);

[idx_class,C] = kmeans(mat_curve',nb_class);

nb_class = numel(unique(idx_class));

cols = lines(nb_class);


fig = new_echo_figure(esp3_obj.main_figure,'Name',str_disp,'UiFigureBool',true,'Position',[0 0 600 400]);
uigl = uigridlayout(fig,[ceil(nb_class/2),2]);
for ui = 1:nb_class
    ax(ui) = uiaxes(uigl,'nextplot','add','Box','on');
    ax(ui).Title.String = sprintf('Class %.0f',ui);
    
    grid(ax(ui),'on');
    xlabel(ax(ui),'Freq(kHz)','FontSize',12);
    ylabel(ax(ui),val_str,'FontSize',12);
end

for uic = 1:dc:numel(curves)
    if ~isnan(idx_class(uic))
        plot(ax(idx_class(uic)),ff(idx_keep),mat_curve_ori(idx_keep,uic),'Color',[0.6 0.6 0.6],'LineWidth',0.5);
        curves(uic).Tag = sprintf('Class %.0f',idx_class(uic));
        uid = strsplit(curves(uic).Unique_ID,'_');
        layer_obj.set_tag_to_region_with_uid(uid{1},curves(uic).Tag);
    else
        curves(uic).Tag = '';
    end
end

for uic = 1:size(C,1)
    plot(ax(uic),ff(idx_keep),(C(uic,:)*std_curves+mean_curves),'Color',cols(uic,:),'LineWidth',3);
    ylim(ax(uic),yl+[-5 +5]);
end


layer_obj.add_curves(curves);


update_multi_freq_disp_tab(esp3_obj.main_figure,tag_f,1);
update_reglist_tab(esp3_obj.main_figure,1);
display_regions('all');
