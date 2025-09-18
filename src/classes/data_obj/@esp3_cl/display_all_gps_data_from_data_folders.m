function display_all_gps_data_from_data_folders(esp3_obj)

curr_disp  = esp3_obj.curr_disp;
logbook_list = esp3_obj.list_logbooks();

gps_data = get_ping_data_from_db(fileparts(logbook_list),[]);
idx_rem = cellfun(@isempty,gps_data);
logbook_list(idx_rem) = [];
gps_data(idx_rem) = [];
if isempty(logbook_list)
    return;
end
%dg = 15;
%[lat_disp_cell,lon_disp_cell] = cellfun(@(x) reducem_perso(x.Lat,x.Long,dg),gps_data,'UniformOutput',false);
% survey_data = get_survey_data_from_db(fileparts(logbook_list));


hfig = new_echo_figure(esp3_obj.main_figure,'UiFigureBool',true,'Name','Tracks from data files','Tag','all_logbook_gps');
uigl = uigridlayout(hfig,[1 1]);

gax = geoaxes(uigl,'Basemap',curr_disp.Basemap);
gax.Layout.Column = 1;
gax.Layout.Row = 1;
format_geoaxes(gax);

color = [0.6 0 0];
sty='-';
mark='none';
str_tag = '';

for uig = 1:numel(gps_data)
    if ~isempty(gps_data{uig})
        geoplot(gax,gps_data{uig}.Lat,gps_data{uig}.Long,...
            'color',color,...
            'linestyle',sty,...
            'marker',mark,...
            'tag',str_tag);

        text(gax,mean(gps_data{uig}.Lat,"all","omitnan"),mean(gps_data{uig}.Long,"all","omitnan"),fileparts(logbook_list{uig}),...
            'Fontsize',10,'Fontweight','bold','Interpreter','None','VerticalAlignment','bottom','Clipping','on','Color',color,'tag',logbook_list{uig});


    end
end

end