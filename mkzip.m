classdef mkzip
    %MKZIP - losslessly compress numerical matrices and strings
    %
    %   Example:
    %     d = randi(8,1000,1000); % generate some data
    %     M = mkzip(d) % returns compressed version of d in mkzip object M 
    %     d = M.unzip; % returns uncompressed data in d 
    %     r = M.ratio % returns the compression ratio r
    %
    %   This is a class wrapper for Michael Kleder dzip/dunzip functions.
    %   The main advantage of making this a class is that it is impossible
    %   to forget that a certain array is zipped and end up doing
    %   calculations on it as if it is the actual data, which could be
    %   disastrous. It also provides some extra functionality (e.g., ratio)
    %   and as a class only one M-file is needed instead of one for dzip
    %   and one for dunzip.
    
    % Jacob Duijnhouwer Dec-2011, updated Feb-2019
    
    properties (Access=protected)
        data=[];
    end
    properties (GetAccess=public,SetAccess=protected)
        zipBytes@double;
        dataClass@char;
        dataSize@double;
        dataBytes@double;
        ratio@double;
    end
    methods
        function Z=mkzip(M)
            narginchk(1,1);
            Z.data=dzip(M);
            tmp=whos('M');
            Z.dataClass=tmp.class;
            Z.dataSize=size(M);
            Z.dataBytes=tmp.bytes;
            tmp=whos('Z');
            Z.zipBytes=tmp.bytes;
            Z.ratio=Z.zipBytes/Z.dataBytes;
        end
        function disp(Z)
            dataSizeStr=sprintf('%dx',Z.dataSize);
            dataSizeStr(end)=[];
            dataInf=[dataSizeStr ' ' Z.dataClass 's-array'];
            fprintf(['\t<a href="matlab:help mkzip">mkzip</a> object holding a ' dataInf ' (' num2str(100-Z.ratio*100,'%.1f') '%% compressed)\n\n']);
        end
        function data=unzip(Z)
            data=dunzip(Z.data);
        end
    end
end

% PRIVATE FUNCTIONS
% These are the functions that do the zipping and unzipping, programmed by
% Michael Kleder

function Z = dzip(M)
    % DZIP - losslessly compress data into smaller memory space
    %
    % USAGE:
    % Z = dzip(M)
    %
    % VARIABLES:
    % M = variable to compress
    % Z = compressed output
    %
    % NOTES: (1) The input variable M can be a scalar, vector, matrix, or
    %            n-dimensional matrix
    %        (2) The input variable must be a non-complex and full (meaning
    %            matrices declared as type "sparse" are not allowed)
    %        (3) Permitted input types include: double, single, logical,
    %            char, int8, uint8, int16, uint16, int32, uint32, int64,
    %            and uint64.
    %        (4) In testing, DZIP compresses several megabytes of data per
    %            second.
    %        (5) In testing, random matrices of type double compress to about
    %            75% of their original size. Sparsely populated matrices or
    %            matrices with regular structure can compress to less than
    %            1% of their original size. The realized compression ratio
    %            is heavily dependent on the data.
    %        (6) Variables originally occupying very little memory (less than
    %            about half of one kilobyte) are handled correctly, but
    %            the compression requires some overhead and may actually
    %            increase the storage size of such small data sets.
    %            One exception to this rule is noted below.
    %        (7) LOGICAL variables are compressed to a small fraction of
    %            their original sizes.
    %        (8) The DUNZIP function decompresses the output of this function
    %            and restores the original data, including size and class type.
    %        (9) This function uses the public domain ZLIB Deflater algorithm.
    %       (10) Carefully tested, but no warranty; use at your own risk.
    %       (11) Michael Kleder, Nov 2005
    
    s = size(M);
    c = class(M);
    cn = strmatch(c,{'double','single','logical','char','int8','uint8',...
        'int16','uint16','int32','uint32','int64','uint64'});
    if isempty(cn)
        error(['Not a valid datatype to compress: ' c '. (mkzip only can compress numeric and char variables)']);
    end
    if cn == 3 || cn == 4
        M=uint8(M);
    end
    M=typecast(M(:),'uint8');
    M=[uint8(cn);uint8(length(s));typecast(s(:),'uint8');M(:)];
    f=java.io.ByteArrayOutputStream();
    g=java.util.zip.DeflaterOutputStream(f);
    g.write(M);
    g.close;
    Z=typecast(f.toByteArray,'uint8');
    f.close;
    return
end

function M = dunzip(Z)
    % DUNZIP - decompress DZIP output to recover original data
    %
    % USAGE:
    % M = dzip(Z)
    %
    % VARIABLES:
    % Z = compressed variable to decompress
    % M = decompressed output
    %
    % NOTES: (1) The input variable Z is created by the DZIP function and
    %            is a vector of type uint8
    %        (2) The decompressed output will have the same data type and
    %            dimensions as the original data provided to DZIP.
    %        (3) See DZIP for other notes.
    %        (4) Carefully tested, but no warranty; use at your own risk.
    %        (5) Michael Kleder, Nov 2005
    
    import com.mathworks.mlwidgets.io.InterruptibleStreamCopier
    a=java.io.ByteArrayInputStream(Z);
    b=java.util.zip.InflaterInputStream(a);
    isc = InterruptibleStreamCopier.getInterruptibleStreamCopier;
    c = java.io.ByteArrayOutputStream;
    isc.copyStream(b,c);
    Q=typecast(c.toByteArray,'uint8');
    cn = double(Q(1)); % class
    nd = double(Q(2)); % # dims
    s = typecast(Q(3:8*nd+2),'double')'; % size
    Q=Q(8*nd+3:end);
    if cn == 3
        M  = logical(Q);
    elseif cn == 4
        M = char(Q);
    else
        ct = {'double','single','logical','char','int8','uint8',...
            'int16','uint16','int32','uint32','int64','uint64'};
        M = typecast(Q,ct{cn});
    end
    M=reshape(M,s);
    return
end


function s=bytesToStr(b,forceunit)
    if ~exist('forceunit','var') || isempty(forceunit)
        forceunit='dynamic';
    end
    dyn=strcmpi(forceunit,'dynamic');
    kilo=1024;
    mega=kilo*kilo;
    giga=kilo*mega;
    tera=kilo*giga;
    peta=kilo*tera;
    exa=kilo*peta;
    if b<kilo && dyn || strcmpi(forceunit,'B');
        s=[num2str(b) ' Byte'];
    elseif b>=kilo && b<mega  && dyn || strcmpi(forceunit,'kB') || strcmpi(forceunit,'k');
        s=[num2str(b/kilo,'%.2f') ' kB'];
    elseif b>=mega && b<giga && dyn|| strcmpi(forceunit,'MB') || strcmpi(forceunit,'M');
        s=[num2str(b/mega,'%.2f') ' MB'];
    elseif b>=giga && b<tera && dyn|| strcmpi(forceunit,'GB') || strcmpi(forceunit,'G');
        s=[num2str(b/giga,'%.2f') ' GB'];
    elseif b>=tera && b<peta && dyn|| strcmpi(forceunit,'TB') || strcmpi(forceunit,'T');
        s=[num2str(b/tera,'%.2f') ' TB'];
    elseif b>=peta && b<exa && dyn|| strcmpi(forceunit,'PB') || strcmpi(forceunit,'P');
        s=[num2str(b/peta,'%.2f') ' PB'];
    elseif b>=exa && dyn || strcmpi(forceunit,'EB') || strcmpi(forceunit,'E');
        s=[num2str(b/exa,'%.2f') ' EB'];
    else
        s=[num2str(b) ' B'];
    end
end
