function growed_mat = grow_mat(init_mat,id_mat,id_grow_mat)
    growed_mat  =nan(size(id_grow_mat));
    ids  =unique(id_grow_mat(:));
    ids(isnan(ids))=[];
    tmp = [];
    for ui = ids'
        for ip  =1:size(id_grow_mat,2)
            if ip > numel(numel(init_mat))&&~isempty(tmp)
                growed_mat(id_grow_mat(:,ip)==ui,ip)  = tmp;
            else
                idd = id_mat{ip}==ui;
                if any(idd)
                    tmp  = init_mat{ip}(idd);
                    growed_mat(idd,ip) = tmp;
                end
            end
        end
    end
    
    growed_mat(isnan(growed_mat))=init_mat{1}(1);
end
