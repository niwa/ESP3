function   disconnect_parpool(esp3_obj)

if isempty(esp3_obj.ppool) || ~esp3_obj.ppool.Connected
    delete(esp3_obj.ppool);
end