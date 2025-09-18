function output_reg_1D = output_reg_2D_to_1D(output_reg_2D)


if isempty(output_reg_2D)
    output_reg_1D = [];
    return;
end

[Ny,Nx] = size(output_reg_2D.eint);

field_struct = fieldnames(output_reg_2D);
[~,idx_int] = unique(output_reg_2D.Vert_Slice_Idx);
duplicate_indices =setdiff(1:numel(output_reg_2D.Vert_Slice_Idx), idx_int);
idx_int(duplicate_indices) = [];
idx_int = repmat(idx_int(:)',Ny,1);

idx_int = [ones(numel(idx_int),1) idx_int(:)];

for ifi = 1:numel(field_struct)

    [Ny_ifi,~] = size(output_reg_2D.(field_struct{ifi}));
    if duplicate_indices
        output_reg_2D.(field_struct{ifi})(:,duplicate_indices) = [];
    end

    if duplicate_indices
        output_reg_2D.(field_struct{ifi})(:,duplicate_indices) = [];
    end

    if Ny_ifi == 1
        output_reg_1D.(field_struct{ifi}) = output_reg_2D.(field_struct{ifi});
    else

        switch field_struct{ifi}
            case {'Tags' 'Thickness_tot' 'Thickness_mean' 'PRC'}

            otherwise
                switch   field_struct{ifi}
                    case 'sd_Sv'
                        ff = @(x) sqrt(mean(x.^2,1,'omitnan'));
                    case {'nb_tracks' 'nb_st' 'eint' 'NASC' 'ABC'}
                        ff = @(x) sum(x,1,'omitnan');
                    case {'st_ts_mean' 'tracks_ts_mean'}
                        ff = @(x) pow2db(mean(db2pow(x),1,'omitnan'));
                    otherwise
                        if contains(field_struct{ifi},'min')
                            ff = @(x) mean(x,1,'omitnan');
                        elseif contains(field_struct{ifi},'max')
                            ff = @(x) mean(x,1,'omitnan');
                        elseif contains(field_struct{ifi},'tot')
                            ff = @(x) range(x,1,'omitnan');
                        else
                            ff = @(x) mean(x,1,'omitnan');
                        end

                end
                
                output_reg_1D.(field_struct{ifi}) = accumarray(idx_int,output_reg_2D.(field_struct{ifi})(:),[1,Nx],ff);
        end

    end

end
