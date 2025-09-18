function [nSamples,nPings]=get_nb_samples(fid,CIDs)

HEADER_LEN = 12;               
ping=0;


fPosition=ftell(fid);

nXcvrs = length(CIDs);
nSamples = zeros(nXcvrs, 1);

nPings = zeros(nXcvrs, 1);


while (nXcvrs > 0)
    len = fread(fid, 1, 'int32');
    
    if (feof(fid))
        break;
    end
    
    [dgType, ~] = readEK60Header_v2(fid);
    
    
    if strcmp(dgType, 'RAW3')
        %disp(dgType);
        channelID = (fread(fid,128,'*char')');
        datatype=fread(fid,1,'int16');
        fread(fid,2,'char');
        offset=fread(fid,1,'int32');
        sampleCount=fread(fid,1,'int32');
        
        idx = find(strcmp(deblank(CIDs),deblank(channelID)));
       
        
        if (~isempty(idx)) && (sampleCount > 0) && (nPings(idx) >= ping) 
             nPings(idx) = nPings(idx) + 1;
            nSamples(idx) = sampleCount;
        end
        
        fseek(fid, len - 140 - HEADER_LEN, 0);
        
    else
        fseek(fid, len - HEADER_LEN, 0);
    end   
    len=fread(fid, 1, 'int32');
end

fseek(fid, fPosition, 'bof');

end