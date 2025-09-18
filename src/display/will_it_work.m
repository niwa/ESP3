function bool_func = will_it_work(parent_h,ver_num_str,ui_or_not_ui)
bool_func_ui = true;
bool_func_num = true;

if ~isempty(parent_h)
    if ui_or_not_ui
        bool_func_ui = matlab.ui.internal.isUIFigure(ancestor(parent_h,'figure')); 
    else
        bool_func_ui = ~matlab.ui.internal.isUIFigure(ancestor(parent_h,'figure')); 
    end
end

if ~isempty(ver_num_str)
    cur_ver= ver('Matlab');
    cur_ver_num = str2double(strsplit(cur_ver.Version,'.'));
    ver_num  = str2double(strsplit(ver_num_str,'.'));

    bool_func_num = cur_ver_num(1) > ver_num(1) || (cur_ver_num(1) == ver_num(1) && cur_ver_num(2) >= ver_num(2));
end

bool_func = bool_func_ui && bool_func_num;