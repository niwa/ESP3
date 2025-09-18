function load_secondary_freq_win(main_figure,rotate)

secondary_freq=init_secondary_axes_struct();

curr_disp=get_esp3_prop('curr_disp');
if curr_disp.DispSecFreqs<=0
    setappdata(main_figure,'Secondary_freq',secondary_freq);
    return;
end
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();

if isempty(layer)
    setappdata(main_figure,'Secondary_freq',secondary_freq);
    return;
end

new=0;
secondary_freq=getappdata(main_figure,'Secondary_freq');

if isempty(secondary_freq)
    new=1;
else
    if isempty(secondary_freq.echo_obj)
        new=1;
    end
end

if new
    switch curr_disp.DispSecFreqsOr
        case 'horz'
            fig_pos=[0.1 0.1 0.4 0.9];
        case 'vert'
            fig_pos=[0.1 0.1 0.9 0.4];
    end
else
    set(secondary_freq.fig,'units','norm');
    fig_pos=get(secondary_freq.fig,'Position');
    if rotate
        fig_pos=[fig_pos(1) fig_pos(2) fig_pos(4) fig_pos(3)];
    end
end

if new==0
    secondary_freq=getappdata(main_figure,'Secondary_freq');

    delete(secondary_freq.link_props_top_ax_internal);
    delete(secondary_freq.link_props_side_ax_internal);
    delete(secondary_freq.echo_obj.get_main_ax());
    delete(secondary_freq.echo_obj.get_vert_ax());
    delete(secondary_freq.echo_obj.get_hori_ax());
    delete(secondary_freq.echo_obj.get_echo_surf());
    delete(secondary_freq.echo_obj.get_echo_bt_surf());
    secondary_freq.echo_obj=echo_disp_cl.empty();

    if rotate>0
        fig_pos = get_dlg_position(main_figure,fig_pos, secondary_freq.fig.Units,'other');
        set(secondary_freq.fig,'units','norm');
        set(secondary_freq.fig,'Position',fig_pos);
    end

else
    secondary_freq.fig=new_echo_figure(main_figure,'Position',fig_pos,'Units','normalized',...
        'Name','Other Channels and Fields','CloseRequestFcn',@rm_Secondary_freq,'Tag','Secondary_freq_win','WhichScreen','other','UiFigureBool',false);
end
%% Install mouse pointer manager in figure
iptPointerManager( secondary_freq.fig);


%fieldnames = {'sv' 'sp' 'acrossangle'};
nb_chan = numel(curr_disp.SecChannelIDs);

if nb_chan==0
    curr_disp.SecChannelIDs{1}=layer.ChannelID{1};
    curr_disp.SecFreqs(1)=layer.Frequencies(1);
end

trans_obj = layer.get_trans(curr_disp);
%Types = trans_obj.Data.Type;
Fields = {};

for uit = 1:numel(layer.Transceivers)
    Fields = union(Fields,trans_obj.Data.Fieldname);
end

curr_disp.SecFieldnames = intersect(curr_disp.SecFieldnames,Fields);

if isempty(curr_disp.SecFieldnames)
    curr_disp.SecFieldnames = {curr_disp.Fieldname};
end

if isempty(curr_disp.SecFieldnames)
    curr_disp.SecFieldnames = Fields(1);
end

trans_obj_tot = cellfun(@(x) layer.get_trans(x),curr_disp.SecChannelIDs,'UniformOutput',false);

mb_bool = cellfun(@ismb,trans_obj_tot);

if any(mb_bool) 
    trans_obj_tot(~mb_bool) = [];
    curr_disp.SecChannelIDs(~mb_bool) = [];
    curr_disp.SecFreqs(~mb_bool) = [];
end

nb_fields =  numel(curr_disp.SecFieldnames);
nb_chan = numel(trans_obj_tot);

secondary_freq.names=gobjects(1,nb_chan*nb_fields);

secondary_freq.link_props_side_ax_internal=[];
secondary_freq.link_props_top_ax_internal=[];

if curr_disp.DispSecFreqsWithOffset
    dd = 'depth';
else
    dd = 'range';
end

ii = 0;
for iax=1:nb_chan
    trans_obj = trans_obj_tot{iax};
    for uif = 1:nb_fields

        switch curr_disp.DispSecFreqsOr
            case 'vert'
                pos=[(iax-1)/nb_chan 1-uif/nb_fields 1/nb_chan 1/nb_fields];
            case 'horz'
                pos=[(uif-1)/nb_fields 1-iax/nb_chan 1/nb_fields 1/nb_chan];
        end

        vis_top='off';
        vis_side='off';
        ii = ii+1;

        if (strcmpi(curr_disp.DispSecFreqsOr,'vert') || iax==1 )&& (strcmpi(curr_disp.DispSecFreqsOr,'horz') || uif == 1)
            vis_top='on';
        end

        if (strcmpi(curr_disp.DispSecFreqsOr,'horz') || iax==nb_chan) && (strcmpi(curr_disp.DispSecFreqsOr,'vert') || uif == nb_fields)
            vis_side='on';
        end
        echo_usrdata_tmp = init_echo_usrdata();
        echo_usrdata_tmp.CID = curr_disp.SecChannelIDs{iax};
        echo_usrdata_tmp.Fieldname = curr_disp.SecFieldnames{uif};
        echo_usrdata_tmp.ax_tag = curr_disp.SecChannelIDs{iax};

        secondary_freq.echo_obj(ii) = echo_disp_cl(secondary_freq.fig,...
            'YDir',curr_disp.YDir,...
            'geometry_y',dd,...
            'geometry_x','pings',...curr_disp.Xaxes_current,...
            'visible_vert',vis_side,...
            'visible_hori',vis_top,...
            'y_ax_pos','right',...
            'tag','sec_ax',...
            'CID',curr_disp.SecChannelIDs{iax},...
            'echo_usrdata',echo_usrdata_tmp,...
            'ax_tag',curr_disp.SecChannelIDs{iax},...
            'add_colorbar',false,...
            'pos_in_parent',pos,...
            'cmap',curr_disp.Cmap,...
            'FaceAlpha','flat',...
            'uiaxes',false);

        secondary_freq.echo_obj(ii).echo_usrdata.Fieldname = curr_disp.SecFieldnames{uif};
        secondary_freq.echo_obj(ii).main_ax.XMinorGrid = 'off';
        secondary_freq.echo_obj(ii).main_ax.YMinorGrid = 'off';

        ss = trans_obj.get_freq_str();
        [~,Type,uu]=init_cax(curr_disp.SecFieldnames{uif});

        ss = sprintf('%s %s(%s)',ss{1},Type,uu);

        usrdata.CID = curr_disp.SecChannelIDs{iax};
        usrdata.Field = curr_disp.SecFieldnames{uif};
        secondary_freq.echo_obj(ii).h_name=text(secondary_freq.echo_obj(ii).main_ax,10,15,ss,...
            'Units','Pixel','Fontweight','normal','Fontsize',10,...
            'ButtonDownFcn',{@change_cid,main_figure});
        enterFcn =  @(figHandle, currentPoint)...
            set(figHandle, 'Pointer', 'hand');
        iptSetPointerBehavior(secondary_freq.echo_obj(ii).h_name,enterFcn);

    end
end


uistack(secondary_freq.echo_obj.get_hori_ax(),'top');
uistack(secondary_freq.echo_obj.get_vert_ax(),'top');

setappdata(main_figure,'Secondary_freq',secondary_freq);
create_context_menu_sec_echo();


end

function  change_cid(src,~,main_figure)
up = false;
disable_listeners(main_figure);

curr_disp=get_esp3_prop('curr_disp');
if ~strcmp(curr_disp.ChannelID,src.UserData.CID)
    up = true;
    curr_disp.ChannelID=src.UserData.CID;
end

if ~strcmp(curr_disp.Fieldname,src.UserData.Fieldname)
    up = true;
    curr_disp.setField(src.UserData.Fieldname);
end

enable_listeners(main_figure);
if up
    curr_disp.ChannelID=src.UserData.CID;
end
end
