function compensation=create_motion_comp_subdata(layer,idx_freq,load_bar_comp)

trans_obj=layer.Transceivers(idx_freq);

% if ismember('motioncompensation',trans_obj.Data.Fieldname)&&force==0
%     return;
% end

time_pings_start=trans_obj.Time;
sample_vec = trans_obj.Data.get_samples();

block_len = get_block_len(50,'cpu',[]);
block_size = min(ceil(block_len/numel(sample_vec)),numel(time_pings_start));
num_ite = ceil(numel(time_pings_start)/block_size);

roll=layer.AttitudeNav.Roll;
pitch=layer.AttitudeNav.Pitch;
time_att=layer.AttitudeNav.Time;

time_ping_vec=(sample_vec-1)*trans_obj.get_params_value('SampleInterval',1);

[faBW,psBW] = trans_obj.get_beamwidth_at_f_c([]);
% block processing loop
idx_ping_tot = 1:numel(time_pings_start);

disp_str = 'Creating motion Correction data';

if ~isempty(load_bar_comp)
    load_bar_comp.progress_bar.setText(disp_str);
else
    disp(disp_str);
end

for ui = 1:num_ite
    
    % pings for this block
    idx_ping = idx_ping_tot((ui-1)*block_size+1:min(ui*block_size,numel(idx_ping_tot)));
    
    compensation=create_motion_comp(pitch,roll,time_att,time_pings_start(idx_ping),time_ping_vec,faBW,psBW);
    compensation(abs(compensation)>12)=12;
    
    trans_obj.Data.replace_sub_data_v2(compensation,'motioncompensation','idx_ping',idx_ping)
    if ~isempty(load_bar_comp)
        set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite,'Value',ui);
    end
end


end

