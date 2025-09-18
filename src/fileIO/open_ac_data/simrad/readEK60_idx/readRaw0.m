function [data,power,angle]=readRaw0(data,idx_data,i_ping,fid)

data.pings(idx_data).number(i_ping) = i_ping;

temp=fread(fid,8,'float32');
data.pings(idx_data).transducerdepth(i_ping) = temp(1);
data.pings(idx_data).frequency(i_ping) = temp(2);
data.pings(idx_data).transmitpower(i_ping) = temp(3);
data.pings(idx_data).pulselength(i_ping) = temp(4);
data.pings(idx_data).bandwidth(i_ping) = temp(5);
data.pings(idx_data).sampleinterval(i_ping) = temp(6);
data.pings(idx_data).soundvelocity(i_ping) = temp(7);
data.pings(idx_data).absorptioncoefficient(i_ping) = temp(8);

temp=fread(fid,7,'float32');

data.pings(idx_data).heave(i_ping) = temp(1);
data.pings(idx_data).roll_tx(i_ping) = temp(2);
data.pings(idx_data).pitch_tx(i_ping) = temp(3);
data.pings(idx_data).temperature(i_ping) = temp(4);
data.pings(idx_data).spare(i_ping) = temp(5);
data.pings(idx_data).roll_rx(i_ping) = temp(6);
data.pings(idx_data).pitch_rx(i_ping) = temp(7);

temp=fread(fid,2,'int32');

power=[];
angle=[];

data.pings(idx_data).offset(i_ping) = temp(1);
data.pings(idx_data).count(i_ping) = temp(2);

if data.pings(idx_data).count(i_ping) > 0
    
    if data.pings(idx_data).datatype(1)==dec2bin(1)
        power=fread(fid,data.pings(idx_data).count(i_ping),'int16');
        data.pings(idx_data).count(i_ping)=numel(power);
    end
    
    if data.pings(idx_data).datatype(2)==dec2bin(1)
        angle=fread(fid,[2 data.pings(idx_data).count(i_ping)],'int8');
    end
    data.pings(idx_data).samplerange=[1 data.pings(idx_data).count(i_ping)];
end

end