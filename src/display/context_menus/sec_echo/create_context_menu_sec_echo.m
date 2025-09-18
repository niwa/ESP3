function create_context_menu_sec_echo()

lay_obj  = get_current_layer();
main_figure = get_esp3_prop('main_figure');
curr_disp = get_esp3_prop('curr_disp');

[echo_obj,~,~,~]=get_axis_from_cids(main_figure,lay_obj.ChannelID);

if isempty(echo_obj)
    return;
end

secondary_freq_fig = ancestor(echo_obj(1).echo_bt_surf,'figure');

delete(findobj(secondary_freq_fig,'Type','UiContextMenu','-and','Tag','MFContextMenu'));
echo_usrdata = [echo_obj(:).echo_usrdata];
cids = {echo_usrdata(:).CID};
fff = {echo_usrdata(:).Fieldname};
trans_obj = lay_obj.get_trans(curr_disp);
Types = trans_obj.Data.Type;
fields = trans_obj.Data.Fieldname;
nb_fields = numel(fields);

nb_chan = numel(cids);

disp_fi=ismember(fields,fff);

disp_chan=ismember(lay_obj.ChannelID,cids);

checked_state=cell(1,nb_chan);
checked_state(disp_chan)={'on'};
checked_state(~disp_chan)={'off'};

checked_state_fi=cell(1,nb_fields);
checked_state_fi(disp_fi)={'on'};
checked_state_fi(~disp_fi)={'off'};


if curr_disp.DispSecFreqsWithOffset
    c='on';
else
    c='off';
end

context_menu = uicontextmenu(secondary_freq_fig,'Tag','MFContextMenu');
uimenu(context_menu,'Label','Change orientation','Callback',{@change_orientation_callback,main_figure});
uimenu(context_menu,'Label','Save Echogramm','Callback',{@save_sec_echo_callback,main_figure,'file'});
uimenu(context_menu,'Label','Copy Echogramm to clipboard','Callback',{@save_sec_echo_callback,main_figure,'clipboard'});
uimenu(context_menu,'Label','Display Transducer depth Offset','Callback',{@toggle_offset_callback,main_figure},'separator','on','Checked',c);
chan_menu = uimenu(context_menu,'Label','Channel(s) to display','separator','on');
uimenu(chan_menu,'Label','all', 'Callback',{@set_secondary_channels_cback,main_figure,'all'});
uimenu(chan_menu,'Label','current', 'Callback',{@set_secondary_channels_cback,main_figure,'current'});

ss = lay_obj.Transceivers.get_CID_freq_str();

for ifreq=1:numel(lay_obj.ChannelID)
    uimenu(chan_menu,'Label',ss{ifreq},'Checked',checked_state{ifreq},...
        'Callback',{@set_secondary_channels_cback,main_figure,lay_obj.ChannelID{ifreq}});
end
fi_menu=uimenu(context_menu,'Label','Field(s) to display','separator','on');

for ifi=1:numel(fields)
    uimenu(fi_menu,'Label',Types{ifi},'Checked',checked_state_fi{ifi},...
        'Callback',{@set_secondary_fields_cback,fields{ifi}});
end

for ui = 1:numel(echo_obj)
    context_menu.UserData.ChannelID = echo_obj(ui).echo_usrdata.CID;
    set(echo_obj(ui).echo_bt_surf,'UIContextMenu',context_menu);
    set(echo_obj(ui).main_ax,'ContextMenu',context_menu);
end

end


function toggle_offset_callback(src,~,~)
checked=get(src,'checked');
switch checked
    case 'on'
        src.Checked='off';
    case'off'
        src.Checked='on';
end

curr_disp=get_esp3_prop('curr_disp');
curr_disp.DispSecFreqsWithOffset=strcmpi(src.Checked,'on');

end

function set_secondary_fields_cback(src,~,new_fi)
curr_disp=get_esp3_prop('curr_disp');
checked=get(src,'checked');
switch checked
    case 'on'
        if isscalar(curr_disp.SecFieldnames)
            return;
        end
        curr_disp.SecFieldnames(strcmp(curr_disp.SecFieldnames,new_fi))=[];
        src.Checked='off';
    case'off'
        curr_disp.SecFieldnames=union(curr_disp.SecFieldnames,new_fi);
        src.Checked='on';
end

curr_disp.DispSecFreqs = curr_disp.DispSecFreqs;

end

function set_secondary_channels_cback(src,~,~,tag)
curr_disp=get_esp3_prop('curr_disp');
lay_obj=get_current_layer();

switch tag
    case 'all'
        curr_disp.SecChannelIDs = lay_obj.ChannelID;
    case 'current'
        curr_disp.SecChannelIDs = {curr_disp.ChannelID};
    otherwise
        checked=get(src,'checked');
        switch checked
            case 'on'
                if isscalar(curr_disp.SecChannelIDs)
                    return;
                end
                curr_disp.SecChannelIDs(strcmp(curr_disp.SecChannelIDs,tag))=[];
            case'off'
                curr_disp.SecChannelIDs = union(curr_disp.SecChannelIDs,tag);
        end
end

for uif = 1:numel(src.Parent.Children)
    if ismember(src.Parent.Children(uif).Tag,curr_disp.SecChannelIDs)
        src.Parent.Children(uif).Checked = 'on';
    else
        src.Parent.Children(uif).Checked = 'off';
    end
end

[idx,~] = find_cid_idx(lay_obj,curr_disp.SecChannelIDs);
curr_disp.SecFreqs = lay_obj.Frequencies(idx);
[~,idx_s] = sort(lay_obj.Frequencies(idx));
curr_disp.SecChannelIDs = curr_disp.SecChannelIDs(idx_s);
curr_disp.SecFreqs = curr_disp.SecFreqs(idx_s);
curr_disp.DispSecFreqs = curr_disp.DispSecFreqs;

end

function change_orientation_callback(~,~,~)
curr_disp=get_esp3_prop('curr_disp');

switch curr_disp.DispSecFreqsOr
    case 'vert'
        curr_disp.DispSecFreqsOr='horz';
    case 'horz'
        curr_disp.DispSecFreqsOr='vert';
end

end



function save_sec_echo_callback(~,~,~,tag)

lay_obj=get_current_layer();

if isempty(lay_obj)
    return;
end

surf_obj = gco;

switch tag
    case 'clipboard'
        save_echo('fileN','-clipboard','cid',surf_obj.UserData.CID,'field',surf_obj.UserData.Fieldname);
    otherwise
        [path_tmp,~,~]=fileparts(lay_obj.Filename{1});
        layers_Str=list_layers(lay_obj,'nb_char',80,'valid_filename',true);

        [fileN, path_tmp] = uiputfile('*.png',...
            'Save echogram',...
            fullfile(path_tmp,[layers_Str{1} '.png']));

        if isequal(path_tmp,0)
            return;
        else
            save_echo('path_echo',path_tmp,'fileN',fileN,'cid',surf_obj.UserData.CID,'field',surf_obj.UserData.Fieldname);

        end
end

end
