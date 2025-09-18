function [bot_ver_new,reg_ver_new]=save_bot_reg_to_db(layer_obj,varargin)

% input parser
p = inputParser;
addRequired(p,'layer_obj',@(obj) isa(obj,'layer_cl'));
addParameter(p,'bot',1);
addParameter(p,'reg',1);
parse(p,layer_obj,varargin{:});

[path_xml,reg_file_str,bot_file_str]=layer_obj.create_files_str();
bot_ver_new=0;
reg_ver_new=0;

max_bot_ver=0;
max_reg_ver=0;
for ib=1:length(bot_file_str)
    dbfile=fullfile(path_xml{ib},'bot_reg.db');

    if exist(dbfile,'file')==0
        initialize_reg_bot_db(dbfile)
    end

    dbconn=sqlite(dbfile,'connect');
    if p.Results.bot>0
        bot_ver = dbconn.fetch(sprintf('select Version from bottom where instr(Filename, ''%s'')>0',bot_file_str{ib}));
        if ~isempty(bot_ver)&&istable(bot_ver)&&~isempty(bot_ver.Version)
            max_bot_ver=max([max_bot_ver max(bot_ver.Version)]);
        end
    end
    
    if p.Results.reg>0
        reg_ver = dbconn.fetch(sprintf('select Version from region where instr(Filename, ''%s'')>0',reg_file_str{ib}));
        if ~isempty(reg_ver)&&istable(reg_ver)&&~isempty(reg_ver.Version)
            max_reg_ver=max([max_reg_ver max(reg_ver.Version)]);
        end
    end
    
    close(dbconn);
    
end

for ifile=1:length(reg_file_str)
    if exist(path_xml{ifile},'dir')==0
        mkdir(path_xml{ifile});
    end
    xml_reg_file=fullfile(path_xml{ifile},reg_file_str{ifile});
    xml_bot_file=fullfile(path_xml{ifile},bot_file_str{ifile});
    
    dbfile=fullfile(path_xml{ifile},'bot_reg.db');
    
    dbconn=sqlite(dbfile,'connect');
    
    
    if isfile(xml_bot_file) && p.Results.bot>0
        xml_str_bot=fileread(xml_bot_file);
        bot_ver_new=max_bot_ver+1;
        fprintf('Saving Bottom to database as version %.0f for file %s\n',max_bot_ver+1,bot_file_str{ifile});
        dbconn.sqlwrite('bottom',table(bot_file_str(ifile),{xml_str_bot},bot_ver_new,'VariableNames',{'Filename' 'Bot_XML' 'Version'}));
    end
    
    
    if isfile(xml_reg_file) && p.Results.reg>0
        xml_str_reg=fileread(xml_reg_file);
        reg_ver_new=max_reg_ver+1;
        fprintf('Saving Regions to database as version %.0f for file %s\n',reg_ver_new,reg_file_str{ifile});
        dbconn.sqlwrite('region',table(reg_file_str(ifile),{xml_str_reg},reg_ver_new,'VariableNames',{'Filename' 'Reg_XML' 'Version'}));   
    end
    
    
    close(dbconn)
end
end