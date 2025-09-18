function output_struct=detect_multiple_bottom_echo(trans_obj,varargin)
p = inputParser;

addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));

addParameter(p,'WC_lgth','deep',@ischar);
addParameter(p,'p_int_offset',0.15,@isnumeric);
addParameter(p,'copy_other_f',false,@islogical);
addParameter(p,'singleMBE_region',false,@islogical);
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'load_bar_comp',[]);

parse(p,trans_obj,varargin{:});

output_struct.done = false;
Range_trans = trans_obj.get_samples_range();

if isempty(p.Results.reg_obj)
    idx_r_tot=1:length(Range_trans);
    idx_ping_tot=1:length(trans_obj.get_transceiver_pings());
    reg_obj=region_cl('Name','Temp','Idx_r',idx_r_tot,'Idx_ping',idx_ping_tot);
else
    reg_obj=p.Results.reg_obj;
end

idx_ping_tot=reg_obj.Idx_ping;
idx_r_tot=1:length(Range_trans);

if ~any(~isnan(trans_obj.get_bottom_depth))
    dlg_perso([],'No bottom detected','No bottom detected, cannot run the algorithm');
    output_struct.done =  true;
    return;
end

block_len = get_block_len(50,'cpu',p.Results.block_len);

block_size=min(ceil(block_len/numel(idx_r_tot)/2),numel(idx_ping_tot));

num_ite=ceil(numel(idx_ping_tot)/block_size);

shape = 'Polygon';
name = 'MBE';
type_data = 'Bad Data';
reference = 'Bottom';
cell_w_units = 'pings';
cell_h_units = 'meters';
cell_w = 10;
cell_h = 10;
reg_dbe = [];
copy_other_f = p.Results.copy_other_f;
singleMBE_region = p.Results.singleMBE_region;
main_figure=get_esp3_prop('main_figure');

up_bar=~isempty(p.Results.load_bar_comp);
if up_bar
    p.Results.load_bar_comp.progress_bar.setText('Multiple bottom echo detection');
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
end

for ui=1:num_ite

    idx_ping=idx_ping_tot((ui-1)*block_size+1:min(ui*block_size,numel(idx_ping_tot)));
    idx_ping = (idx_ping(1)-5):(idx_ping(end)+5);
    idx_ping(idx_ping<1) = [];
    idx_ping(idx_ping>numel(idx_ping_tot)) = [];

    Rb = trans_obj.get_bottom_depth(idx_ping);

    c = mean(trans_obj.get_soundspeed());
    p_int_per_ping =  gradient(trans_obj.Time(idx_ping)*24*60*60);
    p_int_offset = p.Results.p_int_offset;
    WC_lgth = p.Results.WC_lgth;
    
    Rmbe_offmin = zeros(size(Rb));
    Rmbe = zeros(size(Rb));

    idx_plus = p_int_per_ping*c/2>Rb;
    idx_minus = ~idx_plus;

    if strcmp(WC_lgth,'shallow')
        p_int_per_ping =  gradient(trans_obj.Time(idx_ping)*24*60*60)/2;
        for i=1:length(Rmbe)
            n=0;
            while p_int_per_ping(i)*c/2>n*Rb(i)
                n=n+1;
                Rmbe(i) = n*Rb(i)-p_int_per_ping(i)*c/2;
                Rmbe_offmin(i) = n*Rb(i)-(p_int_per_ping(i)-p_int_offset)*c/2;
            end
        end
    else
        if any(idx_plus)
            n=0;
            while any(Rmbe(idx_plus)<=0)
                n=n+1;
                Rmbe(idx_plus) = n*Rb(idx_plus)-p_int_per_ping(idx_plus)*c/2;
                Rmbe_offmin(idx_plus) = n*Rb(idx_plus)-(p_int_per_ping(idx_plus)-p_int_offset)*c/2;
                idx_plus(Rmbe(idx_plus)>0) = false;
            end
        end
    
        if any(idx_minus)
            n=0;
            while any(Rmbe(idx_minus)<=0)
                n=n+1;
                Rmbe(idx_minus) = Rb(idx_minus)-n*p_int_per_ping(idx_minus)*c/2;
                Rmbe_offmin(idx_minus) = Rb(idx_minus)-n*(p_int_per_ping(idx_minus)-p_int_offset)*c/2;
                idx_minus(Rmbe(idx_minus)>0) = false;
            end   
        end
    end

    r_min = Rb-Rmbe_offmin;
    r_max = Rb-Rmbe;

    temp_r_min = r_min;
    r_min(r_min<=0) = Rb(r_min<=0)+r_min(r_min<=0);
    r_max(temp_r_min<=0) = Rb(temp_r_min<=0)+r_max(temp_r_min<=0);

    mask = bsxfun(@ge, Range_trans, Rb-r_max ) & ...
        bsxfun( @le, Range_trans, Rb-r_min );

    idx_r_mb = find(sum(mask,2)>0,1,'first'):find(sum(mask,2)>0,1,'last');

    if ~isempty(idx_r_mb)
        mask = mask(idx_r_mb,:);
        reg_tmp = region_cl(...
            'ID',trans_obj.new_id(),...
            'Shape',shape,...
            'MaskReg',mask,...
            'Name',name,...
            'Type',type_data,...
            'Idx_ping',idx_ping-1,...
            'Idx_r',idx_r_mb,...
            'Reference',reference,...
            'Cell_w',cell_w,...
            'Cell_w_unit',cell_w_units,...
            'Cell_h',cell_h,...
            'Cell_h_unit',cell_h_units,...
            'Tag','MBE');
        reg_dbe = [reg_dbe reg_tmp];

    end
    if up_bar
        set(p.Results.load_bar_comp.progress_bar,'Value',ui);
    end
end
trans_obj.rm_region_name(name);

if isempty(reg_dbe)
    dlg_perso([],'No MB detected','No MB echoe detected');
else
    reg_dbe = merge_regions(reg_dbe,'overlap_only',0);
    reg_dbe.Name = name;  
    if singleMBE_region          
        trans_obj.add_region(reg_dbe);
    else
        reg_dbe=reg_dbe.split_regions();  
        for itype=1:length(reg_dbe)
            reg_dbe(itype).Type = 'Bad Data';
        end
        trans_obj.add_region(reg_dbe);
    end
end

if copy_other_f==true
    layer = get_current_layer();
    app_path_main=whereisEcho();
    esp3_icon = fullfile(app_path_main,'icons','echoanalysis.png');
    copy_reg_fig = uifigure(main_figure, ...
        'Units','pixels',...
        'Position',[700 500 500 200],...
        'Resize','off',...
        'Name','Select frequencies to copy false bottom echo region to',...
        'Tag','copy_reg','Icon',esp3_icon,'Color',[1 1 1]);

    uicontrol(copy_reg_fig,...
    'Style','Text',...
    'String','Channels:',...
    'TooltipString','Select one or several channels',...
    'units','normalized',...
    'HorizontalAlignment','right',...
    'BackgroundColor','white',...
    'Position',[0.1 0.8 0.27 0.07]);
    
    freqs_nom = layer.Frequencies;
    freqs_nom_str = cell(1,length(freqs_nom));
    for fnom=1:length(freqs_nom)
        freqs_nom_str{1,fnom} = append(num2str(freqs_nom(fnom)/1000),' kHz');
    end
    maxl = length(freqs_nom)+1;
    minl = 1;
    freqs = uicontrol(copy_reg_fig,...
        'Style','listbox',...
        'String',freqs_nom_str,...
        'TooltipString','Select one or several channels',...
        'Value',1,...
        'Max',maxl,...
        'Min',minl,...
        'units','normalized',...
        'Position',[0.4 0.4 0.2 0.5]);

    uicontrol(copy_reg_fig,...
    'Style','pushbutton',...
    'units','normalized',...
    'string','Copy',...
    'pos',[0.35 0.01 0.25,0.1],...
    'HorizontalAlignment','left',...
    'BackgroundColor','white',...
    'callback',{@copy_mbecho});
end
    
    function copy_mbecho(~,~)  
        lreg = length(reg_dbe);
        disp(reg_dbe(end))
        layer.copy_region_across(1,reg_dbe(1:lreg),freqs.Value);
        close(copy_reg_fig)
        dlg_perso([],'Done',append('Copied false bottom echo region from ',freqs_nom_str{1}));
    end

output_struct.done =  true;
end
