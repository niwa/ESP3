function set_pulse_comp_Teff(trans_obj)

[~,y_tx_matched,~]=trans_obj.get_pulse();
if isempty(y_tx_matched)
    return;
end
y_tx_auto=xcorr(y_tx_matched,'normalized');
tmp=(sum(abs(y_tx_auto).^2,'omitnan')/(max(abs(y_tx_auto).^2))).*trans_obj.get_params_value('SampleInterval');
if~isempty(tmp)
    if size(tmp,3) > 1
        tmp = squeeze(tmp)';
    end
    tmp = tmp(:,trans_obj.Params.PingNumber);

    trans_obj.Params.TeffCompPulseLength=tmp;
end
end