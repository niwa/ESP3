function create_unsclassif_dlbox(~,~,main_figure)

layer = get_current_layer();
app_path_main=whereisEcho();
esp3_icon = fullfile(app_path_main,'icons','echoanalysis.png');

if isempty(layer)
    return;
end

freqs_nom = layer.Frequencies;
idxTrans = 1:length(freqs_nom);

default_val = [10 3 inf];
%% Main Window
reg_fig=new_echo_figure(main_figure,'UiFigureBool',true,...
    'WindowStyle','normal','Resize','off',...
    'Position',[697 311 560 660],...
    'Name','Run unsupervised classification on WC data','Tag','create_reg');

% Window title
uicontrol(reg_fig, ...
    'Style','text',...
    'BackgroundColor','white',...
    'Units','normalized',...
    'Position',[0.2 0.85 0.6 0.1],...
    'fontsize',14,...
    'String','WC clustering');


%% Clustering algorithm

% possible values and default
algos_classif = {'KMeans','AgC','GM'};
default_algo_idx = 1;

% text
uicontrol(reg_fig,...
    'Style','Text',...
    'BackgroundColor','white',...
    'String','Clustering method:',...
    'units','normalized',...
    'TooltipString',['-KMeans' newline ...
    '-AgC: Agglomerative Clustering' newline...
    '-GM: Gaussian Mixture'],...
    'HorizontalAlignment','right',...
    'Position',[0 0.70 0.26 0.07]);

% value
cluster_method = uicontrol(reg_fig,...
    'Style','popupmenu',...
    'String',algos_classif,...
    'Value',default_algo_idx,...
    'units','normalized',...
    'TooltipString',['-KMeans' newline ...
    '-AgC: Agglomerative Clustering' newline...
    '-GM: Gaussian Mixture'],...
    'Position',[0.27 0.68 0.2 0.1]);


% text
uicontrol(reg_fig,...
    'Style','Text',...
    'BackgroundColor','white',...
    'String','Number of clusters:',...
    'units','normalized',...
    'HorizontalAlignment','right',...
    'Position',[0.49 0.55 0.26 0.07]);

% value
nbclusters = uicontrol(reg_fig,...
    'Style','edit',...
    'unit','normalized',...
    'position',[0.78 0.55 0.1 0.07],...
    'string',default_val(2),...
    'Tag','w');



%% Dimension reducion technique (if applicable)

% possible values and default
dim_reduc = {'None' 'PCA' 't-SNE'};
dim_reduc_idx = 1;

% text
uicontrol(reg_fig,...
    'Style','Text',...
    'String','Dimension reduction:',...
    'units','normalized',...
    'TooltipString',['-None' newline ...
    '-PCA: Principal Component Analysis' newline...
    '-t-SNE: t-distributed stochastic neighbour embedding'],...
    'HorizontalAlignment','right',...
    'BackgroundColor','white',...
    'Position',[0.5 0.70 0.27 0.07]);

% value
dim_reduc_method = uicontrol(reg_fig,...
    'Style','popupmenu',...
    'String',dim_reduc,...
    'Value',dim_reduc_idx,...
    'units','normalized',...
    'TooltipString',['-None' newline ...
    '-PCA: Principal Component Analysis' newline...
    '-t-SNE: t-distributed stochastic neighbour embedding'],...
    'Position',[0.78 0.68 0.2 0.1]);

%% Surface offset and step (in pings) for subsampling of the WC into several regions to EI and cluster
%% To use if high resolution for EI + time consuming clustering method (AgC for ex)

text_top_position = [0 0.55 0.26 0.07];
value_top_position = [0.27 0.555 0.1 0.07];
text_bottom_position = [0 0.35 0.57 0.07];
value_bottom_position = [0.6 0.35 0.1 0.07];

% surface offset text
uicontrol(reg_fig,...
    'Style','Text',...
    'BackgroundColor','white',...
    'String','Surface offset (m):',...
    'units','normalized',...
    'HorizontalAlignment','right',...
    'Position',text_top_position);

% surface offset value
surf_offset = uicontrol(reg_fig,...
    'Style','edit',...
    'unit','normalized',...
    'position',value_top_position,...
    'string',default_val(1),...
    'Tag','w');


% step text 
uicontrol(reg_fig,...
    'Style','Text',...
    'BackgroundColor','white',...
    'String','Step for subsampling of WC (number of pings):',... 
    'units','normalized',...
    'TooltipString',['-Step (in pings) for subsampling the ' ...
    'WC region into several smaller regions to optimize time comsumption. ' newline ...
    '-Final results will then recombine all subregions created every xxx pings into one. ' newline ...
    '-To use when choosing a high resolution for echo-integration or when choosing time' ...
    ' consuming clustering methods (AgC for ex)'],...
    'HorizontalAlignment','right',...
    'Position',text_bottom_position);

% step value
step = uicontrol(reg_fig,...
    'Style','edit',...
    'unit','normalized',...
    'position',value_bottom_position,...
    'TooltipString',['-Step (in pings) for subsampling the ' ...
    'WC region into several smaller regions to optimize time comsumption. ' newline ... 
    '-Final results will then recombine all subregions created every xxx pings into one. ' newline ...
    '-To use when choosing a high resolution for echo-integration or when choosing time' ...
    ' consuming clustering methods (AgC for ex)'],...
    'string',default_val(3),...
    'Tag','w');

%% Cell width

% text
uicontrol(reg_fig,...
    'Style','Text',...
    'BackgroundColor','white',...
    'String','Cell Width (pings):',...
    'units','normalized',...
    'HorizontalAlignment','right',...
    'Position',[0 0.45 0.26 0.07]);

% value
cell_w = uicontrol(reg_fig,...
    'Style','edit',...
    'unit','normalized',...
    'position',[0.27 0.457 0.1 0.07],...
    'string',10,...
    'Tag','w');

% text
uicontrol(reg_fig,...
    'Style','Text',...
    'BackgroundColor','white',...
    'String','Cell Height (m):',...
    'units','normalized',...
    'HorizontalAlignment','right',...
    'Position',[0.45 0.45 0.26 0.07]);

% value
cell_h = uicontrol(reg_fig,...
    'Style','edit',...
    'unit','normalized',...
    'position',[0.78 0.457 0.1 0.07],...
    'string',10,...
    'Tag','h');

% Freqs to EI and cluster

% text
uicontrol(reg_fig,...
    'Style','Text',...
    'String','Channels:',...
    'TooltipString','Select one or several channels',...
    'units','normalized',...
    'HorizontalAlignment','right',...
    'BackgroundColor','white',...
    'Position',[0.3 0.18 0.27 0.07]);

% value
maxl = length(freqs_nom)+1;
minl = 1;
freqs_nom_str = cell(1,length(freqs_nom));
for fnom=1:length(freqs_nom)
    if strcmpi(layer.Transceivers(fnom).Mode,'FM')
        freqs_nom_str{1,fnom} = append(num2str(freqs_nom(fnom)/1000),'kHz (FM)');
    else
        freqs_nom_str{1,fnom} = append(num2str(freqs_nom(fnom)/1000),'kHz');
    end
end
freqs = uicontrol(reg_fig,...
    'Style','listbox',...
    'String',freqs_nom_str,...
    'TooltipString','Select one or several channels',...
    'Value',1,...
    'Max',maxl,...
    'Min',minl,...
    'units','normalized',...
    'Position',[0.6 0.15 0.2 0.15]);


reopen_EIdata = uicontrol(reg_fig,...
    'Style','Radiobutton',...
    'String','Re-cluster EI',...
    'TooltipString','Re-run clustering on water column data that was already echo-integrated',...
    'Value',0,...
    'BackgroundColor',[1 1 1],...
    'Position',[40 150 100 100],...
    'callback',{@grey_out_fields});


%% Create "Run" button
trans_obj = layer.Transceivers(idxTrans);
uicontrol(reg_fig,...
    'Style','pushbutton',...
    'units','normalized',...
    'string','Run',...
    'pos',[0.35 0.01 0.25,0.1],...
    'TooltipString','Run unsupervised classification',...
    'HorizontalAlignment','left',...
    'BackgroundColor','white',...
    'callback',{@unsupervised_classif_WC});

%% make window visible
set(reg_fig,'visible','on');

    
    function grey_out_fields(~,~) 
        switch reopen_EIdata.Value
            case 0
                surf_offset.Enable = 'on';
                cell_w.Enable = 'on';
                cell_h.Enable = 'on';
                freqs.Enable = 'on';  
            case 1
                surf_offset.Enable = 'off';
                cell_w.Enable = 'off';
                cell_h.Enable = 'off';
                freqs.Enable = 'off';  
        end
    end

    
    function unsupervised_classif_WC(~,~)
    
    warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
    jframe=get(gcf,'javaframe');
    app_path_main=whereisEcho();
    esp3_icon = fullfile(app_path_main,'icons','echoanalysis.png');
    jIcon=javax.swing.ImageIcon(esp3_icon);
    jframe.setFigureIcon(jIcon);
    dlg = uiprogressdlg(reg_fig,'Icon',esp3_icon, ...
        'Interpreter','html');
    
    if str2double(surf_offset.String)<0
        surf_offset=default_val(1);
    end
    
    if str2double(nbclusters.String)>10
        nclusters=10;
    end
    
    step = str2double(step.String);
    nclusters = str2double(nbclusters.String);
    cell_size_pings = str2double(cell_w.String);
    cell_size_depth = str2double(cell_h.String);
    offset_surf = str2double(surf_offset.String);
    clustering_method = cluster_method.String{cluster_method.Value};
    dim_reduc_method = dim_reduc_method.String{dim_reduc_method.Value};
    
    path = pwd;
    path = append(path,'\echo_results\','WC_clusteringResults');

    if ~isempty(layer.SurveyData)
        fname = append(layer.SurveyData{1}.Voyage,'_',layer.SurveyData{1}.Type,'_Snapshot',num2str(layer.SurveyData{1}.Snapshot),'_Stratum_',layer.SurveyData{1}.Stratum,'_Transect',num2str(layer.SurveyData{1}.Transect));
        path = append(path,'\',fname);
    else
        indstr1 = strfind(layer.Filename{1},'\');
        indstr1 = indstr1(end)+1;
        indstr2 = strfind(layer.Filename{1},'.raw');
        indstr2 = indstr2-1;
        if isscalar(layer.Filename)
            fname = append(layer.Filename{1}(indstr1:indstr2));
            path = append(path,'\',fname);
        else
            fname1 = append(layer.Filename{1}(indstr1:indstr2));
            fname2 = append(layer.Filename{end}(indstr1:indstr2));
            path = append(path,'\',fname1,'_',fname2);
        end
    end
    
    if ~isfolder(path)
        mkdir(path) 
    end

    cell_w_units = 'pings';
    
    mymap = [1 1 0
            0 1 1
            1 0 1
            0 0 1
            1 0 0
            0 1 0
            0 0 0
            1 0.6 0.05
            0.5 0.5 0.5
            0.6 0.05 1];
    
    mymap = mymap(1:nclusters,:);
    Cax = get_esp3_prop('curr_disp').Cax;
    
    
    if ~reopen_EIdata.Value
        if step~= Inf
            steps = 300;
            sn = 3;
            sk1 = 2;
        else
            steps = 200;
            sn = 2;
            sk1 = 1;
        end
        survey = survey_cl;
        idx_freq_main = freqs.Value(1);
        idx_freq_out_tot = freqs.Value;
        
        idx_f = idx_freq_main == idx_freq_out_tot;
        trans_obj = layer.Transceivers(idx_freq_main);
        
        survey.SurvInput.Options.Vertical_slice_size.Value = cell_size_pings;
        survey.SurvInput.Options.Horizontal_slice_size.Value = cell_size_depth;
        survey.SurvInput.Options.Vertical_slice_units.Value = cell_w_units;
        survey.SurvInput.Options.DepthMin.Value = offset_surf;
        
        survey.SurvInput.Options.RunInt.Value = 1;
        survey.SurvInput.Options.IntType.Value = 'WC';

        cmap = winter(steps)*100;
        for stepi = 1:steps/sn
            r = num2str(cmap(stepi,1));
            g = num2str(cmap(stepi,2));
            b = num2str(cmap(stepi,3));
            msg = ['<p style=color:rgb(' r '%,' g '%,' b '%)>','Echointegrating WC data','... </p>'];
            dlg.Message = msg;
            dlg.Value = stepi/steps;
            pause(0.05);
        end
    
        layer.multi_freq_slice_transect2D('survey_options',survey.SurvInput.Options,'idx_main_freq',idx_freq_main,'idx_sec_freq',idx_freq_out_tot);
        output_2D = layer.EchoIntStruct.output_2D;
        if ~isempty(output_2D{1}{1})
            sliced_output_table = reg_output_to_table(output_2D{1}{1});
            f_names = fieldnames(sliced_output_table);
            mask_fieldnames = contains(f_names,'_fm');
            sliced_output_table=removevars(sliced_output_table,f_names(mask_fieldnames));
            switch survey.SurvInput.Options.IntRef.Value
                case 'Transducer'
                    outputFileXLS = sprintf('%s_transect_snap_%d_type_%s_strat_%s_trans_%d%s%s',layer.SurveyData{1}.Voyage,layer.SurveyData{1}.Snapshot,layer.SurveyData{1}.Type,layer.SurveyData{1}.Stratum,layer.SurveyData{1}.Transect,'_Transducer','.csv');
                case 'Surface'
                    outputFileXLS = sprintf('%s_transect_snap_%d_type_%s_strat_%s_trans_%d%s%s',layer.SurveyData{1}.Voyage,layer.SurveyData{1}.Snapshot,layer.SurveyData{1}.Type,layer.SurveyData{1}.Stratum,layer.SurveyData{1}.Transect,'_Surface','.csv');
                case 'Bottom'
                    outputFileXLS = sprintf('%s_transect_snap_%d_type_%s_strat_%s_trans_%d%s%s',layer.SurveyData{1}.Voyage,layer.SurveyData{1}.Snapshot,layer.SurveyData{1}.Type,layer.SurveyData{1}.Stratum,layer.SurveyData{1}.Transect,'_Bottom','.csv');
            end
            writetable(sliced_output_table,append(path,'/',outputFileXLS));
        end
    
        
        freq_nom = layer.Frequencies(freqs.Value);
    
        Freqs = [];
        nbfreq = zeros(1,length(freq_nom)); 
        sv_nom = cell(length(freq_nom),1);
        for iit=1:length(freq_nom) 
            switch layer.Transceivers(freqs.Value(iit)).Mode
                case 'FM'
                    f = output_2D{iit}{1}.f_fm;
                    sf = zeros(size(output_2D{iit}{1}.f_fm,1)*size(output_2D{iit}{1}.f_fm,2),1);
                    for iif=1:size(output_2D{iit}{1}.f_fm,1)*size(output_2D{iit}{1}.f_fm,2)
                        sf(iif) = size(f{iif},2);
                    end
                    nbf = min(sf(sf~=0)); 
                    F = find(sf==nbf); 
                    Freqs = [Freqs f{F(1)}]; 
                    nbfreq(iit) = nbf; 
                case 'CW'
                    Freqs = [Freqs freq_nom(iit)];
                    nbfreq(iit) = 1;
            end
            sv_nom{iit} = output_2D{iit}{1}.sv;
            sa{iit} = output_2D{iit}{1}.NASC;
        end
        nbfreqs = length(Freqs);
        nbfreq_ind = cumsum(nbfreq);
        nbfreq_ind = [0 nbfreq_ind];
        ping_s = output_2D{1}{1}.Ping_S;
        ping_e = output_2D{1}{1}.Ping_E;
        depth = output_2D{1}{1}.Depth_mean;
        lat = (output_2D{1}{1}.Lat_S+output_2D{1}{1}.Lat_E)/2;
        lon = (output_2D{1}{1}.Lon_S+output_2D{1}{1}.Lon_E)/2;
        
        temp_mvbs = cell(size(output_2D{1}{1}.sv,1),size(output_2D{1}{1}.sv,2));
        temp_sa = cell(size(output_2D{1}{1}.sv,1),size(output_2D{1}{1}.sv,2));
        for ix=1:size(output_2D{1}{1}.sv,1)
            for iy=1:size(output_2D{1}{1}.sv,2)
                temp_mvbs_i = [];
                temp_sa_i = [];
                for iit=1:length(freq_nom)
                    if strcmpi(layer.Transceivers(freqs.Value(iit)).Mode,'FM')
                        if ~isempty(output_2D{iit}{1}.Sv_fm{ix,iy})
                            if size(output_2D{iit}{1}.Sv_fm{ix,iy},2)>nbfreq(iit)
                                icomp = zeros(size(output_2D{iit}{1}.Sv_fm{ix,iy},2),1);
                                icomp(1) = 1;
                                for jjf=2:length(icomp)-1
                                    icomp_temp = find(abs(Freqs(iit)-output_2D{iit}{1}.f_fm{ix,iy}(jjf))==min(abs(Freqs(iit)-output_2D{iit}{1}.f_fm{ix,iy}(jjf))));
                                    icomp(jjf) = icomp_temp(1);
                                end
                            icomp(sf(iif)) = nbfreq(iit);
                            temp=[];
                            [~,ia1,~] = unique(icomp,'stable');
                            for i=1:nbfreq(iit)-1
                                temp=[temp 10*log10(mean(10.^(output_2D{iit}{1}.Sv_fm{ix,iy}(ia1(i):ia1(i+1)-1)/10)))];
                            end
                            temp = [temp output_2D{iit}{1}.Sv_fm{ix,iy}(ia1(end))]; 
                            temp_mvbs_i = [temp_mvbs_i temp];
                            else
                                temp_mvbs_i = [temp_mvbs_i output_2D{iit}{1}.Sv_fm{ix,iy}];
                            end
                        else
                            temp_mvbs_i = [temp_mvbs_i nan(1,nbfreq(iit))];
                        end
                    else
                        if ~isempty(output_2D{iit}{1}.sv(ix,iy))
                            temp_mvbs_i = [temp_mvbs_i 10*log10(output_2D{iit}{1}.sv(ix,iy))];
                        else
                            temp_mvbs_i = [temp_mvbs_i nan(1,nbfreq(iit))];
                        end
                    end
                    temp_sa_i = [temp_sa_i output_2D{iit}{1}.NASC(ix,iy)];
                temp_mvbs{ix,iy} = temp_mvbs_i;
                temp_sa{ix,iy} = temp_sa_i;
                end
            end
        end
        mvbs_to_classify = nan(size(output_2D{1}{1}.sv,1),size(output_2D{1}{1}.sv,2),nbfreqs);
        sa_to_classify = nan(size(output_2D{1}{1}.sv,1),size(output_2D{1}{1}.sv,2),length(nbfreq));
        t_sv = cell2table(temp_mvbs);
        t_sa = cell2table(temp_sa);
        for ix=1:size(output_2D{1}{1}.sv,1)
            for iy=1:size(output_2D{1}{1}.sv,2)
                mvbs_to_classify(ix,iy,:) = t_sv{ix,iy};
                sa_to_classify(ix,iy,:) = t_sa{ix,iy};
            end
        end
        mvbs_to_classify(isinf(mvbs_to_classify)) = NaN;
        
        EI.Freqs = Freqs;
        EI.freq_nom = freq_nom;
        EI.sv = sv_nom;
        EI.Ping_s = ping_s;
        EI.Ping_e = ping_e;
        EI.Depth = depth;
        EI.lat = lat;
        EI.lon = lon;
        EI.MVBS = mvbs_to_classify;
        EI.Sa = sa_to_classify;
        EI.trans_select = freqs.Value;
        
        save(append(path,'/','EI_results_for_clustering.mat'),'EI');
    else
        [EIfile,pathEI] = uigetfile('EI_results_for_clustering.mat');
        EI = load(append(pathEI,EIfile));
        EI = EI.EI;
        Freqs = EI.Freqs;
        freq_nom = EI.freq_nom;
        sv_nom = EI.sv;
        ping_s = EI.Ping_s;
        ping_e = EI.Ping_e;
        depth = EI.Depth;
        lat = EI.lat;
        lon = EI.lon;
        mvbs_to_classify = EI.MVBS;
        sa_to_classify = EI.Sa;
        nbfreqs = size(mvbs_to_classify,3);
        freqs.Value = EI.trans_select;
        nbfreq = length(freqs.Value);
        if step~= Inf
            steps = 200;
            sn = 2;
            sk1 = 1;
        else
            steps = 100;
            sn = 1;
            sk1 = 1;
        end
        cmap = winter(steps)*100;
    end
    
    k = 1;
    id_step = 1;

    while ping_s(end)>step*k
        idk = find(ping_s<=step*k);
        id_step = [id_step idk(end)];
        k = k+1;
    end
    Ping_S = [ping_s ping_e(end)];
    id_step_p = id_step;
    if id_step(end)~=length(ping_s)
        id_step = [id_step length(ping_s)];
        id_step_p = [id_step_p length(ping_s)+1];
    else
        id_step_p(end) = id_step_p(end)+1;
    end
    
    
    
    meanRFclusters_final = [];
    idx_clusters_final = cell(length(id_step)-1,1);
    for ti=2:length(id_step)
        nd = length(freq_nom);
        d = 2;
        r = mod(nd,d);
        if r~=0
            nd = nd+1;
        end
        q = nd/d;
        xlims = [Ping_S(id_step_p(ti-1)) Ping_S(id_step_p(ti))];
        dlims = depth(:,id_step(ti-1):id_step(ti));
        dlims = [dlims(1) dlims(end)];
        if step == Inf
            fig = new_echo_figure(main_figure,'Name','Mean volume backscattering strength');
            axtoolbar({'zoomin','zoomout','pan','restoreview'});
        else
            fig = new_echo_figure(main_figure,'Name',append('Mean volume backscattering strength sample n°',num2str(ti-1)));
        end
        colormap('jet');
        tiledlayout(d,q);
        for iit=1:length(freqs.Value)
            nexttile
            while isnan(dlims(1))
                depth(1,:) = [];
                sv_nom{iit}(1,:) = [];
                sa_to_classify(1,:,:) = [];
                mvbs_to_classify(1,:,:) = [];
                dlims = depth(:,id_step(ti-1):id_step(ti));
            end
            while isnan(dlims(end))
                depth(end,:) = [];
                sv_nom{iit}(end,:) = [];
                sa_to_classify(end,:,:) = [];
                mvbs_to_classify(end,:,:) = [];
                dlims = depth(:,id_step(ti-1):id_step(ti));
            end
            dlims = [dlims(1) dlims(end)];
            img = 10*log10(sv_nom{iit}(:,id_step(ti-1):id_step(ti)));
            img(isinf(img))=NaN;
            set(imagesc(xlims,dlims,img),'AlphaData', ~isnan(img));
            xlim(xlims);
            ylim(dlims);
            clim(Cax);
            xlabel('Ping number')
            ylabel('Depth (m)')
            title(append('Mean volume backscattering strength',' (',num2str(freq_nom(iit)/1000),'kHz)'));
        end
        cb = colorbar;
        cb.Layout.Tile = 'east';
        if step == Inf
            paths = path;
        else
            paths = append(path,'/','Sample n°',num2str(ti-1));
            if ~isfolder(paths)
                mkdir(paths) 
            end
        end
        titlesave = append(paths,'/','Echointegration');
        saveas(fig,titlesave,'png');
        if step~=Inf
            delete(fig);
        end
    
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% CLUSTERING
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for stepi = steps/sn:sk1*steps/sn
            r = num2str(cmap(stepi,1));
            g = num2str(cmap(stepi,2));
            b = num2str(cmap(stepi,3));
            if step == Inf
                msg = ['<p style=color:rgb(' r '%,' g '%,' b '%)>','Clustering WC data ','... </p>'];
            else
                msg = ['<p style=color:rgb(' r '%,' g '%,' b '%)>',append('Clustering WC data segment n°',num2str(ti-1)),'... </p>'];
            end
            dlg.Message = msg;
            dlg.Value = stepi/steps;
            pause(0.05);
        end
    
        ncomponents = 4;
        if nbfreqs<ncomponents
            ncomponents = nbfreqs;
        end
        switch clustering_method    
            case 'KMeans'    
            switch dim_reduc_method
                case 'None'
                    [idx,~] = kmeans(reshape(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),nbfreqs),nclusters);
                case 'PCA'
                    [~,pca_vect] = pca(reshape(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),nbfreqs),'NumComponents',ncomponents);
                    if isempty(pca_vect(~isnan(pca_vect))) 
                        [idx,~] = kmeans(reshape(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),nbfreqs),nclusters);
                    else
                        [idx,~] = kmeans(pca_vect,nclusters);
                    end
                case 't-SNE'
                    sne_vect = tsne(reshape(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),nbfreqs),'NumDimensions',ncomponents);
                    if isempty(sne_vect(~isnan(sne_vect))) 
                        [idx,~] = kmeans(reshape(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),nbfreqs),nclusters);
                    else
                        [idx,~] = kmeans(sne_vect,nclusters);
                    end
            end
            case 'AgC'
                switch dim_reduc_method
                    case 'None'
                        l = linkage(reshape(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),nbfreqs),'average','chebychev');
                        idx = cluster(l,'Maxclust',nclusters);
                    case 'PCA'
                        [~,pca_vect] = pca(reshape(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),nbfreqs),'NumComponents',ncomponents);
                        if isempty(pca_vect(~isnan(pca_vect))) 
                            l = linkage(reshape(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),nbfreqs),'average','chebychev');
                            idx = cluster(l,'Maxclust',nclusters);                   
                        else
                            l = linkage(pca_vect,'average','chebychev');
                            idx = cluster(l,'Maxclust',nclusters);
                        end
                    case 't-SNE'
                        sne_vect = tsne(reshape(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),nbfreqs),'NumDimensions',ncomponents);
                        if isempty(sne_vect(~isnan(sne_vect))) 
                            l = linkage(reshape(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),nbfreqs),'average','chebychev');
                            idx = cluster(l,'Maxclust',nclusters);
                        else
                            l = linkage(sne_vect,'average','chebychev');
                            idx = cluster(l,'Maxclust',nclusters);
                        end
                end
            case 'GM'    
                switch dim_reduc_method
                    case 'PCA'
                        [~,pca_vect] = pca(reshape(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),nbfreqs),'NumComponents',ncomponents);
                        if isempty(pca_vect(~isnan(pca_vect))) 
                            gmfit = fitgmdist(reshape(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),nbfreqs),nclusters);
                            idx = cluster(gmfit,reshape(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),nbfreqs));                
                        else
                            gmfit = fitgmdist(pca_vect,nclusters);
                            idx = cluster(gmfit,pca_vect);
                        end                    
                    case 'None'
                        gmfit = fitgmdist(reshape(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),nbfreqs),nclusters);
                        idx = cluster(gmfit,reshape(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),nbfreqs));
                    case 't-SNE'
                        sne_vect = tsne(reshape(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),nbfreqs),'NumDimensions',ncomponents);
                        if isempty(sne_vect(~isnan(sne_vect))) 
                            gmfit = fitgmdist(reshape(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),nbfreqs),nclusters);
                            idx = cluster(gmfit,reshape(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),nbfreqs));
                        else
                            gmfit = fitgmdist(sne_vect,nclusters);
                            idx = cluster(gmfit,sne_vect);
                        end
                end
        end
        meanRFclusters = zeros(nclusters,nbfreqs);
        Mvbs_to_classify = reshape(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),nbfreqs);
    
        for iin=1:nclusters
            idxc = find(idx==iin);
            if length(idxc)>1
                meanRFclusters(iin,:) = 10*log10(mean(10.^(Mvbs_to_classify(idxc,:)/10)));
            else
                meanRFclusters(iin,:) = Mvbs_to_classify(idxc,:);
            end
        end
        
        temp_idx = nan(size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),1);
        temp_idx(1:size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),:) = idx;
        idx_clusters_final{ti-1} = temp_idx;
        meanRFclusters_final = vertcat(meanRFclusters_final,meanRFclusters);
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% PLOTS
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if step == Inf
            fig = new_echo_figure(main_figure,'Name','Clustering of Sv data');
            axtoolbar({'zoomin','zoomout','pan','restoreview'});
        else
            fig = new_echo_figure(main_figure,'Name',append('Clustering of Sv data sample n°',num2str(ti-1)));
        end
        colormap(mymap);
        img = reshape(idx,size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2));
        img(isinf(img))=NaN;
        set(imagesc(xlims,dlims,img),'AlphaData', ~isnan(img));
        xlim(xlims);
        ylim(dlims);
        xlabel('Ping number')
        ylabel('Depth (m)')
        colorbar();
        titlesave = append(paths,'/','Clustering');
        saveas(fig,titlesave,'png');
        if step~=Inf
            delete(fig);
        end
        
        if step == Inf
            fig = new_echo_figure(main_figure,'Name','Frequency spectra for each cluster ');
            axtoolbar({'zoomin','zoomout','pan','restoreview'});
        else
            fig = new_echo_figure(main_figure,'Name',append('Frequency spectra for each cluster sample n°',num2str(ti-1)));
        end
        legendtxt = {};
        for iic=1:nclusters
            hold on
            plot(Freqs,meanRFclusters(iic,:),'Color',mymap(iic,:),'LineWidth',2) 
            legendtxt{iic} = append('Cluster n°',num2str(iic));
        end
        xlabel('Frequencies (Hz)')
        ylabel('MVBS (dB)') 
        legend(legendtxt)
        titlesave = append(paths,'/','ClusteringFR');
        saveas(fig,titlesave,'png');
        if step ~= Inf
            delete(fig);
        end
    
        Sa_interm = reshape(sa_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*...
            size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),length(freqs.Value));
        Lat = repelem(lat(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1),1);
        Lon = repelem(lon(:,id_step_p(ti-1):id_step_p(ti)-1,:),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1),1);
        Lat = reshape(Lat,size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),1);
        Lon = reshape(Lon,size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),1)*size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2),1);
        for iin=1:nclusters
            if step == Inf
                figgeo = new_echo_figure(main_figure,'Name',append('Nautical area scattering coefficient (cluster n°',num2str(iin),')'));
            else
                figgeo = new_echo_figure(main_figure,'Name',append('Nautical area scattering coefficient for sample n°',num2str(ti-1),' (cluster n°',num2str(iin),')'));
            end
            tiledlayout(d,q);
            for iit=1:length(freqs.Value)
                Sa = Sa_interm(:,iit);
                tablePlotSaLatLon=table(Lat,Lon,Sa);
                idxc = find(idx==iin);
                nexttile;
                gb = geobubble(tablePlotSaLatLon(idxc,:),'Lat','Lon','SizeVariable','Sa','Basemap','darkwater');
                gb.BubbleColorList = mymap(iin,:);
                gb.SizeLimits = [min(Sa) max(Sa)];
                gb.Title = ['Nautical area scattering coefficient ' '(m^{' num2str(2) '}' 'nmi^{' num2str(-2) '}' ') for cluster n°' num2str(1) ' (' num2str(freqs_nom(1)/1000) 'kHz)'];
                gb.SizeLegendTitle = 'Depth integrated abundance';
            end
            titlesave=append(paths,'/','NASC for cluster n°',num2str(iin));
            saveas(figgeo,titlesave,'png');
            if step ~= Inf
                delete(figgeo);
            end
        end 
    end
    
    if step ~= Inf
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% RECOMBINING RESULTS FOR WHOLE LAYER SELECTED
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for stepi = sk1*steps/sn:steps
            r = num2str(cmap(stepi,1));
            g = num2str(cmap(stepi,2));
            b = num2str(cmap(stepi,3));
            msg = ['<p style=color:rgb(' r '%,' g '%,' b '%)> Calculating and recombining final results... </p>'];
            dlg.Message = msg;
            dlg.Value = stepi/steps;
            pause(0.05);
        end
        
        fig = new_echo_figure(main_figure,'Name','Mean volume backscattering strength');
        axtoolbar({'zoomin','zoomout','pan','restoreview'});
        tiledlayout(d,q);
        colormap('jet')
        Xlims = [ping_s(1) ping_s(end)];
        dlims = depth(:,1);
        dlims = [dlims(1) dlims(end)];
        for iit=1:length(freqs.Value)
            nexttile
    
            img = 10*log10(sv_nom{iit});
            img(isinf(img))=NaN;
    
            set(imagesc(Xlims,dlims,img),'AlphaData', ~isnan(img));
            xlim(Xlims);
            ylim(dlims);
            clim(Cax);
            xlabel('Ping number')
            ylabel('Depth (m)')
            title(append('Mean volume backscattering strength',' (',num2str(freq_nom(iit)/1000),'kHz)'))
        end
        cb = colorbar;
        cb.Layout.Tile = 'east';
        titlesave = append(path,'/','Echointegration');
        saveas(fig,titlesave,'png');
        
        mymapfinal = mymap(1:nclusters,:);
        
        [idxRF,~] = kmeans(meanRFclusters_final,nclusters);
        
        fig = new_echo_figure(main_figure,'Name','Frequency spectra for each cluster');
        axtoolbar({'zoomin','zoomout','pan','restoreview'});
        legendtxt = {};
        for iin=1:nclusters
            idxc = find(idxRF==iin);
            if length(idxc)>1
                meanRFrecomb = 10*log10(mean(10.^(meanRFclusters_final(idxc,:)/10)));
            else
                meanRFrecomb = meanRFclusters_final(idxc,:);
            end
            hold on
            plot(Freqs,meanRFrecomb,'Color',mymapfinal(iin,:),'LineWidth',2);
            legendtxt{iin} = append('Cluster n°',num2str(iin));
        end
        xlabel('Frequencies (Hz)')
        ylabel('MVBS (dB)') 
        legend(legendtxt)
        titlesave = append(path,'/','ClusteringFR');
        saveas(fig,titlesave,'png');
        
        idx_clusters_final_recomb = [];
        for ti=2:length(id_step)
            idxRF = reshape(idxRF,nclusters,length(id_step)-1); 
            idx_clusters_final_temp = nan(size(mvbs_to_classify,1),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2));
            for iin=1:nclusters
                mask = idx_clusters_final{ti-1}==iin;
                idx_clusters_final_temp(mask)=idxRF(iin,ti-1);
            end
            idx_clusters_final_temp2 = nan(size(mvbs_to_classify,1),size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2));
            idx_clusters_final_temp2(1:size(mvbs_to_classify,1),1:size(mvbs_to_classify(:,id_step_p(ti-1):id_step_p(ti)-1,:),2)) = idx_clusters_final_temp;
            idx_clusters_final_recomb = [idx_clusters_final_recomb idx_clusters_final_temp2]; 
        end
        
        fig = new_echo_figure(main_figure,'Name','Clustering of Sv data');
        axtoolbar({'zoomin','zoomout','pan','restoreview'});
        colormap(mymapfinal);
        img = idx_clusters_final_recomb;
        img(isinf(img))=NaN;
    
        set(imagesc(Xlims,dlims,img),'AlphaData', ~isnan(img));
        axis on
        xlabel('Ping number')
        xlim(Xlims)
        ylim(dlims);
        ylabel('Depth (m)')
        colorbar();
        titlesave = append(path,'/','Clustering');
        saveas(fig,titlesave,'png');
    
        Lat = repelem(lat,size(mvbs_to_classify,1),1);
        Lon = repelem(lon,size(mvbs_to_classify,1),1);
        Lat = reshape(Lat,size(mvbs_to_classify,1)*size(mvbs_to_classify,2),1);
        Lon = reshape(Lon,size(mvbs_to_classify,1)*size(mvbs_to_classify,2),1);
        for iin=1:nclusters
            figgeo = new_echo_figure(main_figure,'Name',append('Nautical area scattering coefficient (cluster n°',num2str(iin),')'));
            tiledlayout(d,q);
            idxc = find(idx_clusters_final_recomb==iin);
            for iit=1:length(freqs.Value)
                Sa = reshape(sa_to_classify(:,:,iit),size(mvbs_to_classify,1)*size(mvbs_to_classify,2),1);
                tablePlotSaLatLon=table(Lat,Lon,Sa);
                nexttile;
                gb = geobubble(tablePlotSaLatLon(idxc,:),'Lat','Lon','SizeVariable','Sa','Basemap','darkwater');
                gb.BubbleColorList = mymapfinal(iin,:);
                gb.SizeLimits = [min(Sa) max(Sa)];
                gb.Title = ['Nautical area scattering coefficient ' '(m^{' num2str(2) '}' 'nmi^{' num2str(-2) '}' ') for cluster n°' num2str(1) ' (' num2str(freqs_nom(1)/1000) 'kHz)'];
                gb.SizeLegendTitle = 'Depth integrated abundance';
            end
            titlesave=append(path,'/','NASC for cluster n°',num2str(iin));
            saveas(figgeo,titlesave,'png');
        end
    end
    close(dlg)
    close(reg_fig)
    end
end















