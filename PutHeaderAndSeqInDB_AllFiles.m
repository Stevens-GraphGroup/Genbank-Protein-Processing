%% Script PutHeaderAndSeqInDB_AllFiles Put many fasta files in DB
Fastadir = 'dirStore';
%Fastadir = 'dirStoreCut';
%Fastafile = 'gbenv1._aas.cut';
DB = DBserver('localhost:2181','Accumulo','instance', 'root','secret');
DoDB = true;                       % Use DB or in-memory Assoc
DoDeleteDB = true;                 % Delete pre-existing tables.
DoPutHeader = true;
DoPutRawSequence = true;
Tablebase = 'Tseq';
RowLengthLimit = 2e5; % Size before sending to server

% Ideas:
% -Check if a file has info in Tinfo. If yes, that file is complete. If no, ingest it.
%       (note: will not help with degree tables)
% -PMatlab on different files.
% -Preallocate arrays so they don't change size every iteration.
% -Presum degree counts using associative array.

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if DoDB
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
nl = char(10);
for i = 1:numfiles
    Fastafile = deblank(files(i).name);
    if numel(Fastafile) < 5 || ~strcmp('gb',Fastafile(1:2)) || ~strcmp('_aas',Fastafile(end-3:end))
        continue
    end
    fprintf('[%s %4d/%04d] Processing: %s\n',datestr(now),i,numfiles,Fastafile);
    
    tic;
    PutHeaderAndSeqInDB;
    putTime = toc;
    
%     if DoDB
%        putTriple(Tinfo,[Fastafile nl],sprintf('putTime|%010.2f\n',putTime),'1\n');
%     else
%         Tinfo = Tinfo + Assoc([Fastafile nl],sprintf('putTime|%010.2f\n',putTime),'1\n');
%     end
    DoDeleteDB = false;
end

