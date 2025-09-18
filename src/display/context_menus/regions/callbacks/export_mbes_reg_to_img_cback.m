function export_mbes_reg_to_img_cback(~,~)

layer = get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~] = layer.get_trans(curr_disp);
reg_curr = trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
cmap_struct = init_cmap(curr_disp.Cmap,curr_disp.ReverseCmap);%('beer-lager');
% get ouptut location
[path_tmp,~,~] = fileparts(layer.Filename{1});
layers_Str = list_layers(layer,'nb_char',80);
pathname = uigetdir(path_tmp, 'Save "cleaned" WC data to images' );

if isequal(pathname,0)
    return;
end

%file = fullfile(pathname,fileN);
main_figure = get_esp3_prop('main_figure');
[load_bar_comp,~]=show_status_bar(main_figure);
load_bar_comp.progress_bar.setText('Exporting WC data to image');
set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(reg_curr), 'Value',0);

cax = curr_disp.Cax;

for ireg = 1:numel(reg_curr)
    
    idx_pings  = reg_curr(ireg).Idx_ping;
    idx_r = reg_curr(ireg).Idx_r;
   
    
    theta = trans_obj.get_params_value('BeamAngleAthwartship',idx_pings,[]);
    if isempty(idx_pings)
        idx_pings = 1:size(theta,2);
    end
    
    r = trans_obj.get_samples_range(idx_r);
    d = trans_obj.get_transducer_depth(idx_pings);
    
    heave = trans_obj.AttitudeNavPing.Heave(idx_pings);
    pitch = trans_obj.AttitudeNavPing.Pitch(idx_pings);
    roll = trans_obj.AttitudeNavPing.Roll(idx_pings);
    yaw = trans_obj.AttitudeNavPing.Yaw(idx_pings);
    h = trans_obj.AttitudeNavPing.Heading(idx_pings);
    
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(idx_pings), 'Value',0);
    
    for ip = 1:numel(idx_pings)
        set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(idx_pings), 'Value',ip);
        [amp_tot,sampleAcrossDist_tot,~,sampleUpDist_tot]=trans_obj.get_subdatamat_AcUp_pos('field',curr_disp.Fieldname,'idx_ping',idx_pings(ip),'idx_r',idx_r);%,'idx_beam',p.Results.idx_beam,'idx_r',p.Results.idx_r
   
        amp = squeeze(amp_tot);
        sampleAcrossDist = double(squeeze(sampleAcrossDist_tot));
        sampleUpDist = double(squeeze(sampleUpDist_tot));
        
        d_ac = max(diff(sampleAcrossDist,1,2),[],'all');
        d_up = max(diff(sampleUpDist,1,2),[],'all');
        dr = min(d_ac,d_up)/2;
        y = min(sampleUpDist(:)):dr:max(sampleUpDist(:));
        x = min(sampleAcrossDist(:)):dr:max(sampleAcrossDist(:));
        
        [xx,yy]=meshgrid(x,y);
        amp_grid = griddata(sampleAcrossDist,sampleUpDist,amp,xx,yy);
        theta_grid = griddata(sampleAcrossDist,sampleUpDist,double(repmat(shiftdim(theta(:,ip,:),1),size(sampleAcrossDist,1),1)),xx,yy);
        range_grid = griddata(sampleAcrossDist,sampleUpDist,repmat(r,1,size(sampleAcrossDist,2)),xx,yy);
        
        switch curr_disp.YDir
            case 'normal'
                amp_grid   = flipud(amp_grid);
                theta_grid = flipud(theta_grid);
                range_grid = flipud(range_grid);
        end
        if size(cmap_struct.cmap,1)>256
            id_c  =floor(linspace(1,size(cmap_struct.cmap,1),256));
            cmap_red = cmap_struct.cmap(id_c,:);
        else
           cmap_red  = cmap_struct.cmap; 
        end
        
        data.Amp =amp_grid;
        data.Theta =theta_grid;
        data.Range =range_grid;
        data.Sonar_att = [pitch(ip) roll(ip) yaw(ip) ];
        data.Heave = heave(ip);
        data.Depth = d(ip); 
        data.Heading = h(ip); 
        
         I= mat2ind(amp_grid, double(cax),size(cmap_red,1));
%        I = gray2ind(Ig, size(cmap,1));
        fileN  = sprintf('%s_WC_ping_%.0f.png',layers_Str{1},idx_pings(ip));
        
        file = fullfile(pathname,fileN);
        imwrite(I, cmap_red, file,'Transparency',0);
        
        file_mat  = sprintf('%s_WC_ping_%.0f.mat',layers_Str{1},idx_pings(ip));
        
        save(fullfile(pathname,file_mat),'data');
    end
    
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(reg_curr), 'Value',0);
end
hide_status_bar(main_figure);
end