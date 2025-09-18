function output_3D = echo_integrate_3D(trans_obj,varargin)
p = inputParser;

addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addParameter(p,'line_obj',[],@(x) isa(x,'line_cl')||isempty(x));
addParameter(p,'depthBounds',[-inf inf],@isnumeric);
addParameter(p,'rangeBounds',[-inf inf],@isnumeric);
addParameter(p,'refRangeBounds',[-inf inf],@isnumeric);
addParameter(p,'BeamAngularLimit',[-inf inf],@isnumeric);
addParameter(p,'timeBounds',[0 inf],@isnumeric);
addParameter(p,'denoised',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'ref','Surface',@(ref) ~isempty(strcmpi(ref,list_echo_int_ref)));
addParameter(p,'field','sv',@ischar);
addParameter(p,'vert_res',10,@isnumeric);
addParameter(p,'horz_res',10,@isnumeric);
addParameter(p,'along_res',10,@isnumeric);
addParameter(p,'across_res',10,@isnumeric);
addParameter(p,'sv_thr',-999,@isnumeric);
addParameter(p,'output_grid_ref','ship',@(x) ismember(x,{'ship','geo'}));
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
addParameter(p,'load_bar_comp',[]);

parse(p,trans_obj,varargin{:});
output_3D = [];

block_len= p.Results.block_len;
if isempty(block_len)
    block_len = get_block_len(50,'cpu',p.Results.block_len);
end

if any([p.Results.horz_res p.Results.vert_res]<=0)
    print_errors_and_warnings([],'Warning','Invalid resolution for 3D echo-integration');
    return;
end

field = p.Results.field;

switch field
    case {'sv' 'svdenoised'}
        if p.Results.denoised>0
            field='svdenoised';
            if ~ismember('svdenoised',trans_obj.Data.Fieldname)
                field='sv';
            end
        end
        [~,found]=trans_obj.Data.find_field_idx(field);
        if ~found
            return;
        end

    case 'features'
        if isempty(trans_obj.Features)
            return;
        end
end

idx_beam = trans_obj.get_idx_beams(p.Results.BeamAngularLimit);
idx_r_init = trans_obj.get_transceiver_samples();
idx_ping_init = trans_obj.get_transceiver_pings();

reg_obj = region_cl('Name','Temp','Reference',p.Results.ref,'Idx_r',idx_r_init,'Idx_ping',idx_ping_init,...
    'Cell_w',p.Results.horz_res,'Cell_h',p.Results.vert_res);

[idx_r_tot,idx_ping_tot,~] = trans_obj.get_idx_r_idx_ping(reg_obj,...
    'idx_beam',idx_beam,...
    'timeBounds',p.Results.timeBounds,...
    'rangeBounds',p.Results.rangeBounds,...
    'refRangeBounds',p.Results.refRangeBounds,...
    'depthBounds',p.Results.depthBounds,...
    'timeBounds',p.Results.timeBounds);


[data_struct,~] = trans_obj.get_xxx_ENH('data_to_pos',{'bottom'},'idx_beam',idx_beam);
data_struct_bot = data_struct.bottom;

switch p.Results.output_grid_ref
    case 'geo'
        data_bot_struct.x = data_struct_bot.E(:)';
        data_bot_struct.y = data_struct_bot.N(:)';
        data_bot_struct.H = data_struct_bot.H(:)';
        dx = p.Results.horz_res;
        dy = p.Results.horz_res;
    case 'ship'
        data_bot_struct.x = data_struct_bot.AlongDist(:)';
        data_bot_struct.y = data_struct_bot.AcrossDist(:)';
        data_bot_struct.H = data_struct_bot.H(:)';
        dx = p.Results.along_res;
        dy = p.Results.across_res;
end
dz = p.Results.vert_res;

switch field
    case 'features'
        num_ite = 1;
        block_size = numel(idx_ping_tot);
        out_lim = trans_obj.Features.get_lim('Idx_ping',idx_ping_tot,'Idx_r',idx_r_tot,'Idx_beam',idx_beam);
        if isempty(out_lim.E)
            return;
        end
        switch p.Results.output_grid_ref
            case 'geo'
                x_lim = out_lim.E;
                y_lim = out_lim.N;
            case 'ship'
                x_lim = out_lim.Alongdist;
                y_lim = out_lim.Acrossdist;
        end

        switch lower(p.Results.ref)
            case 'bottom'
                z_lim = [-max(data_bot_struct.H,[],"all","omitmissing") 0];
            case 'surface'
                z_lim = out_lim.H;
            case 'transducer'
                z_lim = out_lim.H;
        end

    otherwise
        block_size=min(ceil(block_len/(numel(idx_r_tot)*numel(idx_beam))),numel(idx_ping_tot),'omitnan');

        num_ite=ceil(numel(idx_ping_tot)/block_size);
        x_lim = [nan nan];
        y_lim = [nan nan];
        z_lim = [nan nan];


        for ui = 1:num_ite
            idx_ping=idx_ping_tot((ui-1)*block_size+1:min(ui*block_size,numel(idx_ping_tot)));
            [~,sub_idx_ping]=intersect(idx_ping_tot,idx_ping);
            
            [data_struct,~]= trans_obj.get_xxx_ENH('data_to_pos',{'WC'},...
                'idx_ping',sub_idx_ping,'idx_r',[idx_r_tot(1) idx_r_tot(end)],'idx_beam',idx_beam,...
                'comp_angle',[false false]);
            data_struct_wc  = data_struct.WC;
            switch p.Results.output_grid_ref
                case 'geo'
                    x_lim(1) = min(min(data_struct_wc.E(:)),x_lim(1),"omitmissing");
                    x_lim(2) = max(max(data_struct_wc.E(:)),x_lim(2),"omitmissing");
                    y_lim(1) = min(min(data_struct_wc.N(:)),y_lim(1),"omitmissing");
                    y_lim(2) = max(max(data_struct_wc.N(:)),y_lim(2),"omitmissing");
                case 'ship'
                    y_lim(1) = min(min(data_struct_wc.AcrossDist(:)),y_lim(1),"omitmissing");
                    y_lim(2) = max(max(data_struct_wc.AcrossDist(:)),y_lim(2),"omitmissing");
                    x_lim(1) = min(min(data_struct_wc.AlongDist(:)),x_lim(1),"omitmissing");
                    x_lim(2) = max(max(data_struct_wc.AlongDist(:)),x_lim(2),"omitmissing");
            end
            
            switch lower(p.Results.ref)
                case 'bottom'
                    z_lim = [-max(data_bot_struct.H,[],"all","omitmissing") 0];
                case 'surface'
                    z_lim(1) = min(min(data_struct_wc.H(:)),z_lim(1),"omitmissing");
                    z_lim(2) = max(max(data_struct_wc.H(:)),z_lim(2),"omitmissing");
                case 'transducer'
                    z_lim(1) = min(min(data_struct_wc.Range(:)),z_lim(1),"omitmissing");
                    z_lim(2) = max(max(data_struct_wc.Range(:)),z_lim(2),"omitmissing");
            end



        end
end

    x_ori = min(x_lim,[],'all','omitnan');
    y_ori = min(y_lim,[],'all','omitnan');
    z_ori = min(z_lim,[],'all','omitnan');

    N_x = ceil(range(x_lim)/dx);
    x_vec = (0:N_x-1)*dx+x_ori;
    N_y = ceil(range(y_lim)/dy);
    y_vec = (0:N_y-1)*dy+y_ori;
    N_z = ceil(range(z_lim)/dz);
    z_vec = (0:N_z-1)*dz+z_ori;


[output_3D.x,output_3D.y,output_3D.z] = meshgrid(x_vec,y_vec,z_vec);
output_3D.sv = zeros(size(output_3D.x));
%output_3D.stdSv = nan(size(data_grid.x));
output_3D.H = nan(size(output_3D.x));
output_3D.nb_samples = zeros(size(output_3D.x));
output_3D.E = nan(size(output_3D.x));
output_3D.N = nan(size(output_3D.x));
output_3D.AcrossDist = nan(size(output_3D.x));
output_3D.AlongDist = nan(size(output_3D.x));
output_3D.Zone = nan(size(output_3D.x));
output_3D.Idx_ping = nan(size(output_3D.x));

% [data_bot_grid.x,data_bot_grid.y] = meshgrid(x_vec,y_vec);
% data_bot_grid = grid_data(data_bot_struct,data_bot_grid_ENH,dx,dy,dz);


% switch region.Reference
%     case 'Surface'
%         depth_transd = trans_obj.get_transducer_depth(idx_ping_tot);
%         line_ref = -repmat(depth_transd,1,1,numel(idx_beam));
%     case 'Transducer'
%         line_ref = zeros(1,numel(idx_ping_tot),numel(idx_beam));
%     case 'Bottom'
%         line_ref = trans_obj.get_bottom_depth(idx_ping_tot,idx_beam);
% end

load_bar_comp=p.Results.load_bar_comp;
if ~isempty(load_bar_comp)
    load_bar_comp.progress_bar.setText(sprintf('3D Echo-Integrating %s',trans_obj.Config.ChannelID));
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
end

for ui = 1:num_ite
    idx_ping_tmp=idx_ping_tot((ui-1)*block_size+1:min(ui*block_size,numel(idx_ping_tot)));
    [~,sub_idx_ping]=intersect(idx_ping_tot,idx_ping_tmp);


    switch field
        case 'features'

            data.Sv =  [trans_obj.Features(:).Sv];
            switch p.Results.output_grid_ref
                case 'geo'
                    data.x = [trans_obj.Features(:).E];
                    data.y = [trans_obj.Features(:).N];

                case 'ship'
                    data.x = [trans_obj.Features(:).Alongdist];
                    data.y = [trans_obj.Features(:).Acrossdist];
            end
            
            data.E = [trans_obj.Features(:).E];
            data.N = [trans_obj.Features(:).N];
            data.AlongDist = [trans_obj.Features(:).Alongdist];
            data.AcrossDist = [trans_obj.Features(:).Acrossdist];
            data.H = [trans_obj.Features(:).H];
            data.Time = [trans_obj.Features(:).Time];
            data.Idx_r = [trans_obj.Features(:).Idx_r];
            data.Idx_ping = [trans_obj.Features(:).Idx_ping];
            data.Idx_beam = [trans_obj.Features(:).Idx_beam];
            data.Zone = [trans_obj.Features(:).Zone];
            data.Range = trans_obj.get_samples_range(data.Idx_r)';

        otherwise


            reg_obj = region_cl('Name','Temp','Reference',p.Results.ref,'Idx_r',idx_r_tot,'Idx_ping',sub_idx_ping,...
                'Cell_w',p.Results.horz_res,'Cell_h',p.Results.vert_res);

            [Sv,idx_r,idx_ping,idx_beam,bad_data_mask,bad_trans_vec,intersection_mask,below_bot_mask,mask_from_st] = get_data_from_region(trans_obj,reg_obj,...
                'field',field,...
                'timeBounds',p.Results.timeBounds,...
                'depthBounds',p.Results.depthBounds,...
                'BeamAngularLimit',p.Results.BeamAngularLimit,...
                'rangeBounds',[min(p.Results.rangeBounds) min(max(p.Results.rangeBounds),trans_obj.get_samples_range(idx_r_tot(end)),'omitnan')],...
                'refRangeBounds',p.Results.refRangeBounds);

            Mask_reg = true(size(Sv));
            Mask_reg(:,bad_trans_vec,:) = false;

            Sv(Sv<p.Results.sv_thr) = -999;

            if numel(size(Sv))>2
                Sv(bad_data_mask,:) = nan;
            else
                Sv(bad_data_mask) = nan;
            end

            Sv(~Mask_reg) = nan;
            Sv(below_bot_mask) = nan;
            det_mask = ~isnan(Sv);
            [data_struct,no_nav] = trans_obj.get_xxx_ENH('data_to_pos',{'WC'},...
                'idx_ping',idx_ping,'idx_r',idx_r,'idx_beam',idx_beam,...
                'detection_mask',det_mask,...
                'comp_angle',[false false]);
            data = data_struct.WC;
             
            if no_nav
                continue;
            end

            Sv(~det_mask) = [];
            data.Sv =  Sv;

            switch p.Results.output_grid_ref
                case 'geo'
                    data.x = data.E;
                    data.y = data.N;
                case 'ship'
                    data.x = data.AlongDist;
                    data.y = data.AcrossDist;
            end
    end
    data = compute_z_values(data,lower(p.Results.ref),data_bot_struct);

    idx_rem = ~ismember(data.Idx_ping,idx_ping_tot) | ~ismember(data.Idx_r,idx_r_tot) | ...
        data.H>max(p.Results.depthBounds)| data.H<min(p.Results.depthBounds) | ...
        data.Range>max(p.Results.rangeBounds)| data.Range<min(p.Results.rangeBounds) | ...
        data.z>max(p.Results.refRangeBounds)| data.z<min(p.Results.refRangeBounds)|...
        data.Time>max(p.Results.timeBounds)| data.Time<min(p.Results.timeBounds)|...
        data.Sv<p.Results.sv_thr|...
        ~ismember(data.Idx_beam,idx_beam);

    ff = fieldnames(data);
    for uif = 1:numel(ff)
        data.(ff{uif})(idx_rem) = [];
    end

    output_3D = grid_data(data,output_3D,dx,dy,dz);

    switch p.Results.output_grid_ref
        case 'geo'
            output_3D.E = output_3D.x;
            output_3D.N = output_3D.y;
        case 'ship'
            output_3D.AlongDist = output_3D.x;
            output_3D.AcrossDist = output_3D.y;
    end
    [lat_tmp,lon_tmp] = utm2ll(output_3D.E(~isnan(output_3D.Zone)),output_3D.N(~isnan(output_3D.Zone)),output_3D.Zone(~isnan(output_3D.Zone)));
    output_3D.Lat = nan(size(output_3D.AcrossDist));
    output_3D.Lon = nan(size(output_3D.AcrossDist));
    output_3D.Lat(~isnan(output_3D.Zone)) = lat_tmp;
    output_3D.Lon(~isnan(output_3D.Zone)) = lon_tmp;
    
    if ~isempty(load_bar_comp)
        set(load_bar_comp.progress_bar,'Value',ui);
    end
end

end

function data = compute_z_values(data,reference,bot_data)

switch lower(reference)
    case 'bottom'
        bot_data = clean_data(bot_data);
        F = scatteredInterpolant(bot_data.x(:),bot_data.y(:),bot_data.H(:),'nearest');
        tmp  = F(data.x,data.y);
        data.z  = data.H - tmp;
        data.z(data.z>=0) = nan;
    case 'surface'
        data.z = data.H;
    case 'transducer'
        data.z = data.Range;
end
end

function data = clean_data(data)

ff = fieldnames(data);
idx_rem = false(size(data.(ff{1})));
for uif = 1:numel(ff)
     idx_rem = idx_rem |isnan(data.(ff{uif})) | isinf(data.(ff{uif}));
end

for uif = 1:numel(ff)
    data.(ff{uif})(idx_rem) = [];
end
end


function data_grid = grid_data(data,data_grid,x_res,y_res,z_res)

data = clean_data(data);

x_idx = floor((data.x-min(data_grid.x,[],"all"))/x_res)+1;
y_idx = floor((data.y-min(data_grid.y,[],"all"))/y_res)+1;

if isfield(data,'z')
    z_idx = floor((data.z-min(data_grid.z,[],"all"))/z_res)+1;
else
    z_idx = ones(size(x_idx));
end

% first index
idx_x_start = min(x_idx);
idx_y_start = min(y_idx);
idx_z_start = min(z_idx);

% data indices in temp mosaic (mosaic just for this file)
x_idx = x_idx - min(x_idx) + 1;
y_idx = y_idx - min(y_idx) + 1;
z_idx = z_idx - min(z_idx) + 1;

% size of temp mosaic
N_x = max(x_idx);
N_y = max(y_idx);
N_z = max(z_idx);
x_idx_out = idx_x_start: idx_x_start + N_x -1;
y_idx_out = idx_y_start: idx_y_start + N_y -1;
z_idx_out = idx_z_start: idx_z_start + N_z -1;

subs = single([y_idx' x_idx' z_idx']); % indices in the temp grid of each data point
sz   = single([N_y N_x N_z]);     % size of ouptut

if isfield(data,'Sv')
    sv_mean = accumarray(subs,db2pow(data.Sv'),sz,@(x) mean(x,"all","omitmissing"),0);
    nb_samples = accumarray(subs,data.Sv',sz,@numel,0);
    data_grid.sv(y_idx_out,x_idx_out,z_idx_out) = data_grid.sv(y_idx_out,x_idx_out,z_idx_out).*data_grid.nb_samples(y_idx_out,x_idx_out,z_idx_out) + sv_mean .* nb_samples;
    data_grid.nb_samples(y_idx_out,x_idx_out,z_idx_out) = data_grid.nb_samples(y_idx_out,x_idx_out,z_idx_out) + nb_samples;
    idx_null = nb_samples == 0;
    tmp = data_grid.sv(y_idx_out,x_idx_out,z_idx_out)./data_grid.nb_samples(y_idx_out,x_idx_out,z_idx_out);
    tmp(idx_null) = 0;
    data_grid.sv(y_idx_out,x_idx_out,z_idx_out) = tmp;
end

fields = {'E' 'N' 'AlongDist' 'AcrossDist' 'H' 'Zone' 'Idx_ping'};

for uif = 1:numel(fields)
    if isfield(data,fields{uif})
        tmp = accumarray(subs,data.(fields{uif})',sz,@(x) mean(x,"all","omitmissing"),nan);
        data_grid.(fields{uif})(y_idx_out,x_idx_out,z_idx_out) = tmp;
    end
end


end