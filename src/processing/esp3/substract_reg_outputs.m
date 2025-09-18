function  output_diff  = substract_reg_outputs( output_reg_1,output_reg_2)

output_diff=output_reg_1;

if ~all(size(output_reg_1.sv)==size(output_reg_2.sv))
   warning('There might be an issue in frequency differences computation...')
end

[N_x,N_y]=size(output_reg_1.sv);
[N_x_2,N_y_2]=size(output_reg_2.sv);


output_diff.sv=zeros(N_x,N_y);
output_diff.eint=zeros(N_x,N_y);
idx_nan=false(N_x,N_y);

idx_nan(1:min(N_x,N_x_2),1:min(N_y,N_y_2))=output_reg_1.sv(1:min(N_x,N_x_2),1:min(N_y,N_y_2))<=db2pow(-900)|output_reg_2.sv(1:min(N_x,N_x_2),1:min(N_y,N_y_2))<=db2pow(-900);

output_diff.sv(1:min(N_x,N_x_2),1:min(N_y,N_y_2))=db2pow(pow2db_perso(output_reg_1.sv(1:min(N_x,N_x_2),1:min(N_y,N_y_2)))-pow2db_perso(output_reg_2.sv(1:min(N_x,N_x_2),1:min(N_y,N_y_2))));
output_diff.eint(1:min(N_x,N_x_2),1:min(N_y,N_y_2))=db2pow(pow2db_perso(output_reg_1.eint(1:min(N_x,N_x_2),1:min(N_y,N_y_2)))-pow2db_perso(output_reg_2.eint(1:min(N_x,N_x_2),1:min(N_y,N_y_2))));

% output_diff.sv(idx_nan)=0;
% output_diff.eint(idx_nan)=0;


output_diff.ABC=zeros(N_y,N_x);
output_diff.NASC=zeros(N_y,N_x);


end

