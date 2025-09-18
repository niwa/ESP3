function [data_init,log_files]=get_table_data_from_survey_input_obj(survey_input_obj,logbook_file)

log_files=cell(1,length(survey_input_obj.Snapshots));
for ilog=1:numel(log_files)
    log_files{ilog}= survey_input_obj.Snapshots{ilog}.Folder;
end

if ~iscell(logbook_file)
    log_add={logbook_file};
else
    log_add=logbook_file;
end

log_files=unique([log_files(:);log_add(:)]);

data_init=[];
idx_rem=[];
for ilog=1:numel(log_files)
    log_file=log_files{ilog};
    if isfile(log_file)||isfolder(log_file)
        db_conn=connect_to_db(log_file);
        if ~isempty(db_conn)
            sql_query='SELECT DISTINCT Snapshot,Type,Stratum,Transect,Comment FROM logbook';
            data_init_tmp=db_conn.fetch(sql_query);
            db_conn.close();



            folder_cell=cell(size(data_init_tmp,1),1);
            if isfile(log_file)
                folder_cell(:)={fileparts(log_file)};
            else
                folder_cell(:)={log_file};
            end

            data_init_tmp=[num2cell(false(size(data_init_tmp,1),1)) folder_cell data_init_tmp];
            if isempty(data_init)
                data_init = data_init_tmp;
            else
                data_init=[data_init;data_init_tmp];
            end
        else
            idx_rem=union(idx_rem,ilog);
        end
    else
        idx_rem=union(idx_rem,ilog);
    end
end
log_files(idx_rem)=[];

[valid,ff]=survey_input_obj.check_n_complete_input('silent',true);

if valid&&~isempty(ff)
    [snaps,types,strat,trans_tot,~,~,~]=survey_input_obj.merge_survey_input_for_integration();
    for isnap=1:numel(snaps)

        switch types{isnap}
            case {' ',''}
                idx_true=find(trans_tot(isnap)==data_init.Transect....
                    &snaps(isnap)==data_init.Snapshot...
                    &strcmpi(deblank(strat{isnap}),deblank(data_init.Stratum)));
            otherwise
                idx_true=find(trans_tot(isnap)==data_init.Transect....
                    &snaps(isnap)==data_init.Snapshot...
                    &strcmpi(deblank(strat{isnap}),deblank(data_init.Stratum))...
                    &contains(deblank(data_init.Type),deblank(strsplit(types{isnap},';'))));
        end
        data_init(idx_true,1)={true};
    end
end