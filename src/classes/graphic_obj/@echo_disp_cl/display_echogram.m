%% Function
function [dr,dp,up] = display_echogram(echo_obj,trans_obj,varargin)
up=0;
curr_disp_default=curr_state_disp_cl();

p = inputParser;
addRequired(p,'echo_obj',@(x) isa(x,'echo_disp_cl'));
addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addParameter(p,'curr_disp',curr_disp_default,@(x) isa(x,'curr_state_disp_cl'));
addParameter(p,'main_figure',[],@(x) isempty(x)||ishandle(x));
addParameter(p,'fieldname','sv',@ischar);
addParameter(p,'Unique_ID',generate_Unique_ID([]),@ischar);
addParameter(p,'x',[],@isnumeric);
addParameter(p,'y',[],@isnumeric);
addParameter(p,'BeamAngularLimit',[],@isnumeric);
addParameter(p,'force_update',true,@islogical);

parse(p,echo_obj,trans_obj,varargin{:});


% cur_ver=ver('Matlab');
% cur_ver_num = str2double(cur_ver.Version);

curr_disp = p.Results.curr_disp;

x = p.Results.x;
y = p.Results.y;
BeamAngularLimit = p.Results.BeamAngularLimit;

if isempty(BeamAngularLimit)
    BeamAngularLimit  = curr_disp.BeamAngularLimit;
end

echo_obj = p.Results.echo_obj;

fieldname = p.Results.fieldname;

force_update = p.Results.force_update;
ss = trans_obj.get_CID_freq_str();
str_tt =sprintf('%s: %s',curr_disp.Type,ss{1});

switch class(echo_obj.main_ax.Parent)
    case 'matlab.ui.container.Tab'
        ph = echo_obj.main_ax.Parent;
    case 'matlab.ui.container.Panel'
        ph = echo_obj.main_ax.Parent.Parent;
    case 'matlab.ui.Figure'
       ph = echo_obj.main_ax.Parent;
    otherwise       
        ph = echo_obj.main_ax.Parent;
end

switch class(ph)
    case 'matlab.ui.container.Tab'
        if ~strcmpi(echo_obj.main_ax.Tag,'mini')
            ph.Title = str_tt;
        end         
    case 'matlab.ui.Figure'
        if isempty(echo_obj.main_ax.Parent.Name)
            ph.Name = str_tt;
        end
end


ax = echo_obj.main_ax;
echo_h = echo_obj.echo_surf;

switch echo_h.UserData.geometry_x
    case 'seconds'
        xdata=trans_obj.get_transceiver_time();
        xdata=xdata*(24*60*60);
    case 'pings'
        xdata=trans_obj.get_transceiver_pings();
    case 'meters'
        xdata=trans_obj.GPSDataPing.Dist;
        if  ~any(~isnan(trans_obj.GPSDataPing.Lat))
            disp('No GPS Data');
            curr_disp.Xaxes_current='pings';
            curr_disp.init_grid_val(trans_obj)
            xdata=trans_obj.get_transceiver_pings();
        end
    otherwise
        xdata=trans_obj.get_transceiver_pings();
end

ydata=trans_obj.get_transceiver_samples();

if isempty(x)
    x = xdata;
end

if isempty(y)
    y = ydata;
end

idx_beam = trans_obj.get_idx_beams(BeamAngularLimit);

idx_ping_min=find((xdata-x(1)>=0),1);
idx_r_min=find((ydata-y(1)>=0),1);
idx_ping_max=find((xdata-x(end)>=0),1);
idx_r_max=find((ydata-y(end)>=0),1);

if isempty(idx_r_min)
    idx_r_min=1;
end

if y(end)==Inf||isempty(idx_r_max)
    idx_r_max=length(ydata);
end

if isempty(idx_ping_min)
    idx_ping_min=1;
end

if isempty(idx_ping_max)
    idx_ping_max=length(xdata);
end

idx_ping=idx_ping_min:idx_ping_max;

screensize = getpixelposition(ax);

if all(isinf(x))
    idx_ping=idx_ping(1:floor(min(screensize(3),length(idx_ping))));
end
%screen_ratio=(screensize(3)/screensize(4));

idx_r=(idx_r_min:idx_r_max)';

nb_samples=length(idx_r);
nb_pings=length(idx_ping);

[dr,dp]=get_dr_dp(ax,nb_samples,nb_pings,curr_disp.EchoQuality);

% nb_beams = numel(idx_beam);
% dr = ceil(dr * sqrt(nb_beams));
% dp = ceil(dp * sqrt(nb_beams));


% profile on;

idx_r_red_ori=(idx_r(1:dr:end));
idx_ping_red_ori=idx_ping(1):dp:idx_ping(end);


if force_update==0
    update_echo=echo_obj.get_update_echo(p.Results.Unique_ID,trans_obj.Config.ChannelID,fieldname,idx_r_red_ori,idx_ping_red_ori,dr,dp);
else
    update_echo=1;
end

if update_echo>0
    
    %     mem_struct=memory;
    %     size_tot=ceil(mem_struct.MaxPossibleArrayBytes/(8*32));
    %     ip_size_max=(ceil(sqrt(size_tot))*sqrt(screen_ratio)-numel(numel(idx_ping_red_ori)))/2;
    %     ir_size_max=(ceil(sqrt(size_tot))/sqrt(screen_ratio)-numel(numel(idx_r_red_ori)))/2;
    %
    i_p=ceil(numel(idx_ping_red_ori)*curr_disp.Disp_dy_dx(2));
    %i_p=max(ip_size_max,200)
    buffer_p=0:dp:i_p*dp;
    
    i_r=ceil(numel(idx_r_red_ori)*curr_disp.Disp_dy_dx(1));
    %i_r=max(ir_size_max,200)
    buffer_r=0:dr:i_r*dr;
    
    %     buffer_r=[];
    %     buffer_p=[];
    
    idx_r_red=union(union(idx_r_red_ori,idx_r_red_ori(1)-buffer_r),idx_r_red_ori(end)+buffer_r);
    idx_r_red(idx_r_red<ydata(1)|idx_r_red>ydata(end))=[];
    
    idx_ping_red=union(union(idx_ping_red_ori,idx_ping_red_ori(1)-buffer_p),idx_ping_red_ori(end)+buffer_p);
    idx_ping_red(idx_ping_red<1|idx_ping_red>numel(xdata))=[];
    
    
    if ~isdeployed()
        fprintf('Pings to load %d to %d\n',idx_ping_red(1),idx_ping_red(end));
        fprintf('Pings to display %d to %d\n',idx_ping_red_ori(1),idx_ping_red_ori(end));
    end
    
    echo_obj.echo_usrdata.Fieldname = fieldname;
    [data,sc] = trans_obj.Data.get_subdatamat('idx_beam',idx_beam,'idx_r',idx_r_red,'idx_ping',idx_ping_red,'field',fieldname);
    switch echo_obj.echo_usrdata.geometry_y
        case {'depth'}
            [roll_comp_bool,pitch_comp_bool,yaw_comp_bool,heave_comp_bool] = trans_obj.get_att_comp_bool();
            [data_struct,~]=trans_obj.get_xxx_ENH('data_to_pos',{'WC'},'idx_ping',idx_ping_red,'idx_r',idx_r_red,'idx_beam',idx_beam,...
                'comp_angle',[false false],...
                'yaw_comp',yaw_comp_bool,...
                'roll_comp',roll_comp_bool,...
                'pitch_comp',pitch_comp_bool,...
                'heave_comp',heave_comp_bool,...
                'no_nav',true);

            y_data_disp = data_struct.WC.H;

            x_data_disp=xdata(repmat(idx_ping_red,size(y_data_disp,1),1));
        case { 'range'}
            x_data_disp=xdata(idx_ping_red);
            y_data_disp=trans_obj.get_samples_range(idx_r_red);
        otherwise
            x_data_disp=xdata(idx_ping_red);
            y_data_disp=ydata(idx_r_red);
    end
    
    if isempty(data)
        data=nan(size(y_data_disp,1),size(x_data_disp,2));
        sc='lin';
    end

    idx_last = size(data,1);

    if trans_obj.ismb()
        idx_bot = ceil(max(trans_obj.get_bottom_idx(idx_ping_red,ceil(mean(idx_beam))),[],'all')/dr);
        [fields,~,~,~,default_values]=init_fields();
        idx_field = strcmpi(fields,fieldname);
        dval = default_values(idx_field);
        switch fieldname
            case {'feature_sv' 'feature_id'}
                dmax =  sum((data>dval),[2 3]);
                dval = 0;
            otherwise
                prc_thr = 100-max(log10(1e4/size(data,2)),1);
                dmax =  prctile(data,prc_thr,[2 3]);
        end

        idx_last= numel(dmax) - find(flipud(dmax>dval),1)+1;

        if isempty(idx_last)
            idx_last = size(data,1);
        end
        
        idx_last = max(idx_bot,idx_last);
    end
    
    idx_last = min(idx_last,numel(idx_r_red));

    idx_r_red = idx_r_red(1:idx_last);
    y_data_disp = y_data_disp(1:idx_last,:,:);
    data = data(1:idx_last,:,:);
    
    if size(data,3) > 1
        av_func = @(x) pow2db_perso(mean(db2pow_perso(x),3,'omitnan'));
        switch  lower(sc)
            case 'db'
                switch fieldname
                    case 'feature_sv'
                        av_func = @(x) max(x,[],3,'omitnan');
                    otherwise
                        av_func = @(x) pow2db_perso(mean(db2pow_perso(x),3,'omitnan'));
                end
            case 'angle'
                av_func = @(x) mean(x,3,'omitnan');
            case 'id'
                av_func = @(x) max(x,[],3,'omitnan');
            otherwise %{'lin','density','speed'}
                av_func = @(x) mean(x,3,'omitnan');
        end
        data = squeeze(av_func(data));
        %        data = gather(data);
        %        toc;
    end
    
    
    if size(y_data_disp,3) > 1
        y_data_disp = squeeze(y_data_disp(:,:,ceil(size(y_data_disp,3)/2)));
    end

    
    %y_data_disp=logspace(log10(ydata(idx_r_red(1))),log10(ydata(idx_r_red(end))),numel(idx_r_red));
    
    % x_data_disp=xdata(idx_ping);
    % y_data_disp=ydata(idx_r);
    if isempty(data)
        switch  fieldname
            case 'spdenoised'
                fieldname='sp';
            case 'svdenoised'
                fieldname='sv';
        end
        if strcmp(echo_obj.echo_usrdata.geometry_y,'depth')
            %[x_data_disp,y_data_disp,data,sc]=trans_obj.apply_line_depth(fieldname,idx_r_red,idx_beam,idx_ping_red);
            [roll_comp_bool,pitch_comp_bool,yaw_comp_bool,heave_comp_bool] = trans_obj.get_att_comp_bool();
            [data_struct,~]=trans_obj.get_xxx_ENH('data_to_pos',{'WC'},'idx_ping',idx_ping_red,'idx_r',idx_r_red,'idx_beam',idx_beam,...
                'comp_angle',[false false],...
                'yaw_comp',yaw_comp_bool,...
                'roll_comp',roll_comp_bool,...
                'pitch_comp',pitch_comp_bool,...
                'heave_comp',heave_comp_bool);

            y_data_disp = data_struct.WC.H;

            idx_ping_disp=repmat(idx_ping_red,size(y_data_disp,1),1);
            x_data_disp=xdata(idx_ping_disp);
        end
    end

    switch fieldname
        case {'y' 'y_filtered' 'comp_sig_1' 'comp_sig_2' 'comp_sig_3' 'comp_sig_4'}
            data = abs(double_to_complex_single(data));
    end

    switch sc
        case 'lin'
            data_mat = 10*log10(abs(data));
        case 'db'
            data_mat = data;
        otherwise
            data_mat = data;
    end
    
    data_mat=single(real(data_mat));

    if size(x_data_disp,1)>1
        x_data_disp = x_data_disp(1:idx_last,:);
    end

    echo_obj.echo_usrdata.Idx_r=idx_r_red;
    echo_obj.echo_usrdata.Idx_ping=idx_ping_red;
    
    echo_obj.echo_usrdata.CID=trans_obj.Config.ChannelID;
    echo_obj.echo_usrdata.Fieldname=fieldname;
    echo_obj.echo_usrdata.Layer_ID=p.Results.Unique_ID;
    
    switch echo_obj.echo_usrdata.geometry_y
        case 'samples'  
            y_data_disp=y_data_disp-1/2;
    end
    
    x_data_disp=x_data_disp-1/2;
    set(echo_h,'XData',x_data_disp,'YData',y_data_disp,'CData',data_mat,'ZData',zeros(size(data_mat),'int8'),'AlphaData',ones(size(data_mat)));%,'UserData',data_mat
    
    up=1;
else
    if ~isdeployed()
        disp('Not updating datamat and display');
    end
    x_data_disp=echo_h.XData;
    y_data_disp=echo_h.YData;
    
end

idx_p=echo_obj.echo_usrdata.Idx_ping>=idx_ping_red_ori(1)&echo_obj.echo_usrdata.Idx_ping<=idx_ping_red_ori(end);
idx_r=echo_obj.echo_usrdata.Idx_r>=idx_r_red_ori(1)&echo_obj.echo_usrdata.Idx_r<=idx_r_red_ori(end);

if isempty(p.Results.x)||isempty(p.Results.y)
    echo_obj.main_ax.XLim = [xdata(1) xdata(end)];
    echo_obj.main_ax.YLim = [1 numel(trans_obj.Range)];
end

if length(x)>1
    x=x_data_disp(:,idx_p);
    x_lim=[min(x,[],'all','omitnan') max(x,[],'all','omitnan')]+1/2;
    if x_lim(2)>x_lim(1)&&~any(isinf(x_lim))&&~any(isnan(x_lim))
        echo_obj.echo_usrdata.xlim=x_lim;
    else
        echo_obj.echo_usrdata.xlim=[nan nan];
    end
end

% [y_data_disp(1) y_data_disp(end)]
if length(y_data_disp)>1
    y=y_data_disp(idx_r,:);
    if size(y,2)>1
        y=y(:,idx_p);
    end
    y_lim=[min(y,[],'all','omitnan') max(y,[],'all','omitnan')];
    if y_lim(2)>y_lim(1)&&~any(isinf(y_lim))&&~any(isnan(y_lim))
        echo_obj.echo_usrdata.ylim=y_lim;
    else
        echo_obj.echo_usrdata.ylim=[nan nan];
    end
end

end