
function [temp,depth,pressure,date]=read_rbr(file)

tt = readtable(file);

tt = table2struct(tt,'ToScalar',true);
ff = fieldnames(tt);
if all(ismember({'Time' 'Temperature' 'Pressure' 'Depth'},ff))
    temp = tt.Temperature;
    depth = tt.Depth;
    pressure  =tt.Pressure;
    date = datenum(tt.Time);
    return;
end

fid=fopen(file);
line='';

while ~contains(line,'Depth')
    line=fgetl(fid);
end

il=0;
line=fgetl(fid);
date=[];
temp=[];
pressure=[];
depth=[];

while line~=-1

    data = textscan(line, '%4d/%2d/%2d %2d:%2d:%2d %f %f %f ');
    if length(data)==9
        il=il+1;
        date(il)=datenum(double(data{1}),double(data{2}),double(data{3}),double(data{4}),double(data{5}),double(data{6}));
        temp(il)=data{7};
        pressure(il)=data{8};
        depth(il)=data{9};
    end
   line=fgetl(fid);
end

fclose(fid);