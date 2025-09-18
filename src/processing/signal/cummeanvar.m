function [x_cum_mean,x_cum_var] = cummeanvar(x,dim,win,nanflag)

sx = size(x);
x_cum_mean = nan(sx);
x_cum_var = nan(sx);

if sx(dim)<win
    x_cum_var = var(x,0,dim,nanflag);
    x_cum_mean = mean(x,dim,nanflag);
    return;
end


for ui = 1:sx(dim)
    if ui<win
        continue;
    end
    switch dim
        case 1
            x_cum_mean(ui,:) = mean(x(1:ui,:),dim,nanflag);
            x_cum_var(ui,:) = var(x(1:ui,:),0,dim,nanflag);
        case 2
            x_cum_mean(:,ui) = mean(x(:,1:ui),dim,nanflag);
            x_cum_var(:,ui) = var(x(:,1:ui),0,dim,nanflag);
    end
end





