function save_tt_to_xls(trans_obj,file,stt,ett)

if exist(file,'file')>0
    try
        delete(file);
    catch err
        if strcmpi(err.identifier,'MATLAB:DELETE:Permission')
            war_fig = dlg_perso([],'Could not overwrite file',sprintf('File %s is open in another process. Please close it and then close this box to continue...',file),'Timeout',30);
            waitfor(war_fig);
            delete(file);
        else
            rethrow(err);
        end
    end
end

st=trans_obj.ST;

if isempty(st)||isempty(st.TS_comp)||isempty(trans_obj.Tracks)
    dlg_perso([],'','No tracks to export');
    return;
end


reg=region_cl.empty();
[data_struct_new,~] = reg.get_region_3D_echoes(trans_obj,'field','singletarget');
data_struct_new = data_struct_new.singletarget;

if isfield(data_struct_new,'Lat')
    st.lat=data_struct_new.Lat(:)';
    st.lon=data_struct_new.Lon(:)';
    st.depth=data_struct_new.H(:)';
end

algo_obj=get_algo_per_name(trans_obj,'SingleTarget');
algo_tt_obj=get_algo_per_name(trans_obj,'TrackTarget');

al_st_varin=algo_obj.input_params_to_struct();
al_tt_varin=algo_tt_obj.input_params_to_struct();

algo_sheet=[fieldnames(al_st_varin) struct2cell(al_st_varin)];
algo_tt_sheet=[fieldnames(al_tt_varin) struct2cell(al_tt_varin)];

idx_rem = st.Time<stt|st.Time>ett|isnan(st.Track_ID);

st_tracks=structfun(@(x) x(~idx_rem),st,'un',0);

tt_sheet=struct_to_sheet(st_tracks);
try
    writetable(cell2table(algo_sheet),file,'WriteVariableNames',0,'Sheet','Parameters');
catch err
    if strcmpi(err.identifier,'MATLAB:table:write:FileOpenInAnotherProcess')
        war_fig = dlg_perso([],'Could not write file',sprintf('File %s is open in another process. Please close it and then close this box to continue...',file),'Timeout',30);
        waitfor(war_fig);
        writetable(cell2table(algo_sheet),file,'WriteVariableNames',0,'Sheet','Parameters');
    else
        rethrow(err);
    end
end

writetable(cell2table(algo_tt_sheet),file,'WriteVariableNames',0,'Sheet','TT Parameters');
writetable(cell2table(tt_sheet'),file,'WriteVariableNames',0,'Sheet','Tracked Targets');

fprintf('Tracked targets saved to %s\n',file);