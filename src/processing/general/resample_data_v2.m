function [ydata_new,xdata_n]=resample_data_v2(ydata,xdata,xdata_n,varargin)
p = inputParser;

addRequired(p,'ydata',@isnumeric);
addRequired(p,'xdata',@isnumeric);
addRequired(p,'xdata_n',@isnumeric);
addParameter(p,'IgnoreNans',0,@isnumeric);
addParameter(p,'Opt','Linear',@ischar);
addParameter(p,'Type','Real',@ischar);

parse(p,ydata,xdata,xdata_n,varargin{:});
idx_nan=isnan(xdata);

xdata(idx_nan)=[];
ydata(idx_nan)=[];
[xdata,IA,~] = unique(xdata);
ydata=ydata(IA);

xdata_n = sort(xdata_n);

if isscalar(ydata)
    ydata_new=repmat(ydata,size(xdata_n,1),size(xdata_n,2));
    return;
end

switch p.Results.Type
    case 'Real'
        ydata_use=ydata;
    case 'Angle'
        ydata_use=exp(1i*ydata/180*pi);
end

ydata_new_temp = interp1(xdata,ydata_use,xdata_n,lower(p.Results.Opt),'extrap');
            
switch p.Results.Type
    case 'Real'
        ydata_new=ydata_new_temp;
    case 'Angle'
        ydata_new_temp=ydata_new_temp./abs(ydata_new_temp);
        ydata_new=sign(asin(imag(ydata_new_temp))).*acos(real(ydata_new_temp))/pi*180;
end

if p.Results.IgnoreNans>0
    idx_nan_old=isnan(ydata);
    X=xdata(~idx_nan_old);
    
    if isempty(X)
        return;
    end

    idx_nan=isnan(ydata_new) & xdata_n>=X(1)&xdata_n<=X(end);
else
    idx_nan=isnan(ydata_new);
end

if all(size(xdata_n) == size(unique(xdata_n)))
    ydata_new = fillmissing(ydata_new,lower(p.Results.Opt),"SamplePoints",xdata_n,"MissingLocations",idx_nan);
end


% 
% figure();
% plot(xdata,ydata,'k');
% hold on;
% plot(xdata_n,ydata_new,'r');
% legend('Original','resampled');



