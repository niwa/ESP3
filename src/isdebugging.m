function otp = isdebugging(inp)
persistent state
switch nargin
    case 0
        state = (~isempty(state) && state);
    case 1
        state = inp;
end
otp = state && ~isdeployed;
end