function fig  = disp_transceivers_beam_configurations(layer_obj,varargin)

p = inputParser;

addRequired(p,'layer_obj',@(trans_obj) isa(layer_obj,'layer_cl'));
addParameter(p,'idx_ping',1,@isnumeric);
addParameter(p,'font','default',@ischar);

parse(p,layer_obj,varargin{:});

fig = [];

if ~any(any(layer_obj.Transceivers.ismb))
    return;
end
ip = p.Results.idx_ping;

lay_str = list_layers(layer_obj,'valid_filename',false);
lay_str = lay_str{1};
fig =new_echo_figure([],'Units','pixels','Position',[200 300 800 600],'Resize','on',...
    'Name',sprintf('Transceiver beams configurations %s',lay_str),...
    'Tag',sprintf('Transceiver beams configurations %s',lay_str),'UiFigureBool',true);

idx_mb = find(layer_obj.Transceivers.ismb);

str_y_cell = {'Frequency' 'BeamAngleAlongship' 'BeamAngleAthwartship'};
str_x_cell = {'BeamAngleAthwartship' 'BeamAngleAthwartship' 'BeamNumber'};
yfmt = {'%d\kHz' '%.1f^o' '%.1f^o'};
xfmt = {'%.1f^o' '%.1f^o' '%d'};
yfact = [1/1e3 1 1];
xfact = [1 1 1];
nb_ax = numel(xfact);

uigl = uigridlayout(fig,[nb_ax,1]);

for iax = 1:nb_ax
    ax(iax) = uiaxes(uigl,'NextPlot','add','Box','on','XGrid','on','YGrid','on','Tag',str_y_cell{iax});
    grid(ax(iax),'on')
    ax(iax).YAxis.TickLabelFormat  = yfmt{iax};
    ax(iax).XAxis.TickLabelFormat  = xfmt{iax};
    ylabel(ax(iax),str_y_cell{iax});
    xlabel(ax(iax),str_x_cell{iax});
end

leg_str = layer_obj.ChannelID(idx_mb);
ii = 0;
for uit = idx_mb
    ii = ii+1;
    for iax = 1:nb_ax
        yval = squeeze(layer_obj.Transceivers(uit).get_params_value(str_y_cell{iax},'idx_ping',ip));
        if strcmpi(str_x_cell{iax},'BeamNumber')
            xval = layer_obj.Transceivers(uit).Params.BeamNumber;
        else
            xval = squeeze(layer_obj.Transceivers(uit).get_params_value(str_x_cell{iax},'idx_ping',ip));
        end
        h_tmp = plot(ax(iax),xfact(iax)*xval,yfact(iax)*yval,'-o');
        if iax == 1
            h(ii) = h_tmp;
        end
    end
end

legend(h,leg_str);