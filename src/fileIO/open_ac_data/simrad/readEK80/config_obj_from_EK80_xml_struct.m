function config_obj=config_obj_from_EK80_xml_struct(xml_struct,t_line,config_ori)
try
    if isempty(config_ori)
        config_obj = config_cl();
    else
        config_obj = config_ori;
    end
    prop_config=properties(config_obj);
    props=fieldnames(xml_struct);
    for iii=1:length(props)
        switch props{iii}
            case 'PulseDuration'
                config_obj.PulseLength=xml_struct.(props{iii});       
            case 'BeamType'
                switch xml_struct.BeamType
                    case 0
                        config_obj.SounderType = 'single-beam';
                        config_obj.BeamType = 'single-beam';
                    case 'single-beam'
                        config_obj.SounderType = 'single-beam';
                        config_obj.BeamType = 'single-beam';
                    case {97;256}
                        config_obj.SounderType = 'adcp';
                        config_obj.BeamType = 'single-beam';
                    otherwise
                        config_obj.SounderType = 'split-beam';
                        config_obj.BeamType = 'split-beam';
                end
            otherwise
                if  any(strcmp(prop_config,props{iii}))
                    config_obj.(props{iii})=xml_struct.(props{iii});
                else
                    if ~isdeployed
                        fprintf('New parameter in Configuration XML: %s\n', props{iii});
                    end
                end
        end
    end
    
    if isnumeric(config_obj.SerialNumber)
        config_obj.SerialNumber=num2str(config_obj.SerialNumber);
    end
    
    if isnumeric(config_obj.TransducerSerialNumber)
        config_obj.TransducerSerialNumber=num2str(config_obj.TransducerSerialNumber);
    end
   
    config_obj.XML_string=t_line;
    
    %this part to deal with older version of the ek80 *.raw file format
    %that did not have the serial number as a field in the XML
    if isempty(config_obj.SerialNumber)
        if contains(config_obj.TransceiverName,'WBT Tube')
            out=textscan(config_obj.TransceiverName,'%s %s %s');
            str_tmp=out{3};
        elseif contains(config_obj.TransceiverName,'WBT')||contains(config_obj.TransceiverName,'GPT')
            out=textscan(config_obj.TransceiverName,'%s %s');
            str_tmp=out{2};
        end
        
        if iscell(str_tmp)
            str_tmp = str_tmp{1};
        end
        
        if ~isempty(str_tmp)
            config_obj.SerialNumber=str_tmp;
        end
    end
    if ~isempty(config_obj.TransducerSerialNumber)
        config_obj.ChannelID = sprintf('%s_%s',config_obj.ChannelID,config_obj.TransducerSerialNumber);
    end

catch err
    print_errors_and_warnings([],'warning',err);
    config_obj=config_cl.empty();
end

end