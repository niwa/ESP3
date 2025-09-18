function [fnames,idx_keep]= filter_ac_files(filenames)

 [~,~,reg_exp_filter] = get_ftypes_and_extensions();

idx_keep = (~cellfun(@isempty,regexpi(filenames,sprintf('(%s)',strjoin(reg_exp_filter,'|')))));
idx_keep = find(idx_keep & ~strcmpi(filenames,'desktop.ini'));

fnames=filenames(idx_keep);

if ~isempty(fnames)
    [~,fnames_f,~] = cellfun(@fileparts,fnames,'un',0);
    [~,ia,~]  =unique(fnames_f);
    idx_keep=idx_keep(ia);
    fnames = fnames(ia);
end