
classdef bin_file_cl < handle
    
    properties
        
        filename char
        encoding char
        machine_fmt char
        permission char
        content uint8
        position uint64
        blocksize uint64
        blockstart uint64
        filesize uint64
        
    end
    
    methods
        
        %% constructor %%
        function fobj = bin_file_cl(filename,varargin)
            
            p = inputParser;
            addRequired(p,'filename', @ischar);
            addOptional(p,'permission','r',@ischar);
            addOptional(p,'encoding','b',@ischar);
            addOptional(p,'machine_fmt','',@ischar); 
            addParameter(p,'blocktoread',[],@isnumeric);
            parse(p,filename,varargin{:});
            
            
            fobj.filename = filename;
            if ~isfile(fobj.filename)
                return;
            end
            
            s=dir(filename);
            fobj.filesize=s.bytes;
            
            if isempty(p.Results.blocktoread)
                fobj.blockstart = uint64(0);
            else
               fobj.blockstart = uint64(p.Results.blocktoread(1)-1);
            end
            
            fobj.permission = p.Results.permission;
            fobj.encoding = p.Results.encoding;
            fobj.machine_fmt = p.Results.machine_fmt;
            
            
            if ~isempty(fobj.encoding)&&~isempty(fobj.machine_fmt)
                fid  =fopen(fobj.filename,fobj.permission,fobj.encoding,fobj.machine_fmt);
            elseif isempty(fobj.encoding)
                fid  =fopen(fobj.filename,fobj.permission,fobj.encoding);
            else
                fid  =fopen(fobj.filename,fobj.permission);
            end
            
            if fid<0
                fprintf('Could not open file %s',fobj.filename);
                return;
            end
            fobj.position = 0;
            if isempty(p.Results.blocktoread)
                fobj.content = fread(fid,'uint8=>uint8');
            else
                fobj.content = fread(fid,p.Results.blocktoread,'uint8=>uint8');
            end
            fobj.blocksize = numel(fobj.content);
            
            fclose(fid);
        end
        
        function data = readf(fobj,varargin)
            sz = 1;
            prec = 'uint8';
            skip = 0;
            
            if nargin > 1
                sz  =varargin{1};
            end
            
            if nargin > 2
                prec  =varargin{2};
            end
            
            if nargin > 3
                skip  =varargin{3};
            end
            
            if isscalar(sz)
                sz = [sz 1];
            end
            func = [];
            switch prec
                case {'uint8' 'int8'}
                    nb_bits  = 1;
                case {'char' 'uchar' 'schar'}
                    nb_bits  = 1;
                    prec = 'int8';
                    func = @char;
                case {'uint16' 'int16'}
                    nb_bits = 2;
                    
                case {'uint32' 'int32'} 
                    nb_bits = 4;
                    
                case{'single' 'float32' 'float'}
                    nb_bits = 4;
                    prec = 'single';
                case {'uint64' 'int64'} 
                    nb_bits = 8;
                case {'double' 'float64'}
                    nb_bits = 8;
                    prec = 'double';
            end
            
            nb_elt = sz(1)*sz(2);
            idx = fobj.position+(1:uint64(1+nb_bits*skip):uint64(nb_elt*nb_bits));
            idx(idx>fobj.blocksize) = [];
            tmp =fobj.content(idx);
            data = double(typecast(tmp,prec));
            if ~isempty(func)
               data = func(data); 
            end
            data = reshape(data,sz);
            fobj.position = idx(end)+fobj.blockstart;
        end
        
        function pos = tellf(fobj)
            pos = fobj.position;
        end
        
        function seekf(fobj,offset,varargin)
            origin = 'bof';
            if nargin>2
                origin = varargin{1};
            end
            
            switch origin
                case {'bof' -1}
                    fobj.position = offset;
                case {'cof' 0}
                    fobj.position = fobj.position+offset;
                case {'eof' 1}
                    fobj.position = fobj.blocksize-offset;
            end
            
            if fobj.position>fobj.blocksize
                fobj.position = fobj.blocksize+fobj.blockstart;
            end
            
            if fobj.position<fobj.blockstart
                fobj.position = fobj.blockstart;
            end
             
        end
        
        function rewindf(fobj)
            fobj.position = fobj.blockstart;
        end
        
        function iseof = eof(fobj)
            iseof = fobj.position>=(fobj.blocksize-obj.blockstart);
        end
        
        
        
    end
    
end
