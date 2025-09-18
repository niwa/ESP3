function cids_upped=update_axis(main_figure,new,varargin)
cids_upped = {};
if ~isdeployed
    disp('update_axis')
end
layer_obj=get_current_layer();
if isempty(layer_obj)
    return;
end
curr_disp=get_esp3_prop('curr_disp');
p = inputParser;

%profile on;
addRequired(p,'main_figure',@ishandle);
addRequired(p,'new',@isnumeric);
addParameter(p,'main_or_mini',union({'main','mini'},curr_disp.ChannelID,'stable'));
addParameter(p,'force_update',0);

parse(p,main_figure,new,varargin{:});

if~iscell(p.Results.main_or_mini)
    main_or_mini={p.Results.main_or_mini};
else
    main_or_mini=p.Results.main_or_mini;
end
axes_panel_comp=getappdata(main_figure,'Axes_panel');
mini_axes_comp=getappdata(main_figure,'Mini_axes');

[echo_obj,trans_obj_tot,~,cids]=get_axis_from_cids(main_figure,main_or_mini);
if isempty(echo_obj)
    return;
end

upped=zeros(1,numel(echo_obj));
xlim_sec=[nan nan];
ylim_sec=[nan nan];
idx_sec=[];
field_main = curr_disp.Fieldname;
echo_userdata = [echo_obj(:).echo_usrdata];
for iax=1:length(echo_obj)

    echo_im=echo_obj.get_echo_surf(iax);
    echo_ax=echo_obj.get_main_ax(iax);
    trans_obj=trans_obj_tot(iax);
    pings=trans_obj.get_transceiver_pings();
    samples=trans_obj.get_transceiver_samples();
    range_t=trans_obj.get_samples_range();
    nb_pings=length(pings);
    nb_samples=length(samples);

    field = field_main;
    [~,~,uu]=init_cax(field);
    if ~isempty(echo_obj(iax).colorbar_h) && isvalid(echo_obj(iax).colorbar_h)
        echo_obj(iax).colorbar_h.Label.String = uu;
    end

    switch echo_obj(iax).echo_usrdata.ax_tag
        case 'main'
            if new==0
                x=double(get(echo_ax,'xlim'));
                y=double(get(echo_ax,'ylim'));
            else
                x=[-inf inf];
                y=[-inf inf];
                u=findobj(echo_ax,'Tag','SelectLine','-or','Tag','SelectArea');
                delete(u);
            end
            axes_panel_comp.axes_panel.UserData = curr_disp.ChannelID;
            delete(axes_panel_comp.listeners);
            axes_panel_comp.listeners=[];
            clear_lines(axes_panel_comp.echo_obj.main_ax);

        case 'mini'
            y=[1 nb_samples];
            x=[1 nb_pings];

        otherwise
            x=double(get(axes_panel_comp.echo_obj.main_ax,'xlim'));
            dr=mean(diff(range_t));
            y1=(curr_disp.R_disp(1)-range_t(1))/dr;
            y2=(curr_disp.R_disp(2)-range_t(1))/dr;
            y=[y1 y2];
            field = echo_obj(iax).echo_usrdata.Fieldname;
            [~,Type,uu]=init_cax(field);
            if ~ismember(field,curr_disp.SecFieldnames)
                id_chan = strcmpi(echo_obj(iax).echo_usrdata.CID,{echo_userdata(:).CID});
                fields_chan = unique({echo_userdata(id_chan).Fieldname});
                field_diff = setdiff(curr_disp.SecFieldnames,fields_chan);

                if ~isempty(field_diff)
                    field = field_diff{1};
                end
            end

            if ~ismember(field,trans_obj.Data.Fieldname)&&ismember(strrep(field,'denoised',''),trans_obj.Data.Fieldname)
                field = strrep(field,'denoised','');
            end

            if ~ismember(field,trans_obj.Data.Fieldname)&&ismember(strcat(field,'denoised'),trans_obj.Data.Fieldname)
                field = strcat(field,'denoised');
            end


            ss = trans_obj.get_freq_str();
            
            ss = sprintf('%s %s(%s)',ss{1},Type,uu);
            echo_obj(iax).h_name.String = ss;

            
    end

    if ~isempty(echo_im)
        [dr,dp,upped(iax)]=echo_obj(iax).display_echogram(trans_obj,...
            'Unique_ID',layer_obj.Unique_ID,...
            'curr_disp',curr_disp,...
            'Fieldname',field,...
            'x',x,'y',y,.....
            'force_update',p.Results.force_update>0);
        tmp = echo_obj(iax).echo_usrdata;
        tmp.Fieldname = field;
        tmp.CID = trans_obj.Config.ChannelID;
        echo_obj(iax).update_echo_usrdata(tmp);
        
    end

    switch echo_obj(iax).echo_usrdata.ax_tag
        case 'main'
            str_subsampling=sprintf('SubSampling: [%.0fx%.0f]',dr,dp);
            info_panel_comp=getappdata(main_figure,'Info_panel');
            if dr>1||dp>1
                set(info_panel_comp.display_subsampling,'String',str_subsampling,'ForegroundColor',[0.5 0 0],'Fontweight','bold');
            else
                set(info_panel_comp.display_subsampling,'String',str_subsampling,'ForegroundColor',[0 0.5 0],'Fontweight','normal');
            end

            if diff(echo_obj(iax).echo_usrdata.xlim)>0
                echo_obj.get_main_ax(iax).XLim=echo_obj(iax).echo_usrdata.xlim;
            end
            if diff(echo_obj(iax).echo_usrdata.ylim)>0
                echo_obj.get_main_ax(iax).YLim=echo_obj(iax).echo_usrdata.ylim;
            end

            ylim_ax=get(axes_panel_comp.echo_obj.main_ax,'YLim');

            if new
                if ~isempty(ylim_ax)&& ~all(ylim_ax == [0 1])
                    if strcmpi(axes_panel_comp.echo_obj.echo_usrdata.geometry_y,'samples')
                        curr_disp.R_disp=range_t(round(ylim_ax));
                    else
                        curr_disp.R_disp=ylim_ax;
                    end
                else
                    curr_disp.R_disp=[range_t(1) range_t(end)];
                end


            end
            axes_panel_comp.listeners=addlistener(axes_panel_comp.echo_obj.main_ax,'YLim','PostSet',@(src,envdata)listenYLim(src,envdata,main_figure));
            setappdata(main_figure,'Axes_panel',axes_panel_comp);
        case 'mini'

            if diff(echo_obj(iax).echo_usrdata.xlim)>0
                echo_obj.get_main_ax(iax).XLim=echo_obj(iax).echo_usrdata.xlim;
            end
            if diff(echo_obj(iax).echo_usrdata.ylim)>0
                echo_obj.get_main_ax(iax).YLim=echo_obj(iax).echo_usrdata.ylim;
            end

            x_lim=get(axes_panel_comp.echo_obj.main_ax,'xlim');
            y_lim=get(axes_panel_comp.echo_obj.main_ax,'ylim');
            v1 = [x_lim(1) y_lim(1);x_lim(2) y_lim(1);x_lim(2) y_lim(2);x_lim(1) y_lim(2)];
            f1=[1 2 3 4];
            set(mini_axes_comp.patch_obj,'Faces',f1,'Vertices',v1);
            xd=get(axes_panel_comp.echo_obj.echo_surf,'xdata');
            yd=get(axes_panel_comp.echo_obj.echo_surf,'ydata');

            v2 = [min(xd) min(yd);max(xd) min(yd);max(xd) max(yd);min(xd) max(yd)];
            f2=[1 2 3 4];
            set(mini_axes_comp.patch_lim_obj,'Faces',f2,'Vertices',v2);

        otherwise
            if diff(echo_obj(iax).echo_usrdata.ylim)>0&&diff(echo_obj(iax).echo_usrdata.xlim)>0
                idx_sec=iax;
                xlim_sec=[min(xlim_sec(1),echo_obj(iax).echo_usrdata.xlim(1))...
                    max(xlim_sec(2),echo_obj(iax).echo_usrdata.xlim(2))];
                ylim_sec=[min(ylim_sec(1),echo_obj(iax).echo_usrdata.ylim(1))...
                    max(ylim_sec(2),echo_obj(iax).echo_usrdata.ylim(2))];
            end


    end
end
cids_upped = cids(upped>0);
if ~isempty(idx_sec)
    if any(echo_obj.get_main_ax(idx_sec).XLim~=xlim_sec)&&xlim_sec(2)>xlim_sec(1)
        echo_obj.get_main_ax(idx_sec).XLim=xlim_sec;
    end
    if any(echo_obj.get_main_ax(idx_sec).YLim~=ylim_sec)&&ylim_sec(2)>ylim_sec(1)
        echo_obj.get_main_ax(idx_sec).YLim=ylim_sec;
    end
end

if any(strcmpi(main_or_mini,'mini'))
    update_grid_mini_ax(main_figure);
end

if any(strcmpi(main_or_mini,'main'))
    update_grid(main_figure);
end
update_info_panel([],[],1);
end