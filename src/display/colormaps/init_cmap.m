function cmap_struct =init_cmap(cmap_name,varargin)

cmap_folder=fullfile(whereisEcho,'private','cmaps');
cmap_struct.cmap=[];
cmap_struct.cmap_name = cmap_name;
if isfile(fullfile(cmap_folder,[cmap_struct.cmap_name '.cpt']))
    try
        [cmap_struct.cmap, ~, ~, bfncol, ~]=cpt_to_cmap(fullfile(cmap_folder,[cmap_struct.cmap_name '.cpt'])); 
        B=bfncol(1,:);
        F=bfncol(2,:);
        N=bfncol(3,:);
    catch err
        print_errors_and_warnings([],'error',err);
        fprintf('Could not read colormap file: %s\n',fullfile(cmap_folder,[cmap_struct.cmap_name '.cpt']));
    end
end

if isempty(cmap_struct.cmap)
    cmap_struct.cmap=colormap('Parula');
    B=[1 1 1];
    N=[1 1 1];
    F=[0 0 0];    
end

cmap_struct.col_ax=B;
cmap_struct.col_grid=F;
cmap_struct.col_txt=F;
cmap_struct.col_lab=F;
cmap_struct.col_bot=F;

if nargin >= 2
    if strcmpi(varargin{1},'on')
        cmap_struct.cmap = flipud(cmap_struct.cmap);
        cmap_struct.col_ax = 1-cmap_struct.col_ax;
        cmap_struct.col_grid = 1-cmap_struct.col_grid;
        cmap_struct.col_txt = 1-cmap_struct.col_txt;
        cmap_struct.col_lab = 1-cmap_struct.col_lab;
        cmap_struct.col_bot = 1-cmap_struct.col_bot;
    end
end

switch cmap_name
    case 'beer-lager'
        cmap_struct.cmap  =flipud (cmap_struct.cmap);
end

sc=size(cmap_struct.cmap,1);

idx_t=max(floor(sc*9/10),1);

cmap_struct.col_tracks=cmap_struct.cmap(min(idx_t,sc),:);


end