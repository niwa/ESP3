
function IDs_out=add_region(trans_obj,regions,varargin)

p = inputParser;

addRequired(p,'trans_obj',@(trans_obj) isa(trans_obj,'transceiver_cl'));
addRequired(p,'regions',@(obj) isa(obj,'region_cl')||isempty(obj));
addParameter(p,'Tag','',@(x) ischar(x)||iscell(x));
addParameter(p,'IDs',[],@(x) isnumeric(x)||isempty(x));
addParameter(p,'Split',0,@(x) isnumeric(x)||islogical(x));
addParameter(p,'Merge',1,@(x) isnumeric(x)||islogical(x));
addParameter(p,'Idx_beam',1,@(x) isnumeric(x));
addParameter(p,'Origin','',@ischar);
addParameter(p,'Ping_offset',0,@isnumeric);


parse(p,trans_obj,regions,varargin{:});

IDs=p.Results.IDs;
Tag=p.Results.Tag;
Origin=p.Results.Origin;
Split=p.Results.Split;
Ping_offset=p.Results.Ping_offset;
IDs_out={};

for ireg=1:length(regions)
    
    regions(ireg).Idx_ping=regions(ireg).Idx_ping-Ping_offset;
    
    switch (regions(ireg).Cell_w_unit)
        case {'meters' 'seconds'}
          regions(ireg).Cell_w=regions(ireg).Cell_w;  
        case 'pings'
          regions(ireg).Cell_w=max(1,regions(ireg).Cell_w);
    end
    
        
    switch (regions(ireg).Cell_h_unit)
        case 'meters'
            regions(ireg).Cell_h=regions(ireg).Cell_h;
    end
    
    if ~isempty(regions(ireg).Poly)
        regions(ireg).Poly.Vertices(:,1)=regions(ireg).Poly.Vertices(:,1)-Ping_offset;
    end

    regions(ireg)=trans_obj.validate_region(regions(ireg));

       vertices_1=unique(regions(ireg).Poly.Vertices(~isnan(regions(ireg).Poly.Vertices(:,1)),1));
       vertices_2=unique(regions(ireg).Poly.Vertices(~isnan(regions(ireg).Poly.Vertices(:,2)),2));
       
       if numel(vertices_1)<2||numel(vertices_2)<2
            continue;
       end   
    
    if numel(regions(ireg).Idx_ping)<2||numel(regions(ireg).Idx_r)<2
        continue;
    end

    regs_id=trans_obj.get_region_from_Unique_ID(regions(ireg).Unique_ID);
    
    if isempty(regs_id)||p.Results.Merge==0
        reg_curr=regions(ireg);
    else
        reg_tmp=[regions(ireg) regs_id];
                reg_curr=reg_tmp.concatenate_regions();
    end

    reg_curr.Unique_ID=regions(ireg).Unique_ID;
    trans_obj.rm_region_id(regions(ireg).Unique_ID);

    if ~strcmpi(Tag,'')
        if ~iscell(Tag)
            reg_curr.Tag=Tag;
        else
            if length(Tag)>=ireg
                reg_curr.Tag=Tag{ireg};
            else
                reg_curr.Tag=Tag{length(Tag)};
            end
        end 
    end
    
    if ~isempty(IDs)&&length(IDs)==length(regions)
        reg_curr.ID=IDs(ireg);
    end
    
    if ~strcmpi(Origin,'')
        if ~iscell(Origin)
            reg_curr.Origin=Origin;
        else
            if length(Origin)>=ireg
                reg_curr.Origin=Origin{ireg};
            else
                reg_curr.Origin=Origin{length(Origin)};
            end
        end
    end
    
    if Split>0
        splitted_reg=reg_curr.split_region_per_fileID(trans_obj.Data.FileId,0);
        trans_obj.Regions=[trans_obj.Regions splitted_reg];
        IDs_out=union(IDs_out,{splitted_reg(:).Unique_ID});
    else
        trans_obj.Regions=[trans_obj.Regions reg_curr];
        IDs_out=union(IDs_out,reg_curr.Unique_ID);
    end
end
end
