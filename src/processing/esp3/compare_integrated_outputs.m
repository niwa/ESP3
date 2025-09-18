function [lin_pow,lin_pow_ref,hist1,hist2,x_data,y_data]=compare_integrated_outputs(lay1,lay2,id1,idt1,id2,idt2,lin_pow,lin_pow_ref,hist1,hist2,cmap_str,sname)
cmap_struct = init_cmap(cmap_str);
cmap = cmap_struct.cmap;
bins = 150;
cax_prc = [0 100];
thr = 0.001;
yy =[0 8];
xx =[-140 -70];
thr_sv = -80;



if isempty(lin_pow)
    lin_pow = new_echo_figure([]);colormap(lin_pow,cmap);
end
if isempty(lin_pow_ref)
    lin_pow_ref = new_echo_figure([]);colormap(lin_pow_ref,cmap);
end

if isempty(hist1)
    hist1 = new_echo_figure([]);colormap(hist1,cmap);
end

if isempty(hist2)
    hist2 = new_echo_figure([]);colormap(hist2,cmap);
end


echo_int_struct_nc = lay1.EchoIntStruct.output_2D{id1}{idt1};
echo_int_struct_raw = lay2.EchoIntStruct.output_2D{id2}{idt2};

if isempty(echo_int_struct_nc)||isempty(echo_int_struct_raw)
    return;
end

if numel(lay1.EchoIntStruct.output_2D)==0||numel(lay2.EchoIntStruct.output_2D)==0
    return;
end

alpha = lay1.Transceivers(1).get_absorption();
alpha = mean(alpha)/1e3;

sv_nc = pow2db_perso(lay1.EchoIntStruct.output_2D{id1}{idt1}.sv);
sv_raw  = pow2db_perso(lay2.EchoIntStruct.output_2D{id2}{idt2}.sv);

r_nc = (echo_int_struct_nc.Range_ref_min+echo_int_struct_nc.Range_ref_max)/2;
r_raw = (echo_int_struct_raw.Range_ref_min+echo_int_struct_raw.Range_ref_max)/2;

ping = (echo_int_struct_nc.Ping_S+echo_int_struct_nc.Ping_S)/2;

size_data = min(size(sv_nc),size(sv_raw));

sv_nc = sv_nc(1:size_data(1),1:size_data(2));
sv_raw = sv_raw(1:size_data(1),1:size_data(2));

r_nc = r_nc(1:size_data(1),1:size_data(2));
r_raw = r_raw(1:size_data(1),1:size_data(2));

ping = ping(1,1:size_data(2));

sv_nc(isinf(sv_nc)|sv_nc < -900) = nan;
sv_raw(isinf(sv_raw)|sv_raw < -900) = nan;
%

power_nc = sv_nc - 20*log10(r_nc)-2*alpha*r_nc;
power_raw = sv_raw - 20*log10(r_raw)-2*alpha*r_raw;
%
%     power_nc = sv_nc - 20*log10(r_nc)-2*alpha*r_nc +10*log10(c.*t_eff_nc/2)+eq_beam_angle_nc;
%     power_raw = sv_raw - 20*log10(r_raw)-2*alpha*r_raw +10*log10(c.*t_eff_raw/2)+eq_beam_angle_raw;


thr_diff = 0;

data  = sv_nc-sv_raw;
pings = lay2.Transceivers(id1).get_transceiver_pings;
bot_range = lay2.Transceivers(id1).get_bottom_range;

pings_nc = lay1.Transceivers(id2).get_transceiver_pings;
bot_range_nc = lay1.Transceivers(id2).get_bottom_range;


sv_comp = new_echo_figure([],'Units','pixels','Position',[1960 501 1617 370]);colormap(sv_comp,cmap);
nexttile();
u = pcolor(repmat(ping,size(data,1),1),r_nc,sv_nc);hold on;
set(u,...
    'Facealpha','flat',...
    'FaceColor','flat',...
    'LineStyle','none',...
    'AlphaData',(sv_nc>thr_sv));
axis ij;
plot(pings_nc,bot_range_nc,'k');

clim([thr_sv -35]);colorbar;

title(sprintf('%s %s',sname,'S_{v,1}'));

nexttile();
u = pcolor(repmat(ping,size(data,1),1),r_nc,data);hold on;
set(u,...
    'Facealpha','flat',...
    'FaceColor','flat',...
    'LineStyle','none',...
    'AlphaData',abs(data)>thr_diff&sv_nc>thr_sv&sv_raw>thr_sv);
axis ij;
plot(pings,bot_range,'k');

clim([-2 6]);colorbar;
title(sprintf('%s %s',sname,'S_{v,1}-S_{v,2}'));

nexttile();
u = pcolor(repmat(ping,size(data,1),1),r_raw,sv_raw);hold on;
set(u,...
    'Facealpha','flat',...
    'FaceColor','flat',...
    'LineStyle','none',...
    'AlphaData',(sv_raw>thr_sv));
axis ij;
plot(pings,bot_range,'k');

clim([thr_sv -35]);colorbar;

title(sprintf('%s %s',sname,'S_{v,2}'));

figure(hist1); nexttile();
h11=histogram2(r_nc,data,[ceil(range(r_nc(:))/mean(diff(mean(r_nc,2)))) bins],'DisplayStyle','tile','Normalization','pdf','LineStyle','none');hold on;
hold on;yline(0,'k','linewidth',2);
[~,id_mpp] = max(h11.BinCounts,[],2);
yhh = h11.YBinEdges(id_mpp)+h11.BinWidth(2)/2;
yhh(sum(h11.Values,2)<thr*sum(h11.Values,'all')) = nan;
plot(h11.XBinEdges(1:end-1),yhh,'linewidth',1.5,'color',[0.8 0 0]);
title(sname);
ylabel('S_{v,1}-S_{v,2}');

xlabel('Range(m)');
ylim([-5 10]);
clim(prctile(h11.Values,cax_prc,'all'));

figure(hist2);  nexttile();
h2=histogram2(r_nc,power_nc,[ceil(range(r_nc(:))/mean(diff(mean(r_nc,2)))) bins],'DisplayStyle','tile','Normalization','pdf','LineStyle','none');hold on;
hold on;
[~,id_mpp] = max(h2.BinCounts,[],2);
yhh = h2.YBinEdges(id_mpp)+h2.BinWidth(2)/2;
yhh(sum(h2.Values,2)<thr*sum(h2.Values,'all')) = nan;
plot(h2.XBinEdges(1:end-1),yhh,'linewidth',1.5,'color',[0.8 0 0]);
title(sname);
ylabel('P_{v,1}');
xlabel('Range(m)');
clim(prctile(h2.Values,cax_prc,'all'));
ylim(xx);
id_keep = ~isnan(sv_nc)&~isnan(sv_raw)&~isnan(sv_nc)&~isinf(sv_raw);

x_p = linspace(min(power_nc(id_keep)),max(power_nc(id_keep)),100);
figure(lin_pow);
nexttile()
h1 = histogram2(power_nc,power_raw,bins,'DisplayStyle','tile','Normalization','pdf','LineStyle','none');
hold on; plot(x_p,x_p,'k','linewidth',1.5);
[~,id_mpp] = max(h1.BinCounts,[],2);
yhh = h1.YBinEdges(id_mpp)+h1.BinWidth(2)/2;
yhh(sum(h1.Values,2)<thr*sum(h1.Values,'all')) = nan;
plot(h1.XBinEdges(1:end-1),yhh,'linewidth',1.5,'color',[0.8 0 0]);


axis equal
xlim(xx);
ylim(xx);

ylabel('P_{v,2}');
xlabel('P_{v,1}');
title(sname);
clim(prctile(h1.Values,cax_prc,'all'));

figure(lin_pow_ref);
nexttile()
h = histogram2(power_nc,db2pow(power_nc-power_raw),bins,'DisplayStyle','tile','YBinLimits',[0 20],'Normalization','pdf','LineStyle','none');
hold on;yline(1,'k','linewidth',1.5);
[~,id_mpp] = max(h.Values,[],2);
yhh = h.YBinEdges(id_mpp)+h.BinWidth(2)/2;
yhh(sum(h.Values,2)<thr*sum(h.Values,'all')) = nan;
plot(h.XBinEdges(1:end-1),yhh,'linewidth',1.5,'color',[0.8 0 0]);
%plot(power_nc,power_raw,'.k')
hold on; %plot(x_p,x_p,'linewidth',1.5);%plot(x_p,y_p,'r','linewidth',1.5);
%axis equal
contour(h.XBinEdges(1:end-1),h.YBinEdges(1:end-1),h.Values',[max(h.Values(:))*0.2 max(h.Values(:))*0.5],'linewidth',1.5,'linecolor',[0.2 0.2 0.2]);
xlim(xx);
ylabel('p_{v,1}/p_{v,2}');
xlabel('P_{v,2}(dB)');
title(sname);
clim(prctile(h.Values,cax_prc,'all'));
ylim(yy)

x_data = h.XBinEdges(1:end-1);
y_data = yhh;