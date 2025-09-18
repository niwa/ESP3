function need=need_escorr(trans_obj)

need=any(contains(trans_obj.Config.TransceiverName,{'ES60','ES70'},"IgnoreCase",true)) ;

end