function datainsert_perso(ac_db_filename,tablename,data,varargin)

%% input parser
p = inputParser;

addRequired(p,'ac_db_filename',@(x) ischar(x)||isa(x,'database.jdbc.connection')||isa(x,'sqlite'));
addRequired(p,'tablename',@ischar);
addRequired(p,'data',@(x) isstruct(x)||istable(x));

addParameter(p,'idx_insert',[],@isnumeric);
addParameter(p,'unique_conflict_handling','',@ischar);

parse(p,ac_db_filename,tablename,data,varargin{:});

%% connect to database
if ischar(ac_db_filename)
    dbconn = connect_to_db(ac_db_filename);
else
    dbconn = ac_db_filename;
end


%% formatting data
if istable(data)
    data = table2struct(data,'ToScalar',true);
end

col_names = fieldnames(data);
col_num   = numel(col_names);
row_num   = nan(1,col_num);
data_type = cell(1,col_num);

%% checking that data to insert has appropriate number of entries
for ifi = 1:col_num
    row_num(ifi) = size(data.(col_names{ifi}),1);
    data_type{ifi} = class(data.(col_names{ifi}));
end
row_num = unique(row_num);

if numel(row_num)>1
    error('datainsert_perso:Could not insert data, not the same number of entries in every columns');
end

%% writing the INSERT SQL statement

% start of statement, with table and column names
sql_query_start = sprintf('INSERT INTO %s (%s) VALUES ',tablename,strjoin(col_names,','));


%% formatting values to insert

% idx_insert is the row(s) we actually want to save in database
if ~isempty(p.Results.idx_insert)
    id_row_tot = p.Results.idx_insert;
else
    id_row_tot = 1:row_num;
end

block_size = 1e4;

num_ite = ceil(numel(id_row_tot)/block_size);

for uit = 1:num_ite
    id_row = id_row_tot((uit-1)*block_size+1:min(uit*block_size,numel(id_row_tot)));

    % initialize insert values
    input_vals = cell(1,numel(id_row));

    % complete insert values
    for ir = id_row(:)'
        tmp = cell(1,col_num);
        for j = 1:col_num
            switch data_type{j}
                case 'cell'
                    tmp{j} = data.(col_names{j}){ir};
                case 'char'
                    tmp{j} = data.(col_names{j})(ir,:);
                otherwise
                    tmp{j} = data.(col_names{j})(ir);
            end
        end
        tmp = cellfun(@fmt_input,tmp,'un',0);
        input_vals{ir} = strjoin(tmp,',');
    end

    % removing remaining empties
    input_vals(cellfun(@isempty,input_vals)) = [];

    %% complete the SQL query
    sql_query = sprintf('%s (%s) %s',sql_query_start,strjoin(input_vals,'),('),p.Results.unique_conflict_handling);

    %% execute SQL query
    switch class(dbconn)
        case 'sqlite'
            out.Message='';
            dbconn.exec(sql_query);
        otherwise
            out = dbconn.exec(sql_query);
    end
    % dealing with error message
    if ~isempty(out.Message)
        if contains(out.Message,'ERROR') || contains(out.Message,'failed')
            if contains(out.Message,'A PRIMARY KEY constraint failed')
                % issue was trying to enter a primary key that already existed.
                % If we tried to enter exactly the same info, then that's ok.
                %
                warning(out.Message);
            else
                error(out.Message);
            end
        end
    end
end
% close database
if ischar(ac_db_filename)
    dbconn.close();
end



end


%% subfunctions
%
function  b = fmt_input(a)

if isnumeric(a)
    if isnan(a)
        b = ['''' 'NaN' ''''];
    else
        b = num2str(a);
    end
else
    b = strrep(a,'''','''''');
    b = ['''' b ''''];
end

end