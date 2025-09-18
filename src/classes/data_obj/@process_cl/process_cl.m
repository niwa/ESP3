
classdef process_cl < handle
    properties
        Freq
        CID
        Algo
    end
    
    methods
        function obj = process_cl(varargin)
            p = inputParser;
            
            check_algo_cl=@(algo_obj) isa(algo_obj,'algo_cl');
            
            addParameter(p,'Algo',algo_cl(),check_algo_cl);
            addParameter(p,'CID','',@(x) ischar(x));
            addParameter(p,'Freq',38000,@isnumeric);
            
            parse(p,varargin{:});
            
            results=p.Results;
            props=fieldnames(results);
            
            for iprop=1:length(props)
                obj.(props{iprop})=results.(props{iprop});
            end
            
        end
        function delete(obj)
            if  isdebugging
                c = class(obj);
                disp(['ML object destructor called for class ',c])
            end
        end
    end
end

