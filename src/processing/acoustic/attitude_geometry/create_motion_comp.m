function compensation=create_motion_comp(pitch,roll,time_att,time_pings_start,time_ping_vec,faBW, psBW)
p = inputParser;

addRequired(p,'pitch',@isnumeric);
addRequired(p,'roll',@isnumeric);
addRequired(p,'time_att',@isnumeric);
addRequired(p,'time_pings_start',@isnumeric);
addRequired(p,'time_ping_vec',@isnumeric);
addRequired(p,'faBW',@isnumeric);
addRequired(p,'psBW',@isnumeric);

parse(p,pitch,roll,time_att,time_pings_start,time_ping_vec,faBW, psBW);

[time_att,id_u] = unique(time_att);
roll = roll(id_u);
pitch = pitch(id_u);

nb_samples=length(time_ping_vec);
nb_pings=length(time_pings_start);

if ~isempty(time_att)
    pitch_pings=resample_data_v2(pitch,time_att,time_pings_start,'Type','Angle');
    roll_pings=resample_data_v2(roll,time_att,time_pings_start,'Type','Angle');
    
    pitch_t=repmat(pitch_pings(:)',nb_samples,1);
    roll_t=repmat(roll_pings(:)',nb_samples,1);
    
    time_mat=repmat(double(time_ping_vec(:)),1,nb_pings)+repmat((60*60*24)*time_pings_start(:)',nb_samples,1);
    
    
    roll_r=spline (86400*time_att,roll,time_mat);
    pitch_r=spline(86400*time_att,pitch,time_mat);
    

    compensation = attCompensation(faBW, psBW, roll_t, pitch_t,roll_r,pitch_r);   
    
    
else
    compensation=zeros(nb_samples,nb_pings);   
end

end