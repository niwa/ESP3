function [layers,metrics] = plot_vertical_metrics_urmy(Sv,depths,pings,trans_obj,varargin)

p = inputParser;
addRequired(p,'Sv');
addRequired(p,'depths');
addRequired(p,'pings');
addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addParameter(p,'Threshold',-75,@isnumeric);
addParameter(p,'MinLayerHeight',10,@isnumeric);
addParameter(p,'SmoothSigma',1.5,@isnumeric);
addParameter(p,'main_figure',[],@(x) ishandle(x)||ishandle());

parse(p,Sv,depths,pings,trans_obj,varargin{:});

thr = p.Results.Threshold;
min_height = p.Results.MinLayerHeight;
smooth_sigma = p.Results.SmoothSigma;
main_figure = p.Results.main_figure;

trans_obj_time = trans_obj.get_transceiver_time(pings);

Sv(isnan(Sv))=-999;
sv = 10.^(Sv/10);
threshold_linear = 10^(thr/10);

sv(sv<threshold_linear) = 0;

sv_smoothed = imgaussian(sv,smooth_sigma);

mean_profile = mean(sv_smoothed,2);
mean_depths = mean(depths,2);

binary_profile = mean_profile>threshold_linear;

layer_labels = bwlabel(binary_profile);
num_layers = max(layer_labels);

layers = struct('ID',{},'TopDepth',{},'BottomDepth',{},'Thickness',{});
valid_idx = 1;

for iil = 1:num_layers
    layer_indices = find(layer_labels == iil);
    layer_depths = depths(layer_indices);

    current_thickness = max(layer_depths)-min(layer_depths);

    if current_thickness>=min_height
        layers(valid_idx).ID = valid_idx;
        layers(valid_idx).TopDepth = min(layer_depths);
        layers(valid_idx).BottomDepth = max(layer_depths);
        layers(valid_idx).Thickness = current_thickness;
        valid_idx = valid_idx+1;
    end
end

sum_sv = sum(mean_profile);

if sum_sv>0
    centre_of_mass = sum(mean_profile .* mean_depths(:))/sum_sv;

    inertia = sum(mean_profile.*((mean_depths(:)-centre_of_mass).^2))/sum_sv;

    equivalent_area = (sum_sv^2)/sum(mean_profile.^2);

    proportion_occupied = mean(binary_profile);
else
    centre_of_mass = NaN;
    inertia = NaN;
    equivalent_area = NaN;
    proportion_occupied = 0;
end

metrics.CentreOfMass = centre_of_mass;
metrics.Inertia = inertia;
metrics.EquivalentArea = equivalent_area;
metrics.AggregationIndex = 1/equivalent_area;
metrics.Occupancy = proportion_occupied;
metrics.DetectedLayerCount = length(layers);

plot_echogram(Sv,depths,pings,layers,centre_of_mass,trans_obj_time,main_figure);

num_pings = pings(end);
com = zeros(1,num_pings);
inertia = zeros(1,num_pings);
proportion_occupied = zeros(1,num_pings);
aggregation_index = zeros(1,num_pings);
Sa = zeros(1,num_pings);
MVBS = zeros(1,num_pings);
N_layers = zeros(1,num_pings);

for iip = 1:num_pings
    sv_profile = sv_smoothed(:,iip);

    sum_sv_plot = sum(sv_profile);

    depth_profile = depths(:,iip);

    if sum_sv_plot > 0
        com(iip) = sum(depths(:,iip) .* sv_profile) / sum_sv_plot;
        
        inertia(iip) = sum(((depths(:,iip) - com(iip)).^2) .* sv_profile)/sum_sv_plot;

        proportion_occupied(iip) = sum(sv_profile > threshold_linear)/length(sv_profile);

        sorted_sv = sort(sv_profile);
        n = length(sorted_sv);
        cum_sv = cumsum(sorted_sv);

        numerator = sum((1:n)' .* sorted_sv);
        aggregation_index(iip) = (sum(sv_profile.^2))/(sum(sv_profile)^2);

        MVBS(iip) = 10*log10(sum_sv_plot/length(sv_profile)); 
        Sa(iip) = 10*log10(sum_sv_plot);

        binary_profile = sv_profile>threshold_linear;
        layer_labels = bwlabel(binary_profile);
        num_layers = max(layer_labels);
        layers = struct('ID',{},'TopDepth',{},'BottomDepth',{},'Thickness',{});
        valid_idx = 1; 
        depth_profile = depths(:,iip);
        for iil = 1:num_layers
            layer_indices = find(layer_labels == iil);
            layer_depths = depth_profile(layer_indices);
            current_thickness = max(layer_depths)-min(layer_depths);     
            if current_thickness>=min_height
                layers(valid_idx).ID = valid_idx;
                layers(valid_idx).TopDepth = min(layer_depths);
                layers(valid_idx).BottomDepth = max(layer_depths);
                layers(valid_idx).Thickness = current_thickness;
                valid_idx = valid_idx+1;
            end
        end
        N_layers(iip) = length(layers);
    else
        MVBS(iip) = NaN;
        Sa(iip) = NaN;
        com(iip) = NaN;
        inertia(iip) = NaN;
        proportion_occupied(iip) = 0;
        aggregation_index(iip) = NaN;
        N_layers = 0;
    end
end
metrics.MVBS = MVBS;
metrics.Sa = Sa;
metrics.COM = com;
metrics.I = inertia;
metrics.Pocc = proportion_occupied;
metrics.AI = aggregation_index;
metrics.EA = 1./aggregation_index;
metrics.N_layers = N_layers;

plot_metrics(MVBS,Sa,com,inertia,proportion_occupied,aggregation_index,N_layers,trans_obj_time,main_figure)

end

function smoothed = imgaussian(I,smooth_sigma)
window = ceil(3*smooth_sigma)*2+1;
kernel = fspecial('gaussian',[window window],smooth_sigma);
smoothed = filter2(kernel,I);
end

function plot_echogram(Sv,depths,pings,layers,cm,trans_obj_time,main_figure)
figure = new_echo_figure(main_figure,'UiFigureBool',true);
mean_depths = mean(depths,2);
imagesc(trans_obj_time,mean_depths,Sv);
colormap("jet");
c = colorbar;
curr_disp=get_esp3_prop('curr_disp');
clim([curr_disp.Caxes{1}]);
c.Label.String = 'S_v (dB re 1 m^{-1})';
datetick('x', 'dd/mm/yyyy HH:MM:SS', 'keeplimits', 'keepticks');
xtickangle(45)
xlabel('Time (UTC)');
ylabel('Depth (m)');
title('Layer Detection');
hold on;

if ~isnan(cm)
    plot([trans_obj_time(1),trans_obj_time(end)],[cm cm],'r--','LineWidth',4);
    text(trans_obj_time(2),cm-10,'Centre of Mass','Color','r','FontWeight','bold','FontSize',15);
end

for k = 1:length(layers)
    yline(layers(k).TopDepth,'w-','LineWidth',4);
    yline(layers(k).BottomDepth,'w-','LineWidth',4);
    text(trans_obj_time(2),layers(k).TopDepth+(layers(k).Thickness/2),['Layer ',...
        num2str(layers(k).ID)],'Color','w','FontWeight','bold','FontSize',15);
end
hold off;
end

function plot_metrics(MVBS,Sa,com,inertia,proportion_occupied,aggregation_index,N_layers,trans_obj_time,main_figure)
fig = new_echo_figure(main_figure,'UiFigureBool',true);

t = tiledlayout(fig,8,1);
nexttile(t);
plot(MVBS,'k-','LineWidth',1.5);
title('S_v');
ylabel('S_v (dB re 1m^(-1))');
grid('on')

nexttile(t);
plot(Sa,'k-','LineWidth',1.5);
title('S_a');
ylabel('S_a (dB re 1m^2m^(-2))');
grid('on')

nexttile(t);
plot(com,'k-','LineWidth',1.5);
title('Centre of Mass');
ylabel('COM (m)');
grid('on')

nexttile(t);
plot(inertia,'k-','LineWidth',1.5);
title('Inertia');
ylabel('I (m^(-2))');
grid('on')

nexttile(t);
plot(proportion_occupied,'k-','LineWidth',1.5);
title('Proportion occupied');
ylabel('P_occ');
grid('on')

nexttile(t);
EA = 1./aggregation_index;
plot(EA,'k-','LineWidth',1.5);
title('Equivalent area');
ylabel('EA (m)');
grid('on')

nexttile(t);
plot(aggregation_index,'k-','LineWidth',1.5);
title('Index of aggregation ');
ylabel('IA (m^2)');
grid('on')

nexttile(t);
plot(trans_obj_time,N_layers,'k-','LineWidth',1.5);
title('Number of detected layers');
datetick('x', 'dd/mm/yyyy HH:MM:SS', 'keeplimits', 'keepticks');
xtickangle(45)
grid('on')
xlabel('Time (UTC)')
ylabel('N_layers');

end