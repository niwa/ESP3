function reg_wc = create_WC_region(trans_obj,varargin)

%% input parser
p = inputParser;

check_w_unit = @(unit) ~isempty(strcmpi(unit,{'pings','meters'}));
check_h_unit = @(unit) ~isempty(strcmpi(unit,{'meters'}));
check_ref = @(ref) ~isempty(strcmpi(ref,list_echo_int_ref));
check_dataType = @(data) ~isempty(strcmpi(data,{'Data','Bad Data'}));

addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addParameter(p,'y_min',-inf,@isnumeric)
addParameter(p,'y_max',inf,@isnumeric)
addParameter(p,'t_min',0,@isnumeric)
addParameter(p,'t_max',inf,@isnumeric)
addParameter(p,'idx_beam',1,@isnumeric)
addParameter(p,'Type','Data',check_dataType);
addParameter(p,'Ref','Surface',check_ref);
addParameter(p,'Cell_w',10,@isnumeric);
addParameter(p,'Cell_h',10,@isnumeric);
addParameter(p,'Cell_w_unit','pings',check_w_unit);
addParameter(p,'Cell_h_unit','meters',check_h_unit);
addParameter(p,'Remove_ST',0,@(x) isnumeric(x)||islogical(x));
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));

parse(p,trans_obj,varargin{:});

block_len = get_block_len(50,'cpu',p.Results.block_len);

%% cell width
switch p.Results.Cell_w_unit
    case 'pings'
        cell_w = p.Results.Cell_w;
        cell_w_units = 'pings';
    case 'meters'
        if ~isempty(trans_obj.GPSDataPing.Dist)
            cell_w = p.Results.Cell_w;
            cell_w_units = 'meters';
        else
            cell_w_units = 'pings';
            cell_w = p.Results.Cell_w;
        end
    case 'seconds'
        cell_w_units = 'seconds';
        cell_w = p.Results.Cell_w;
        
    otherwise
        warning('Vertical slice unit %s not recognized, treating that as an WC region based on pings...',p.Results.Cell_w_unit);
        cell_w = p.Results.Cell_w;
        cell_w_units = 'pings';
end

bot_data = trans_obj.get_bottom_range();

%% ?
time_t = trans_obj.get_transceiver_time();
rr = trans_obj.get_samples_range();
idx_ping = find( time_t >= p.Results.t_min & time_t <= p.Results.t_max );
bot_data(trans_obj.get_bottom_idx() == numel(rr)) = nan;
bot_data = bot_data(idx_ping);
nb_pings = length(bot_data);
name = 'WC';
%% region reference
shape= 'Rectangular';

y_min=p.Results.y_min;
y_max=p.Results.y_max;

switch lower(p.Results.Ref)
    case 'transducer'
        ydata = rr;
    case 'surface'
        ydata = trans_obj.get_samples_depth([],idx_ping,p.Results.idx_beam);
        shape='Polygon';
    case 'bottom'
        shape='Polygon';
        ydata = trans_obj.get_samples_range() - trans_obj.get_bottom_range(idx_ping,p.Results.idx_beam);
        y_max = -p.Results.y_min;
        y_min = -p.Results.y_max;
    otherwise
        warning('Reference %s not recognized, treating that as transducer based WC region...',p.Results.Ref);
end


switch shape
    
    case 'Rectangular'
         idx_r_min = find(ydata >= y_min,1,'first');
        
        idxBad = trans_obj.Bottom.Tag(idx_ping) == 0;

        if all(~isnan(bot_data(~idxBad)))
            [~,idx_r_max] = min(abs(ydata-(max(bot_data+p.Results.Cell_h,[],"all","omitnan"))),[],"all","omitnan");
        else
            idx_r_max = length(ydata);
        end
        
        if p.Results.y_max ~= Inf
            idx_r_y_max = find(ydata<=y_max,1,'last');
            idx_r_max   = min(idx_r_max,idx_r_y_max);
        end
        mask = [];
        idx_r = idx_r_min:idx_r_max;
        
    case 'Polygon'
        
        mask = false(size(ydata,1),nb_pings);
        block_size = ceil(block_len/numel(ydata));
        num_ite = ceil(nb_pings/block_size);
        
        for ui = 1:num_ite
            idx_ping_red = ((ui-1)*block_size+1:min(ui*block_size,nb_pings));
            mask(:,idx_ping_red) = ydata(:,idx_ping_red) <= y_max & ydata(:,idx_ping_red) >= y_min;
        end
        
        idx_r = find(sum(mask,2)>0,1,'first'):find(sum(mask,2)>0,1,'last');
        mask = mask(idx_r,:);
        
end

if isempty(idx_r)||isempty(idx_ping)
    reg_wc = [];
else
    reg_wc = region_cl(...
        'ID',trans_obj.new_id(),...
        'Shape',shape,...
        'MaskReg',mask,...
        'Name',name,...
        'Type',p.Results.Type,...
        'Idx_ping',idx_ping,...
        'Idx_r',idx_r,...
        'Reference',p.Results.Ref,...
        'Cell_w',cell_w,...
        'Cell_w_unit',cell_w_units,...
        'Cell_h',p.Results.Cell_h,...
        'Cell_h_unit',p.Results.Cell_h_unit,...
        'Remove_ST',p.Results.Remove_ST);
end

end
