function [grid_tot,poly_cov,grid_size_tot,zones] = grid_bathy(data_struct_cell,nb_points_per_node,grid_size_master,grid_meth,prc_thr)


zone_tot = [];
grid_tot = {};
poly_cov = {};
grid_size_tot = [];

if isempty(data_struct_cell)
    return;
end

for icell = 1:numel(data_struct_cell)
    data_struct_tot = data_struct_cell{icell};
    zone_tot = [zone_tot [data_struct_tot(:).Zone]];
end

zones = unique(zone_tot);

grid_tot = cell(1,numel(zones));
poly_cov = cell(1,numel(zones));
grid_size_tot = grid_size_master*ones(1,numel(zones));

for uiz = 1:numel(zones)
    E_tot = [];
    N_tot = [];

    grid_size = inf;

    for icell = 1:numel(data_struct_cell)
        data_struct_tot = data_struct_cell{icell};
        E_tmp = [data_struct_tot(:).E];
        N_tmp = [data_struct_tot(:).N];
        H_tmp = [data_struct_tot(:).H];
        zone_tmp = [data_struct_tot(:).Zone];
        id_keep = ~isnan(E_tmp.*N_tmp.*H_tmp) & zone_tmp==zones(uiz);
        E = E_tmp(id_keep);
        N = N_tmp(id_keep);
        dr = ceil(numel(E)/1e4);
        E_red = E(1:dr:end)';
        N_red = N(1:dr:end)';
        E_tot = [E_tot E];
        N_tot = [N_tot N];
        [k_bathy,av] = boundary(E_red,N_red,1);
        grid_size = min(grid_size,nb_points_per_node*sqrt(av/(numel(E_tmp(id_keep)))));
        if ~isempty(k_bathy) &ismember(grid_meth(1:end-1),{'griddata' 'scatteredInterpolant'})
            poly_cov_tmp{uiz}{icell} = polyshape(E_red(k_bathy),N_red(k_bathy));
        end
    end


    if grid_size_tot(uiz) == 0
        grid_size_tot(uiz) = grid_size;
    else
        grid_size = grid_size_tot(uiz);
    end

    %creating full grid
    E_ori = min(E_tot,[],'all','omitnan');
    N_ori = min(N_tot,[],'all','omitnan');

    N_E = ceil(range(E_tot)/grid_size);
    E_vec = (0:N_E-1)*grid_size+E_ori;
    N_N = ceil(range(N_tot)/grid_size);
    N_vec = (0:N_N-1)*grid_size+N_ori;
    [E_grid_tot,N_grid_tot] = meshgrid(E_vec,N_vec);
        [lat_grid,lon_grid] = utm2ll(E_grid_tot(:),N_grid_tot(:),zones(uiz));
    data_to_grid = {'AbsSlope' 'AcrossSlope' 'AlongSlope' 'BS_corr'};
    scale_data_to_grid = {'lin' 'lin' 'lin' 'log'};
    %griding data
    for icell = 1:numel(data_struct_cell)
        data_struct_tot = data_struct_cell{icell};
        grid_tot{uiz}{icell}.E = E_grid_tot;
        grid_tot{uiz}{icell}.N = N_grid_tot;
        grid_tot{uiz}{icell}.Lat = reshape(lat_grid,size(N_grid_tot));
        grid_tot{uiz}{icell}.Lon = reshape(lon_grid,size(N_grid_tot));

        grid_tot{uiz}{icell}.H = nan(size(E_grid_tot));
        grid_tot{uiz}{icell}.StdH = nan(size(E_grid_tot));
        grid_tot{uiz}{icell}.BS = nan(size(E_grid_tot));
        grid_tot{uiz}{icell}.SoundingDensity = nan(size(E_grid_tot));

        for uig = 1:numel(data_to_grid)
            grid_tot{uiz}{icell}.(data_to_grid{uig}) = nan(size(E_grid_tot));
        end

        E = [data_struct_tot(:).E];
        N = [data_struct_tot(:).N];
        H = [data_struct_tot(:).H];
        
        dt = [];

        for uig = 1:numel(data_to_grid)
            if isfield(data_struct_tot(1),(data_to_grid{uig}))
                dt.(data_to_grid{uig}) = [data_struct_tot(:).(data_to_grid{uig})];
            end
        end
        if ~isempty(dt)
            data_to_grid = fieldnames(dt);
        else
            data_to_grid = {};
        end

        id_keep = ~isnan(E.*N);
        wbool = strcmpi(grid_meth(end),'w');

        if wbool
            if isfield(data_struct_tot,'BS')
                w = db2pow([data_struct_tot(:).BS]);
            else
                w = db2pow([data_struct_tot(:).data_disp]);
            end

            if prc_thr>0
                bds = prctile(w,prc_thr);
                id_keep = id_keep & (w>=bds);
            end
        else
            w = ones(size(H));
        end

        %w = ones(size(sv));
        E = E(id_keep);
        N = N(id_keep);
        H = H(id_keep);
        for uig = 1:numel(data_to_grid)
            dt.(data_to_grid{uig}) = dt.(data_to_grid{uig})(id_keep);
        end
        w = w(id_keep);

        if isempty(E)
            continue;
        end


        dtg = [];
        switch grid_meth(1:end-1)
            case 'accumarray'
                x_idx = floor((E-E_ori)/grid_size)+1;
                y_idx = floor((N-N_ori)/grid_size)+1;
                                
                HW_grid = accumarray([y_idx(:) x_idx(:)],H(:).*w(:),[], @(x) mean(x,'omitmissing'),nan);
                BS_grid = accumarray([y_idx(:) x_idx(:)],w(:),[], @(x) mean(x,'omitmissing'),nan);
                nb_elt = accumarray([y_idx(:) x_idx(:)],w(:),[], @(x) sum(~isnan(x)),nan);
                H_grid = HW_grid./BS_grid;

                Std_grid = accumarray([y_idx(:) x_idx(:)],H(:),[], @(x) std(x,'omitmissing'),nan);
                
                for uig = 1:numel(data_to_grid)
                    switch scale_data_to_grid{uig}
                        case 'lin'
                            data_tmp = dt.(data_to_grid{uig})(:);
                        case 'log'
                            data_tmp = db2pow(dt.(data_to_grid{uig})(:));
                    end
                    dtg.(data_to_grid{uig}) = ...
                        accumarray([y_idx(:) x_idx(:)],data_tmp,[], @(x) mean(x,'omitmissing'),nan);
                end

                [Ny,Nx] = size(H_grid);

                [E_grid,N_grid] = meshgrid(E_ori+(0:Nx-1)*grid_size,N_ori+(0:Ny-1)*grid_size);

            case {'griddata' 'scatteredInterpolant'}

                N_E = ceil(range(E)/grid_size);
                E_vec = (0:N_E-1)*grid_size+E_ori;
                N_N = ceil(range(N)/grid_size);
                N_vec = (0:N_N-1)*grid_size+N_ori;
                [E_grid,N_grid] = meshgrid(E_vec,N_vec);

                switch grid_meth(1:end-1)
                    case 'griddata'
                        HW_grid = griddata(E,N,H.*w,E_grid,N_grid,'linear');
                        BS_grid = griddata(E,N,w,E_grid,N_grid);
                        for uig = 1:numel(data_to_grid)
                            switch scale_data_to_grid{uig}
                                case 'lin'
                                    data_tmp = dt.(data_to_grid{uig})(:);
                                case 'log'
                                    data_tmp = db2pow(dt.(data_to_grid{uig})(:));
                            end
                            dtg.(data_to_grid{uig}) = griddata(E,N,data_tmp,E_grid,N_grid);
                        end
                    case 'scatteredInterpolant'
                        F = scatteredInterpolant(E(:),N(:),H(:).*w(:),'linear','none') ;
                        HW_grid = F(E_grid,N_grid);
                        Fbs = scatteredInterpolant(E(:),N(:),w(:),'linear','none') ;
                        BS_grid = Fbs(E_grid,N_grid);
                        for uig = 1:numel(data_to_grid)
                            switch scale_data_to_grid{uig}
                                case 'lin'
                                    data_tmp = dt.(data_to_grid{uig})(:);
                                case 'log'
                                    data_tmp = db2pow(dt.(data_to_grid{uig})(:));
                            end  
                            Ftmp = scatteredInterpolant(E(:),N(:),data_tmp,'linear','none') ;
                            dtg.(data_to_grid{uig}) = Ftmp(E_grid,N_grid);
                        end
                end
                H_grid = HW_grid./BS_grid;
                Std_grid = nan(size(H_grid));
                nb_elt = nan(size(H_grid));
                [Ny,Nx] = size(H_grid);

                if ~isempty(poly_cov_tmp{uiz}{icell})
                    idx_in  = inpolygon(E_grid,N_grid,poly_cov_tmp{uiz}{icell}.Vertices(:,1),poly_cov_tmp{uiz}{icell}.Vertices(:,2));
                    H_grid(~idx_in) = nan;
                    BS_grid(~idx_in) = nan;
                end
        end


        [~,idx_E_start] = min(abs(E_grid(1)-E_grid_tot(1,:)));
        [~,idx_N_start] = min(abs(N_grid(1)-N_grid_tot(:,1)));

        grid_tot{uiz}{icell}.H(idx_N_start:idx_N_start+Ny-1,idx_E_start:idx_E_start+Nx-1) = H_grid;
        grid_tot{uiz}{icell}.BS(idx_N_start:idx_N_start+Ny-1,idx_E_start:idx_E_start+Nx-1) = pow2db(BS_grid);
        grid_tot{uiz}{icell}.StdH(idx_N_start:idx_N_start+Ny-1,idx_E_start:idx_E_start+Nx-1) = Std_grid;
        grid_tot{uiz}{icell}.SoundingDensity(idx_N_start:idx_N_start+Ny-1,idx_E_start:idx_E_start+Nx-1) = nb_elt/grid_size^2;

        for uig = 1:numel(data_to_grid)
            switch scale_data_to_grid{uig}
                case 'lin'
                    data_tmp = dtg.(data_to_grid{uig});
                case 'log'
                    data_tmp = pow2db(dtg.(data_to_grid{uig}));
            end
            grid_tot{uiz}{icell}.(data_to_grid{uig})(idx_N_start:idx_N_start+Ny-1,idx_E_start:idx_E_start+Nx-1) = data_tmp;
        end
    end

    for icell = 1:numel(data_struct_cell)
        E_tmp = E_grid_tot(~isnan(grid_tot{uiz}{icell}.H));
        N_tmp = N_grid_tot(~isnan(grid_tot{uiz}{icell}.H));
        [k_bathy,av] = boundary(E_grid_tot(~isnan(grid_tot{uiz}{icell}.H)),N_grid_tot(~isnan(grid_tot{uiz}{icell}.H)),1);
        if ~isempty(k_bathy)
            poly_cov{uiz}{icell} = polyshape(E_tmp(k_bathy),N_tmp(k_bathy));
        end
    end

end