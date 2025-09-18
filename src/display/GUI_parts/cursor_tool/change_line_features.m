function change_line_features(~,~,main_figure)

fig = uifigure(main_figure,'Position',[600 300 200 200],'Color','white');
dd1 = uidropdown(fig,'Items',{'','Red','Green','Blue','Cyan','Magenta','Yellow','Orange','Black','White','Purple'}, ...
                'ItemsData',[0 2 3 4 5 6 7 8 9 10 11], ...
                'Placeholder','Line Color','Position',[50 120 100 50]);
dd2 = uidropdown(fig,'Items',{'','0.5','1','1.5','2','2.5','3'}, ...
                'Value','', ...
                'Placeholder','Line Width');
dd2.Position = [50 50 100 50];
uicontrol(fig,...
    'Style','pushbutton',...
    'string','Apply changes',...
    'Position',[50 10 100 25],...
    'HorizontalAlignment','left',...
    'BackgroundColor','red',...
    'callback',{@apply_changes});

    function apply_changes(~,~)
        colorNum = [[1 0 0];[0.4660 0.6740 0.1880];[0 0 1];[0 1 1];[1 0 1];[1 1 0];[0.8500 0.3250 0.0980];[0 0 0];[1 1 1];[0.4940 0.1840 0.5560]];
        esp3_obj=getappdata(groot,'esp3_obj');
        main_figure=esp3_obj.main_figure;
        layer=get_current_layer();
        curr_disp=get_esp3_prop('curr_disp');

        lines_tab_comp=getappdata(main_figure,'Lines_tab');
        nb_lines=numel(layer.Lines);
        
        if ~isempty(layer.Lines)
            active_line=layer.Lines(min(nb_lines,get(lines_tab_comp.tog_line,'value')));
            if ~isempty(dd2.Value)
                active_line.LineWidth = str2double(dd2.Value);
            end
            if dd1.Value~=0
                disp(dd1.Value)
                active_line.LineColor = colorNum(dd1.Value-1,:);
            end
        else
            return
        end

        main_or_mini=union({'main' 'mini'},layer.ChannelID);
        [echo_obj,trans_obj_tot,text_size,~]=get_axis_from_cids(main_figure,main_or_mini);
        
        for iax=1:length(echo_obj)
            trans_obj=trans_obj_tot(iax);
            
            echo_obj(iax).display_echo_lines(trans_obj,active_line,'curr_disp',curr_disp,'text_size',text_size(iax));
        end
        close(fig)
    end



end
