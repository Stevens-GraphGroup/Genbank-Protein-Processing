%% Script PutHeaderAndSeqInDB_AllFiles Put many fasta files in DB
%Fastadir = 'testProtein1';
Fastadir = 'dirStore';
%Matdir = 'dirMat';
%Fastafile = 'gbenv1._aas.cut';
DB = DBserver('localhost:2181','Accumulo','instance', 'root','secret');
DoDB = true;                       % Use DB or in-memory Assoc
DoDBInfo = true;
DoDisp = false;
DoSaveMat = false;
DoSaveStats = true;
DoDeleteDB = false;                 % Delete pre-existing tables.
DoPutHeader = true;
DoPutRawSequence = true;
Tablebase = 'Tseq';
BytesLimit = 5e5; % Size before sending to server
LargestSequence = 11000;
LargestMeta = 6000;
Skip = 0;%126; % to file 127
PARALLEL = true;
% eval(pRUN('PutHeaderAndSeqInDB_AllFiles',4,{}))
% Ideas:
% -Check if a file has info in Tinfo. If yes, that file is complete. If no, ingest it.
%       (note: will not help with degree tables)
% -PMatlab on different files.
% -Preallocate arrays so they don't change size every iteration.
% -Presum degree counts using associative array.

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if DoDBInfo
    if DoDeleteDB
        prompt = input('Are you sure you want to create new tables and delete old ones? [y/n]','s');
        if ~strcmpi(prompt,'y')
            return
        end
        clear prompt
        Tinfo = DB([Tablebase 'Info']);
        deleteForce(Tinfo);
    end
    Tinfo = DB([Tablebase 'Info']);
else
    Tinfo = Assoc('','','');
end
files = dir([Fastadir filesep '*._aas']);
numfiles = size(files,1);
if PARALLEL
    myfiles =  global_ind(zeros(numfiles-Skip,1,map([Np 1],{},0:Np-1)));
else
    myfiles = 1:(numfiles-Skip)
end
disp(myfiles);

nl = char(10);
cumTotalTime = 0;
FLOG = fopen([Fastadir filesep 'PutHeaderAndSeqInDB_AllFiles.' num2str(Np) '.log'],'w');
for origi = myfiles%1:numfiles-Skip
    i = origi+Skip;
    Fastafile = deblank(files(i).name);
    if numel(Fastafile) < 5 || ~strcmp('gb',Fastafile(1:2)) || ~strcmp('_aas',Fastafile(end-3:end))
        continue
    end
    fprintf('[%s %4d/%04d] Processing: %s\t',datestr(now),i,numfiles,Fastafile);
    fprintf(FLOG,'[%s %4d/%04d] Processing: %s\t',datestr(now),i,numfiles,Fastafile);
    
    tic;
    PutHeaderAndSeqInDB(DB,DoDB,DoDisp,DoSaveMat,DoDeleteDB,...
        DoPutHeader,DoPutRawSequence,Tablebase,BytesLimit,LargestSequence,LargestMeta,...
        Fastadir,Fastafile,DoSaveStats,DoDBInfo);
    putTime = toc;
    
    cumTotalTime = cumTotalTime + putTime;
    Np=1;
    
    %disp(['Extrapolated total run time (totalTime*Numfiles/Np/3600): ' num2str(totalTime*Numfiles/Np/3600)]);
    %disp(['Cummulative Extrapolated total run time (cumTotalTime*numfiles/fileNum/Np/3600): ' num2str(cumTotalTime*numfiles/i/Np/3600)]);
    fprintf('Expected finish %s\n',num2str(cumTotalTime*numfiles/i/Np/3600));
    fprintf(FLOG,'Expected finish %s\n',num2str(cumTotalTime*numfiles/i/Np/3600));
    
%     if DoDB
%        putTriple(Tinfo,[Fastafile nl],sprintf('putTime|%010.2f\n',putTime),'1\n');
%     else
%         Tinfo = Tinfo + Assoc([Fastafile nl],sprintf('putTime|%010.2f\n',putTime),'1\n');
%     end
    DoDeleteDB = false;
end
fclose(FLOG);
