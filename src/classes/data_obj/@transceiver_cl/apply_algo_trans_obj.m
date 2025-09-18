%% apply_algo_trans_obj.m
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
% * |trans_obj|: TODO: write description and info on variable
% * |algo_name|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_struct|: TODO: write description and info on variable
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
function output_struct= apply_algo_trans_obj(trans_obj,algo_name,varargin)


p = inputParser;

addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addRequired(p,'algo_name',@(x) ismember(x,list_algos()));
addParameter(p,'replace_bot',1,@isnumeric);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl')||ischar(x)||isnumeric(x)||isa(x,'matlab.graphics.primitive.Patch')||iscell(x));
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
addParameter(p,'bpool',[]);
addParameter(p,'load_bar_comp',[]);
addParameter(p,'force_ignore_status_bar',0,@isnumeric);


parse(p,trans_obj,algo_name,varargin{:});

block_len = get_block_len(50,'cpu',p.Results.block_len);

%bpool = p.Results.bpool;

% if isempty(bpool)
%     bpool = backgroundPool;
% end

fig=[];
init_state=0;

if p.Results.force_ignore_status_bar==0
    fig=findobj(0,'Type','figure','-and','Name','ESP3');
    if ~isempty(fig)
        [~,init_state]=show_status_bar(fig,0);
    end
end
output_struct.done = false;


try
    [idx_alg,alg_found]=find_algo_idx(trans_obj,algo_name);

    switch class(p.Results.reg_obj)
        case 'region_cl'
            reg_obj = p.Results.reg_obj;
        case 'char'
            idx=trans_obj.find_regions_tag(p.Results.reg_obj);
            if isempty(idx)
                reg_obj=region_cl.empty();
            else
                reg_obj=trans_obj.Regions(idx);
            end

        case 'cell'
            reg_obj=trans_obj.get_region_from_Unique_ID(p.Results.reg_obj);

        case 'matlab.graphics.primitive.Patch'
            idx_ping=round(min(p.Results.reg_obj.XData)):round(max(p.Results.reg_obj.XData));
            idx_r=round(min(p.Results.reg_obj.YData)):round(max(p.Results.reg_obj.YData));
            reg_obj=region_cl('Name','Select Area','Idx_r',idx_r,'Idx_ping',idx_ping,'Unique_ID','select_area');
        otherwise
            if isnumeric(p.Results.reg_obj)
                idx=trans_obj.find_regions_ID(p.Results.reg_obj);

                if isempty(idx)
                    reg_obj=region_cl.empty();
                else
                    reg_obj=trans_obj.Regions(idx);
                end
            else
                reg_obj=region_cl.empty();
            end
    end

    if alg_found==0
        algo_obj=init_algos(algo_name);
        trans_obj.add_algo_trans_obj(algo_obj);
    else
        algo_obj=trans_obj.Algo(idx_alg);
    end

    if isempty(algo_obj)
        return;
    end
    
    if trans_obj.ismb()&&~algo_obj.does_it_work_on_mbes()
        dlg_perso([],'Nope...','This algorithm has not been ported to MBES/Imaging sonar data (yet)... Sorry about that!');
        return;
    end


    if ~isempty(p.Results.load_bar_comp)
        p.Results.load_bar_comp.progress_bar.setText(sprintf('Applying %s on %s (%.0fkHz)',algo_name,trans_obj.Config.ChannelID,mean(trans_obj.Config.Frequency/1e3)));
    end

    varin=namedargs2cell(algo_obj.input_params_to_struct());

    if ~isempty(reg_obj)
        if numel(reg_obj)>1
            reg_obj_tmp = num2cell(merge_regions(reg_obj,'overlap_only',2));
        else
            reg_obj_tmp = num2cell(reg_obj);
        end
    else
        reg_obj_tmp = {region_cl.empty()};
    end

    %       F=parfeval(algo_obj.Function,1,trans_obj,'load_bar_comp',p.Results.load_bar_comp,'block_len',block_len,varin{:},'reg_obj',reg_obj_tmp);
    %
    %      output_struct = fetchOutputs(F);

    output_struct_t = [];
    for uireg = 1:numel(reg_obj_tmp)
        output_struct_tmp=feval(algo_obj.Function,trans_obj,'load_bar_comp',p.Results.load_bar_comp,'block_len',block_len,varin{:},'reg_obj',reg_obj_tmp{uireg});
        % if ~isfield(output_struct_tmp,'done')
        %     output_struct_tmp.done = true;
        % end
        output_struct_t = [output_struct_t output_struct_tmp];
    end

    output_struct.done = all([output_struct_t(:).done]);
    output_struct_t = rmfield(output_struct_t,'done');
    ff_out = fieldnames(output_struct_t);

    for uif = 1:numel(ff_out)
        output_struct.(ff_out{uif}) = output_struct_t.(ff_out{uif});
    end

    if ~isempty(p.Results.load_bar_comp)
        p.Results.load_bar_comp.progress_bar.setText('');
        set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',100, 'Value',0);
    end

catch err
    print_errors_and_warnings(1,'error',err);
end

if ~init_state
    hide_status_bar(fig);
end

end

