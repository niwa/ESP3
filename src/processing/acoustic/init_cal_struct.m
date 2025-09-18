function cal_struct=init_cal_struct(obj)
cal_struct=[];

switch class(obj)
    case 'layer_cl'
        cal_init=obj.get_cw_cal();
        nb_trans=numel(cal_init.G0);
    case 'struct'

        fcal=fieldnames(obj);
        for ui=1:numel(fcal)
            if ischar(obj(1).(fcal{ui}))
                cal_init.(fcal{ui})={obj(:).(fcal{ui})};
            else
                cal_init.(fcal{ui})=[obj(:).(fcal{ui})];
            end
        end

        nb_trans=numel(cal_init.G0);

    case 'char'
        [~,~,ext] = fileparts(obj);

        switch ext
            case '.csv'
                if isfile(obj)

                    cal_csv=readtable(obj);
                    cal_init=table2struct(cal_csv,'ToScalar',true);

                    if isfield(cal_init,'G0')
                        nb_trans=numel(cal_init.G0);
                    else
                        cal_struct=[];
                        return;
                    end

                    if  isfield(cal_init,'alpha')
                        cal_init.alpha=cal_init.alpha;
                    end
                else
                    return;
                end

            case '.db'
                    
               cal_init = get_cal_table_from_cal_db(obj);     
                if isempty(obj)
                    return;
                end 
                cal_init = table2struct(cal_init,'ToScalar',true);
                nb_trans=numel(cal_init.G0);
        end

    otherwise
        nb_trans=obj;
        cal_init=[];
end

if isempty(nb_trans)||~isnumeric(nb_trans)
    nb_trans = 1;
end

if isfield(cal_init,'F')
    cal_init.FREQ=cal_init.F;
    cal_init=rmfield(cal_init,'F');
end

cal_struct=struct('G0',nan(1,nb_trans),...
    'SACORRECT',nan(1,nb_trans),...
    'EQA',nan(1,nb_trans),...
    'FREQ',nan(1,nb_trans),...
    'alpha',nan(1,nb_trans),...
    'pulse_length',nan(1,nb_trans));

cal_struct.CID=cell(1,nb_trans);
cal_struct.CID(:)={''};

config_fields = config_cl.get_config_cal_fields();

for ui = 1:numel(config_fields)
    cal_struct.(config_fields{ui}) = nan(1,nb_trans);
end

if isstruct(cal_init)
    f_cal=fieldnames(cal_init);
    for ifi=1:numel(f_cal)
        cal_struct.(f_cal{ifi})=(cal_init.(f_cal{ifi}));
    end
end

cal_struct.CID=deblank(cal_struct.CID);

if isempty(cal_struct.CID)
    cal_struct.CID={''};
end

if isrow(cal_struct.G0)
    cal_struct = structfun(@transpose,cal_struct,'Un',0);
end

end