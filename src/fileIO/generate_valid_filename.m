function fname=generate_valid_filename(fstr)

idx = strfind(fstr,':');

if any(idx>2)
    fstr(idx(idx>2))='';
end

[path_f,f_name,ext]=fileparts(fstr);

f_name  = clean_str(f_name,true);

fname=fullfile(path_f,[f_name ext]);


end