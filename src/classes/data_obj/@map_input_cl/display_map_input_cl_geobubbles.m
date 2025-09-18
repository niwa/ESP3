function hfigs=display_map_input_cl_geobubbles(obj_tot,varargin)
p = inputParser;

addRequired(p,'obj_tot',@(x) isa(x,'map_input_cl'));
addParameter(p,'main_figure',[],@(h) isempty(h)|isa(h,'matlab.ui.Figure'));
addParameter(p,'echomaps',{},@(h) iscell(h));
addParameter(p,'field','SliceAbscf',@ischar);
addParameter(p,'oneMap',0,@isnumeric);
addParameter(p,'coloredCircle','Proportional',@ischar);
addParameter(p,'LatLim',[],@isnumeric);
addParameter(p,'LongLim',[],@isnumeric);
addParameter(p,'Colormap',[],@(x) isnumeric(x)||ischar(x));

parse(p,obj_tot,varargin{:});


main_figure=p.Results.main_figure;
field=p.Results.field;
uid=generate_Unique_ID(numel(obj_tot));

for ui=1:numel(obj_tot)
    obj=obj_tot(ui);

    surv_name=unique(obj.Title);

    fig_name=sprintf('%s',strjoin(surv_name, 'and'));


    hfigs(ui)=new_echo_figure(main_figure,'Name',fig_name,'Tag',sprintf('nav_%s',uid{ui}),'Toolbar','esp3','MenuBar','esp3','UiFigureBool',true);
    hfig=hfigs(ui);


    if ~isempty(p.Results.Colormap)
        colormap(hfig,p.Results.Colormap);
    end

    LongLim=[nan nan];
    LatLim=[nan nan];


    if ~strcmp(field,'Tag')
        [~,~,survey_name_num]=unique(obj.SurveyName);
        snap=unique([obj.Snapshot(:)';survey_name_num(:)']','rows');
    else
        [tag,~]=unique(obj.Regions.Tag);
        snap=ones(length(tag),2);
    end

    LongLim(1)=min(LongLim(1),obj.LongLim(1));
    LongLim(2)=max(LongLim(2),obj.LongLim(2));
    LatLim(1)=min(LatLim(1),obj.LatLim(1));
    LatLim(2)=max(LatLim(2),obj.LatLim(2));

    [LatLim,LongLim]=ext_lat_lon_lim_v2(LatLim,LongLim,0.1);

    if p.Results.oneMap>0
        snap=[1 1];
    end

    nb_snap=size(snap,1);

    nb_row=ceil(nb_snap/3);
    nb_col=min(nb_snap,3);

    tt = uigridlayout(hfigs(ui),[nb_row nb_col]);

    for usnap=1:nb_snap

        if p.Results.oneMap==0
            idx_snap=find(obj.Snapshot==snap(usnap,1)&survey_name_num(:)'==snap(usnap,2));
            if isempty(idx_snap)
                continue;
            end
        else
            idx_snap=1:length(obj.Snapshot);
        end

        lat = [];
        lon = [];
        r_size = [];
        r_size_disp = [];


        for uui=1:length(idx_snap)


            if ~isempty(obj.SliceLong{idx_snap(uui)})

                ring_size=obj.(field){idx_snap(uui)};
                idx_rings=find(ring_size>0);
                switch lower(obj.PlotType)
                    case {'log10' 'db'}
                        ring_size_d=zeros(size(ring_size));
                        ring_size_d(idx_rings) = log10(ring_size(idx_rings));

                    case {'sqrt' 'square root'}
                        ring_size_d = sqrt(ring_size);

                    otherwise
                        ring_size_d = ring_size;
                end

                lat = [lat obj.SliceLat{idx_snap(uui)}(idx_rings)];
                lon = [lon obj.SliceLong{idx_snap(uui)}(idx_rings)];
                r_size = [r_size ring_size(idx_rings)];
                r_size_disp = [r_size_disp ring_size_d(idx_rings)];


            end
        end
        C=[0 0 0.8];
        switch p.Results.coloredCircle
            case 'Red'
                C=[0.8 0 0];
            case 'Blue'
                C=[0 0 0.8];
            case 'Black'
                C=[0 0 0];
            case 'Green'
                C=[0 0.8 0];
            case 'Yellow'
                C=[ 0.8 0.8 0];
            case 'White'
                C=[1 1 1];
        end

        panel_h = uipanel(tt);
        b_obj(usnap)=geobubble(panel_h,lat,lon,r_size_disp,...
            'Basemap',obj.Basemap,'MapLayout','maximized');
        b_obj(usnap).BubbleColorList = C;
        title(b_obj(usnap),sprintf('%s Snapshot %d',obj.Voyage{idx_snap(1)},snap(usnap,1)));

        if ~isempty(p.Results.LatLim)
            geolimits(b_obj(usnap),p.Results.LatLim,p.Results.LongLim);
        else
            geolimits(b_obj(usnap),LatLim,LongLim);
        end
    end

end
