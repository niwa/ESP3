function data_cell=divide_mat(data,nb_samples,nb_pings)

data_cell=cell(1,length(nb_samples));

for i=1:length(nb_pings)
    if i==1
        ping_start=1;
        ping_end=min(nb_pings(i),size(data,2));
    else
        ping_start=min(sum(nb_pings(1:i-1))+1,size(data,2));
        ping_end=min(sum(nb_pings(1:i)),size(data,2));
    end

data_cell{i}=data(1:nb_samples(i),ping_start:ping_end);
end
    

end