classdef sub_ac_data_cl < handle
    
    properties
        Memap
        Type='Power';
        Fmt='single';
        ConvFactor=1;
        Scale='lin';
        Fieldname='power'
        Units='dB';
        DefaultValue=-999;
    end
    
    methods
        
        %%
        function obj = sub_ac_data_cl(field,varargin)
            
            
            checkname=@(name) iscell(name)||ischar(name);
            checkdata=@(data) iscell(data)||isnumeric(data)||isa(data,'memmapfile');
            
            [fields_tot,scale_fields,fmt_fields,factor_fields,default_values]=init_fields();
            
            obj.Fieldname=lower(deblank(field));
            
            idx_field=strcmpi(fields_tot,obj.Fieldname);
            
            if ~any(idx_field)&&contains(lower(obj.Fieldname),'khz')
                idx_field=contains(fields_tot,'khz');
            end
            p = inputParser;
            
            addRequired(p,'field',@ischar);
            addParameter(p,'memapname','',checkname);
            addParameter(p,'data',[],checkdata);
            addParameter(p,'datasize',[1 1],@isnumeric);
            addParameter(p,'DefaultValue',default_values(idx_field),@isnumeric);
            addParameter(p,'Scale',scale_fields{idx_field},@ischar);
            addParameter(p,'Fmt',fmt_fields{idx_field},@ischar);
            addParameter(p,'ConvFactor',factor_fields(idx_field),@isnumeric);
            
            parse(p,field,varargin{:});
            
            memapname=p.Results.memapname;
            data=p.Results.data;
                        
            obj.Scale=p.Results.Scale;
            obj.Fmt=p.Results.Fmt;
            obj.ConvFactor=p.Results.ConvFactor;
            obj.DefaultValue=p.Results.DefaultValue;
            
            if ischar(memapname)
                memapname={memapname};
            end
            
            if ~iscell(data)
                data={data};
            end
            
 
            [~,obj.Type,obj.Units]=init_cax(field);
            
            
            obj.Memap={};
            
            for icell=1:length(data)
                switch class(data{icell})
                    case 'memmapfile'
                        obj.Memap{icell}=data{icell};
                    case 'char'
                        format={obj.Fmt,p.Results.datasize,obj.Fieldname};
                        obj.Memap{icell} = memmapfile(data{icell},...
                            'Format',format,'repeat',1,'writable',true);
                    otherwise
                        if ~isempty(data{icell})
                            curr_name=sprintf('%s_%s_%d.bin',memapname{icell},obj.Fieldname,icell);
                            
                            [folder,~,~] = fileparts(curr_name);
                            if ~isfolder(folder)
                                mkdir(folder);
                            end

                            fileID = fopen(curr_name,'w+');
                            
                            if fileID==-1
                                continue;
                            end
                            
                            if numel(data{icell})==2
                                nb_samples=data{icell}(1);
                                nb_pings=data{icell}(2);
                                nb_beams = 1;
                            elseif numel(data{icell})==3
                                nb_samples=data{icell}(1);
                                nb_pings=data{icell}(2);
                                nb_beams=data{icell}(3);
                            elseif size(data{icell},3) > 1
                                [nb_samples,nb_pings,nb_beams]=size(data{icell});
                            else
                                [nb_samples,nb_pings]=size(data{icell});
                                nb_beams = 1;
                            end
                            
                            if nb_beams ==1
                                format={obj.Fmt,[nb_samples,nb_pings],obj.Fieldname};
                            else
                                format={obj.Fmt,[nb_samples,nb_pings,nb_beams],obj.Fieldname};
                            end
                            
                            switch obj.Fmt
                                case {'int8' 'uint8'}
                                    nb=1;
                                case {'int16' 'uint16'}
                                    nb=2;
                                case {'int32' 'uint32'}
                                    nb=4;
                                case {'int64' 'uint64'}
                                    nb=8;
                                case {'single'}
                                    nb=4;
                                case {'double'}
                                    nb=8;
                            end
                            
                            init= false;
                            if numel(data{icell})==2||numel(data{icell})==3
                                fwrite(fileID, obj.DefaultValue/obj.ConvFactor,obj.Fmt,nb*(nb_beams*nb_samples*nb_pings-1));
                                init = true;
                            else
                                fwrite(fileID,double(data{icell})/obj.ConvFactor,obj.Fmt);
                            end
                            
                            fclose(fileID);
                            
                            obj.Memap{icell} = memmapfile(curr_name,'Format',format,'repeat',1,'writable',true);
                            if init
                                obj.Memap{icell}.Data.(obj.Fieldname)(:) = obj.DefaultValue/obj.ConvFactor;
                            end
                        else
                            obj.Memap{icell}=[];
                        end
                        
                end
            end
            
            
            
        end
        
        %%
        function obj_out=get_sub_data_file_id(obj,file_id)
            obj_out=sub_ac_data_cl(obj.Fieldname,'data',obj.Memap(file_id));
        end
        
        %%
        function delete(obj)
            
            if  isdebugging
                c = class(obj);
                disp(['ML object destructor called for class ',c])
            end
            % for icell=1:length(obj.Memap)
            %
            % if ~isdeployed
            %     disp(['Deleting file' ,obj.Memap{icell}.Filename]);
            % end
            %
            %    file=obj.Memap{icell}.Filename;
            %    obj.Memap{icell}=[];
            %    delete(file);
            % end
        end
        
    end
    
    %%
    methods (Static)
        [sub_ac_data_temp,curr_name]=sub_ac_data_from_struct(curr_data,dir_data,fieldnames);
        sub_ac_data_temp=sub_ac_data_from_files(dfiles,dsize,fieldnames);
    end
    
end
