function fig=disp_config_params(trans_obj,varargin)

p = inputParser;

addRequired(p,'trans_obj',@(trans_obj) isa(trans_obj,'transceiver_cl'));
addParameter(p,'idx_ping',1,@isnumeric);
addParameter(p,'font','default',@ischar);

parse(p,trans_obj,varargin{:});

config_str=trans_obj.Config.config2str();

param_str=trans_obj.Params.param2str([],p.Results.idx_ping);


fig =new_echo_figure([],'Units','pixels','Position',[200 300 1200 400],'Resize','off',...
    'Name',sprintf('Configuration/Parameters %s ping %d',trans_obj.Config.ChannelID,p.Results.idx_ping),...
    'Tag',sprintf('config_params%s',trans_obj.Config.ChannelID),'UiFigureBool',true);

uidl = uigridlayout(fig,[1 2]);

h_conf_str = uihtml(uidl); 
h_conf_str.HTMLSource = config_str;

h_param_str = uihtml(uidl); 
h_param_str.HTMLSource = param_str;

end