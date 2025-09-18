function output_struct = bad_pings_from_attitude(layer_obj,varargin)

p = inputParser;

addRequired(p,'layer_obj',@(x) isa(x,'layer_cl'));
addParameter(p,'idx_chan',1:numel(layer_obj.ChannelID),@isnumeric);
addParameter(p,'thr_motion_angular_speed',10,@(x) isnumeric(x)&&x>=0);
addParameter(p,'thr_angular_motion_diff',5,@(x) isnumeric(x)&&x>=0);
addParameter(p,'thr_sv_correction',12,@(x) isnumeric(x)&&x>=0);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'survey_options',[],@(x) isempty(x)||isa(x,'survey_options_cl'));
addParameter(p,'timeBounds',[0 inf],@isnumeric);
addParameter(p,'load_bar_comp',[]);

parse(p,layer_obj,varargin{:});

output_struct.done = false;


att_obj = layer_obj.AttitudeNav;
if isempty(att_obj)
    return;
end
idx_chan = p.Results.idx_chan;
if isempty(idx_chan)
    idx_chan = 1:numel(layer_obj.Frequencies);
end

if ~isempty(p.Results.reg_obj)
    for itr = idx_chan
        trans_obj = layer_obj.Transceivers(itr);
        idx=find_regions_Unique_ID(trans_obj,p.Results.reg_obj.Unique_ID);
        if ~isempty(idx)
            [reg_obj_temp,idx_freq_end,~,~]=layer_obj.generate_regions_for_other_freqs(itr,p.Results.reg_obj,idx_chan);
            reg_obj = [p.Results.reg_obj reg_obj_temp];
            [~,idx_sort] = sort([itr idx_freq_end]);
            reg_obj = reg_obj(idx_sort);
            if ~isempty(idx_freq_end)
                reg_obj(idx_freq_end) = reg_obj_temp;
            end
            break;
        end

    end
end

for itr = idx_chan

    trans_obj = layer_obj.Transceivers(itr);
    
    if trans_obj.ismb()
        disp('This algorithm has not been ported to MBES/Imaging sonar data (yet)... Sorry about that!');
        continue;
    end
    
    if isempty(p.Results.reg_obj) || isempty(reg_obj(itr))
        %idx_r = 1:length(trans_obj.get_samples_range());
        idx_ping = 1:length(trans_obj.get_transceiver_pings());
    else
        idx_ping = reg_obj(itr).Idx_ping;
        % = reg_obj{itr}.Idx_r;
    end


    start_ping_time = trans_obj.Time(idx_ping);
    sample_vec = trans_obj.Data.get_samples();
    time_ping_vec=(sample_vec-1)*trans_obj.get_params_value('SampleInterval',1);
    bot_sample = trans_obj.get_bottom_idx(idx_ping);
    bot_sample(isnan(bot_sample)) = numel(sample_vec);
    end_ping_time = start_ping_time+1/(24*60*60)*time_ping_vec(bot_sample)';
    dt = (end_ping_time-start_ping_time)*24*60*60;

    roll_start = resample_data_v2(att_obj.Roll,att_obj.Time,start_ping_time,'Type','Angle');
    roll_end = resample_data_v2(att_obj.Roll,att_obj.Time,end_ping_time,'Type','Angle');

    pitch_start = resample_data_v2(att_obj.Pitch,att_obj.Time,start_ping_time);
    pitch_end= resample_data_v2(att_obj.Pitch,att_obj.Time,end_ping_time,'Type','Angle');

    delta_roll = roll_end-roll_start;
    delta_pitch = pitch_end-pitch_start;

    roll_speed = delta_roll./dt;
    pitch_speed = delta_pitch./dt;

    [faBW,psBW] = trans_obj.get_beamwidth_at_f_c([]);

    compensation = attCompensation(faBW, psBW, roll_start, pitch_start,roll_end,pitch_end);

    disp_analysis = false;

    if disp_analysis && ~isdeployed()

        hfig=new_echo_figure([],'UiFigureBool',true,'Name','Pitch/Roll analysis','Tag','pitch_roll_bad_ping');
        uigl_ax = uigridlayout(hfig,[3,1]);

        ax_pitch_roll=uiaxes(uigl_ax,'Box','on','Nextplot','add');
        grid(ax_pitch_roll,'on');
        ylabel(ax_pitch_roll,'Attitude (deg)')
        ax_pitch_roll.XTickLabels={''};
        hp = plot(ax_pitch_roll,pitch_end-mean(pitch_start),'r');
        %plot(ax_pitch_roll,pitch_end,'--r');
        hr = plot(ax_pitch_roll,roll_end-mean(roll_start),'k');
        %plot(ax_pitch_roll,roll_end,'--k');
        legend([hp hr],{'Pitch','Roll'});

        ax_pitch_roll_speed=uiaxes(uigl_ax,'Box','on','Nextplot','add');
        grid(ax_pitch_roll_speed,'on');
        ylabel(ax_pitch_roll_speed,'Angular speed (deg/s)');
        hpp = plot(ax_pitch_roll_speed,pitch_speed,'r');
        hrr = plot(ax_pitch_roll_speed,roll_speed,'k');
        yline(ax_pitch_roll_speed,[-p.Results.thr_motion_angular_speed p.Results.thr_motion_angular_speed],'--b');
        legend([hpp hrr],{'Pitch angular speed','Roll angular speed'});

        ax_compensation=uiaxes(uigl_ax,'Box','on','Nextplot','add');
        grid(ax_compensation,'on');
        ylabel(ax_compensation,'Motion compensation (dB)');
        plot(ax_compensation,compensation,'r');
        yline(ax_compensation,[-p.Results.thr_sv_correction p.Results.thr_sv_correction],'--b');
        drawnow;
        linkaxes([ax_compensation ax_pitch_roll ax_pitch_roll_speed],'x');
        xlim(ax_compensation,[1 numel(roll_speed)]);
    end

    idx_noise_sector=find(abs(compensation)>p.Results.thr_sv_correction |...
        abs(roll_speed)>p.Results.thr_motion_angular_speed | ...
        abs(pitch_speed)>p.Results.thr_motion_angular_speed |...
        abs(pitch_end-mean(pitch_start))>p.Results.thr_angular_motion_diff | ...
        abs(roll_end-mean(roll_start))>p.Results.thr_angular_motion_diff);

    output_struct.idx_noise_sector{itr}=idx_noise_sector;

    tag = trans_obj.Bottom.Tag(idx_ping);

    tag(output_struct.idx_noise_sector{itr}) = 0;

    trans_obj.Bottom.Tag(idx_ping) = tag;
end

output_struct.done = true;