function Sv_freq_response_func(layer_obj,varargin)

p = inputParser;

addRequired(p,'layer_obj',@(x) isa(x,'layer_cl'));
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'win_fact',1,@(x) isnumeric(x) && x>0);
addParameter(p,'idx_freq',1,@isnumeric);
addParameter(p,'sliced',false,@islogical);
addParameter(p,'load_bar_comp',[]);

parse(p,layer_obj,varargin{:});

trans_obj = layer_obj.Transceivers(p.Results.idx_freq);

if isempty(p.Results.reg_obj)
    idx_r=(1:length(trans_obj.get_samples_range()))';
    idx_ping=1:length(trans_obj.get_transceiver_pings());
    [~,Np_p]=trans_obj.get_pulse_length();
    idx_r(idx_r<3*max(Np_p))=[];
    reg_obj=region_cl('Idx_r',idx_r,'Idx_ping',idx_ping);
else
    reg_obj=p.Results.reg_obj;

end
init_done = false;
[cal_fm_cell,~] =layer_obj.get_fm_cal([]);

[regs,idx_freq_end]=layer_obj.generate_regions_for_other_freqs(p.Results.idx_freq,reg_obj,[]);

[~,idx_sort_f]=sort(layer_obj.Frequencies);

SD_f= [];
Sv_f= [];
f_vec=[];
r_vec=[];

for uui=idx_sort_f
    
    reg=regs(idx_freq_end==uui);

    if layer_obj.Transceivers(uui).ismb
        continue;
    end

    if isempty(reg)
        if uui == p.Results.idx_freq
            reg=reg_obj;
        else
            continue;
        end
    end

    cal=cal_fm_cell{uui};

    if p.Results.sliced
        cell_h=reg.Cell_h;
    else
        cell_h=0;
    end

    output_size='2D';

    [Sv_f_out,f_vec_temp,pings,r_f]=layer_obj.Transceivers(uui).sv_f_from_region(reg,...
        'envdata',layer_obj.EnvData,'cal',cal,'output_size',output_size,'sliced_output',cell_h,'load_bar_comp',p.Results.load_bar_comp,'win_fact',p.Results.win_fact);

    sv_f_temp=10.^(Sv_f_out/10);

    if isempty(sv_f_temp)
        continue;
    end
   


    if ~p.Results.sliced

        Sv_f_temp=10*log10(mean(sv_f_temp,[1 2],'omitnan'));
        SD_f_temp=std(10*log10(sv_f_temp),[],[1 2],'omitnan');

        Sv_f_temp=permute(Sv_f_temp,[2 3 1]);
        SD_f_temp=permute(SD_f_temp,[2 3 1]);
        r_tmp=mean(r_f,'omitnan');
    else

        idx_slice_r=round((r_f-r_f(1))/cell_h)+1;
        idx_slice=repmat(idx_slice_r',length(pings),1,length(f_vec_temp));
        idx_ping=repmat((1:length(pings))',1,length(r_f),length(f_vec_temp));
        idx_f=repmat(shiftdim((1:length(f_vec_temp)),-1),size(Sv_f_out,1),length(r_f),1);
        sv_f_temp=(accumarray([idx_ping(:) idx_slice(:) idx_f(:)],db2pow(Sv_f_out(:)),[],@mean));

        Sv_f_temp=shiftdim(pow2db_perso(mean(sv_f_temp,1,'omitnan')),1);
        SD_f_temp=shiftdim(std(pow2db_perso(sv_f_temp),1,1),1);
        r_tmp=accumarray(idx_slice_r,r_f,[],@mean);

    end


    if init_done
        SD_f_temp_final=nan(size(r_vec,1),size(SD_f_temp,2));
        Sv_f_temp_final=nan(size(r_vec,1),size(Sv_f_temp,2));
        f_vec_temp_final=f_vec_temp;
        r_tmp_final=nan(size(r_vec,1),1);

        for iv=1:size(r_vec,1)
            [~,idx_r]=min(abs(r_vec(iv)-r_tmp),[],'omitnan');
            SD_f_temp_final(iv,:)=SD_f_temp(idx_r,:);
            Sv_f_temp_final(iv,:)=Sv_f_temp(idx_r,:);
            r_tmp_final(iv)=r_tmp(idx_r);
        end

        SD_f=[SD_f SD_f_temp_final];
        Sv_f=[Sv_f Sv_f_temp_final];
        f_vec=[f_vec f_vec_temp_final];
        r_vec=[r_vec r_tmp_final];
    else
        SD_f= SD_f_temp;
        Sv_f= Sv_f_temp;
        f_vec=f_vec_temp;
        r_vec=r_tmp;
        init_done = true;
    end
end

r_vec = mean(r_vec,2,'omitnan');

if isempty(r_vec)
    return;
end

[~,idx_sub_r] = min(abs(trans_obj.get_samples_range(reg_obj.Idx_r)-r_vec'),[],'omitnan');

d_vec = mean(trans_obj.get_samples_depth(reg_obj.Idx_r(idx_sub_r),reg_obj.Idx_ping),2,'omitnan');

[f_vec,idx_sort]=sort(f_vec);
Sv_f=Sv_f(:,idx_sort);
SD_f=SD_f(:,idx_sort);


if~isempty(f_vec)
    for ii=1:size(Sv_f,1)
        layer_obj.add_curves(curve_cl('XData',f_vec/1e3,...
            'YData',Sv_f(ii,:),...
            'SD',SD_f(ii,:),...
            'Depth',d_vec(ii),...
            'Type','sv_f',...
            'Xunit','kHz',...
            'Yunit','dB',...
            'Tag',reg_obj.Tag,...
            'Name',sprintf('%s %.0f %.0f kHz @ %.1fm',reg_obj.Name,reg_obj.ID,layer_obj.Frequencies(p.Results.idx_freq)/1e3,d_vec(ii)),...
            'Unique_ID',sprintf('%s_%.0f',reg_obj.Unique_ID,r_vec(ii))));
    end
end

end