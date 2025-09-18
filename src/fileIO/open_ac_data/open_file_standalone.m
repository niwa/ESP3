function [new_layers,multi_lay_mode]=open_file_standalone(Filename,ftype,varargin)

PROF = false && ~isdeployed;
if PROF
    profile on;
end

p = inputParser;

if ~iscell(Filename)
    Filename={Filename};
end

def_path_m = fullfile(tempdir,'data_echo');

addRequired(p,'Filename',@(x) ischar(x)||iscell(x));
addRequired(p,'ftype',@(x) ischar(x));
addParameter(p,'PathToMemmap',def_path_m,@ischar);
addParameter(p,'load_bar_comp',[]);
addParameter(p,'already_opened_files',{},@iscell);
addParameter(p,'parallel_process',false,@islogical);
addParameter(p,'dfile',0,@isnumeric);
addParameter(p,'CVSCheck',1);
addParameter(p,'CVSroot','');
addParameter(p,'SvCorr',1);
addParameter(p,'Calibration',[]);
addParameter(p,'EnvData',[]);
addParameter(p,'absorption',[]);
addParameter(p,'absorption_f',[]);
addParameter(p,'Frequencies',[]);
addParameter(p,'Channels',{});
addParameter(p,'open_all_channels',false);
addParameter(p,'Keep_complex_data',false,@islogical);
addParameter(p,'ComputeImpedance',false,@islogical);
addParameter(p,'FieldNames',{});
addParameter(p,'EsOffset',[]);
addParameter(p,'GPSOnly',0);
addParameter(p,'LoadEKbot',0);
addParameter(p,'force_open',1);
addParameter(p,'bot_ver',-1);
addParameter(p,'reg_ver',-1);

new_layers=[];
multi_lay_mode=0;

parse(p,Filename,ftype,varargin{:});

Filename(strcmpi(Filename,'desktop.ini'))=[];
block_len = get_block_len(50,'cpu',[]);
if isempty(Filename)
    return;
end

if isempty(ftype)
    ftype_cell = cellfun(@get_ftype,Filename,'un',0);
else
    ftype_cell=cell(1,numel(Filename));
    ftype_cell(:)={ftype};
end

ftype_cell_unique=unique(ftype_cell);

for iftype=1:numel(ftype_cell_unique)
    try
        new_layers_tmp=[];
        Filename_tmp=Filename(strcmp(ftype_cell,ftype_cell_unique{iftype}));
        ftype=ftype_cell_unique{iftype};

        switch ftype
            case 'SLG'
                new_layers_tmp=open_sl_file_stdalone(Filename_tmp,...
                    'PathToMemmap',p.Results.PathToMemmap,...
                    'Frequencies',p.Results.Frequencies,...
                    'Channels',p.Results.Channels,...
                    'GPSOnly',p.Results.GPSOnly,...
                    'load_bar_comp',p.Results.load_bar_comp);
            case 'OCULUS'
                new_layers_tmp=open_oculus_file_stdalone(Filename_tmp,...
                    'PathToMemmap',p.Results.PathToMemmap,...
                    'Frequencies',p.Results.Frequencies,...
                    'Channels',p.Results.Channels,...
                    'GPSOnly',p.Results.GPSOnly,...
                    'load_bar_comp',p.Results.load_bar_comp);

            case 'NETCDF4'
                new_layers_tmp=open_NETCDF4_file_stdalone(Filename_tmp,...
                    'PathToMemmap',p.Results.PathToMemmap,...
                    'Frequencies',p.Results.Frequencies,...
                    'Channels',p.Results.Channels,...
                    'GPSOnly',p.Results.GPSOnly,...
                    'load_bar_comp',p.Results.load_bar_comp);
            case 'DIDSON'
                new_layers_tmp=open_DDF_file_stdalone(Filename_tmp,...
                    'PathToMemmap',p.Results.PathToMemmap,...
                    'load_bar_comp',p.Results.load_bar_comp);
                multi_lay_mode=0;

            case 'EM'
                new_layers_tmp=open_em_file_standalone(Filename_tmp,...
                    'Frequencies',p.Results.Frequencies,...
                    'Channels',p.Results.Channels,...
                    'GPSOnly',p.Results.GPSOnly,...
                    'PathToMemmap',p.Results.PathToMemmap,...
                    'load_bar_comp',p.Results.load_bar_comp);
            case 'KEM'
                new_layers_tmp=open_kem_file_standalone(Filename_tmp,...
                    'Frequencies',p.Results.Frequencies,...
                    'Channels',p.Results.Channels,...
                    'GPSOnly',p.Results.GPSOnly,...
                    'PathToMemmap',p.Results.PathToMemmap,...
                    'load_bar_comp',p.Results.load_bar_comp);
            case 'FCV-30'
                for ifi = 1:length(Filename_tmp)
                    if ~isempty(p.Results.load_bar_comp)
                        str_disp=sprintf('Opening File %d/%d : %s',ifi,length(Filename_tmp),Filename_tmp{ifi});
                        p.Results.load_bar_comp.progress_bar.setText(str_disp);
                    end

                    lays_tmp=open_FCV30_file(Filename_tmp{ifi},...
                        'already_opened_files',p.Results.already_opened_files,...
                        'PathToMemmap',p.Results.PathToMemmap,...
                        'load_bar_comp',p.Results.load_bar_comp);

                    new_layers_tmp=[new_layers_tmp lays_tmp];
                    if ~isempty(p.Results.load_bar_comp)
                        set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(Filename_tmp),'Value',ifi);
                    end
                end
                multi_lay_mode=0;

            case {'EK60','EK80','ME70','MS70'}
                new_layers_tmp=open_EK_file_stdalone(Filename_tmp,...
                    'parallel_process',p.Results.parallel_process,...
                    'LoadEKbot',p.Results.LoadEKbot,...
                    'EsOffset',p.Results.EsOffset,...
                    'Frequencies',p.Results.Frequencies,...
                    'Channels',p.Results.Channels,...
                    'open_all_channels',p.Results.open_all_channels,...
                    'GPSOnly',p.Results.GPSOnly,...
                    'FieldNames',p.Results.FieldNames,...
                    'PathToMemmap',p.Results.PathToMemmap,...
                    'load_bar_comp',p.Results.load_bar_comp,...
                    'env_data',p.Results.EnvData,...
                    'Calibration',p.Results.Calibration,...
                    'force_open',p.Results.force_open,...
                    'Keep_complex_data',p.Results.Keep_complex_data,....
                    'ComputeImpedance',p.Results.ComputeImpedance);
                multi_lay_mode=0;
            case 'ASL'
                new_layers_tmp=open_asl_files(Filename_tmp,...
                    'already_opened_files',p.Results.already_opened_files,...
                    'PathToMemmap',p.Results.PathToMemmap,...
                    'Frequencies',p.Results.Frequencies,...
                    'load_bar_comp',p.Results.load_bar_comp,...
                    'force_open',p.Results.force_open);
                multi_lay_mode=0;

            case 'TOPAS'
                new_layers_tmp=open_topas_files(Filename_tmp,...
                    'PathToMemmap',p.Results.PathToMemmap,'load_bar_comp',p.Results.load_bar_comp);
                multi_lay_mode=0;
            case 'CREST'
                switch p.Results.dfile
                    case 1
                        new_layers_tmp=read_crest(Filename_tmp,...
                            'PathToMemmap',p.Results.PathToMemmap,...
                            'load_bar_comp',p.Results.load_bar_comp,...
                            'CVSCheck',p.Results.CVSCheck,...
                            'CVSroot',p.Results.CVSroot,...
                            'SvCorr',p.Results.SvCorr);
                    case 0
                        [new_layers_tmp,found_raw_files]=open_dfile(Filename_tmp,...
                            'CVSCheck',p.Results.CVSCheck,...
                            'CVSroot',p.Results.CVSroot,...
                            'PathToMemmap',p.Results.PathToMemmap,...
                            'load_bar_comp',p.Results.load_bar_comp,...
                            'EsOffset',p.Results.EsOffset);
                        if any(~found_raw_files)
                            new_layers_tmp_2=read_crest(Filename_tmp(~found_raw_files),...
                                'PathToMemmap',p.Results.PathToMemmap,...
                                'CVSCheck',p.Results.CVSCheck,...
                                'CVSroot',p.Results.CVSroot,...
                                'SvCorr',p.Results.SvCorr);
                            new_layers_tmp = [new_layers_tmp new_layers_tmp_2];
                        end
                end
                multi_lay_mode=0;

            case 'XTF'
                new_layers_tmp=open_xtf_file_stdalone(Filename_tmp,...
                    'PathToMemmap',p.Results.PathToMemmap,...
                    'load_bar_comp',p.Results.load_bar_comp);
                multi_lay_mode=0;
            case {'Unknown'}
                for ifi=1:length(Filename_tmp)
                    fprintf('Unknown File type for Filename %s\n',Filename_tmp{ifi});
                end
            otherwise
                for ifi=1:length(Filename_tmp)
                    fprintf('Unrecognized File type for Filename %s\n',Filename_tmp{ifi});
                end
        end

        if isempty(new_layers_tmp)
            return;
        end

        new_layers_tmp.add_config_from_config_xml();
        new_layers_tmp.add_lines_from_line_xml();
        new_layers_tmp.create_survey_options_xml([]);

        if ~isempty(p.Results.load_bar_comp)&&~p.Results.parallel_process
            p.Results.load_bar_comp.progress_bar.set('Minimum',0,'Maximum',numel(new_layers_tmp),'Value',0);
        end

        id_rem_lay = [];

        if ~isempty(p.Results.load_bar_comp)&&~p.Results.parallel_process
            p.Results.load_bar_comp.progress_bar.setText('Last loading steps....');
        end

        for uil=1:numel(new_layers_tmp)

            if p.Results.GPSOnly==0

                nb_trans = numel(new_layers_tmp(uil).Transceivers);
                if nb_trans ==0
                    id_rem_lay = union(uil,id_rem_lay);
                    continue;
                end

                for uit = 1:nb_trans
                    new_layers_tmp(uil).Transceivers(uit).Params = new_layers_tmp(uil).Transceivers(uit).Params.reduce_params();
                end

                if ~isempty(p.Results.EnvData)
                    new_layers_tmp(uil).set_EnvData(p.Results.EnvData);

                    if isempty(p.Results.EnvData.CTD.depth)&&strcmpi(p.Results.EnvData.CTD.ori,'profile')
                        new_layers_tmp(uil).load_ctd('','profile');
                    end

                    if isempty(p.Results.EnvData.SVP.depth)&&strcmpi(p.Results.EnvData.SVP.ori,'profile')
                        new_layers_tmp(uil).load_svp('','profile');
                    end

                else
                    surv_options_obj = new_layers_tmp(uil).get_survey_options();
                    
                    if ~isnan(surv_options_obj.SoundSpeed.Value)
                        new_layers_tmp(uil).EnvData.SoundSpeed=surv_options_obj.SoundSpeed.Value;
                    end

                    if ~isnan(surv_options_obj.Temperature.Value)
                        new_layers_tmp(uil).EnvData.Temperature=surv_options_obj.Temperature.Value;
                    end

                    if ~isnan(surv_options_obj.Salinity.Value)
                        new_layers_tmp(uil).EnvData.Salinity=surv_options_obj.Salinity.Value;
                    end

                    for uit=1:numel(new_layers_tmp(uil).Transceivers)
                        new_layers_tmp(uil).Transceivers(uit).Config.EsOffset = surv_options_obj.Es60_correction.Value;
                    end

                    new_layers_tmp(uil).load_svp('','constant');
                    new_layers_tmp(uil).load_ctd('','constant');
                end

                new_layers_tmp(uil).layer_computeSpSv('Calibration',p.Results.Calibration,...
                    'load_bar_comp',p.Results.load_bar_comp,...
                    'absorption_f',p.Results.absorption_f,...
                    'absorption',p.Results.absorption,...
                    'block_len',block_len);


                if ~isempty(p.Results.load_bar_comp)&&~p.Results.parallel_process
                    p.Results.load_bar_comp.progress_bar.set('Minimum',0,'Maximum',numel(new_layers_tmp),'Value',uil);
                end
            end

        end

        new_layers_tmp(id_rem_lay) = [];

        if ~p.Results.GPSOnly
            switch ftype
                case {'ME70' 'MS70'}
                    if ~isempty(p.Results.load_bar_comp)&&~p.Results.parallel_process
                        p.Results.load_bar_comp.progress_bar.setText('Grouping ME70/MS70 channels');
                        p.Results.load_bar_comp.progress_bar.set('Minimum',0,'Maximum',numel(new_layers_tmp),'Value',0);
                    end
                    for uil = 1:numel(new_layers_tmp)
                        try
                            new_layers_tmp(uil).group_channels('load_bar_comp',p.Results.load_bar_comp);
                        catch err
                            print_errors_and_warnings(1,'error',err);
                        end
                        if ~isempty(p.Results.load_bar_comp)&&~p.Results.parallel_process
                            p.Results.load_bar_comp.progress_bar.set('Minimum',0,'Maximum',numel(new_layers_tmp),'Value',uil);
                        end
                    end

            end
            for uil = 1:numel(new_layers_tmp)
                new_layers_tmp(uil).get_att_data_from_csv({},0);
                new_layers_tmp(uil).get_gps_data_from_csv({},0);
                if ~p.Results.parallel_process
                    algo_vec_init=init_algos();
                    [~,~,algo_vec,~]=load_config_from_xml(0,0,1);
                    new_layers_tmp(uil).add_algo(algo_vec_init,'reset_range',true);
                    new_layers_tmp(uil).add_algo(algo_vec,'reset_range',true);
                    new_layers_tmp(uil).load_bot_regs('bot_ver',p.Results.bot_ver,'reg_ver',p.Results.reg_ver);
                end
            end
        end
        new_layers=[new_layers new_layers_tmp];
    catch err
        print_errors_and_warnings(1,'error',err);
    end

end

if PROF
    profile off;
    profile viewer;
end