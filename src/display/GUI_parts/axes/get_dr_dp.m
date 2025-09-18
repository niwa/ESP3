function [dr,dp]=get_dr_dp(ax,nb_samples,nb_pings,echoQuality)

screensize = getpixelposition(ax);
outputSize=screensize(3:4);

switch echoQuality
    case 'high'
        dqf=2;
    case 'medium'
        dqf=1.5;
    case 'low'
        dqf=1;
    case 'very_low'
        dqf=0.5;
    otherwise
        dqf=1.5;
end

outputSize=ceil(dqf*outputSize);

dr=max(ceil(nb_samples/outputSize(2)),1);
dp=max(floor(nb_pings/outputSize(1)),1);
