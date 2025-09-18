function import_gps_from_csv_callback(~,~,main_figure)
layer=get_current_layer();

if isempty(layer)
return;
end

[path_f,~,~]=fileparts(layer.Filename{1});

[Filename,PathToFile]= uigetfile({fullfile(path_f,'*.csv;*.txt;*.mat')}, 'Pick a csv/txt/mat','MultiSelect','on');


if isempty(Filename)
    return;
end

if ~iscell(Filename)
    if (Filename==0)
        return;
    end
    Filename={Filename};
end


[answer,cancel]=input_dlg_perso(main_figure,'Do you want to apply a time offset?',{'Time offset (in Hours)'},...
    {'%.3f'},{0});

if cancel
    warning('Invalid time offset');
    dt=0;
else
   dt=answer{1}; 
end

layer.get_gps_data_from_csv(fullfile(PathToFile,Filename),dt);


update_grid(main_figure);
update_grid_mini_ax(main_figure);
update_map_tab(main_figure);

end