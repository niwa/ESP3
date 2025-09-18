function clean_bottom(trans_obj,varargin)

p  =  inputParser;
nb_beams = max(trans_obj.Data.Nb_beams,[],'omitnan');
idx_beam_def =  1:nb_beams;
addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addParameter(p,'idx_ping',trans_obj.get_transceiver_pings(),@isnumeric);
addParameter(p,'idx_beam',idx_beam_def,@isnumeric);
addParameter(p,'idx_r',trans_obj.get_transceiver_samples(),@isnumeric);
addParameter(p,'interp_method','none');
addParameter(p,'rm_outliers_method','none');

parse(p,trans_obj,varargin{:});


if ~any(~strcmpi({p.Results.rm_outliers_method,p.Results.interp_method},'none')) || trans_obj.ismb
    return;
end

bot_idx = trans_obj.get_bottom_idx(p.Results.idx_ping);

if size(bot_idx,3)>1
    bot_idx = squeeze(bot_idx)';
end

[data_struct,~] = trans_obj.get_xxx_ENH('idx_r',p.Results.idx_r,'idx_ping',p.Results.idx_ping,'idx_beam',p.Results.idx_beam,'data_to_pos',{'bottom'});
data_struct = data_struct.bottom;
X = repmat(data_struct.Time,1,1,nb_beams);
Y = trans_obj.get_params_value('BeamAngleAthwartship',p.Results.idx_ping,p.Results.idx_beam);
Z = data_struct.Range;

if size(bot_idx,1)>1
    X = squeeze(X)';
    Y = squeeze(Y)';
    Z = squeeze(Z)';
    %res = sqrt((range(X(:))*range(Y(:))/numel(X)*10));
    %[xgrid,ygrid] = meshgrid(min(X,[],'all'):res:max(X,[],'all'),min(Y,[],'all'):res:max(Y,[],'all'));

else
    %res = range(X(:))/numel(X)*10;
    %xgrid = min(X,[],'all'):res:max(X,[],'all');
end
%


switch lower(p.Results.rm_outliers_method)
    case 'none'

    otherwise
        if sum(~isnan(bot_idx),'all')>=2

            [xData, yData, zData] = prepareSurfaceData(X,Y,Z);
  
            switch size(bot_idx,1)
                case 1
                    [fitresult, ~] = fit(xData, zData,'smoothingspline' );
                    Z_filtered = fitresult(X)';
                otherwise
                    [fitresult, ~] = fit([xData, yData],zData,'cubicinterp');
                    Z_filtered = fitresult(X,Y);
            end

            for uib = 1:size(X,1)
                [~,is_outlier] = rmoutliers(Z(uib,:)-Z_filtered(uib,:),lower(p.Results.rm_outliers_method));
                bot_idx(uib,is_outlier) = nan;
            end
        end
end

% X = repmat(p.Results.idx_ping,size(bot_idx,1),1);

Z = mean(bot_idx,1,'omitnan');

switch lower(p.Results.interp_method)
    case 'none'

    otherwise
        if sum(~isnan(bot_idx),"all")>=2
            id_start = find(diff(Z>0)<0);
            id_end = find(diff(Z>0)>0);
            
            if ~isempty(id_start) && isempty(id_end)
                id_end = numel(bot_idx);
            end

            if ~isempty(id_start)

                if id_start(1)>id_end(1)
                    id_start = [1 id_start(:)'];
                end

                if id_start(end)>id_end(end)
                    id_end = [id_end(:)' numel(bot_idx)];
                end


                switch size(bot_idx,1)
                    case 1
                        bot_idx=fillmissing(bot_idx,lower(p.Results.interp_method));
                    otherwise
                        bot_idx=fillmissing2(bot_idx,lower(p.Results.interp_method));
                end


                bot_idx=ceil(bot_idx);
                for uil  = 1:numel(id_start)
                    if id_end(uil)-id_start(uil)>10
                        bot_idx(:,id_start(uil):id_end(uil))= nan;
                    end
                end
            end
        end
end

old_tag = trans_obj.Bottom.Tag;
old_bot = trans_obj.Bottom.Sample_idx;
old_bot(:,p.Results.idx_ping) = bot_idx;

new_bot = bottom_cl('Origin',trans_obj.Bottom.Origin,...
    'Sample_idx',old_bot,...
    'Tag',old_tag);

trans_obj.Bottom = new_bot;
