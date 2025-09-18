function [tag_text_h,tag_lim_h] = disp_reg_tag_on_map(trans_obj,varargin)

p = inputParser;
addRequired(p,'layer',@(obj) isa(obj,'transceiver_cl'));
addParameter(p,'gax',[]);
addParameter(p,'uid',{});
addParameter(p,'Fontsize',12);
addParameter(p,'Linewidth',6);

parse(p,trans_obj,varargin{:});
tag_text_h = [];
tag_lim_h = [];
gax = p.Results.gax;


if isempty(trans_obj.Regions)
    return;
end

if isempty(gax)
    hfig=new_echo_figure([],'UiFigureBool',true,'Name','Regions tags map','Tag','reg_tag_map');
    uigl_ax = uigridlayout(hfig,[1,1]);
    gax=geoaxes(uigl_ax);
    format_geoaxes(gax);
end

if ~isempty(trans_obj.Regions)
    uid_regs = {trans_obj.Regions(:).Unique_ID};
end

uid_disp = p.Results.uid;

if isempty(uid_disp)
    uid_disp = uid_regs;
    idx_uid = 1:numel(uid_regs);
else
    [uid_disp,idx_uid] = intersect(uid_regs,uid_disp);
end

[col_from_xml,tags_from_xml,~] = esp3_cl.get_reg_colors_from_xml();

col_defaults  = lines(numel(idx_uid));

for ii = 1:numel(idx_uid)
    tag_text_h_tmp = findobj(gax,'Tag',sprintf('%s_tag',uid_disp{ii}));
    tag_lim_h_tmp  = findobj(gax,'Tag',sprintf('%s_lim',uid_disp{ii}));

    reg = trans_obj.Regions(idx_uid(ii));
    lat_reg = trans_obj.GPSDataPing.Lat(reg.Idx_ping);
    lon_reg = trans_obj.GPSDataPing.Long(reg.Idx_ping);
    col = [];
    if ~isempty(col_from_xml)
        id_col = find(strcmpi(reg.Tag,tags_from_xml));
        if ~isempty(id_col)
            col = col_from_xml{id_col};
        end
    end

    if isempty(col) && isfield(gax.UserData,'Cols')
        id_col = find(strcmpi(reg.Tag,gax.UserData.Tags));
        if ~isempty(id_col)
            col = gax.UserData.Cols{id_col};
        end
    end

    if isempty(col)
        col = col_defaults(ii,:);
        if ~isempty(reg.Tag)
            if isfield(gax.UserData,'Cols')
                gax.UserData.Cols = [gax.UserData.Cols col];
                gax.UserData.Tags = [gax.UserData.Tags {reg.Tag}];
            else
                gax.UserData.Cols = {col};
                gax.UserData.Tags = {reg.Tag};
            end
        end
    end

    if isempty(tag_text_h_tmp)
        tag_text_h_tmp=text(gax,mean(lat_reg),mean(lon_reg),reg.Tag,...
            'Fontsize',p.Results.Fontsize,'Fontweight','bold','Interpreter','None',...
            'VerticalAlignment','bottom','Clipping','on','Color',col,'tag',sprintf('%s_tag',uid_disp{ii}));
        tag_text_h = [tag_text_h tag_text_h_tmp];
    else
        tag_text_h_tmp.Position = [mean(lat_reg) mean(lon_reg) 0];
        tag_text_h_tmp.String = reg.Tag;
        tag_text_h_tmp.FontSize = p.Results.Fontsize;
        tag_text_h_tmp.Color = col;
    end

    if isempty(tag_lim_h_tmp)
        tag_lim_h_tmp=geoplot(gax,lat_reg,lon_reg,'Color',col,'Linewidth',p.Results.Linewidth,'tag',sprintf('%s_lim',uid_disp{ii}));
        tag_lim_h = [tag_lim_h tag_lim_h_tmp];
    else
        tag_lim_h_tmp.LatitudeData = lat_reg;
        tag_lim_h_tmp.LongitudeData = lon_reg;
        tag_lim_h_tmp.LineWidth = p.Results.Linewidth;
        tag_lim_h_tmp.Color = col;
    end

end