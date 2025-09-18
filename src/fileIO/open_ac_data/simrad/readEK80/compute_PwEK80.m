function [y,power]=compute_PwEK80(Rwt_rx,Ztrd,data)

y = 0;
power = 0;
nb_chan=sum(contains(fieldnames(data),'comp_sig'));
if nb_chan == 5
    nb_chan =1;
end
if nb_chan>0
    y=zeros(size(data.comp_sig_1));

    for ic=1:nb_chan
        y=y+data.(sprintf('comp_sig_%1d',ic));
    end

    y=y/nb_chan;

    power=(nb_chan*(abs(y)/(2*sqrt(2))).^2*((Rwt_rx+Ztrd)/Rwt_rx)^2/Ztrd);

end