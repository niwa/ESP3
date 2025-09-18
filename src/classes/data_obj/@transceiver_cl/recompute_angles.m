function recompute_angles(trans_obj,new_ss)

ss_n = mean(new_ss,'all');
val =ss_n/trans_obj.Config.SoundSpeedNominal(1);

if ~isnan(ss_n)&&(val~=1)    
     %trans_obj.Data.multiply_sub_data('alongangle',val);
     %trans_obj.Data.multiply_sub_data('acrossangle',val);
%     trans_obj.Config.BeamWidthAlongship = trans_obj.Config.BeamWidthAlongship *val;
%     trans_obj.Config.BeamWidthAthwartship = trans_obj.Config.BeamWidthAthwartship *val;
    trans_obj.Config.SoundSpeedNominal = new_ss(1);
end

end