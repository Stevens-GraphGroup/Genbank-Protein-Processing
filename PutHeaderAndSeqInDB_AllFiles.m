%% Script PutHeaderAndSeqInDB_AllFiles Put many fasta files in DB
Fastadir = 'dirStoreCut';
%Fastafile = 'gbenv1._aas.cut';
DB = DBserver('localhost:2181','Accumulo','instance', 'root','secret');
DoDB = true;                       % Use DB or in-memory Assoc
DoDeleteDB = true;                 % Delete pre-existing tables.
DoPutHeader = true;
DoPutRawSequence = true;
Tablebase = 'Tseq';
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
    fprintf('[%s] Processing: %s\n',datestr(now),Fastafile);
    
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

