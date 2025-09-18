function data=match_filter_data(data,y_tx_matched,gpu_comp)

if ~isempty(y_tx_matched)
    
    Np=numel(y_tx_matched);

    nb_chan=sum(contains(fieldnames(data),'comp_sig'));
    
    for ic=1:nb_chan
        s=data.(sprintf('comp_sig_%1d',ic));
        
        if ic  == 1
            [nb_s,nb_pings]=size(s);
            y_tx_matched = cast(y_tx_matched,class(s));
            data.ping_num=(1:nb_pings);
            
            val_sq=sum(abs(y_tx_matched).^2);
            
            n = Np + nb_s - 1;
            if gpu_comp>0
                y_tx_matched  =gpuArray(y_tx_matched);
                s = gpuArray(s);
            end
            fft_matched = fft(y_tx_matched,n);
        end
        
        if gpu_comp>0
            s = gpuArray(s);
        end
        
        yc_temp =ifft(fft_matched.*fft(s,n,1));
        
        if gpu_comp>0
            yc_temp = gather(yc_temp);
        end
        
        yc_temp = yc_temp/val_sq;

        ddr = floor(Np/2);
        yc_temp = circshift(yc_temp,-ddr,1);
        yc_temp(end-ddr:end,:)=0;

        data.(sprintf('comp_sig_%1d',ic)) = yc_temp;

    end
end  

