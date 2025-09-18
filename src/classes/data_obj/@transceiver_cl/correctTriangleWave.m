function correctTriangleWave(trans_obj,varargin)

p = inputParser;

addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addParameter(p,'EsOffset',[]);
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
addParameter(p,'load_bar_comp',[]);

parse(p,trans_obj,varargin{:});

range=trans_obj.get_samples_range();
pings=trans_obj.get_transceiver_pings();

nb_samples=numel(range);
nb_pings=numel(pings);
block_len = get_block_len(50,'cpu',p.Results.block_len);
bsize=ceil(block_len/nb_samples);

if nb_pings>=ceil(2721/2)
    bsize=max(bsize,ceil(2721/2));
else
    bsize=max(bsize,nb_pings);
end
mean_err=p.Results.EsOffset;

if isempty(mean_err)||isnan(mean_err)||~isnumeric(mean_err)
    mean_err=trans_obj.Config.EsOffset;
end

u=0;
% initialize progress bar
if ~isempty(p.Results.load_bar_comp)
    p.Results.load_bar_comp.progress_bar.setText('Correcting Triangle wave error');
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',ceil(nb_pings/bsize), 'Value',0);
end

while u<ceil(nb_pings/bsize)
    
    idx_ping=(u*bsize+1):min(((u+1)*bsize),nb_pings);
    
    u=u+1;
    
    idx_ping_next=(u*bsize+1):min(((u+1)*bsize),nb_pings);
    if ~isempty(idx_ping_next)
        if idx_ping_next(end)==nb_pings
            idx_ping=union(idx_ping,idx_ping_next);
            u=u+1;
        end
    end
    power=trans_obj.Data.get_subdatamat('idx_r',1:nb_samples,'idx_ping',idx_ping,'field','power');
    
    [power_corr_db,mean_err]=correctES60(10*log10(power),mean_err,u-1);
    
    if mean_err~=0
        trans_obj.Data.replace_sub_data_v2(10.^(power_corr_db/10),'power','idx_ping',idx_ping);
    end
    trans_obj.Config.EsOffset=mean_err;
    if ~isempty(p.Results.load_bar_comp)
    
    set(p.Results.load_bar_comp.progress_bar,'Value',u);
    end
end
if ~isempty(p.Results.load_bar_comp)
    p.Results.load_bar_comp.progress_bar.setText('');
end


end