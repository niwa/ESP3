%% create_regions_from_linked_candidates.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |trans|: TODO: write description and info on variable
% * |linked_candidates|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-03-28: header (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function [reg_out,id_rem]=create_regions_from_linked_candidates(trans_obj,linked_candidates,varargin)

p = inputParser;

check_w_unit=@(unit) ~isempty(strcmp(unit,{'pings','meters'}));
check_h_unit=@(unit) ~isempty(strcmp(unit,{'meters'}));

addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addRequired(p,'linked_candidates',@(x) isnumeric(x)||isstring(x));
addParameter(p,'idx_ping',1:size(linked_candidates,2),@isnumeric);
addParameter(p,'idx_r',1:size(linked_candidates,1),@isnumeric);
addParameter(p,'w_unit','pings',check_w_unit);
addParameter(p,'h_unit','meters',check_h_unit);
addParameter(p,'cell_w',10);
addParameter(p,'cell_h',5);
addParameter(p,'ref','Transducer');
addParameter(p,'reg_names','School',@ischar);
addParameter(p,'rm_overlapping_regions',true,@islogical);
addParameter(p,'add_regions',true,@islogical);
addParameter(p,'tag','',@(x) ischar(x)||istring(x));
addParameter(p,'bbox_only',0);


parse(p,trans_obj,linked_candidates,varargin{:});

reg_out = [];

w_unit=p.Results.w_unit;
h_unit=p.Results.h_unit;
cell_h=p.Results.cell_h;
cell_w=p.Results.cell_w;

bbox_only=p.Results.bbox_only;
ref=p.Results.ref;

reg_schools=trans_obj.get_region_from_name(p.Results.reg_names);

nb_pings = length(trans_obj.get_transceiver_pings());
nb_samples = length(trans_obj.get_samples_range());

[classes,id_classes,ic]=unique(linked_candidates);
%
%
if isstring(classes)
    ic(ic==id_classes(id_classes==find(classes=="")))=0;
    classes(classes=="")=[];
    tags=classes;
    classes=unique(ic);
    classes(classes==0)=[];
    linked_candidates=reshape(ic,size(linked_candidates));
else
    classes(classes==0)=[];
    tags=strings(size(classes));
    tags(:) = p.Results.tag;
end

idx_ping=p.Results.idx_ping;
idx_ping(idx_ping<0|idx_ping>nb_pings) = [];

idx_r=p.Results.idx_r;
idx_r(idx_r<0 | idx_r >nb_samples) = [];

idx_ping_vec = floor(linspace(min(idx_ping,[],'all','omitnan'),max(idx_ping,[],'all','omitnan'),size(linked_candidates,2)));
idx_r_vec = floor(linspace(min(idx_r,[],'all','omitnan'),max(idx_r,[],'all','omitnan'),size(linked_candidates,1)))';

if (numel(idx_ping)~=size(linked_candidates,2)) && ~all(size(idx_ping)==size(linked_candidates))
    idx_ping = idx_ping_vec;
end

if (numel(idx_r)~=size(linked_candidates,1)) && ~all(size(idx_r)==size(linked_candidates))
    idx_r = idx_r_vec;
end


% f = figure();
% ax = axes(f);
% imagesc(ax,isnan(idx_r));hold on;

for j=1:numel(classes)
    try

        curr_reg=(linked_candidates==classes(j));

        if any(curr_reg,'all')


            if bbox_only==1
                [J,I]=find(curr_reg);


                reg_temp=region_cl(...
                    'ID',trans_obj.new_id(),...
                    'Name',p.Results.reg_names,...
                    'Type','Data',...
                    'Idx_ping',unique(idx_ping(I)),...
                    'Idx_r',unique(idx_r(J)),...
                    'Shape','Rectangular',...
                    'Reference',ref,...
                    'Cell_w',cell_w,...
                    'Cell_w_unit',w_unit,...
                    'Cell_h',cell_h,...
                    'Cell_h_unit',h_unit,'Tag',char(tags(j)));
            else
                [x_c,y_c]=cont_from_mask(full(curr_reg));
                [x_c,y_c]=reduce_reg_contour(x_c,y_c,10);
                if all(size(idx_r)==size(curr_reg))
                    [~,dr] = gradient(idx_r);
                    dr = floor(dr/2);
                    dp = floor(gradient(idx_ping/2));

                    xx = cellfun(@(u) idx_ping(u)'+dp(u)', x_c,'un',0);
                    yy = cellfun(@(u,v) idx_r(u+size(curr_reg,1)*(v-1))+dr(u+size(curr_reg,1)*(v-1)),y_c,x_c,'un',0);

                    try
                        pp=polyshape(xx,yy,'Simplify',true);
                        %                     cellfun(@(u,v) plot(ax,u,v),x_c,y_c);
                    catch
                        continue;
                    end

                else
                    idx_r = idx_r(:)';
                    idx_ping = idx_ping(:)';
                    dr = floor(gradient(idx_r)/2);
                    dp = floor(gradient(idx_ping)/2);
                    pp=polyshape(cellfun(@(u) idx_ping(u)+dp(u), x_c,'un',0),cellfun(@(u) idx_r(u)+dr(u), y_c,'un',0),'Simplify',true);
                end

                reg_temp=region_cl(...
                    'ID',trans_obj.new_id(),...
                    'Name',p.Results.reg_names,...
                    'Type','Data',...
                    'Shape','Polygon',...
                    'Poly',pp,...
                    'Reference',ref,...
                    'Cell_h',cell_h,...
                    'Cell_h_unit',h_unit,...
                    'Cell_w',cell_w,...
                    'Cell_w_unit',w_unit,'Tag',char(tags(j)));

            end

            vertices_1=unique(reg_temp.Poly.Vertices(~isnan(reg_temp.Poly.Vertices(:,1)),1));
            vertices_2=unique(reg_temp.Poly.Vertices(~isnan(reg_temp.Poly.Vertices(:,2)),2));

            if numel(vertices_1)<2||numel(vertices_2)<2
                continue;
            end

            id_rem={};
            if p.Results.rm_overlapping_regions
                for ireg=1:length(reg_schools)
                    mask_inter=reg_temp.get_mask_from_intersection(reg_schools(ireg));
                    if any(mask_inter(:))
                        id_rem=union(id_rem,reg_schools(ireg).Unique_ID);
                        trans_obj.rm_region_id(reg_schools(ireg).Unique_ID);
                    end
                end
            end
            reg_out = [reg_out reg_temp];
            if p.Results.add_regions
                trans_obj.add_region(reg_temp,'Split',0);
            end
        end
    catch err
        print_errors_and_warnings([],'warning',sprintf('Error creating regions for classe %d...',classes(j)));
        print_errors_and_warnings([],'warning',err);
    end

end