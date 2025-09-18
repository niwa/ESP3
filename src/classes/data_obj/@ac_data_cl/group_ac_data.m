function ac_data_obj_out = group_ac_data(ac_data_obj_in,fields_to_group,id_group)
nb_ac  =numel(ac_data_obj_in);
nb_f = cellfun(@numel,{ac_data_obj_in(:).Nb_samples});
nb_f_u = unique(nb_f);
nb_pings = max([ac_data_obj_in(:).Nb_pings]);

if isscalar(nb_f_u)
    [nb_samples,id_in] = max(reshape([ac_data_obj_in(:).Nb_samples],nb_f_u,nb_ac),[],2);
    id_in = unique (id_in);
    nb_samples = nb_samples';
    nb_beams = sum(reshape([ac_data_obj_in(:).Nb_beams],nb_f_u,nb_ac),2)';
else
    [nb_samples,id_in] = max([ac_data_obj_in(:).Nb_samples]);
    nb_beams = sum(cellfun(@max,{ac_data_obj_in(:).Nb_beams}));
end

    tt = strfind(ac_data_obj_in(1).MemapName{1},filesep);
    curr_name = fullfile(ac_data_obj_in(1).MemapName{1}(1:tt(end-1)),sprintf('grouped_channels_%d',id_group),'data_transceiver');
    ac_data_obj_out=ac_data_cl('SubData',[],...
        'FileId',ac_data_obj_in(id_in(1)).FileId,...
        'BlockId',ac_data_obj_in(id_in(1)).BlockId,...
        'Nb_samples',nb_samples,...
        'Nb_beams',nb_beams,...
        'Nb_pings',nb_pings,...
        'MemapName',curr_name);

    for uif = 1:numel(fields_to_group)
        id_beam = 0;
        for uiac = 1:numel(ac_data_obj_in)
            data = ac_data_obj_in(uiac).get_subdatamat('field',fields_to_group{uif});
            if ~isempty(data)
                ac_data_obj_out.replace_sub_data_v2(data,fields_to_group{uif},'idx_beam',id_beam+(1:max(ac_data_obj_in(uiac).Nb_beams)));
                id_beam = id_beam + max(ac_data_obj_in(uiac).Nb_beams);
            end
        end
    end


end