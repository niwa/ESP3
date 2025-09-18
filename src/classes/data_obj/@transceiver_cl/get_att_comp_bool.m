function [roll_comp_bool,pitch_comp_bool,yaw_comp_bool,heave_comp_bool] = get_att_comp_bool(trans_obj)

%MS70
%No pitch no yaw, no heave comp

%ME70
%No yaw, no heave comp
%trans_obj.Config.MotionCompBool = [false false false false];
tmp  = ~trans_obj.Config.MotionCompBool;
roll_comp_bool = tmp(1);
pitch_comp_bool = tmp(2);
yaw_comp_bool = tmp(3);
heave_comp_bool = tmp(4);
% yaw_comp_bool = false;
%heave_comp_bool = false;
% roll_comp_bool = true;
% pitch_comp_bool = true ;
