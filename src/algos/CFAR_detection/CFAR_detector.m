function detection_mask = CFAR_detector(sv_SPB,varargin)

p = inputParser;
addRequired(p,'sv_SPB',@isnumeric);
addParameter(p,'L',20,@(x) x>0);
addParameter(p,'GC',4,@(x) x>0);
addParameter(p,'DT',5,@(x) x>0);
addParameter(p,'load_bar_comp',[]);
parse(p,sv_SPB,varargin{:});

detection_mask = false(size(sv_SPB));


[~,nb_pings,~] = size(sv_SPB);

L = p.Results.L;
GC = p.Results.GC;
DT = p.Results.DT;


if ~isempty(p.Results.load_bar_comp)
    p.Results.load_bar_comp.progress_bar.setText('CFAR detector...');
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_pings, 'Value',0);
end
for uip = 1:nb_pings
    if ~isempty(p.Results.load_bar_comp)
        set(p.Results.load_bar_comp.progress_bar, 'Value',uip);
    end
    idx_pings = uip + (-round(L/2):round(L/2));
    idx_pings(idx_pings<1|idx_pings>nb_pings|abs(idx_pings-uip)<=round(GC/2)) = [];
    m = mean(sv_SPB(:,idx_pings,:),2,'omitnan');
    s = sv_SPB(:,uip,:);
    detection_mask(:,uip,:) = pow2db_perso(s./m) > DT...
    | m == 0 ...
    | (isnan(m) & ~isnan(s));
end
end






