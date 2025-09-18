
function [AlongAngle,AcrossAngle]=computesPhasesAngles_v3(data_pings,angleSensitivityAlongship,angleSensitivityAthwartship,isek60,TransducerName,AngleOffsetAlongship,AngleOffsetAthwartship)

if isek60
    k_angle=180/128;
else
    k_angle=1;
    nb_chan=sum(contains(fieldnames(data_pings),'comp_sig'));
    if nb_chan>1
        switch TransducerName
            case {'ES38-7' 'ES333' 'ES38-10' }
                switch TransducerName
                    case 'ES38-7'

                        sa=data_pings.comp_sig_1;
                        pa=data_pings.comp_sig_2;
                        fo=data_pings.comp_sig_3;
                        ce=data_pings.comp_sig_4;

                        sec1=sa+ce;
                        sec2=pa+ce;
                        sec3=fo+ce;

                    case {'ES333' 'ES38-10'}
                        sec1=data_pings.comp_sig_1;
                        sec2=data_pings.comp_sig_2;
                        sec3=data_pings.comp_sig_3;
                end

                phi31=angle(sec3.*conj(sec1))/pi*180;
                phi32=angle(sec3.*conj(sec2))/pi*180;

                data_pings.AlongPhi=1/sqrt(3)*(phi31+phi32);
                data_pings.AcrossPhi=(phi32-phi31);

            case 'ES38-18|200-18C'
                if nb_chan==3
                    sec1=data_pings.comp_sig_1;
                    sec2=data_pings.comp_sig_2;
                    sec3=data_pings.comp_sig_3;

                    phi31=angle(sec3.*conj(sec1))/pi*180;
                    phi32=angle(sec3.*conj(sec2))/pi*180;
                    data_pings.AlongPhi=1/sqrt(3)*(phi31+phi32);
                    data_pings.AcrossPhi=(phi32-phi31);

                else
                    data_pings.AlongPhi=zeros(size(data_pings.comp_sig_1));
                    data_pings.AcrossPhi=zeros(size(data_pings.comp_sig_1));
                end
            case {'ME70' 'MS70'}
                switch nb_chan
                    case 4
                        s1=data_pings.comp_sig_1;
                        s2=data_pings.comp_sig_2;
                        s3=data_pings.comp_sig_3;
                        s4=data_pings.comp_sig_4;

                        fore =(s3+s4)/2;
                        aft  =(s2+s1)/2;
                        stbd =(s1+s4)/2;
                        port =(s3+s2)/2;

                        data_pings.AlongPhi=angle(fore.*conj(aft))/pi*180;
                        data_pings.AcrossPhi=angle(stbd.*conj(port))/pi*180;

                    case 5

                        fore = data_pings.comp_sig_2;
                        aft  = data_pings.comp_sig_3;
                        stbd = data_pings.comp_sig_4;
                        port = data_pings.comp_sig_5;

                        data_pings.AlongPhi=angle(fore.*conj(aft))/pi*180;
                        data_pings.AcrossPhi=angle(stbd.*conj(port))/pi*180;
                    otherwise
                        data_pings.AlongPhi=zeros(size(data_pings.comp_sig_1));
                        data_pings.AcrossPhi=zeros(size(data_pings.comp_sig_1));

                end

            otherwise
                switch nb_chan
                    case 4
                        s1=data_pings.comp_sig_1;
                        s2=data_pings.comp_sig_2;
                        s3=data_pings.comp_sig_3;
                        s4=data_pings.comp_sig_4;

                        fore=(s3+s4)/2;
                        aft =(s2+s1)/2;
                        stbd =(s1+s4)/2;
                        port =(s3+s2)/2;


                        data_pings.AlongPhi=angle(fore.*conj(aft))/pi*180;
                        data_pings.AcrossPhi=angle(stbd.*conj(port))/pi*180;

                    case 3
                        sec1=data_pings.comp_sig_1;
                        sec2=data_pings.comp_sig_2;
                        sec3=data_pings.comp_sig_3;

                        phi31=angle(sec3.*conj(sec1))/pi*180;
                        phi32=angle(sec3.*conj(sec2))/pi*180;

                        data_pings.AlongPhi=1/sqrt(3)*(phi31+phi32);
                        data_pings.AcrossPhi=(phi32-phi31);
                    otherwise
                        data_pings.AlongPhi=zeros(size(data_pings.comp_sig_1));
                        data_pings.AcrossPhi=zeros(size(data_pings.comp_sig_1));
                end
        end


    else
        data_pings.AlongPhi=0;
        data_pings.AcrossPhi=0;
    end
end


AlongAngle=asind((data_pings.AlongPhi/180*pi)*k_angle/angleSensitivityAlongship)-AngleOffsetAlongship;
AcrossAngle=asind((data_pings.AcrossPhi/180*pi)*k_angle/angleSensitivityAthwartship)-AngleOffsetAthwartship;

end
