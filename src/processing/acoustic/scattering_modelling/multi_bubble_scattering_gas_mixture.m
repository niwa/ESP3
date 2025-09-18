function sigmaBS=multi_bubble_scattering_gas_mixture(distr_param,distrib,varargin)

p = inputParser;

addRequired(p,'distr_param',@isnumeric);%
addRequired(p,'distrib',@(x) ismember(x,{'wbl' 'ray' 'lognorm' 'uni' 'mono'}));
addParameter(p,'f',(1:200)*1e3,@isnumeric);%frequency
addParameter(p,'z',200,@isnumeric);%depth
addParameter(p,'tau',0.075,@isnumeric);
addParameter(p,'T',10,@isnumeric);
addParameter(p,'S',35,@isnumeric);
addParameter(p,'gas_list',{'O2' 'N2' 'CH4' 'CO2' 'Ar'});
addParameter(p,'gas_frac',[20.95 78.09 0 0.04 0.93]);
addParameter(p,'Nb_bins',250,@(x) x>0);
addParameter(p,'rmin',1e-5,@(x) x>0);
addParameter(p,'rmax',10*1e-3,@(x) x>0);
addParameter(p,'theta',0,@(x) x>=0);
addParameter(p,'e_fact',1,@(x) x>0);
parse(p,distr_param,distrib,varargin{:});

Nb_bins=p.Results.Nb_bins;

%r=logspace(log10(p.Results.rmin),log10(p.Results.rmax),Nb_bins);
r=linspace(p.Results.rmin,p.Results.rmax,Nb_bins);

bubbles_pdf = compute_pdf(distrib,r,distr_param);

tmp=arrayfun(@(y) single_bubble_scattering_gas_mixture(y,...
'f',p.Results.f,...
'z',p.Results.z,...
'tau',p.Results.tau,...
'T',p.Results.T,...
'S',p.Results.S,...
'gas_list',p.Results.gas_list,...
'gas_frac',p.Results.gas_frac,...
'theta',p.Results.theta,...
'e_fact',p.Results.e_fact,...
'gamma',[]),...
 r,'un',0);

sigmaBS=sum(bubbles_pdf'.*gradient(r)'.*cell2mat(tmp'),1,'omitnan');



end
