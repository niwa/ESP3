function  connect_parpool(esp3_obj)

if ~isdeployed()
    tf = canUseParallelPool();
else
    tf  = true;
end

if tf && (isempty(esp3_obj.ppool) || ~esp3_obj.ppool.Connected)
    if isempty(gcp('nocreate'))
        esp3_obj.ppool = parpool('local');
    else
        esp3_obj.ppool = gcp('nocreate');
    end
    esp3_obj.ppool.IdleTimeout = 240;
end

if ~isempty(esp3_obj.ppool) && ~isempty(esp3_obj.ppool.Cluster)
    fprintf('ESP3 parallel pool connected (%s) with %d workers on %s\n',...
        esp3_obj.ppool.Cluster.Profile,esp3_obj.ppool.Cluster.NumWorkers,esp3_obj.ppool.Cluster.Host);
else
     fprintf('ESP3 parallel pool not connected\n');
end