function str  = clean_str(str,varargin)
if isempty(str)
    return;
end
str  = regexprep(str,'[\\\\/:*?\"<>.|]', '_');
str = regexprep(str,'\W','_');
str = strrep(str,'__','_');
str = regexprep(str,'(^_)|(_$)','');

just_clean_it = false;

if nargin>1
    just_clean_it = varargin{1};
end

if ~isempty(str) && ~strcmpi(str,' ')&&~just_clean_it
    str = matlab.lang.makeValidName(str);
end

end