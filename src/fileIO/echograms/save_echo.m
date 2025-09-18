function save_echo(varargin)

p = inputParser;

addParameter(p,'path_echo','',@ischar);
addParameter(p,'fileN','',@ischar);
addParameter(p,'cid','main',@ischar);
addParameter(p,'field','sv',@ischar);
addParameter(p,'vis','on',@ischar);
addParameter(p,'size',[],@isnumeric);

parse(p,varargin{:});

esp3_obj=getappdata(groot,'esp3_obj');

main_figure=esp3_obj.main_figure;
curr_disp=esp3_obj.curr_disp;
layer_obj=esp3_obj.get_layer();

if isempty(layer_obj)
    return;
end

cid = p.Results.cid;

if isempty(cid)
    cid = curr_disp.ChannelID;
end

[echo_obj_existing,trans_obj,~,~]=get_axis_from_cids(main_figure,{cid});

if isempty(echo_obj_existing)
    [trans_obj,~]=layer_obj.get_trans(cid);
    if isempty(trans_obj)
        return;
    end
    ydir = curr_disp.YDir;
    gx = 'pings';
    gy = 'depth';
    idx_ping = 1:numel(trans_obj.Time);
    idx_r = (1:numel(trans_obj.Range));
    field = curr_disp.Fieldname;
else
    echo_userdata  = [echo_obj_existing(:).echo_usrdata];
    field = p.Results.field;
    idx_field = find(strcmpi(field,{echo_userdata(:).Fieldname}),1);
    if isempty(idx_field)
        return;
    end
    echo_obj_existing = echo_obj_existing(idx_field);
    trans_obj = trans_obj(idx_field);
    ydir = echo_obj_existing.main_ax.YDir;
    gx = echo_obj_existing.echo_usrdata.geometry_x;
    gy = echo_obj_existing.echo_usrdata.geometry_y;
%     gx = 'meters';
%     gy = 'depth';
    idx_ping = echo_obj_existing.echo_usrdata.Idx_ping;
    idx_r = echo_obj_existing.echo_usrdata.Idx_r;
end

fts = 10;
if ~isempty(echo_obj_existing)
    x_lim = echo_obj_existing.echo_usrdata.xlim;
    y_lim = echo_obj_existing.echo_usrdata.ylim;
else
    x_lim=[];
    y_lim=[];
end

echo_obj = echo_disp_cl([],...
    'visible_fig',p.Results.vis,...
    'cmap',curr_disp.Cmap,...
    'FontSize',fts,...
    'add_colorbar',strcmpi(curr_disp.DispColorbar,'on'),...
    'link_ax',true,...
    'YDir',ydir,...
    'geometry_x',gx,...
    'geometry_y',gy,...
    'pos_in_parent',[0.05 0.05 0.9 0.88],...
    'uiaxes',false);

if ~isempty(p.Results.size)
    echo_obj.main_ax.Position(3:4) = p.Results.size;
end

echo_obj.disp_basic_echo(trans_obj,curr_disp,field,idx_ping,idx_r,x_lim,y_lim)
echo_obj.display_echo_lines(trans_obj,layer_obj.Lines,'curr_disp',curr_disp,'linewidth',1);

[~,Type,Units]=init_cax(curr_disp.Fieldname);
layers_Str=list_layers(layer_obj,'nb_char',80);
gui_fmt =init_gui_fmt_struct();
new_fig = ancestor(echo_obj.main_ax,'figure');

tt_h = uicontrol(new_fig,gui_fmt.txtTitleStyle,'units','norm','position',[0.05 0.93 0.9 0.07],...
    'String',sprintf('%s(%s) for %s : %s\n',Type,Units,deblank(trans_obj.Config.ChannelID),layers_Str{1}),'ForegroundColor','k','Fontsize',fts+2);


% size_max = get(0, 'MonitorPositions');
% pos_main=getpixelposition(main_figure);
% [~,id_screen]=min(abs(size_max(:,1)-pos_main(1)));
% new_fig.Position = size_max(id_screen,:).*[1 1 0.9 0.9];

fileN = p.Results.fileN;
path_echo = p.Results.path_echo;

new_fig.ResizeFcn = @update_HW;
new_fig.CloseRequestFcn = @do_nothing;

size_max = max(get(groot, 'MonitorPositions'),[],1);

fig_size_h = new_echo_figure([],'UiFigureBool',true,...
    'WindowStyle','modal',...
    'Position',[200 200 300 150],'Resize','off',...
    'Name','Resize echogram figure');

lstruct = struct();

lstruct.XTickLabel = echo_obj.hori_ax.XTickLabel;
lstruct.YTickLabel = echo_obj.vert_ax.YTickLabel;
lstruct.XTickLabelRotation = echo_obj.hori_ax.XTickLabelRotation;

uih = uigridlayout(fig_size_h,[2 4],'BackgroundColor',[1 1 1]);
uih.ColumnWidth = {'2x' '1x' '0.5x' '1x'};
uilabel(uih,'Text','Figure size (pixels)');
uilist_H = uieditfield(uih,'numeric','Limits',[1 size_max(3)],'Value',new_fig.Position(3),'RoundFractionalValues','on','ValueChangedFcn',@change_fig_size);
uilabel(uih,'Text','X');
uilist_W = uieditfield(uih,'numeric','Limits',[1 size_max(4)],'Value',new_fig.Position(4),'RoundFractionalValues','on','ValueChangedFcn',@change_fig_size);
uilabel(uih,'Text','Font size');
uiedit_fts = uieditfield(uih,'numeric','Limits',[1 50],'Value',fts,'RoundFractionalValues','off','ValueChangedFcn',@change_fig_size);
tmp = uilabel(uih,'Text','Label position');
tmp.Layout.Row = 3;
tmp.Layout.Column = 1;
uilist_fts = uidropdown(uih,...,...
    'Items',{'Inside','Outside'},... 
    'ValueChangedFcn', @change_fig_size); 
uilist_fts.Layout.Row = 3;
uilist_fts.Layout.Column = [2 3];

uiwait(fig_size_h);

switch fileN
    case '-clipboard'
        print(new_fig,'-clipboard','-dbitmap');
        %hgexport(new_fig,'-clipboard');
        dlg_perso(main_figure,'Done','Echogram copied to clipboard...','Timeout',30);
        delete(new_fig);

    otherwise
        if isempty(path_echo)
            path_echo=fullfile(fileparts(layer_obj.Filename{1}),'esp3_echo');
        end

        if ~isfolder(path_echo)
            mkdir(path_echo);
        end

        if isempty(fileN)
            fileN=generate_valid_filename(sprintf('%s_%s.png',layers_Str{1},trans_obj.Config.ChannelID));
        end

        if ~isfolder(path_echo)
            mkdir(path_echo);
        end

        print(new_fig,fullfile(path_echo,fileN),'-dpng','-r300');

        echo_db_file = fullfile(path_echo,'echo_db.db');
        add_echo_to_echo_db(echo_db_file,fullfile(path_echo,fileN),layer_obj.Filename,trans_obj.Config.ChannelID,trans_obj.Config.Frequency);

        if strcmpi(p.Results.vis,'on')
            dlg_perso(main_figure,'Done','Finished, Echogram has been saved...');
        end
        delete(new_fig);
end




    function change_fig_size(~,~)
        if isvalid(new_fig)
                new_fig.Position(3:4) = [uilist_H.Value uilist_W.Value];
                echo_obj.main_ax.FontSize = uiedit_fts.Value;
                echo_obj.vert_ax.FontSize = uiedit_fts.Value;
                echo_obj.hori_ax.FontSize = uiedit_fts.Value;
                tt_h.FontSize = uiedit_fts.Value+2;
                echo_obj.colorbar_h.FontSize = uiedit_fts.Value-2;

                switch uilist_fts.Value
                    case 'Inside'
                        echo_obj.hori_ax.XTickLabel = lstruct.XTickLabel;
                        echo_obj.vert_ax.YTickLabel = lstruct.YTickLabel;
                        echo_obj.main_ax.XTickLabel = {[]};
                        echo_obj.main_ax.YTickLabel = {[]};
                        echo_obj.pos_in_parent = [0.05 0.05 0.9 0.88];
                        echo_obj.set_axes_position(0,0);
                    case 'Outside'
                        echo_obj.main_ax.XTickLabelRotation = lstruct.XTickLabelRotation; 
                        echo_obj.main_ax.XTickLabel = lstruct.XTickLabel;
                        echo_obj.main_ax.YTickLabel = lstruct.YTickLabel;
                        echo_obj.hori_ax.XTickLabel = {[]};
                        echo_obj.vert_ax.YTickLabel = {[]};
                        echo_obj.pos_in_parent = [0.08 0.05 0.87 0.80];
                        echo_obj.set_axes_position(0,0);

                end
                drawnow;
        end

    end
    function update_HW(~,~)
        if isvalid(fig_size_h)
            uilist_H.Value = new_fig.Position(3);
            uilist_W.Value = new_fig.Position(4);
        end

    end

end