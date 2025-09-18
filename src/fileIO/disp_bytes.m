function disp_bytes(fid,bool,N,varargin)
fmt  = 'uint8';
if isscalar(varargin)
    fmt = varargin{1};
end
if bool
    for iii = 1:N
        fprintf(1,'N %d: %d\n',iii,fread(fid,1,fmt));
    end
    fprintf(1,'\n');
else
    fseek(fid,N,'cof');
end
end