function attitude_mat=create_attitude_matrix(Roll,Pitch,Yaw)%roll,pitch,yaw
% Yaw(isnan(Yaw))=0;
% Roll(isnan(Roll))=0;
% Pitch(isnan(Pitch))=0;
% 
% roll_mat=[[1  0            0          ];...
%            [0  cosd(Roll)  -sind(Roll)];...
%            [0 sind(Roll)  cosd(Roll)]];
% 
% pitch_mat= [[ cosd(Pitch)  0 sind(Pitch)];....
%            [ 0           1 0         ];....
%            [-sind(Pitch)  0 cosd(Pitch)]];
% 
% yaw_mat=[[ cosd(Yaw)  -sind(Yaw) 0];....
%          [sind(Yaw)  cosd(Yaw) 0];...
%          [ 0          0         1]];
% 
% attitude_mat=roll_mat*pitch_mat*yaw_mat;

%[gpu_comp,~]=get_gpu_comp_stat();
gpu_comp = false;
if gpu_comp
    Roll = gpuArray(Roll);
    Pitch = gpuArray(Pitch);
    Yaw = gpuArray(Yaw);
end


attitude_mat = [...
    [cosd(Pitch).*cosd(Yaw) -cosd(Pitch).*sind(Yaw) sind(Pitch)];...
    [cosd(Roll).*sind(Yaw)+cosd(Yaw).*sind(Pitch).*sind(Roll) cosd(Roll).*cosd(Yaw)-sind(Pitch).*sind(Roll).*sind(Yaw) -cosd(Pitch).*sind(Roll)];...
    [sind(Roll).*sind(Yaw)-cosd(Yaw).*sind(Pitch).*cosd(Roll) sind(Roll).*cosd(Yaw)+sind(Pitch).*cosd(Roll).*sind(Yaw) cosd(Pitch).*cosd(Roll)]...
    ];



if gpu_comp
    attitude_mat = gather(attitude_mat);
end



end