
function [idx_process,idx_algo,found]=find_process_algo(process_list,cid,freq,name)

found=0;
idx_process=[];
idx_algo=[];

if ~isempty(process_list)
    if ~isempty(cid)
        idx_process = find(strcmpi({process_list(:).CID},cid),1);
    else
        idx_process = find([process_list(:).Freq]==freq,1);
    end
    
    if ~isempty(idx_process)
        idx_algo = find(strcmpi({process_list(idx_process).Algo(:).Name},name),1);

        if ~isempty(idx_algo)
            found =1;
        end
    else
        idx_algo=[];
    end
end