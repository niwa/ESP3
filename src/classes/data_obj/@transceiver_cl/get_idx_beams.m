function idx_beam = get_idx_beams(trans_obj,BeamAngularLimit)

if trans_obj.ismb
    angleacross=trans_obj.get_params_value('BeamAngleAthwartship',1);
    anglealong=trans_obj.get_params_value('BeamAngleAlongship',1);

    BeamAngularLimit_across = BeamAngularLimit;
    BeamAngularLimit_along = BeamAngularLimit;

    if isempty(BeamAngularLimit)
        BeamAngularLimit_across = [min(angleacross) max(angleacross)];
        BeamAngularLimit_along = [min(anglealong) max(anglealong)];
    end

    idx_beam_along = find(anglealong>=BeamAngularLimit_along(1) & anglealong<=BeamAngularLimit_along(2));
    idx_beam_across = find(angleacross>=BeamAngularLimit_across(1) & angleacross<=BeamAngularLimit_across(2));
    
    
    if isempty(idx_beam_across) && ~isempty(idx_beam_along)
        idx_beam = idx_beam_along;
    elseif isempty(idx_beam_along) && ~isempty(idx_beam_across)
        idx_beam = idx_beam_across;
    else
        idx_beam = intersect(idx_beam_along,idx_beam_across);
    end


else
    idx_beam = 1;
end