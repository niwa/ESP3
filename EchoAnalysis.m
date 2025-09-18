%% EchoAnalysis.m
%
% ESP3 Main function
%
%          |
%         /|\
%        / | \
%       /  |  \
%      /   |___\
%     /____|______
%     \___________\   written by Yoann Ladroit
%          / \          in 2016
%         /   \
%        / <>< \    Fisheries Acoustics
%       /<>< <><\   NIWA - National Institute of Water & Atmospheric Research
%
%% Help
%
% *USE*
%
% Run this function without input variables to launch empty ESP3, or with
% input file names to open. Use the SaveEcho optional parameter to print
% out contents of any input file.
%
% *INPUT VARIABLES*
%
% * 'Filenames': Filenames to load (Optional. char or cell).
% * 'SaveEcho': Flag to print window (Optional. If |1|, print content of
% input file and closes ESP3).
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% NA
%
% *NEW FEATURES*
%
% * 2020-10: New version using esp3_cl objects (Yoann Ladroit)
% * 2017-03-22: reformatting header according to new template (Alex Schimel)
% * 2017-03-17: reformatting comment and header for compatibility with publish (Alex Schimel)
% * 2017-03-02: commented and header added (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
%   EchoAnalysis; % launches ESP3
%   EchoAnalysis('my_file.raw'); % launches ESP3 and opens 'my_file.raw'.
%   EchoAnalysis('my_file.raw',1); % launches ESP3, opens 'my_file.raw', print file data to .png, and close ESP3.
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA.
%
% Copyright 2017 NIWA
%
% Permission is hereby granted, free of charge, to any person obtaining a
% copy of this software and associated documentation files (the
% "Software"), to deal in the Software without restriction, including
% without limitation the rights to use, copy, modify, merge, publish,
% distribute, sublicense, and/or sell copies of the Software, and to permit
% persons to whom the Software is furnished to do so, subject to the
% following conditions: The above copyright notice and this permission
% notice shall be included in all copies or substantial portions of the
% Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
% NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
% DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
% OTHERWISE, ARISING FROM,OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
% USE OR OTHER DEALINGS IN THE SOFTWARE.
%

%% Function
function esp3_obj=EchoAnalysis(varargin)

%% Software main path
if ~isdeployed
    update_path();
end

%% Remove warnings

warning('off','MATLAB:ui:javacomponent:FunctionToBeRemoved');
warning('off','MATLAB:ui:javaframe:PropertyToBeRemoved');
warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
warning('off','MATLAB:polyshape:repairedBySimplify');
warning('off','MATLAB:polyshape:boundaryLessThan2Points');
warning('off','MATLAB:polyshape:boundary3Points');
warning('off','MATLAB:chckxy:IgnoreNaN');
warning('off','curvefit:prepareFittingData:removingNaNAndInf');
warning('off','MATLAB:connector:connector:ConnectorNotRunning');
warning('off','MATLAB:uitogglesplittool:DeprecatedFunction');
warning('off','MATLAB:uitreenode:DeprecatedFunction');
warning('off','MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId');
warning('off','curvefit:fit:iterationLimitReached');
warning('error', 'MATLAB:DELETE:Permission');

setdbprefs('DataReturnFormat','Table');

%% Checking and parsing input variables
p = inputParser;
addOptional(p,'Filenames',{},@(x) ischar(x)||iscell(x));
addOptional(p,'SaveEcho',0,@isnumeric);
parse(p,varargin{:});

files_to_load=p.Results.Filenames;
scripts={};

if ~isempty(files_to_load)
    if ischar(files_to_load)
        files_to_load=cellstr(files_to_load);
    end
    
    [~,~,tmp]=cellfun(@fileparts,files_to_load,'un',0);
    
    idx_xml=strcmpi(tmp,'.xml');
    scripts_tmp=files_to_load(idx_xml);
    
    [folder_xml,f_name,~]=cellfun(@fileparts,scripts_tmp,'un',0);
    files_to_load(idx_xml)=[];
    
    
    for ifo=1:numel(folder_xml)
        if contains(f_name{ifo},'*')
            tmp_scr=dir(fullfile(folder_xml{ifo},[f_name{ifo} '.xml']));
            sc=cellfun(@(x) fullfile(folder_xml{ifo},x),{tmp_scr(:).name},'un',0);
            scripts=union(scripts,sc);
        else
            scripts=union(scripts,fullfile(folder_xml{ifo},[f_name{ifo} '.xml']));
        end
    end

end

%% Default font size for Controls and Panels and db prefs
set(0,'DefaultUipanelFontSize',8,'defaultUipanelFontSizeMode','auto');
set(0,'defaultAxesFontSize',9,'defaultAxesFontSizeMode','auto');
set(0,'defaultTextFontSize',8,'DefaultTextFontSizeMode','auto');
set(0,'defaultLegendFontSize',9,'DefaultLegendFontSizeMode','auto');
set(0,'defaultUicontrolFontSize',9,'defaultUicontrolFontSizeMode','auto');
set(0,'DefaultAxesLooseInset',[0.15,0.15,0.15,0.15]);
set(0,'defaultAxesCreateFcn',@axDefaultCreateFcn);
set(0,'DefaultLegendAutoUpdate','off');


%% Do not Launch a third instance ESP3...
if ispc()
    [~,str]=system('tasklist');
    nb_esp3_instances=sum(contains(strsplit(str,'\n'),'ESP3.exe'));
    if nb_esp3_instances>2
        QuestFig=new_echo_figure([],'units','pixels','position',[200 200 200 100],...
            'WindowStyle','modal','Visible','on','resize','off','tag','doyouwanttoquit');
        uicontrol('Parent',QuestFig,...
            'Style','text',...
            'Position',[10 10 180 80],...
            'String','2 instances of ESP3 are already running around in circles... Use them or close them :)','BackgroundColor','w');
        close(QuestFig);
        return;
    end
else
    nb_esp3_instances=1;
end

%% Do not Relaunch ESP3 if already open (in Matlab)...
if ~isdeployed()&&isappdata(groot,'esp3_obj')
    nb_esp3_instances=nb_esp3_instances+1;
    esp3_obj=getappdata(groot,'esp3_obj');
    if~isempty(esp3_obj)&&isvalid(esp3_obj)&&~isempty(esp3_obj.main_figure)&&isvalid(esp3_obj.main_figure)
        figure(esp3_obj.main_figure);
        return;
    end
end

if (~isempty(scripts)||~isempty(files_to_load))&&p.Results.SaveEcho==1
    nodisplay = true;
else
    nodisplay = false;
end

esp3_obj=esp3_cl('nb_esp3_instances',nb_esp3_instances,...
    'files_to_load',files_to_load,...
    'scripts_to_run',scripts,...
    'nodisplay',nodisplay,...
    'SaveEcho',p.Results.SaveEcho);

% profile off;
% profile viewer;
end

function update_path()
main_path = whereisEcho();
addpath(main_path);
path_src=fullfile(main_path,'src');
addpath(path_src);
addpath(genpath(path_src));
end




