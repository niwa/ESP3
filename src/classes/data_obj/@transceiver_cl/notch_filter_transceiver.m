function notch_filter_transceiver(trans_obj,env_data_obj,varargin)

p = inputParser;

addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addRequired(p,'env_data_obj',@(obj) isa(obj,'env_data_cl'));
addParameter(p,'bands_to_notch',[],@isnumeric);
addParameter(p,'load_bar_comp',[]);
addParameter(p,'block_len',nan,@(x) x>0 || isnan(x));

parse(p,trans_obj,env_data_obj,varargin{:});
band_f=p.Results.bands_to_notch;
block_len = get_block_len(50,'cpu',p.Results.block_len);
FreqStart_tot=(trans_obj.get_params_value('FrequencyStart'));
FreqEnd_tot=(trans_obj.get_params_value('FrequencyEnd'));
f_s_sig_tot=round((1./(trans_obj.get_params_value('SampleInterval'))));

[Vals,unique_freqs,triple_ID]=unique([FreqStart_tot(:) FreqEnd_tot(:) f_s_sig_tot(:)],'rows');
Rwt_rx=trans_obj.Config.Impedance;
Ztrd=trans_obj.Config.Ztrd;
[~,up_t]=trans_obj.Data.find_field_idx('y_real_filtered');

if ~strcmpi(trans_obj.Mode,'CW')
    mbFilt = cell(1,size(Vals,1));
    amp_filt = cell(1,size(Vals,1));
    idx_sub_pings = cell(1,size(Vals,1));
    for iFreq=1:size(Vals,1)
        FreqStart=Vals(iFreq,1);
        FreqEnd=Vals(iFreq,2);
        f_s_sig=Vals(iFreq,3);
        idx_sub_pings{iFreq}=find(triple_ID==unique_freqs(iFreq));
        band_f_tmp=band_f;
        band_f_tmp(band_f_tmp<FreqStart)=FreqStart;
        band_f_tmp(band_f_tmp>FreqEnd)=FreqEnd;
        n_filt_length=ceil(f_s_sig/1e2);
        
        band_f_based=band_f_tmp-f_s_sig*floor(FreqEnd/f_s_sig);
        f_vec_based=linspace(-f_s_sig/2,f_s_sig/2,n_filt_length);
        
        amp_filt{iFreq}=ones(size(f_vec_based));
        f_vec=linspace(min(FreqEnd,FreqStart),max(FreqEnd,FreqStart),n_filt_length);
        
        for ib=1:size(band_f,1)
            if any(f_vec>=min(band_f(ib,:))&f_vec<=max(band_f(ib,:)))
                amp_filt{iFreq}(f_vec_based>=min(band_f_based(ib,:))&f_vec_based<=max(band_f_based(ib,:)))=0;
            end
        end
        
        if ~all(amp_filt{iFreq}>0)
            mbFilt{iFreq} = designfilt('arbmagfir','FilterOrder',60, ...
                'Frequencies',f_vec_based,'Amplitudes',amp_filt{iFreq}, ...
                'SampleRate',f_s_sig);
            up_t = true;
        else
            continue;
        end
    end
    
    for iFreq=1:size(Vals,1)

        block_size = min(ceil(block_len/max(trans_obj.Data.Nb_samples)),numel(idx_sub_pings{iFreq}));
        num_ite = ceil(numel(idx_sub_pings{iFreq})/block_size);
        if ~isempty(p.Results.load_bar_comp)
            p.Results.load_bar_comp.progress_bar.setText(sprintf('Notch Filtering %s',trans_obj.Config.ChannelID));
            set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
        end
        for ui = 1:num_ite
            idx_sub_sub_pings = idx_sub_pings{iFreq}((ui-1)*block_size+1:min(ui*block_size,numel(idx_sub_pings{iFreq})));
            if ~all(amp_filt{iFreq}>0)
                for iping=idx_sub_sub_pings
                    y_c = trans_obj.Data.get_subdatamat('idx_ping',iping,'field','y');
                    y_c = double_to_complex_single(y_c);
                    y_c_filtered = filter(mbFilt{iFreq},y_c);
                    trans_obj.Data.replace_sub_data_v2(complex_single_to_double(y_c_filtered),'y_filtered','idx_ping',iping);
                    power=(trans_obj.Config.NbQuadrants*(abs(y_c_filtered)/(2*sqrt(2))).^2*((Rwt_rx+Ztrd)/Rwt_rx)^2/Ztrd);
                    trans_obj.Data.replace_sub_data_v2(power,'power','idx_ping',iping);
                end
            elseif up_t
                for iping=idx_sub_sub_pings
                    y_c=trans_obj.Data.get_subdatamat('idx_ping',iping,'field','y');
                    y_c = double_to_complex_single(y_c);
                    
                    if ui ==1
                        trans_obj.Data.remove_sub_data('y_filtered');
                    end
                    power=(trans_obj.Config.NbQuadrants*(abs(y_c)/(2*sqrt(2))).^2*((Rwt_rx+Ztrd)/Rwt_rx)^2/Ztrd);
                    trans_obj.Data.replace_sub_data_v2(power,'power','idx_ping',iping);
                    
                end
            end
            
            % update progress bar
            if ~isempty(p.Results.load_bar_comp)
                set(p.Results.load_bar_comp.progress_bar, 'Value',ui);
            end
        end
    end
    
    
    if up_t
        trans_obj.computeSpSv(p.Results.env_data_obj,'load_bar_comp',p.Results.load_bar_comp);
    end
end
end