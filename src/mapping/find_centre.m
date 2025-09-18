%% find_centre.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |lat_cell|: TODO: write description and info on variable
% * |lon_cell|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |lat_centre|: TODO: write description and info on variable
% * |long_centre|: TODO: write description and info on variable
% * |lat_trans|: TODO: write description and info on variable
% * |long_trans|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-04-15: added centre computation for hills survey and weight computation (Yoann Ladroit).
% * 2017-04-13: first version. Methods to find centre for hill survey (Yoann Ladroit).
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function [lat_centre,long_centre,lat_trans,long_trans] = find_centre(lat_cell,lon_cell)
nb_trans=numel(lat_cell);
disp=0;
lat0=0;
long0=0;
for itr=1:nb_trans
    nb_points=numel(lat_cell{itr});
    idx_keep=max(round(nb_points/4),1):max(round(3*nb_points/4),1);
    lat0=lat0+median(lat_cell{itr}(idx_keep));
    long0=long0+mean(lon_cell{itr}(idx_keep));
end

lat0=lat0/nb_trans;
long0=long0/nb_trans;


[xinit,yinit,zone_init]=ll2utm(lat0,long0);

x=cell(1,nb_trans);
y=cell(1,nb_trans);
zone=cell(1,nb_trans);
a=nan(1,nb_trans);
b=nan(1,nb_trans);
c=nan(1,nb_trans);


for itr=1:nb_trans
    nb_points=numel(lat_cell{itr});
    idx_keep=max(round(nb_points/4),1):max(round(3*nb_points/4),1);
    [x{itr},y{itr},zone{itr}]=ll2utm(lat_cell{itr},lon_cell{itr});
    %     x{i}=x{i}-xinit;
    %     y{i}=y{i}-yinit;
    p=polyfit(x{itr}(idx_keep),y{itr}(idx_keep),1);
    a(itr)=-p(1);
    b(itr)=1;
    c(itr)=-p(2);
end




func_sum = @(xp) sum((a*xp(1)+b*xp(2)+c).^2./(a.^2+b.^2));

x_out=fminsearch(func_sum,[xinit,yinit]);

[lat_centre,long_centre]=utm2ll(x_out(1),x_out(2),zone_init);


lat_trans=nan(1,nb_trans);
long_trans=nan(1,nb_trans);

c2=b*x_out(1)-a*x_out(2);

y_trans=-(a.*c2+b.*c)./(a.^2+b.^2);
x_trans=(b.*c2-a.*c)./(a.^2+b.^2);

for itr=1:nb_trans
    [lat_trans(itr),long_trans(itr)]=utm2ll(x_trans(itr),y_trans(itr),zone_init);
end
disp=1;
if disp>0
    hfig=new_echo_figure([]);
    ax=axes(hfig,'Nextplot','add','Box','on');
    grid(ax,'on');
    for itr=1:nb_trans
        x_lin=linspace(min(x{itr},[],'all','omitnan'),max(x{itr},[],'all','omitnan'),numel(x{itr}));
        y_lin=-a(itr)/b(itr)*x_lin-c(itr)/b(itr);
        [lat_lin,long_lin]=utm2ll(x_lin',y_lin',zone{itr});
        plot(ax,lat_cell{itr},lon_cell{itr});
        plot(ax,lat_lin,long_lin,'--k');
    end
    
    plot(ax,lat0,long0,'x');
    plot(ax,lat_centre,long_centre,'s');
    plot(ax,lat_trans,long_trans,'*');
end



end


