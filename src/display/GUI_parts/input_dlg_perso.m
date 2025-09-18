function [answers,cancel]=input_dlg_perso(main_figure,tt_str,cell_input,cell_fmt_input,cell_default_value,varargin)

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

opt={'Ok' 'Cancel'};
nb_lines=numel(cell_input);
cancel=1;
answers=cell_default_value;

str_b_w=max(cellfun(@(x) ceil(numel(x)*8),cell_input));
str_b_w=max(str_b_w,120);

bt_w=max([sum(cellfun(@numel,opt))*8,50]);

box_w=max(str_b_w+20,numel(opt)*(bt_w+10)+10);

ht=17;

QuestFig=new_echo_figure(main_figure,'units','pixels','position',[200 200 box_w 100+(2*nb_lines-1)*ht],...
    'WindowStyle','modal','Visible','on','resize','off','tag','question','Name',tt_str,'UserData',opt{2});%,'CloseRequestFcn',@do_nothing);
for il=1:nb_lines
    switch cell_fmt_input{il}
        case 'bool'
             answers_h(il)=uicontrol('Parent',QuestFig,...
                 'String',cell_input{il},...
                'Style','radiobutton',...
                'Position',[(box_w-str_b_w)/2 40+(2*il+1)*ht str_b_w ht],...
                'Value',cell_default_value{il}>0,'Callback',{@update_answers,-inf,inf,cell_default_value,cell_fmt_input{il},il});
        otherwise
            uicontrol('Parent',QuestFig,...
                'Style','text',...
                'Position',[(box_w-str_b_w)/2 40+(2*il+1)*ht str_b_w ht],...
                'String',cell_input{il},'HorizontalAlignment','Left');
            switch cell_fmt_input{il}
                case {'%s' '%c'}
                    x_val=cell_default_value{il};
                otherwise
                    x_val=num2str(cell_default_value{il},cell_fmt_input{il});
            end
            answers_h(il)=uicontrol('Parent',QuestFig,...
                'Style','edit',...
                'Position',[(box_w-str_b_w)/2 40+(2*il)*ht str_b_w ht],...
                'String',x_val,'Callback',{@update_answers,-inf,inf,cell_default_value,cell_fmt_input{il},il});
    end
end

if strcmp(tt_str,'Authentication required')
    jPasswordField = javax.swing.JPasswordField();  
    jPasswordField = javaObjectEDT(jPasswordField);  
    jhPasswordField = javacomponent(jPasswordField,[(box_w-str_b_w)/2 40+(2*il)*ht str_b_w ht], QuestFig);
end
for il=1:numel(opt)
    noHandle(il)=uicontrol('Parent',QuestFig,...
        'Position',[(box_w-2*bt_w-10)/2+(bt_w+10)*(il-1) 20 bt_w 25],...
        'String',opt{il},...
        'Callback',@decision_callback,...
        'KeyPressFcn',@doControlKeyPress , 'UserData',0);
end
QuestFig.UserData=answers;
setdefaultbutton(QuestFig, noHandle);
format_color_gui(QuestFig,font,cmap);
drawnow;


if ishghandle(QuestFig)
    % Go into uiwait if the figure handle is still valid.
    % This is mostly the case during regular use.
    if will_it_work([],'9.10',true)
        c = matlab.ui.internal.dialog.DialogUtils.disableAllWindowsSafely(true);
    else
        c = matlab.ui.internal.dialog.DialogUtils.disableAllWindowsSafely();
    end
    uiwait(QuestFig);
    delete(c);
end

if ishghandle(QuestFig)
    if strcmp(tt_str,'Authentication required')
        answers = jhPasswordField.getText();
        answers = answers.toCharArray()';
    else
        answers=get(QuestFig,'UserData');
    end

    cancel=noHandle(2).UserData;
end
delete(QuestFig);
drawnow; % Update the view to remove the closed figure (g1031998)

end

function update_answers(src,~,min_val,max_val,deflt_val,precision,i)
check_fmt_box(src,[],min_val,max_val,deflt_val,precision);
switch precision
    case {'%s' '%c'}
        x_val=src.String;
    case 'bool'
        x_val=src.Value>0;
    otherwise
        x_val=str2double(src.String);
end
src.Parent.UserData{i}=x_val;

end

function decision_callback(obj, evd) %#ok
obj.UserData=1;
uiresume(gcbf);
end

function doControlKeyPress(obj, evd)
switch(evd.Key)
    case {'return'}
        set(gcbf,'UserData',get(obj,'String'));
        uiresume(gcbf);
    case 'escape'
        delete(gcbf)
end
end
