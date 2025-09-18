function bubbles_pdf = compute_pdf(distrib,r,distr_param)

try
    switch lower(distrib)
        case {'lognorm' 'log-normal'}
            m=max(distr_param(1),0);
            v =max(distr_param(2),0);
            
            sigma = sqrt(log(1+v^2/m^2));
            mu = log(m)-sigma^2/2;
                 
%             mu = log(m^2/sqrt(v^2+m^2));
%             sigma = sqrt(log(1+v^2/m^2));
%             
            
            bubbles_pdf = lognpdf(r,mu,sigma);
            
        case 'mono'
            bubbles_pdf = zeros(size(r));
            [~,id]  =min(abs(r-distr_param(1)),[],'all','omitnan');
            bubbles_pdf(id) = 1;
        case {'ray' 'rayleigh'}
            mu = sqrt(2/pi)*distr_param(1);
            bubbles_pdf = raylpdf(r,mu);
        otherwise
            
            switch numel(distr_param)
                case 1
                    bubbles_pdf =pdf(distrib,r,distr_param);
                case 2
                    bubbles_pdf =pdf(distrib,r,distr_param(1),distr_param(2));
                case 3
                    bubbles_pdf =pdf(distrib,r,distr_param(1),distr_param(2),distr_param(3));
                case 4
                    bubbles_pdf =pdf(distrib,r,distr_param(1),distr_param(2),distr_param(3),distr_param(4));
            end
    end
    
catch
    bubbles_pdf = zeros(size(r));
end

if sum(bubbles_pdf,'all','omitnan')>0
    bubbles_pdf = bubbles_pdf./sum(bubbles_pdf.*gradient(r),'all','omitnan');
end