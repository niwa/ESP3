function [ftypes,ext,reg_exp_filter] = get_ftypes_and_extensions()

ftypes = {'EK60' 'EK80' 'ME70' 'MS70' 'ASL' 'CREST' 'FCV-30' 'NETCDF4' 'TOPAS' 'DIDSON' 'LOGBOOK' 'OCULUS' 'XTF' 'EM' 'EM' 'KEM' 'KEM' 'SL3' 'SL2'};
ext = {'*.raw' '*.raw' '*.raw' '*.raw' '*A' 'd*' '*.ini;*lst' '*.nc' '*.raw' '*.ddf' 'echo_logbook.db' '*.oculus' '*.xtf' '*.all' '*.wcd' '*.kmall' '*.kmwcd' '*.sl3' '*.sl2'};
reg_exp_filter = {'raw$' 'raw$' 'raw$' 'raw$' 'A$' '^[d]\d{7}$' 'lst$|ini$' 'nc$' 'raw$' 'ddf$' 'oculus$' 'xtf$' 'all$' 'wcd$' 'kmall$' 'kmwcd$' 'sl3$' 'sl2$'};
