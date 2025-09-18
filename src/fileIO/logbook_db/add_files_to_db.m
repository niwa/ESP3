%% list_ac_file_db.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-05-17: first version (Yoann Ladroit). TODO: complete date and comment
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function

function add_files_to_db(datapath,list_raw,ftypes,dbconn,survdata_temp)
nb_files_raw=length(list_raw);

if isempty(survdata_temp)
    survdata_temp=survey_data_cl();
end

if ~iscell(list_raw)
    list_raw={list_raw};
end

for ifif=1:nb_files_raw
    try
        fprintf('Getting Start and End Date from file %s (%i/%i)\n',list_raw{ifif},ifif,nb_files_raw);
        [start_date,end_date,ftype,survdata_temp_2]=start_end_time_from_file(fullfile(datapath,list_raw{ifif}),ftypes{ifif});
        if strcmpi(ftype,'crest')&&~isempty(survdata_temp_2)
            survdata_temp.Snapshot = survdata_temp_2.Snapshot;
            survdata_temp.Stratum = survdata_temp_2.Stratum;
            survdata_temp.Transect = survdata_temp_2.Transect;
        end
        survdata_temp.surv_data_to_logbook_db(dbconn,list_raw{ifif},'StartTime',start_date,'EndTime',end_date);
    catch err
        disp(err.message);
        fprintf('    Could not open file %s\n',list_raw{ifif});
    end
end

end



