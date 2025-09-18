function [soundspeed,range_t] = compute_soundspeed_and_range(trans_obj,env_data_obj,ori,options)
arguments
    trans_obj transceiver_cl
    env_data_obj env_data_cl
    ori char=''
    options.idx_ping_ref (1,1) double = 1
end

t0 = trans_obj.Sample_offset*trans_obj.Params.SampleInterval(1);
d0 = trans_obj.get_transducer_depth(options.idx_ping_ref);

try   
    if isempty(ori)||strcmp(ori,'')
        ori=env_data_obj.SVP.ori;
    end
    
    if (isempty(env_data_obj.SVP.depth)&&strcmpi(ori,'profile'))||trans_obj.ismb
        ori='constant';
    end
    
    switch lower(ori)
        case 'constant'
            soundspeed = env_data_obj.SoundSpeed;
            range_t= get_linear_range(trans_obj,soundspeed);
        case {'theoritical' 'profile'}
            
            t_angle=trans_obj.get_transducer_pointing_angle()+deg2rad(trans_obj.get_params_value('BeamAngleAthwartship',options.idx_ping_ref));
            time_r = t0 +(trans_obj.Data.get_samples()-1) * trans_obj.get_params_value('SampleInterval',1,1);
            d_max=1600*time_r(end)/2+max(trans_obj.get_transducer_depth(options.idx_ping_ref));
            
            switch lower(ori)
                case 'theoritical'
                    dr=(1500*mode(diff(time_r)/2));
                    d_ref=(d0:dr:d_max)';
                    c_ref=seawater_svel_un95(env_data_obj.Salinity,env_data_obj.Temperature,d_ref);
                case 'profile'
                    d_ref=env_data_obj.SVP.depth(:);
                    c_ref=env_data_obj.SVP.soundspeed(:);
            end
               
            dr=(1400*mode(diff(time_r)/2));
            
            d_th=(d0:dr:d_max)';
            
            c_init=resample_data_v2(c_ref,d_ref,d_th);
            
            if any(isnan(c_init))
                print_errors_and_warnings([],'warning',sprintf('SoundSpeed profile provided does not cover the full depth range of the data here... \nCompleting with standard profile based on provided average temperature and Salinity.'))
                default_ss=seawater_svel_un95(env_data_obj.Salinity,env_data_obj.Temperature,d_th);
                c_init(isnan(c_init))=default_ss(isnan(c_init));
                
                if 0
                    h_fig=new_echo_figure([],'tag','soundspeed');
                    ax1=axes(h_fig,'nextplot','add','outerposition',[0 0 1 1],'box','on','nextplot','add');
                    plot(ax1,c_init,d_th,'r');
                    plot(ax1,c_ref,d_ref,'g');
                    plot(ax1,default_ss,d_th,'b');
                    axis(ax1,'ij');
                    ylabel(ax1,'Depth (m)');
                    ylim(ax1,[0 max(d_th)]);
                    xlabel(ax1,'SoundSpeed (m/s)');
                end
            end
            
            [r_ray,t_ray,z_ray,~]=compute_acoustic_ray_path(d_th,c_init,0,0,d0,t_angle,3*time_r(end)/4);
            d_trans_new=sqrt(r_ray.^2+z_ray.^2);
            
            range_t_new=(d_trans_new-d0)/sin(t_angle);
            [~,id_start]=find(range_t_new>=0,1,'first');
            range_t_new=range_t_new(id_start:end);
            t_ray=t_ray(id_start:end);
            t_ray=t_ray-t_ray(1);
            range_t=resample_data_v2(range_t_new,t_ray*2,time_r);
            soundspeed=resample_data_v2(c_init,d_th,range_t*sin(t_angle)+trans_obj.get_transducer_depth(options.idx_ping_ref));
            soundspeed=soundspeed(:);
        otherwise
            soundspeed = env_data_obj.SoundSpeed;
            range_t= get_linear_range(trans_obj,soundspeed);
    end    
catch err
    print_errors_and_warnings([],'error',err);
    soundspeed = env_data_obj.SoundSpeed;
    range_t= get_linear_range(trans_obj,soundspeed);
end

end


function range_t = get_linear_range(trans_obj,c)

t = trans_obj.Params.SampleInterval(1);

dR=double(c .* t / 2);

samples=trans_obj.get_transceiver_samples();

range_t=double(trans_obj.Sample_offset+samples-1)*dR;

end

