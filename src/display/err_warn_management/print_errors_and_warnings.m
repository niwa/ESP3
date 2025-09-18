function print_errors_and_warnings(fids,type,err)

if ischar(err)
	errstr = strrep(err,'\','/');
else
    errstr  = err.message;
end

 arrayfun(@(x) fprintf(x,'%s: %s: %s\n',datestr(now,'HH:MM:SS'),upper(type),errstr),unique([1 fids]),'un',0); 

switch lower(type)
    case 'error'
        if ~ischar(err)
            for is = 1:min(numel(err.stack),5)
                [~,f_temp,e_temp]=fileparts(err.stack(is).file);
                err_str=sprintf('file %s, line %d',[f_temp e_temp],err.stack(is).line);
                arrayfun(@(x) fprintf(x,'        %s\n',datestr(now,'HH:MM:SS'),err_str),unique([1 fids]),'un',0);
            end
        end
    case {'warn' 'warning'}
        warning(errstr,errstr);
end

