DB = DBserver('localhost:2181','Accumulo','instance', 'root','secret');
DoDeleteDB = true;
Fastadir = 'dirStore';
Tablebase = 'Tseq';

nl = char(10);
files = dir([Fastadir filesep '*._aas']);
numfiles = size(files,1);
arrNameFileBase = cell(numfiles,1);
arrNumFilesRaw = zeros(numfiles,1);
arrNumFilesH = zeros(numfiles,1);
for i = 1:numfiles
    arrNameFileBase{i} = [Fastadir filesep files(i).name];
    filesRaw = dir([arrNameFileBase{i} '.' Tablebase 'Raw.mat*']);
    filesRawNumBases = dir([arrNameFileBase{i} '.' Tablebase 'RawNumBases.mat.*']);
    filesvalNumBases = dir([arrNameFileBase{i} '.' Tablebase 'valNumBases.mat.*']);
    filesH       = dir([arrNameFileBase{i} '.' Tablebase '.mat.*']);
    filesHDegT   = dir([arrNameFileBase{i} '.' Tablebase 'DegT.mat.*']);
    %    filesHFieldT = dir([arrNameFileBase{i} '.' Tablebase 'FieldT.mat.*']);
    if size(filesRaw,1) ~= size(filesRawNumBases,1) || size(filesRaw,1) ~= size(filesvalNumBases,1)
        fprintf('ERROR i=%d: size(filesRaw,1) ~= size(filesRawNumBases,1) || size(filesRaw,1) ~= size(filesvalNumBases,1)',i);
        return
    end
    if size(filesH,1) ~= size(filesHDegT,1)
        fprintf('ERROR i=%d: size(filesH,1) ~= size(filesHDegT,1)',i);
        return
    end
    arrNumFilesRaw(i) = size(filesRaw,1);
    arrNumFilesH(i) = size(filesH,1);
end

    if DoDeleteDB
%         prompt = input('Are you sure you want to create new tables and delete old ones? [y/n]','s');
%         if ~strcmpi(prompt,'y')
%             return
%         end
%         clear prompt
        Tablebase(Tablebase == '.') = '_';
        Tseq = DB([Tablebase ''], [Tablebase 'T']);
        TseqDegT = DB([Tablebase 'DegT']);
        TseqFieldT = DB([Tablebase 'FieldT']);
        TseqRaw = DB([Tablebase 'Raw']);
        TseqRawNumBases = DB([Tablebase 'RawNumBases']);
%         Tinfo = DB([Tablebase 'Info']);
%         deleteForce(Tinfo);
        deleteForce(Tseq); deleteForce(TseqRaw);
        deleteForce(TseqDegT); deleteForce(TseqFieldT);
        deleteForce(TseqRaw); deleteForce(TseqRawNumBases);
    end
    Tseq = DB([Tablebase ''], [Tablebase 'T']);
    TseqDegT = DB([Tablebase 'DegT']);
    TseqDegT = addColCombiner(TseqDegT,'deg,','sum');
    TseqFieldT = DB([Tablebase 'FieldT']);
    TseqFieldT = addColCombiner(TseqFieldT,'deg,','sum');
    TseqRaw = DB([Tablebase 'Raw']);
    TseqRawNumBases = DB([Tablebase 'RawNumBases']);
    Tinfo = DB([Tablebase 'Info']);

statTimeMatLoadComputeSeq = 0;
statTimePutSeq = 0;
statTimeMatLoadComputeHeader = 0;
statTimePutHeader = 0;
cumTotalTime = 0;

FLOG = fopen([Fastadir filesep 'MatToDB.log'],'w');
for i = 1:numfiles
    fprintf('[%s %4d/%04d] Processing: %s\n',datestr(now),i,numfiles,files(i).name);
    fprintf(FLOG,'[%s %4d/%04d] Processing: %s\t',datestr(now),i,numfiles,files(i).name);
    putTimeStart = tic;
    for j = 1:arrNumFilesRaw(i)
        tic;
        fRaw = load([arrNameFileBase{i} '.' Tablebase 'Raw.mat.' num2str(j)],'-mat','buf');
        fRawNumBases = load([arrNameFileBase{i} '.' Tablebase 'RawNumBases.mat.' num2str(j)],'-mat','buf');
        fvalNumBases = load([arrNameFileBase{i} '.' Tablebase 'valNumBases.mat.' num2str(j)],'-mat','buf');
        
        
        %row = fRaw.buf;
        if isempty(fRaw.buf)
            return
        end
        sep = fRaw.buf(end);
        numseq = nnz(fRaw.buf==sep);
        col = repmat(['seq' sep],1,numseq);
        %val = hb.getBufCurrent(2); fRawNumBases.buf

        colNumBases = repmat(['num' sep],1,numseq);
        %valNumBases = hb.getBufCurrent(3); fvalNumBases.buf
        statTimeMatLoadComputeSeq = statTimeMatLoadComputeSeq + toc;
        
        tic;
        putTriple(TseqRaw, fRaw.buf,col,fRawNumBases.buf);
        putTriple(TseqRawNumBases, fRaw.buf,colNumBases,fvalNumBases.buf);
        statTimePutSeq = statTimePutSeq + toc;
    end
        
        
    for j = 1:arrNumFilesH(i)
        tic;
        fH = load([arrNameFileBase{i} '.' Tablebase '.mat.' num2str(j)],'-mat','buf');
        fHDegT = load([arrNameFileBase{i} '.' Tablebase 'DegT.mat.' num2str(j)],'-mat','buf');
        %fHFieldT = load([arrNameFileBase{i} '.' Tablebase 'FieldT.mat.' num2str(j)],'-mat','buf');
        
        
        %row = hb.getBufCurrent(1); fH.buf
        if isempty(fH.buf)
            return
        end
        sep = fH.buf(end);
        nummeta = nnz(fH.buf==sep);
        %col = hb.getBufCurrent(2); fHDegT.buf
        val = repmat(['1' sep],1,nummeta);
        

        % pre-summing degree table
        Aorig = Assoc(fHDegT.buf,fH.buf,1,@sum); % sums together columns with the same name
        Anum = putCol(sum(Aorig,2),['deg' char(10)]);
        

        % pre-summing field table
        [r, c, v] = find(Anum);
        r = Str2mat(r);
        for x=1:size(r,1)
            idx = find(r(x,:)=='|',1,'first');
            r(x,idx) = sep;
            r(x,idx+1:end) = char(0);
        end
        r = Mat2str(r);
        Anew = Assoc(r,c,v,@sum); % sums together columns with the same name
        statTimeMatLoadComputeHeader = statTimeMatLoadComputeHeader + toc;
        
        tic;
        putTriple(Tseq, fH.buf,fHDegT.buf,val);
        put(TseqDegT,num2str(Anum));
        put(TseqFieldT,num2str(Anew));
        statTimePutHeader = statTimePutHeader + toc;
    end
    putTime = toc(putTimeStart);
    cumTotalTime = cumTotalTime + putTime;
    Np=1;

    statNum = 4;
    col = ['statTimeMatLoadComputeSeq' nl 'statTimePutSeq' nl 'statTimeMatLoadComputeHeader' nl 'statTimePutHeader' nl];
    val = [statTimeMatLoadComputeSeq statTimePutSeq statTimeMatLoadComputeHeader statTimePutHeader];
    row = repmat([files(i).name nl], 1, statNum);
    Ainfo = num2str(Assoc(row,col,val));
    put(Tinfo,Ainfo);
    %display(Ainfo)
    statTimeMatLoadComputeSeq = 0;
    statTimePutSeq = 0;
    statTimeMatLoadComputeHeader = 0;
    statTimePutHeader = 0;
    
    fprintf('Elapsed %6.2f hrs; Expected finish %6.2f hrs\n',(cumTotalTime/3600),(cumTotalTime*numfiles/i/Np/3600));
    fprintf(FLOG,'Elapsed %6.2f hrs; Expected finish %6.2f hrs\n',(cumTotalTime/3600),(cumTotalTime*numfiles/i/Np/3600));
end
fclose(FLOG);
