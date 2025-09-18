function [bottom,rawFileName]=get_bottom_from_esp2(iFilePath,iFileName,voyage,cvsroot,varargin)

switch nargin
    case 4
        rev = [];
    case 5
        rev = varargin{1};
end


if  ischar(iFileName)
    %if a d-,n- or t- file was specified instead of an i-file use the corresponding i-file
    tok = iFileName(end-7);
    num = iFileName((end-6):end);
    if (tok == 'd' || tok == 'n' || tok == 't') && ~isempty(str2double(num))
        iFileName(end-7) = 'i';
    end
else
    iFileName = sprintf('i%07d', iFileName);
end


ifile_info=parse_ifile(fullfile(iFilePath,iFileName));
rawFileName=ifile_info.rawFileName;
depthFactor = ifile_info.depth_factor;

%% Checkout bFile
outDir = tempname();
%run command - make output directory for cvs
if ~mkdir(outDir)
    error('Unable to create temporary cvs directory');
end

outDir_final = fullfile(iFilePath,'bot_reg_crest');
if ~isfolder(outDir_final)
    mkdir(outDir_final);
end

idx_str=strfind(iFilePath,voyage);
remain_str=iFilePath(idx_str:end);
bFileName = ['b' iFileName(2:end)];


if isempty(rev)
    command = ['cvs -q -d ' cvsroot ' checkout ' strrep(fullfile(remain_str,bFileName),'\','/')];
else
    command = ['cvs -q -d ' cvsroot ' checkout ' '-r ' rev ' ' strrep(fullfile(remain_str,bFileName),'\','/')];
end


%run command - export bottom from cvs
work_path=pwd;
cd(outDir)
[~,~] = system(command,'-echo');
cd(work_path)

bFilePath = fullfile(outDir,remain_str);

bfile = fullfile(outDir_final,bFileName);

if isfile(fullfile(bFilePath,bFileName))
    copyfile(fullfile(bFilePath,bFileName),bfile);
end

if  ~isfile(bfile)
    bottom = bottom_cl('Origin','Esp2','Sample_idx',[]);
    return;
end

sample_idx = load_bottom_file(bfile);

if isempty(sample_idx)
    bottom = bottom_cl( 'Origin','Esp2','Sample_idx',[],'Tag',[]);
    return;
end
bad = load_bad_transmits(bfile);

bottom = bottom_cl('Origin','Esp2','Sample_idx',sample_idx','Tag',bad==0);

rmdir(outDir,'s');

end