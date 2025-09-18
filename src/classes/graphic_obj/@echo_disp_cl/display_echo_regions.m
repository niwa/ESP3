
function reg_plot_tot = display_echo_regions(echo_obj,trans_obj,varargin)

curr_disp_default=curr_state_disp_cl();

p = inputParser;
addRequired(p,'echo_obj',@(x) isa(x,'echo_disp_cl'));
addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addParameter(p,'text_size',8,@isnumeric);
addParameter(p,'curr_disp',curr_disp_default,@(x) isa(x,'curr_state_disp_cl'));

parse(p,echo_obj,trans_obj,varargin{:});

curr_disp = p.Results.curr_disp;

[ac_data_col,ac_bad_data_col,in_data_col,in_bad_data_col,txt_col] = set_region_colors(curr_disp.Cmap);
reg_plot_tot =[];

switch curr_disp.DispReg
    case 'off'
        alpha_in=0;
    case 'on'
        alpha_in=0.4;
end

main_axes=echo_obj.main_ax;

switch echo_obj.echo_usrdata.geometry_y
    case'samples'
        dyi  = 0;
    otherwise
        dyi  = 0;
end

switch echo_obj.echo_usrdata.geometry_x
    case'pings'
        dxi = 0;
    otherwise
        dxi  = 0;
end


active_regs=trans_obj.find_regions_Unique_ID(curr_disp.Active_reg_ID);

reg_h = findobj(main_axes,{'tag','region','-or','tag','region_text'});

if~isempty(reg_h)
    id_disp=get(reg_h,'UserData');
    id_reg=trans_obj.get_reg_Unique_IDs();
    id_rem = setdiff(id_disp,id_reg);
    
    if~isempty(id_rem)
        echo_obj.clear_echo_regions(id_rem)
    end 
end

nb_reg = numel(trans_obj.Regions);
reg_text_obj = findobj(main_axes,{'tag','region_text'},'-depth',1);

for ireg=1:nb_reg
    try
        reg_curr=trans_obj.Regions(ireg);
        
        if ~isempty(reg_text_obj)
            id_text=findobj(reg_text_obj,'UserData',reg_curr.Unique_ID,'-depth',0);
            if ~isempty(id_text)
                set(id_text,'String',reg_curr.disp_str());
                continue;
            end
            
        end
        
        if any(ireg==active_regs)
            
            switch lower(reg_curr.Type)
                case 'data'
                    col=ac_data_col;
                case 'bad data'
                    col=ac_bad_data_col;
            end
        else
            
            switch lower(reg_curr.Type)
                case 'data'
                    col=in_data_col;
                case 'bad data'
                    col=in_bad_data_col;
            end
        end
        
        poly=reg_curr.Poly;
        
        poly.Vertices(:,1)=poly.Vertices(:,1)+dxi;

        switch echo_obj.echo_usrdata.geometry_y
            case'samples'
                poly.Vertices(:,2)=poly.Vertices(:,2)+dyi;
                
            case {'depth' 'range'}
                
                if strcmpi(echo_obj.echo_usrdata.geometry_y,'depth')
                    idx_p = poly.Vertices(:,1)';
                    reg_trans_depth  = nan(size(poly.Vertices(:,1)'));
                    reg_trans_depth(~isnan(idx_p)) =trans_obj.get_transducer_depth(idx_p(~isnan(idx_p)));
                else
                    reg_trans_depth=zeros(1,numel(reg_curr.Idx_ping));
                end
                
                if isscalar(unique(reg_trans_depth))
                    reg_trans_depth=unique(reg_trans_depth);
                end
                
                if any(reg_trans_depth~=0)
                    if numel(reg_trans_depth)>1
                        diff_vert=diff(poly.Vertices(:,1));
                        temp_x_vert=arrayfun(@(x,z) x+sign(z)*(0:abs(z))',poly.Vertices(1:end-1,1),diff_vert,'un',0);
                        %id_rem=isnan(diff_vert);
                        idx_d=find(diff_vert==0);
                        for idi=idx_d(:)'
                            temp_x_vert{idi}=[ temp_x_vert{idi} ;temp_x_vert{idi}];
                        end
                        %temp_x_vert(id_rem)=[];
                        diff_vert(diff_vert==0)=1;
                        temp_y_vert=arrayfun(@(x,y,z) linspace(x,y,z)',poly.Vertices(1:end-1,2),poly.Vertices(2:end,2),abs(diff_vert)+1,'un',0);
                        temp_x_vert=cell2mat(temp_x_vert);
                        temp_y_vert=cell2mat(temp_y_vert);
                        idx_nan=isnan(temp_x_vert)|isnan(temp_y_vert);
                        temp_x_vert(idx_nan)=nan;
                        temp_y_vert(idx_nan)=nan;
                        poly=polyshape([temp_x_vert temp_y_vert],'Simplify',false);
                    end
                end

                if strcmpi(echo_obj.echo_usrdata.geometry_y,'depth')
                    idx_p = poly.Vertices(:,1);
                    reg_trans_depth  = nan(size(poly.Vertices(:,1)'));
                    t_angle  = nan(size(poly.Vertices(:,1)'));
                    reg_trans_depth(~isnan(idx_p)) = trans_obj.get_transducer_depth(idx_p(~isnan(idx_p)));
                    idx_beam = trans_obj.get_idx_beams(curr_disp.BeamAngularLimit);
                    t_angle(~isnan(idx_p)) = mean(trans_obj.get_beams_pointing_angles(idx_p(~isnan(idx_p)),idx_beam),3);
                else
                    reg_trans_depth=zeros(size(poly.Vertices(:,1)'));
                    t_angle=90*ones(size(poly.Vertices(:,1)'));
                end
                
                r = trans_obj.get_samples_range();
                                
                idx = ~isnan(poly.Vertices(:,2));
                idx_r = round(poly.Vertices(idx,2));
                idx_r(idx_r==0) = 1;               
                idx_r(idx_r>numel(r)) = numel(r);
                t_angle = t_angle(idx);
                
                new_vert = r(idx_r).*sind(t_angle(:));
                
                poly.Vertices(idx,2) = new_vert;
                poly.Vertices(:,2) = poly.Vertices(:,2)+reg_trans_depth';
                
                %r_text=mean(poly.Vertices(:,2));
        end
        
        poly = poly.simplify;
        
        sub_reg_poly=poly.regions;
        s_reg=arrayfun(@(x) size(x.Vertices,1),sub_reg_poly);
        
        [s_reg_s,idx_sort]=sort(s_reg,'descend');
        
        switch lower(reg_curr.Shape)
            case 'rectangular'
                nb_draw=1;
            otherwise
                nb_draw=max(sum(s_reg_s>=20,'omitnan'),1);
                
        end
        
        reg_plot=gobjects(1,nb_draw+1);
        
        reg_plot(1)=plot(main_axes,poly, 'FaceColor',col,...
            'parent',main_axes,'FaceAlpha',alpha_in,...
            'EdgeColor',col,...
            'LineWidth',0.7,...
            'tag','region',...
            'UserData',reg_curr.Unique_ID);
        
        id = 1;
        for uipo=idx_sort(1:nb_draw)'
            id=id+1;
            reg_plot(id)=text(mean(sub_reg_poly(uipo).Vertices(:,1),'omitnan'),mean(sub_reg_poly(uipo).Vertices(:,2),'omitnan'),reg_curr.disp_str(),'FontWeight','Normal','Fontsize',...
                p.Results.text_size,'Tag','region_text','color',txt_col,'parent',main_axes,'UserData',reg_curr.Unique_ID,'Clipping', 'on','interpreter','none');
        end
        
        reg_plot_tot = [reg_plot_tot reg_plot];
        
    catch err
        warning('Error display region ID %.0f',reg_curr.ID);
        print_errors_and_warnings(1,'error',err);
    end
end