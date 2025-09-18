function regions_out=split_regions(regions,varargin)

p = inputParser;

addRequired(p,'regions',@(obj) isa(obj,'region_cl'));
addParameter(p,'merge_result',false,@islogical);
parse(p,regions,varargin{:});


regions_out =[];

for uir = 1:numel(regions)
    reg = regions(uir);
    h = reg.Poly.holes;
    d = rmholes(reg.Poly.regions);
    sub_regs = [d;h];
    ishole_b = ones(1,numel(sub_regs));
    ishole_b(1:numel(d)) = 0;
    
    reg_temp = [];
    
    for ui_sub = 1:numel(sub_regs)
        
        sub_reg = sub_regs(ui_sub);
        
        idx_r=floor(min(sub_reg.Vertices(:,1))):ceil(max(sub_reg.Vertices(:,1)));
        
        idx_ping=floor(min(sub_reg.Vertices(:,2))):ceil(max(sub_reg.Vertices(:,2)));
        
        switch ishole_b(ui_sub)
            case 1
                Type = 'Bad Data';
            case 0
                Type = 'Data';
        end
                   
        tmp = region_cl(...
            'Shape','Polygon',...
            'Poly',sub_reg,...
            'ID',reg.ID,...
            'Name',reg.Name,...
            'Type',Type,...
            'Idx_r',idx_r,...
            'Idx_ping',idx_ping,...
            'Reference','Surface',...
            'Cell_w',reg.Cell_w,...
            'Cell_w_unit',reg.Cell_w_unit,...
            'Cell_h',reg.Cell_h,...
            'Cell_h_unit',reg.Cell_h_unit);
        
        reg_temp = [reg_temp tmp];
        
    end
    if ~isempty(reg_temp)&&p.Results.merge_result
        new_regions=reg_temp.merge_regions('overlap_only',1);
        regions_out = [regions_out new_regions];
    else
        regions_out = [regions_out reg_temp];
    end
    
    
end



end
