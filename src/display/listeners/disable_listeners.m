function disable_listeners(main_figure)

if isappdata(main_figure,'ListenersH')
    ls=getappdata(main_figure,'ListenersH');
else
    ls=[];
end

if ~isempty(ls)
    for ils=1:length(ls)
        ls(ils).Enabled = false;
    end
end

setappdata(main_figure,'ListenersH',ls);

end