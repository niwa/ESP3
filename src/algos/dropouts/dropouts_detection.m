function output_struct=dropouts_detection(trans_obj,varargin)

p = inputParser;

addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));

addParameter(p,'thr_sv',-70,@isnumeric);
addParameter(p,'thr_sv_max',-35,@isnumeric);
addParameter(p,'gate_dB',3,@isnumeric);
addParameter(p,'r_max',Inf,@isnumeric);
addParameter(p,'r_min',0,@isnumeric);
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'load_bar_comp',[]);

parse(p,trans_obj,varargin{:});

output_struct.done = false;

if isempty(p.Results.reg_obj)
    idx_r=1:length(trans_obj.get_samples_range());
    idx_ping_tot=1:length(trans_obj.get_transceiver_pings());
    reg_obj=region_cl('Name','Temp','Idx_r',idx_r,'Idx_ping',idx_ping_tot);
    
else
    reg_obj=p.Results.reg_obj;
    idx_ping_tot=p.Results.reg_obj.Idx_ping;
    idx_r=p.Results.reg_obj.Idx_r;
end

range_tot = trans_obj.get_samples_range(idx_r);

if ~isempty(idx_r)
    idx_r(range_tot<p.Results.r_min|range_tot>p.Results.r_max)=[];
end

idx_noise_sector=false(1,numel(idx_ping_tot));

if isempty(idx_r)
    output_struct.idx_noise_sector=idx_noise_sector;
    return;
end

block_len = get_block_len(50,'cpu',p.Results.block_len);
block_size=min(ceil(block_len/numel(idx_r)),numel(idx_ping_tot));
num_ite=ceil(numel(idx_ping_tot)/block_size);


load_bar_comp=p.Results.load_bar_comp;
if ~isempty(p.Results.load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
end

idx_noise_sector=[];
for ui=1:num_ite
    idx_ping=idx_ping_tot((ui-1)*block_size+1:min(ui*block_size,numel(idx_ping_tot)));
    reg_temp=region_cl('Name','Temp','Idx_r',idx_r,'Idx_ping',idx_ping);
    
    [Sv,idx_r,idx_ping,~,~,bad_trans_vec,~,below_bot_mask,~]=get_data_from_region(trans_obj,reg_temp,'field','sv',...
        'intersect_only',1,...
        'regs',reg_obj);
    
    Sv(below_bot_mask|isinf(Sv))=nan;
    Sv(:,bad_trans_vec)=nan;
    Sv_mean_db=mean(Sv,1,'omitnan');
    Sv_mean_db_tot=mean(Sv_mean_db,'all','omitnan');
    
    idx_tmp=idx_ping(((Sv_mean_db<p.Results.thr_sv)&abs(Sv_mean_db-Sv_mean_db_tot)>p.Results.gate_dB));
    idx_noise_sector=union(idx_tmp,idx_noise_sector);
end

output_struct.idx_noise_sector=idx_noise_sector;
output_struct.done = true;

tag = trans_obj.Bottom.Tag;

tag(output_struct.idx_noise_sector) = 0;

trans_obj.Bottom.Tag = tag;


