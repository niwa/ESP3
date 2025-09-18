function fig = dlg_perso(main_figure,tt_str,dlg_str,varargin)
p = inputParser;

addRequired(p,'main_figure',@(obj) isempty(obj)||isa(obj,'matlab.ui.Figure'));
addRequired(p,'tt_str',@ischar);
addRequired(p,'dlg_str',@ischar);
addParameter(p,'type','warning',@(x) ismember(lower(x),{'warning' 'war' 'info' 'information'}));
addParameter(p,'Timeout',10,@(x) isnumeric(x)&&x>=0);

parse(p,main_figure,tt_str,dlg_str,varargin{:});


timeout=p.Results.Timeout;

curr_disp = get_esp3_prop('curr_disp');
if ~isempty(curr_disp)
    font=curr_disp.Font;
    cmap=curr_disp.Cmap;
else
    font=[];
    cmap=[];
end

if isempty(main_figure)
    main_figure=get_esp3_prop('main_figure');
end


split_str = regexp(dlg_str,'\n','split');
s_str  = max(cellfun(@numel,split_str));

w = min(max(300,s_str*7),400);

nb_lines=ceil(s_str*7/w)+numel(split_str)-1;

str_b_w=max(ceil(s_str*7/nb_lines),w);

box_w=str_b_w+40;

switch lower(p.Results.type)
    case {'war' 'warning'}
        tag = 'warning';
        ttt = 'WARNING ';
    otherwise
        tag = p.Results.type;
        ttt = '';
end
        

fig=new_echo_figure(main_figure,'units','pixels','position',[200 200 box_w 40+nb_lines*20],...
    'WindowStyle','modal','Visible','on','resize','off','tag',tag,'Name',sprintf('%s%s',ttt,tt_str));

uicontrol('Parent',fig,...
    'Style','text','HorizontalAlignment','left',...
    'Position',[(box_w-str_b_w)/2 20 str_b_w nb_lines*20],...
    'String',dlg_str);
disp(dlg_str);
format_color_gui(fig,font,cmap);
drawnow;

if timeout>0
    fig_timer=timer;
    fig_timer.UserData.timeout = timeout;
    fig_timer.UserData.tt_str = tt_str;
    fig_timer.UserData.t0 = now;
    fig_timer.TimerFcn = {@update_fig_name,fig};
    fig_timer.StopFcn = @(src,evt) delete(src);
    fig_timer.Period = 1;
    fig_timer.ExecutionMode= 'fixedSpacing';

    if ishghandle(fig)
        % Go into uiwait if the figure handle is still valid.
        % This is mostly the case during regular use.
        if will_it_work([],'9.10',true)
            c = matlab.ui.internal.dialog.DialogUtils.disableAllWindowsSafely(true);
        else
            c = matlab.ui.internal.dialog.DialogUtils.disableAllWindowsSafely();
        end
        fig_timer.start;
        uiwait(fig,timeout);
        if isvalid(fig_timer)
            stop(fig_timer);
            delete(fig_timer)
            delete(c);
        else
            clear fig_timer;
        end
    end
    delete(fig);
    drawnow; % Update the view to remove the closed figure (g1031998)
end



end
function decision_callback(obj, evd) %#ok
set(gcbf,'UserData',get(obj,'String'));
uiresume(gcbf);
end


function update_fig_name(src,~,fig)
t=abs((now-src.UserData.t0)*60*60*24);
if ~isvalid(fig)
    return;
end
if t<src.UserData.timeout
    str_name=sprintf('%s (%.0fs)',src.UserData.tt_str,abs(t-src.UserData.timeout));
    fig.Name=str_name;
end
end


