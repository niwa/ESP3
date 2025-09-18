function I = mat2ind(X, CLim, N)

if ~isa(X, 'double')
    X = single(X);
end
CLim = double(CLim);
N = double(N);

I = (X - CLim(1)) / diff(CLim);
%     sub = find(I < 0);
sub = (I < 0);
I(sub) = 0;
%     sub = find(I > 1);
sub = (I > 1);
I(sub) = 1;

I = uint8(I * N);
