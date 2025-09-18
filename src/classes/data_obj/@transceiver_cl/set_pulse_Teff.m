function set_pulse_Teff(trans_obj)

[~,y_tx_matched,~]=trans_obj.get_pulse();
Np=round(sum(abs(y_tx_matched).^2,'omitnan')/...
    (max(abs(y_tx_matched).^2,[],'omitnan')));

if ~isempty(Np)
    tmp=Np*trans_obj.get_params_value('SampleInterval');

    if ~isempty(tmp)
        if size(tmp,3) > 1
            tmp = squeeze(tmp)';
        end
        tmp = tmp(:,trans_obj.Params.PingNumber);

        trans_obj.Params.TeffPulseLength=tmp;
    end
end
end