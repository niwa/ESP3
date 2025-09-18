function [data,field] = get_data_to_process(trans_obj,varargin)
p = inputParser;



% adding to parser
addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addParameter(p,'field','sp',@ischar);
addParameter(p,'alt_fields',{'sv','img_intensity'},@iscell);
addParameter(p,'idx_r',[],@isnumeric);
addParameter(p,'idx_ping',[],@isnumeric);
addParameter(p,'idx_beam',[],@isnumeric);
% and parse
parse(p,trans_obj,varargin{:});
field = p.Results.field;

%field_ori = field;
data = trans_obj.Data.get_subdatamat('idx_r',p.Results.idx_r,'idx_ping',p.Results.idx_ping,'idx_beam',p.Results.idx_beam,'field',field);

if isempty(data)
    for ifi = 1:numel(p.Results.alt_fields)
        field = p.Results.alt_fields{ifi};

        data = trans_obj.Data.get_subdatamat('idx_r',p.Results.idx_r,'idx_ping',p.Results.idx_ping,'idx_beam',p.Results.idx_beam,'field',field);

        if strcmpi(field,'img_intensity')
            data_min = min(data,[],'all','omitnan');
            data_max = max(data,[],'all','omitnan');
            dyn_db = 90;
            db_min = -80;

            data_range = range(data,'all')/data_max;
            idx_null = data == data_min;
            dyn = dyn_db*data_range;
            data = (data/data_max)*dyn+db_min;
            data(idx_null) = nan;
            field = 'BS';
        end

        if ~isempty(data)
            return;
        end
    end
end