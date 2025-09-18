function ClusterID = data_3D_clustering(x,y,z,varargin)

p = inputParser;
addRequired(p,'x',@isnumeric);
addRequired(p,'y',@isnumeric);
addRequired(p,'z',@isnumeric);
addParameter(p,'Gx',10,@(x) x>0);
addParameter(p,'Gy',10,@(x) x>0);
addParameter(p,'Gz',10,@(x) x>0);
addParameter(p,'N_3D',20,@(x) x>0);
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
addParameter(p,'load_bar_comp',[]);

parse(p,x,y,z,varargin{:});
block_len = ceil(get_block_len(10,'cpu',p.Results.block_len)/10);

num_ite = ceil(numel(x)/block_len);

if ~isempty(p.Results.load_bar_comp)
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
    p.Results.load_bar_comp.progress_bar.setText('3D clustering...');
end

y = y*p.Results.Gx/p.Results.Gy;
z = z*p.Results.Gx/p.Results.Gz;

dx = 3*p.Results.Gx;
x_vec = linspace(min(x(:)),max(x(:))+dx,num_ite+1);
ClusterID = [];
id_init = 0;

for uit = 1:num_ite
    idx_keep = x>=x_vec(uit)& x<=x_vec(uit+1)+dx;
    loc1 = [x(idx_keep)',y(idx_keep)',z(idx_keep)'];
    ptCloud = pointCloud(loc1);
    [ClusterID_tmp,~] = pcsegdist(ptCloud,p.Results.Gx,"NumClusterPoints",[p.Results.N_3D inf]);
    ClusterID_tmp(ClusterID_tmp>0) = ClusterID_tmp(ClusterID_tmp>0)+id_init;
    
    idx_overlap_next = x(idx_keep)>=x_vec(uit+1)& x(idx_keep)<=x_vec(uit+1)+dx;

    idx_merge = x(idx_keep)>=x_vec(uit) & x(idx_keep)<x_vec(uit+1);

    if id_init>0
        idx_overlap_previous = x(idx_keep)>=x_vec(uit)& x(idx_keep)<=x_vec(uit)+dx;

        ClusterID_overlap_new = ClusterID_tmp(idx_overlap_previous);

        Ids_new = unique(ClusterID_overlap_new);
        Ids_new(Ids_new == 0) = [];

        for uid = 1:numel(Ids_new)
            idx_id = ClusterID_overlap_new == Ids_new(uid);
            id_tmp = unique(ClusterID_overlap(idx_id));
            id_tmp(id_tmp==0) = [];
            nb_val = 0;
            for uidd = 1:numel(id_tmp)
                tmp =sum(ClusterID_overlap == id_tmp(uidd));
                if tmp>nb_val
                    nb_val = tmp;
                    ClusterID_tmp(ClusterID_tmp == Ids_new(uid)) = id_tmp(uidd);
                end
            end
        end

    end
    
    ClusterID = [ClusterID;ClusterID_tmp(idx_merge)];
    id_init = max(ClusterID);
    ClusterID_overlap = ClusterID_tmp(idx_overlap_next);
    if ~isempty(p.Results.load_bar_comp)
        set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',uit);
    end
end

