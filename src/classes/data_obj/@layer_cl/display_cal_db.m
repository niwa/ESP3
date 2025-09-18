function[cal_fig,cal_fig_deep] = display_cal_db(layers_obj,varargin)

p = inputParser;

addRequired(p,'layers_obj',@(obj) isa(obj,'layer_cl'));
addParameter(p,'cal_keys',[]);
addParameter(p,'cal_fig',[]);
addParameter(p,'cal_fig_deep',[]);

parse(p,layers_obj,varargin{:});
cal_fig  = p.Results.cal_fig;
cal_fig_deep  = p.Results.cal_fig_deep;
cal_keys  = p.Results.cal_keys;

main_figure = get_esp3_prop('main_figure');
summary_table = [];
for ilay = 1:numel(layers_obj)
    layer_obj = layers_obj(ilay);

    [pathtofile,~]=layer_obj.get_path_files();
    pathtofile=unique(pathtofile);

    pathtofile(cellfun(@isempty,pathtofile))=[];

    fileN=fullfile(pathtofile{1},'cal_echo.db');
    dbconn = connect_to_db(fileN);

    if isempty(dbconn)
        file_sql=fullfile(whereisEcho,'config','db','cal_db.sql');
        create_ac_database(fileN,file_sql,1,false);
        dbconn = connect_to_db(fileN);
    end

    db_to_cal_struct_cell = translate_db_to_cal_cell();
    db_to_params_struct_cell = translate_db_to_params_cell();

    cal_str = strjoin(cellfun(@(x) sprintf('cal.%s AS %s',x{1},x{2}),db_to_cal_struct_cell,'UniformOutput',false),', ');
    params_str = strjoin(cellfun(@(x) sprintf('params.%s AS %s',x{1},x{2}),db_to_params_struct_cell,'UniformOutput',false),', ');

    if isempty(cal_keys)
        sql_cmd = sprintf(['SELECT %s, %s, cal.calibration_date, cal.calibration_fm_xml_str, cal.calibration_pkey,'...
            'soundprop.sound_propagation_absorption AS abs, soundprop.sound_propagation_velocity AS soundspeed '...
            'FROM t_calibration AS cal, t_parameters AS params, t_sound_propagation as soundprop '...
            'WHERE cal.calibration_channel_ID in (%s) AND cal.calibration_parameters_key = params.parameters_pkey AND cal.calibration_sound_propagation_key = soundprop.sound_propagation_pkey'],...
            cal_str,params_str,strjoin(cellfun(@(x) sprintf('''%s''',x),layer_obj.ChannelID,'UniformOutput',false),', '));

    else
        sql_cmd = sprintf(['SELECT %s, %s, cal.calibration_date, cal.calibration_fm_xml_str,'...
            'soundprop.sound_propagation_absorption AS abs, soundprop.sound_propagation_velocity AS soundspeed '...
            'FROM t_calibration AS cal, t_parameters AS params, t_sound_propagation as soundprop '...
            'WHERE cal.calibration_pkey in (%s) AND cal.calibration_channel_ID in (%s) AND cal.calibration_parameters_key = params.parameters_pkey AND cal.calibration_sound_propagation_key = soundprop.sound_propagation_pkey'],...
            strjoin(compose('%d',cal_keys),', '),cal_str,params_str,cal_str,params_str,strjoin(cellfun(@(x) sprintf('''%s''',x),layer_obj.ChannelID,'UniformOutput',false),', '));
    end

    summary_table_tmp = dbconn.fetch(sql_cmd);
    summary_table_tmp.eq_beam_angle=estimate_eba(summary_table_tmp.BeamWidthAthwartship,summary_table_tmp.BeamWidthAlongship);
    summary_table_tmp.ilay = ones(size(summary_table_tmp.eq_beam_angle))*ilay;
    dbconn.close();
    summary_table = [summary_table;summary_table_tmp];
end

if isempty(summary_table.up_or_down_cast)
    return;
end
disp(summary_table);

lgd = {};
h = [];
static_idx = find(strcmpi(summary_table.up_or_down_cast,'static'));

if isempty(cal_fig)&&~isempty(static_idx)
    cal_fig=new_echo_figure(main_figure,'UiFigureBool',true,'Name','Calibration from database','Tag','db_calibration');

    uigl = uigridlayout(cal_fig,[1,2]);
    uigl.ColumnWidth = {0,'1x'};
    uigl_ax = uigridlayout(uigl,[2,2]);
    uigl_ax.Layout.Column = 2;

    ax_G0=axes(uigl_ax,'Box','on','Nextplot','add');
    grid(ax_G0,'on');
    ylabel(ax_G0,'Gain(dB)')
    ax_G0.XTickLabels={''};

    ax_SACORRECT=axes(uigl_ax,'Box','on','Nextplot','add');
    grid(ax_SACORRECT,'on');
    ylabel(ax_SACORRECT,'S_{a,corr}(dB)')
    ax_SACORRECT.XTickLabels={''};

    ax_BW=axes(uigl_ax,'Box','on','Nextplot','add');
    grid(ax_BW,'on')
    ylabel(ax_BW,'BeamWidth(^circ)')
    ax_BW.XAxis.TickLabelFormat  = '%d\kHz';
    %ax_BW.XTickLabels={''};

    ax_EQA=axes(uigl_ax,'Box','on','Nextplot','add');
    grid(ax_EQA,'on')
    ax_EQA.XAxis.TickLabelFormat  = '%d\kHz';
    ylabel(ax_EQA,'EBA(dB)');
end
[cal_path,~,~]=fileparts(layer_obj.Filename{1});
cal_fig.UserData.db_file = fileN;

for uistr  = static_idx'
    switch summary_table.Mode{uistr}
        case 'FM'
            tmpf= fullfile([tempname '.xml']);
            fid = fopen(tmpf,'w+');
            fwrite(fid,summary_table.calibration_fm_xml_str{uistr},'char');
            fclose(fid);
            cal_xml = parse_simrad_xml_calibration_file(tmpf);
            delete(tmpf);
            cal_xml.eq_beam_angle = estimate_eba(cal_xml.BeamWidthAthwartship,cal_xml.BeamWidthAlongship);

            trans_obj = layer_obj.get_trans(summary_table.CID{uistr});

            if ~isempty(trans_obj)
                cal_fm = trans_obj.get_transceiver_fm_cal();
                plot(ax_G0,cal_fm.Frequency/1e3,cal_fm.Gain_th,'Color','k','userdata',summary_table.calibration_pkey(uistr));
                plot(ax_BW,cal_fm.Frequency/1e3,cal_fm.BeamWidthAthwartship_th,'Color','k','userdata',summary_table.calibration_pkey(uistr));
                plot(ax_BW,cal_fm.Frequency/1e3,cal_fm.BeamWidthAlongship_th,'Color','k','linestyle','-.','userdata',summary_table.calibration_pkey(uistr));
                plot(ax_EQA,cal_fm.Frequency/1e3,estimate_eba(cal_fm.BeamWidthAthwartship_th,cal_fm.BeamWidthAlongship_th),'Color','k','userdata',summary_table.calibration_pkey(uistr));
            end

            tmph = plot(ax_G0,cal_xml.Frequency/1e3,cal_xml.Gain,'userdata',summary_table.calibration_pkey(uistr));

            plot(ax_BW,cal_xml.Frequency/1e3,cal_xml.BeamWidthAlongship,'color',tmph.Color,'userdata',summary_table.calibration_pkey(uistr));
            plot(ax_BW,cal_xml.Frequency/1e3,cal_xml.BeamWidthAthwartship,'color',tmph.Color,'linestyle','-.','userdata',summary_table.calibration_pkey(uistr));
            plot(ax_EQA,cal_xml.Frequency/1e3,cal_xml.eq_beam_angle,'color',tmph.Color,'userdata',summary_table.calibration_pkey(uistr));

            create_ctxt_menu(tmph,trans_obj,cal_path,summary_table.calibration_fm_xml_str{uistr});
            pointerBehavior.enterFcn    = @(src, evt) enter_line_plot_fcn(src, evt,tmph);
            pointerBehavior.exitFcn     = @(src, evt) exit_line_plot_fcn(src, evt,tmph);
            pointerBehavior.traverseFcn = [];
            iptSetPointerBehavior(tmph,pointerBehavior);

        otherwise

            tmph = plot(ax_G0,summary_table.FREQ(uistr)/1e3,summary_table.G0(uistr),'Marker','o','linestyle','none','userdata',summary_table.calibration_pkey(uistr));

            plot(ax_BW,summary_table.FREQ(uistr)/1e3,summary_table.BeamWidthAlongship(uistr),'Marker','o','color',tmph.Color,'linestyle','none','userdata',summary_table.calibration_pkey(uistr));
            plot(ax_BW,summary_table.FREQ(uistr)/1e3,summary_table.BeamWidthAthwartship(uistr),'color',tmph.Color,'Marker','x','linestyle','none','userdata',summary_table.calibration_pkey(uistr));
            plot(ax_EQA,summary_table.FREQ(uistr)/1e3,summary_table.EQA(uistr),'Marker','o','color',tmph.Color,'linestyle','none','userdata',summary_table.calibration_pkey(uistr));
            plot(ax_SACORRECT,summary_table.FREQ(uistr)/1e3,summary_table.SACORRECT(uistr),'Marker','o','color',tmph.Color,'linestyle','none','userdata',summary_table.calibration_pkey(uistr));
    end

    h = [h tmph];
    str_tmp = sprintf('%s: Channel %s, %s T: %.1f ms, Ptx: %d W',summary_table.calibration_date{uistr}(1:4),summary_table.CID{uistr},summary_table.Mode{uistr},summary_table.PulseLength(uistr)*1e3,summary_table.TransmitPower(uistr));
    lgd = [lgd str_tmp];

end

if ~isempty(h)
    legend(h,lgd,'interpreter','none','location','southeast');
end

deep_idx = find(ismember(lower(summary_table.up_or_down_cast),{'upcast','downcast'})&strcmpi(summary_table.Mode,'CW'));

if isempty(cal_fig_deep)&&~isempty(deep_idx)
    cal_fig_deep=new_echo_figure(main_figure,'UiFigureBool',true,'Name','Deep Calibration from database','Tag','deep_db_calibration');
    CIDs = unique(summary_table.CID(deep_idx));
    dcast = {'Upcast' 'Downcast'};
    uigl = uigridlayout(cal_fig_deep,[numel(CIDs),4]);

    for uic = 1:numel(CIDs)
        ax_abs(uic) = uiaxes(uigl,'YDir','reverse','NextPlot','add','Box','on');
        grid(ax_abs(uic),'on');ylabel(ax_abs(uic),'Depth(m)');xlabel(ax_abs(uic),'Absorption(dB/km)');

        ax_ss(uic) = uiaxes(uigl,'YDir','reverse','NextPlot','add','Box','on');
        grid(ax_ss(uic),'on'); grid(ax_abs(uic),'on');xlabel(ax_ss(uic),'Soundspeed(m/s)');

        ax_g0(uic) = uiaxes(uigl,'YDir','reverse','NextPlot','add','Box','on');
        grid(ax_g0(uic),'on'); grid(ax_g0(uic),'on');xlabel(ax_g0(uic),'Gain(dB)');

        ax_sac(uic) = uiaxes(uigl,'YDir','reverse','NextPlot','add','Box','on');
        grid(ax_sac(uic),'on'); grid(ax_sac(uic),'on');xlabel(ax_sac(uic),'s_{a,corr}(dB)');

        lgd{uic} = {};


        for uid = 1:numel(dcast)

            idx_t = intersect(deep_idx,find(strcmpi(summary_table.CID,CIDs{uic})&strcmpi(summary_table.up_or_down_cast,dcast{uid})));

            sub_table = summary_table(idx_t,:);

            G = findgroups(sub_table(:,{'TransmitPower' 'PulseLength'}));
            id_g = unique(G);

            for uitt = id_g(:)'
                idx_tt = idx_t(G == uitt);
                [dd,idx_s] = sort(summary_table.depth(idx_tt));

                if ~isempty(idx_tt)
                    plot(ax_sac(uic),summary_table.SACORRECT(idx_tt(idx_s)),dd);
                    plot(ax_g0(uic),summary_table.G0(idx_tt(idx_s)),dd);
                    plot(ax_abs(uic),summary_table.abs(idx_tt(idx_s)),dd);
                    plot(ax_ss(uic),summary_table.soundspeed(idx_tt(idx_s)),dd);
                    str_tmp = sprintf('%s: Channel %s, %s T: %.1f ms, Ptx: %d W',dcast{uid},summary_table.CID{idx_tt(1)},summary_table.Mode{idx_tt(1)},summary_table.PulseLength(idx_tt(1))*1e3,summary_table.TransmitPower(idx_tt(1)));
                    lgd{uic}  = [lgd{uic} str_tmp];
                end
            end
        end
        ax_sac(uic).XLim = ax_sac(uic).XLim +[-0.05 0.05];
        ax_g0(uic).XLim = ax_g0(uic).XLim +[-0.5 0.5];
        legend(ax_ss(uic),lgd{uic},'interpreter','none');
    end


end
drawnow;
pause(0.1);
% if ~isempty(h)
%     linkaxes([ax_G0 ax_SACORRECT ax_BW ax_EQA],'x');
% end



end


function exit_line_plot_fcn(~,~,hplot)

if ~isvalid(hplot)
    delete(hplot);
    return;
end
set(hplot,'linewidth',0.5);

end

function enter_line_plot_fcn(src,~,hplot)

if ~isvalid(hplot)
    delete(hplot);
    return;
end

set(src, 'Pointer', 'hand');
set(hplot,'linewidth',2);
end

function create_ctxt_menu(h,trans_obj,cal_path,cal_str)

file_cal=fullfile(cal_path,generate_valid_filename(['Calibration_FM_' trans_obj.Config.ChannelID '.xml']));
ff = ancestor(h,'figure');
plot_cxtmenu = uicontextmenu(ancestor(h,'figure'));
uimenu(plot_cxtmenu,'Label','Use this calibration','MenuSelectedFcn',{@save_cal_to_xml_cback,file_cal,cal_str});
uimenu(plot_cxtmenu,'Label','Delete this calibration','MenuSelectedFcn',{@delete_cal_from_db_cback,ff});
h.UIContextMenu=plot_cxtmenu;
end


function delete_cal_from_db_cback(src,~,ff)
plot_h = ff.CurrentObject;
pkey = plot_h.UserData;
fileN = ff.UserData.db_file;
dbconn = connect_to_db(fileN);
sql_cmd = sprintf('DELETE FROM t_calibration AS cal WHERE cal.calibration_pkey = %d',pkey);
dbconn.exec(sql_cmd);
dbconn.close();
delete(plot_h);
delete(findobj(ff,'UserData',pkey));
delete(src);
end

function save_cal_to_xml_cback(~,~,fname,cal_str)

fid = fopen(fname,'w+');
fwrite(fid,cal_str,'char');
fclose(fid);
update_calibration_tab(get_esp3_prop('main_figure'));
end