function [out,f] = compute_scattering_model(varargin)


[distr_list,~,~,~,default_distr_params,~,~] = scat_distrib_cl.list_distrib();

p = inputParser;

addParameter(p,'distr_params',[0.1*1e-3 2*1e-3],@isnumeric);
addParameter(p,'distrib',{'wbl'},@(x) all(cellfun(@(y) ismember(y,distr_list),x)));
addParameter(p,'f',(1:200)*1e3,@isnumeric);%frequency
addParameter(p,'Nb_bins',500,@(x) x>0);
addParameter(p,'T',13,@isnumeric);
addParameter(p,'S',35,@(x) x>0);
addParameter(p,'z',100,@(x) x>0);
addParameter(p,'rmin',1e-5,@(x) x>0);
addParameter(p,'rmax',2*1e-3,@(x) x>0);
addParameter(p,'tau',0.075,@(x) all(x>0));
addParameter(p,'modes_conc',{[0 0 1 0 0 0]},@iscell);
addParameter(p,'gas_list',{'O2' 'N2' 'CH4' 'CO2' 'Ar'});
addParameter(p,'equal_ratio',1,@(x) isnumeric(x)||islogical(x));
addParameter(p,'ac_var','Sv',@(x) ismember(x,{'Sv','TS'}));
addParameter(p,'theta',0,@(x) all(x>=0));
addParameter(p,'e_fact',1,@(x) all(x>=1));

parse(p,varargin{:});
distr = p.Results.distrib;
nb_modes  = numel(distr);
equal_ratio  = p.Results.equal_ratio||nb_modes==1;

id = find(strcmpi('distr_params',p.UsingDefaults), 1);

if ~isempty(id)
    x =[];
    equal_ratio = 1;
    for ui = 1:nb_modes
        x = [x default_distr_params{strcmpi(distr{ui},distr_list)}];
    end
else
    x = p.Results.distr_params;
end

z = p.Results.z;
T=p.Results.T;
S=p.Results.S;

%modes_name = p.Results.modes_name;

params_struct.tau  = p.Results.tau;
params_struct.Nb_bins  = p.Results.Nb_bins;
params_struct.rmin = p.Results.rmin;
params_struct.rmax = p.Results.rmax;
params_struct.theta = p.Results.theta;
params_struct.e_fact = p.Results.e_fact;
p_fields = fieldnames(params_struct);


for ifi =1:numel(p_fields)
    if numel(params_struct.(p_fields{ifi}))<=nb_modes
        params_struct.(p_fields{ifi}) = params_struct.(p_fields{ifi})(1)*ones(1,nb_modes);
    end
end

f = p.Results.f;
conc = p.Results.modes_conc;

if numel(conc)<nb_modes
    tmp =conc{1};
    conc = cell(1,nb_modes);
    conc(:) = {tmp};
end

out = zeros(1,numel(f));
iparams = 1;
r_tot = 0;

nb_params = cellfun(@(x) numel(default_distr_params{strcmpi(x,distr_list)}),distr,'un',1);
           
for ui = 1:nb_modes
    
    if equal_ratio==0
        ratio = x(iparams+nb_params(ui));
        dp =1;
    else
        ratio = 1;
        dp= 0;
    end
    
    switch p.Results.ac_var
        case 'Sv'
            out = out + ...
                ratio*...
                multi_bubble_scattering_gas_mixture(x((iparams:iparams+nb_params(ui)-1)),distr{ui},'z',z,'f',f,'T',T,'S',S,...
                'gas_list',p.Results.gas_list,'gas_frac',conc{ui},...
                'e_fact',params_struct.e_fact(ui),...
                'Nb_bins',params_struct.Nb_bins(ui),'tau',params_struct.tau(ui),'rmin',params_struct.rmin(ui),'rmax',params_struct.rmax(ui),'theta',params_struct.theta(ui));
            
        case 'TS'
            
            out = out + ...
                ratio*single_bubble_scattering_gas_mixture(x((iparams:iparams+nb_params(ui)-1)),'z',z,'f',f,'T',T,'S',S,...
                'gas_list',p.Results.gas_list,'gas_frac',conc{ui},'Nb_bins',params_struct.Nb_bins(ui),...
            'e_fact',params_struct.e_fact(ui),...    
            'tau',params_struct.tau(ui),'rmin',params_struct.rmin(ui),'rmax',params_struct.rmax(ui),'theta',params_struct.theta(ui))   ;
    end
    r_tot = ratio+r_tot;
    iparams = iparams+nb_params(ui)+dp;
    
end
out = out./r_tot;

if strcmpi(p.Results.ac_var,'Sv')&&numel(x)>=iparams&&~isnan(x(iparams))
        x(iparams) = max(x(iparams),1e-6,'omitnan');
        out = out*x(iparams);
end
    
if all(out==0)
    out(:) = inf;
end

end
