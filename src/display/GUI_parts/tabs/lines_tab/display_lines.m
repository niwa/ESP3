function display_lines(varargin)

layer=get_current_layer();

curr_disp=get_esp3_prop('curr_disp');
main_figure=get_esp3_prop('main_figure');


if ~isempty(varargin)
    if ischar(varargin{1})
        switch varargin{1}
            case 'both'
                main_or_mini={'main' 'mini' curr_disp.ChannelID};
            case 'mini'
                main_or_mini={'mini'};
            case 'main'
                main_or_mini={'main' curr_disp.ChannelID};
            case 'all'
                main_or_mini=union({'main' 'mini'},layer.ChannelID);
        end
    elseif iscell(varargin{1})
        main_or_mini=varargin{1};
    end
else
    main_or_mini=union({'main' 'mini'},layer.ChannelID);
end

[echo_obj,trans_obj_tot,text_size,~]=get_axis_from_cids(main_figure,main_or_mini);

for iax=1:length(echo_obj)
    trans_obj=trans_obj_tot(iax);
    
    echo_obj(iax).display_echo_lines(trans_obj,layer.Lines,'curr_disp',curr_disp,'text_size',text_size(iax));
end

end
