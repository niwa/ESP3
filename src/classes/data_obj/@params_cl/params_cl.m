
classdef params_cl
    properties
        PingNumber uint32
        BeamNumber uint16
        BeamAngleAlongship single
        BeamAngleAthwartship single
        BandWidth double
        ChannelMode int8
        Frequency double
        FrequencyEnd double
        FrequencyStart double
        PulseForm int8
        PulseLength double
        TeffPulseLength double
        TeffCompPulseLength double
        SampleInterval double
        Slope double        
        TransmitPower double
    end

    methods(Static)
        function ff  = get_params_cal_fields()
            ff = {...
                'FrequencyEnd'...
                'FrequencyStart'...
                'PulseLength'...
                'Slope' ...
                'TransmitPower'};
            
            ff = intersect(ff,properties(params_cl));
        end
    end
    
    methods
        function obj=params_cl(varargin)
            p = inputParser;
            
            addOptional(p,'nb_pings',1,@(x) x>0);
            addOptional(p,'nb_beams',1,@(x) x>0);
            parse(p,varargin{:});
            
            props=properties(obj);
            
            for jj=1:length(props)         
                obj.(props{jj})=zeros(p.Results.nb_beams,p.Results.nb_pings);
            end
            
            obj.PingNumber=1:p.Results.nb_pings;
            obj.BeamNumber=1:p.Results.nb_beams;
        end
        
        function obj_red=reduce_params(obj)
            if isempty(obj.PingNumber)||numel(obj.BeamNumber)>1
                obj_red=obj;
                return;
            end
            
            obj_red=params_cl();
            
            [params_groups,...
                obj_red.BandWidth,...
                obj_red.ChannelMode,...
                obj_red.BeamAngleAlongship,...
                obj_red.BeamAngleAthwartship,...
                obj_red.Frequency,...
                obj_red.FrequencyEnd,...
                obj_red.FrequencyStart,...
                obj_red.PulseForm,...
                obj_red.PulseLength,...
                obj_red.TeffPulseLength,...
                obj_red.TeffCompPulseLength,...
                obj_red.SampleInterval,...
                obj_red.Slope,...
                obj_red.TransmitPower...
                ]=findgroups(...
                obj.BandWidth,...
                obj.ChannelMode,...
                obj.BeamAngleAlongship,...
                obj.BeamAngleAthwartship,...
                obj.Frequency,...
                obj.FrequencyEnd,...
                obj.FrequencyStart,...
                obj.PulseForm,...
                obj.PulseLength,...
                obj.TeffPulseLength,...
                obj.TeffCompPulseLength,...
                obj.SampleInterval,...
                obj.Slope,...
                obj.TransmitPower);
            
            obj_red.PingNumber = splitapply(@min,obj.PingNumber,params_groups);
            obj_red.BeamNumber = 1;
            
            u_params = unique(params_groups);
            
             props=properties(obj);
           
            for ui_conf = 1:numel(u_params)
                
                uip = find(params_groups == u_params(ui_conf),1);

                for iprop=1:length(props)
                    if ~strcmp(props{iprop},'BeamNumber')
                        obj_red.(props{iprop})(ui_conf)= obj.(props{iprop})(uip);
                    end
                end

            end
            
        end

        function [params_obj_out,idx_group] = group_params(params_obj,group_direction,ftype)

            switch group_direction
                case 'along'
                    beamAngleGroup = [params_obj(:).BeamAngleAlongship];
                    beamAngleSort = [params_obj(:).BeamAngleAthwartship];
                case 'across'
                    beamAngleGroup = round(2*[params_obj(:).BeamAngleAthwartship]);                   
                    beamAngleSort = [params_obj(:).BeamAngleAlongship];
            end

            switch ftype 
                case 'ME70'
                    beamAngleGroup = zeros(size(beamAngleGroup));
            end

             dt  = [params_obj(:).SampleInterval];
             [p_groups,~,~] = findgroups(...
                 dt,...
                 beamAngleGroup);
            u_p_groups = unique(p_groups);

            params_obj_out  =[];
            props=properties(params_cl);
            idx_group = cell(1,numel(u_p_groups));

            for ui = 1:numel(u_p_groups)
                idx_params = find(p_groups == u_p_groups(ui));
                
                p_temp = params_cl(params_obj(idx_params(1)).PingNumber,numel(idx_params));
                beamAngleSort_tmp = beamAngleSort(idx_params);
                [~,idx_order] = sort(beamAngleSort_tmp);
                idx_group{ui} = idx_params(idx_order);
                for uip = 1:numel(props)
                    if ~ismember(props{uip},{'BeamNumber','PingNumber'})
                        tmp = [params_obj(idx_params).(props{uip})]';
                        p_temp.(props{uip})= tmp(idx_order);
                    end
                end
                params_obj_out = [params_obj_out p_temp];
            end
        end
        
        
        
        function params_out=concatenate_Params(param_start,param_end,nb_p)
                    
            props=properties(param_start);

            params_out=params_cl(numel(param_start.PingNumber)+numel(param_end.PingNumber),numel(param_start.BeamNumber));
                        
            for jj=1:length(props)
                if ~strcmp(props{jj},'BeamNumber')
                    params_out.(props{jj})=[param_start.(props{jj}) param_end.(props{jj})];
                end
            end
            
            params_out.PingNumber = [param_start.PingNumber param_end.PingNumber+nb_p];
            
        end
        

        function param_str=param2str(param_obj,ib,idx_ping)
            
            fields={'BandWidth',...
                'ChannelMode',...
                'Frequency',...
                'FrequencyStart',...
                'FrequencyEnd',...
                'PulseForm',...
                'PulseLength',...
                'TeffPulseLength',...
                'TeffCompPulseLength',...
                'SampleInterval',...
                'TransmitPower',...
                'BeamAngleAlongship',...
                'BeamAngleAthwartship'};
            
               fact=[1/1e3; ...%'BandWidth',...
                0; ...%'ChannelMode',...
                1/1e3; ...%'Frequency',...
                1/1e3; ...%'FrequencyStart',...
                1/1e3; ...%'FrequencyEnd',...
                 1; %'PulseForm',...
                1e3; ... %'PulseLength',...
                 1e3; ... %'TeffPulseLength',...
                  1e3; ... %'TeffCompPulseLength',...
                1e3; ... %'SampleInterval',...
                1; ...%'TransmitPower'
                1;...
                1;...
                ];
            
            
            fields_name={'BandWidth',...
                'ChannelMode',...
                'Center Frequency',...
                'FrequencyStart',...
                'FrequencyEnd',...
                'PulseForm',...
                'PulseLength',...
                'PulseLength Eff',...
                'PulseLength Comp Eff',...
                'SampleInterval',...
                'TransmitPower',...
                'Beam pointing angle (Alongship)',...
                'Beam pointing angle (Athwartship)'};
            
            fields_fmt={'%.2f kHz',...
                '%d',...
                '%.2fkHz',...
                '%.2fkHz',...
                '%.2fkHz',...
                '%d',...
                '%.3fms',...
                 '%.3fms',...
                 '%.3fms',...
                '%.3fms',...
                '%.0fW',...
                '%.1f&deg',...
                '%.1f&deg'};
                        
            param_str =sprintf('<html><ul>Parameters for ping %d:',idx_ping);
            
            id=find(idx_ping-param_obj.PingNumber>0,1,'last');

            if isempty(ib)
                ib = 1:size(param_obj.(fields{1}),1);
            end

            for ifi=1:length(fields)
                
                if size(param_obj.(fields{ifi}),2)<=id
                    id=1;
                end
                
  
                if isnan(param_obj.(fields{ifi})(ib,id))
                    continue;
                end

                val = fact(ifi)*param_obj.(fields{ifi})(ib,id);
                
                if numel(val)>1
                    str_temp = sprintf(['From ' fields_fmt{ifi} ' to ' fields_fmt{ifi}],min(val,[],'all'),max(val,[],'all'));
                else
                    str_temp=sprintf(fields_fmt{ifi},fact(ifi)*param_obj.(fields{ifi})(ib,id));
                end
                
                param_str = [param_str '<li><i>' fields_name{ifi} ': </i>' str_temp '</li>'];
            end
            param_str = [param_str '</ul></html>'];
        end
        
        function cal_params  = get_cal_params_fields(obj)
            params_fields =obj.get_params_cal_fields();

            for ui = 1:numel(params_fields)
                cal_params.(params_fields{ui}) = obj.(params_fields{ui});
            end
        end

        function params_section=get_params_idx_section(params_obj,idx)          
            params_section=params_cl();
            
            props=properties(params_obj);
            id_sec=ismember(params_obj.PingNumber,idx);
            
            if any(id_sec)
                id_num=find(id_sec);
            else
                id_num=1;
            end
            
            for iprop=1:length(props)
                if ~strcmpi(props{iprop},'PingNumber')&&~strcmp(props{iprop},'BeamNumber')
                    params_section.(props{iprop})= params_obj.(props{iprop})(:,id_num);
                end
            end
            
            params_section.PingNumber=id_num-id_num(1)+1;
            params_section.BeamNumber = params_obj.BeamNumber;
   
        end
        
          
        function delete(obj)
            if  isdebugging
                c = class(obj);
                disp(['ML object destructor called for class ',c])
            end
        end
    end
    
end




