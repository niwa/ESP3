function [Sv_f,f_vec,pings,r_tot]=sv_f_from_region(trans_obj,reg_obj,varargin)

p = inputParser;
addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addRequired(p,'reg_obj',@(x) isa(x,'region_cl'));
addParameter(p,'envdata',env_data_cl,@(x) isa(x,'env_data_cl'));
addParameter(p,'cal',[],@(x) isempty(x)|isstruct(x));
addParameter(p,'win_fact',1,@(x) isnumeric(x) && x>0);
addParameter(p,'output_size','3D',@ischar);
addParameter(p,'sliced_output',0,@isnumeric);
addParameter(p,'bottom_only',false,@islogical);
addParameter(p,'load_bar_comp',[],@(x) isempty(x)|isstruct(x));
parse(p,trans_obj,reg_obj,varargin{:});

field='sv';
if ismember('svdenoised',trans_obj.Data.Fieldname)
    field='svdenoised';
end

if ~isempty(p.Results.load_bar_comp)
    p.Results.load_bar_comp.progress_bar.setText(sprintf('Processing Sv(f) estimation at %.0fkHz',trans_obj.Config.Frequency/1e3));
end
Sv_f=[];
f_vec=[];
pings=[];
r_tot=[];
switch trans_obj.Mode
    
    case 'FM'
        
        [data,idx_r,idx_ping,~,bad_data_mask,bad_trans_vec,intersection_mask,below_bot_mask,~]=trans_obj.get_data_from_region(reg_obj,...
            'field',field);
        %analysis_mask = intersection_mask&~bad_data_mask&~isnan(data)&~below_bot_mask;
        if p.Results.bottom_only
            analysis_mask = intersection_mask&~bad_data_mask&~isnan(data)&below_bot_mask&~bad_trans_vec;
        else
            analysis_mask = intersection_mask&~bad_data_mask&~isnan(data)&~below_bot_mask&~bad_trans_vec;
        end
        idx_r_sub = find(any(analysis_mask,2));

        if isempty(idx_r_sub)||isempty(idx_ping)
            return;
        end

        idx_r  = idx_r(idx_r_sub);
        range_tr=trans_obj.get_samples_range(idx_r);
        pings=trans_obj.get_transceiver_pings(idx_ping);
        analysis_mask = analysis_mask(idx_r_sub,:);
        ip_proc = find(sum(analysis_mask,1));
         pings = pings(ip_proc);

        %data(:,bad_trans_vec|empty_data)=[];
        if isempty(pings)
            return;
        end

        [~,~]=trans_obj.get_pulse_length(1);
        
        if ~isempty(p.Results.load_bar_comp)
            set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(pings),'Value',0);
        end
        
        if p.Results.sliced_output>0
            output_size='3D';
            cell_h=p.Results.sliced_output;
        else
            output_size=p.Results.output_size;
            cell_h=0;
        end
        
         

         Sv_f_cell = cell(1,length(ip_proc));
         r_cell = cell(1,length(ip_proc));
         f_vec_cell = cell(1,length(ip_proc));

         
         for ip=1:length(ip_proc)
             if ~isempty(p.Results.load_bar_comp)
                 set(p.Results.load_bar_comp.progress_bar ,'Value',ip);
             end
             [Sv_f_cell{ip},f_vec_cell{ip},r_cell{ip}] = ...
                 trans_obj.processSv_f_r_2(p.Results.envdata,pings(ip),range_tr(analysis_mask(:,ip_proc(ip))),p.Results.win_fact,p.Results.cal,output_size,cell_h);
         end

         %r_cell = cellfun(@(x) cell_h*round(x/cell_h),r_cell,'UniformOutput',false);
        dr_cell  = cellfun(@diff,r_cell,'UniformOutput',false);
        dr = mean(cellfun(@mean,dr_cell),"all","omitnan");
        r_tot = (min(cellfun(@(x) min(x,[],'all','omitnan'),r_cell),[],'all','omitnan'):dr:max(cellfun(@(x) max(x,[],'all','omitnan'),r_cell),[],'all','omitnan'))';
        [~,idx_f] = max(cellfun(@numel,f_vec_cell));
        f_vec = f_vec_cell{idx_f};

        Sv_f=nan(length(ip_proc),length(r_tot),length(f_vec));
        r_tot_mat = repmat(r_tot,1,numel(f_vec));
        f_vec_mat = repmat(f_vec,numel(r_tot),1);
        
        if ~isempty(p.Results.load_bar_comp)
            p.Results.load_bar_comp.progress_bar.setText(sprintf('Interpolating Sv(f) estimation at %.0fkHz',trans_obj.Config.Frequency/1e3));

            set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(Sv_f_cell),'Value',0);
        end
        
        for uip = 1:numel(Sv_f_cell)
            if ~isempty(p.Results.load_bar_comp)
                set(p.Results.load_bar_comp.progress_bar ,'Value',uip);
            end
            if numel(r_cell{uip})>1
                f_tmp = repmat(f_vec_cell{uip},numel(r_cell{uip}),1);
                r_tmp = repmat(r_cell{uip},1,numel(f_vec_cell{uip}));
                F = scatteredInterpolant(r_tmp(:),f_tmp(:),double(db2pow(Sv_f_cell{uip}(:))),'linear','none');
                sv_tmp = F(r_tot_mat,f_vec_mat);
                if ~isempty(sv_tmp)
                    Sv_f(uip,:,:) = pow2db(sv_tmp);
                end
            else
                [~,idx_r_r] = min(abs(r_cell{uip}-r_tot));
                F = griddedInterpolant(f_vec_cell{uip},double(db2pow(Sv_f_cell{uip})),'linear','none');
                sv_tmp = F(f_vec);
                if ~isempty(sv_tmp)
                    Sv_f(uip,idx_r_r,:) = pow2db(sv_tmp);
                end
            end

        end

     
         
    case 'CW'
        output_reg=trans_obj.integrate_region(reg_obj,'keep_bottom',0,'keep_all',0);
        
        if isempty(output_reg)
            return;
        end
        pings=round((output_reg.Ping_S+output_reg.Ping_E)/2);
        r_tot=trans_obj.get_samples_range(ceil(mean((output_reg.Sample_S+output_reg.Sample_E)/2,2,"omitnan")));
        f_vec=trans_obj.get_params_value('Frequency',pings(1));
        Sv_f=nan(length(pings),length(r_tot),length(f_vec));
        Sv_f(:,:,1)=pow2db_perso(output_reg.sv');        
end


end
