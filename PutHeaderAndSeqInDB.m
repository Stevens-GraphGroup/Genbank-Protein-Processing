%% Script PutHeaderAndSeqInDB Reads fasta file and puts it in the DB
% Tables:
% Tseq: (accession_id,header_column,1) e.g. 
%           (BAH59624.1,date|2009-05-23,1)
%           (BAH59624.1,organism|Sapovirus Tamagawa River,1)
% TseqT:        transpose
% TseqDegT:     (header_column,deg,<degree>) e.g. (date|2009-05-23,deg,7)
% TseqFieldT:   (header_field,deg,<degree>)  e.g. (date,deg,2345)
% TseqRaw:      (accession_id,seq,<SEQUENCE>)e.g. (BAA32142.1,seq,WGVSD...)
% TseqRawNumBases: (accession_id,num,<#>)    e.g. (BAA32142.1,num,5)
% TseqInfo:   (filename,<logCol>|<logVal>,1)e.g. (gbcon1.seq,putTime|0000013.54)
%
% Special handilng
% 'date|2010-07-03'

% Fastadir = 'testProtein1';
% Fastafile = 'gbenv1._aas.cut';
% %DB = DBserver('localhost:2181','Accumulo','instance', 'root','secret');
% DoDB = false;                       % Use DB or in-memory Assoc
% DoDeleteDB = false;                 % Delete pre-existing tables.
% DoPutHeader = true;
% DoPutRawSequence = true;
% %Tablebase = [Fastafile '_table_'];  % Base name for table (when using DB); '.' changed to '_'
% Tablebase = 'Tseq';
% BytesLimit = 1e5; % Size before sending to server

% 2015-01-18: Eliminated taxopart; just keep full taxonomy.
% 2015-01-18: Parsed date and reversed to format "03-JUL-2010" => '2010-07-03'
% 2015-01-18: Fixed '/' inside quotes in '/def="..."'
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function PutHeaderAndSeqInDB(DB,DoDB,DoDisp,DoSaveMat,DoDeleteDB,...
    DoPutHeader,DoPutRawSequence,Tablebase,BytesLimit,LargestSequence,LargestMeta,...
    Fastadir,Fastafile,DoSaveStats,DoDBInfo)
hbSeq    = HandleBuffer(3,BytesLimit);
hbHeader = HandleBuffer(2,BytesLimit);
hbSeqVal = HandleBuffer(1,LargestSequence);
hbMeta   = HandleBuffer(1,LargestMeta);

if DoDB
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
    HBListen.addFunPutDB_Seq(hbSeq,TseqRaw,TseqRawNumBases);
    HBListen.addFunPutDB_Header(hbHeader,Tseq,TseqDegT,TseqFieldT);
end
if DoDBInfo
    Tinfo = DB([Tablebase 'Info']);
end
if DoDisp
%     Tseq = Assoc('','','');
%     TseqRaw = Assoc('','','');
%     TseqDegT = Assoc('','','');
%     TseqFieldT = Assoc('','','');
%     TseqRawNumBases = Assoc('','','');
%     Tinfo = Assoc('','','');
    HBListen.addFunDisp(hbSeq);
    HBListen.addFunDisp(hbHeader);
end
Fastapath = [Fastadir filesep Fastafile];
if DoSaveMat
    HBListen.addFunSaveMat(hbSeq,{[Fastapath '.' Tablebase 'Raw']; [Fastapath '.' Tablebase 'RawNumBases']; [Fastapath '.' Tablebase 'valNumBases']});
    HBListen.addFunSaveMat(hbHeader,{[Fastapath '.' Tablebase]; [Fastapath '.' Tablebase 'DegT']});
end
% if DoMakeBigAssoc
%     TseqRaw = TseqRaw + Assoc(row,col,val);
%     TseqRawNumBases = TseqRawNumBases + Assoc(row, colNumBases, valNumBases);
%     Tseq = Tseq + Assoc(row,col,val);
%     TseqDegT = TseqDegT + Assoc(col,colDeg,1); % SUM collisions
%     TseqFieldT = TseqFieldT + Assoc(col,colDeg,1); % SUM collisions
% end


%statTimePut = 0.0;
statNumSeqPut = 0;
statNumBasePut = 0;
statNumMetaPut = 0;
tic;
F = fopen(Fastapath, 'r');
nl = char(10);
Line = fgetl(F);
while ischar(Line)
    if Line(1) == '>'
        % Header Line - put previous header sequence into raw sequences table
        if DoPutRawSequence && hbSeqVal.BufPos > 0 %~strcmp(val,'') % If not the first header
            row = [SeqID nl];
            numBases = hbSeqVal.BufPos;
            statNumBasePut = statNumBasePut + numBases;
            statNumSeqPut = statNumSeqPut + 1;
            hbSeqVal.appendChars1(nl);
            valNumBases = sprintf('%d\n',numBases);
            hbSeq.appendChars3(row,hbSeqVal.getBufCurrent(1),valNumBases);
            hbSeqVal.clearBuffer();
        end

        if DoPutHeader
            [SeqID, Headerbody] = strtok(Line(2:end));
            Headerbody = Headerbody(2:end);
            
            
            
            [col, num_meta] = ProcessHeader(hbMeta,Headerbody);
            
            row = repmat([SeqID nl], 1, num_meta);
            statNumMetaPut = statNumMetaPut + num_meta;
            hbHeader.appendChars2(row,col);
        end
    else
        % Sequence Line - gather sequence in val
        hbSeqVal.appendChars1(Line);
    end
    Line = fgetl(F);
end
% Last sequence
if DoPutRawSequence && hbSeqVal.BufPos > 0
    row = [SeqID nl];
    numBases = hbSeqVal.BufPos;
    statNumBasePut = statNumBasePut + numBases;
    statNumSeqPut = statNumSeqPut + 1;
    hbSeqVal.appendChars1(nl);
    valNumBases = sprintf('%d\n',numBases);
    hbSeq.appendChars3(row,hbSeqVal.getBufCurrent(1),valNumBases);
    hbSeqVal.clearBuffer();
end
fclose(F);
%clear nl 

% Ingest anything remaining
hbSeq.clearBuffer();
hbHeader.clearBuffer();

% Stats
statTimePut = toc;


%col = sprintf('statTimePut|%09.1f\nstatNumSeqPut|%09d\nstatNumBasePut|%09d\nstatNumMetaPut|%09d\n',...
%    statTimePut,statNumSeqPut,statNumBasePut,statNumMetaPut);
%val = repmat(['1' nl], 1, statNum);
if DoDB
    statNum = 4;
    col = ['statTimePut' nl 'statNumSeqPut' nl 'statNumBasePut' nl 'statNumMetaPut' nl];
    val = [statTimePut statNumSeqPut statNumBasePut statNumMetaPut];
else
    statNum = 4;
    col = ['statTimeComputeSaveMat' nl 'statNumSeqPut' nl 'statNumBasePut' nl 'statNumMetaPut' nl];
    val = [statTimePut statNumSeqPut statNumBasePut statNumMetaPut];
end
row = repmat([Fastafile nl], 1, statNum);
Ainfo = num2str(Assoc(row,col,val));
if DoDBInfo
    put(Tinfo,Ainfo);
end
if DoSaveStats || DoDisp
    if DoSaveStats
        Assoc2CSV(Ainfo,nl,',',[Fastapath '.' Tablebase 'Info']);
    end
    if DoDisp
        display(Ainfo);
    end
end
% if Do___
%     Tinfo = Tinfo + Assoc(row,col,val);
% end
end


function [col, num_meta] = ProcessHeader(hbMeta,Headerbody)
    nl = char(10);
    % Special case: Exons
    [matchstart,matchend,~,~,tokenstring,~]=...
        regexp(Headerbody, ' Exons\[([\d\-\*\$\|]+)\]');
    if matchstart
        hbMeta.appendChars1(cell2mat(['Exons|',tokenstring{1}, nl]));
        num_meta = 1;
        Headerbody = [Headerbody(1:matchstart)  Headerbody(matchend+1:end)];
    else
        num_meta = 0;
    end

%{
%             % Special case: taxonomy
%             % taxopart|Viruses
%             % taxopart|Viruses; Pleth
%             % ...
%             TaxStart = strfind(Headerbody, '/taxonomy');
%             TaxEnd = TaxStart + 9;
%             TaxRest = Headerbody(TaxStart+11 : end);
%             TaxRest = strtok(TaxRest, '/');
%             Val1 = '';
%             Col1 = '';
%             tax_level = 1;
%             tax_collection = 'taxopart|'; % accumulate Viruses; ...
%             while numel(TaxRest)
%                 [TaxPart TaxRest] = strtok(TaxRest, ';'); % replace with textscan?
%                 TaxEnd = TaxEnd + numel(TaxPart) + 1;
%                 if TaxPart(end-2) == '.'
%                     TaxPart = TaxPart(1:end-2); % keep period
%                 else
%                     TaxPart = [TaxPart ';'];
%                 end
%                 tax_collection = [tax_collection TaxPart]
%                 Col1 = [Col1 strtrim(tax_collection) nl];
%                 %Val1 = [Val1 num2str(tax_level) nl];
%                 tax_level = tax_level + 1;
%             end
%             if tax_level > 1
%                 Row1 = repmat([SeqID nl], 1, tax_level-1);
%                 Val1 = repmat(['1' nl], 1, tax_level-1);
%                 if DoDB
%                     putTriple(Theader, Row1, Col1, Val1);
%                 else
%                     Theader = Theader + Assoc(Row1,Col1,Val1);
%                 end
%                 % Eliminates the taxonomy tag later on
%                 %Headerbody = [Headerbody(1:TaxStart-1) Headerbody(TaxEnd+1:end)];
%             end
%}

    while numel(Headerbody)
        [Metaentry, Headerbody] = strtok(Headerbody, '/');
        %[Metavar Metaval] = strtok(Metaentry, '=');
        Eqs = find(Metaentry == '=', 1, 'first');
        Startquote = false;
        if numel(Eqs)
            Metaentry(Eqs) = '|'; % only change first '=' (key-value)
            % Remove beginning and ending quotes if present - a tad messy
            if Metaentry(Eqs+1) == '"'
                Metaentry = [Metaentry(1:Eqs) Metaentry(Eqs+2:end)];
                Startquote = true;
            end
        else
            if Metaentry(Eqs+1) == '"'
                Metaentry = Metaentry(2:end);
                Startquote = true;
            end
            Metaentry = ['def|' Metaentry]; % no metaname; just a general description
        end

        % handle situation where '/' appears inside a quoted header entry 
        % like: '/def="Sapovirus Tamagawa River/Site5_a/Mar2004"'
        MetaentryDeblank = deblank(Metaentry);
        while Startquote && MetaentryDeblank(end) ~= '"'
            [Meta2, Headerbody] = strtok(Headerbody, '/');
            Metaentry = [Metaentry '/' Meta2];
            MetaentryDeblank = deblank(Metaentry);
        end
        Metaentry = MetaentryDeblank;

        if Metaentry(end) == '"'
            Metaentry = Metaentry(1:end-1);
            %             elseif Metaentry(end-1) == '"'
            %                 Metaentry = [Metaentry(1:end-2) Metaentry(end)];
        end
        Metasplitpos = find(Metaentry == '|', 1, 'first');
        Metaname = Metaentry(1:Metasplitpos-1);
        Metabody = Metaentry(Metasplitpos+1:end);
        % HANDLE SPECIAL CASES HERE %%%%%%%%
        % Change Metaname, Metabody to whatever you want.
        if strcmp('date',Metaname)
            Metabody = datestr(Metabody,'yyyy-mm-dd');
        elseif strcmp('protein_id',Metaname)
%             if ~strcmp(Metabody,SeqID)
%                 fprintf('Warning: SeqID %s does not match %s. Ignoring protein_id.',SeqID,Metaentry);
%             end
            continue
        end

        % %%%%%%%%
        Metaentry = [Metaname '|' Metabody nl];


        hbMeta.appendChars1(Metaentry);
        num_meta = num_meta + 1;
    end
    col = hbMeta.getBufCurrent(1);
    hbMeta.clearBuffer();
end
