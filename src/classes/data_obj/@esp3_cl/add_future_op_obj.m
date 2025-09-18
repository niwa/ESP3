function add_future_op_obj(esp3_obj,f_obj)
    if isempty(esp3_obj.future_op_obj)
        esp3_obj.future_op_obj = f_obj;
    else
        esp3_obj.future_op_obj = [esp3_obj.future_op_obj f_obj];
    end
end