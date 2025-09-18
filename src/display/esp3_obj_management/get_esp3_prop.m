function [obj,esp3_obj]=get_esp3_prop(prop_to_get)

obj=[];
esp3_obj=getappdata(groot,'esp3_obj');
if ~isempty(esp3_obj)
    try
        obj=esp3_obj.(prop_to_get);
    catch err
        print_errors_and_warnings([],'error',err);
    end
end