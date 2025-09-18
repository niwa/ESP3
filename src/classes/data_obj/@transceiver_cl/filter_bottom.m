function filter_bottom(trans_obj,varargin)

% input parser
p = inputParser;
addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addParameter(p,'FilterWidth',10,@isnumeric);
parse(p,trans_obj,varargin{:});
results = p.Results;

bot_data = trans_obj.get_bottom_idx();

% filter the bottom
%bot_data_filt=round(filter2_perso(ones(1,results.FilterWidth),bot_data));
if trans_obj.ismb()
    tmp = squeeze(bot_data);
    tmp = round(filter2_perso((ones(results.FilterWidth,1)),tmp));
    bot_data_filt = tmp';
else
    idx_nonnan_start = find(~isnan(bot_data),1);
    idx_nonnan_end = find(~isnan(bot_data),1,'last');
    bot_data_filt = round(smoothdata(bot_data,'sgolay',results.FilterWidth,'omitnan'));
    
    if idx_nonnan_start>1
        bot_data_filt(1:idx_nonnan_start) = nan;
    end

    if idx_nonnan_end<numel(bot_data_filt)
        bot_data_filt(idx_nonnan_end:end) = nan;
    end
end

% create new bottom object with filtered sample_idx
new_bot = bottom_cl('Origin',trans_obj.Bottom.Origin,...
                'Sample_idx',bot_data_filt,...
                'Tag',trans_obj.Bottom.Tag);

% and record in transceiver object
trans_obj.Bottom = new_bot;


end