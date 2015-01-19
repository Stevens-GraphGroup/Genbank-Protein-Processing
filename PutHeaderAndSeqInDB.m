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

% 2015-01-18: Eliminated taxopart; just keep full taxonomy.
% 2015-01-18: Parsed date and reversed to format "03-JUL-2010" => '2010-07-03'
% 2015-01-18: Fixed '/' inside quotes in '/def="..."'
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
        deleteForce(TseqDegT);
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
else
    Tseq = Assoc('','','');
    TseqRaw = Assoc('','','');
    TseqDegT = Assoc('','','');
    TseqFieldT = Assoc('','','');
    TseqRawNumBases = Assoc('','','');
    Tinfo = Assoc('','','');
end

%statTimePut = 0.0;
statNumSeqPut = 0;
statNumBasePut = 0;
statNumMetaPut = 0;
tic;

F = fopen([Fastadir filesep Fastafile], 'r');
nl = char(10);
Line = fgetl(F);
val = '';
while ischar(Line)
    if Line(1) == '>'
        % Header Line - put previous header sequence into raw sequences table
        if DoPutRawSequence && ~strcmp(val,'') % If not the first header
            row = [SeqID nl];
            col = ['seq' nl];
            colNumBases = ['num' nl];
            numBases = numel(val);
            statNumBasePut = statNumBasePut + numBases;
            statNumSeqPut = statNumSeqPut + 1;
            val = [val nl];
            valNumBases = sprintf('%d\n',numBases);
            if DoDB
                putTriple(TseqRaw, row, col, val);
                putTriple(TseqRawNumBases, row, colNumBases, valNumBases); % discount newline
            else
                TseqRaw = TseqRaw + Assoc(row,col,val);
                TseqRawNumBases = TseqRawNumBases + Assoc(row, colNumBases, valNumBases);
            end
        end
        if DoPutHeader
            [SeqID, Headerbody] = strtok(Line(2:end));
            Headerbody = Headerbody(2:end);
            col = '';
            colField = '';
            num_meta = 0;
            
            % Special case: Exons
            [matchstart,matchend,tokenindices,matchstring,tokenstring,tokenname]=...
                regexp(Headerbody, ' Exons\[([\d\-\*\$\|]+)\]');
            if matchstart
                col = cell2mat(['Exons|',tokenstring{1}, nl]);
                num_meta = num_meta + 1;
                Headerbody = [Headerbody(1:matchstart)  Headerbody(matchend+1:end)];
            end
            
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
                    if ~strcmp(Metabody,SeqID)
                        fprintf('Warning: SeqID %s does not match %s. Ignoring protein_id.',SeqID,Metaentry);
                    end
                    continue
                end
                
                % %%%%%%%%
                Metaentry = [Metaname '|' Metabody];
                
                
                col = [col Metaentry nl];
                colField = [colField Metaname nl];
                num_meta = num_meta + 1;
            end
            
            row = repmat([SeqID nl], 1, num_meta);
            colDeg = repmat(['deg' nl], 1, num_meta);
            val = repmat(['1' nl], 1, num_meta);
            statNumMetaPut = statNumMetaPut + num_meta;
            %         if strcmp(class(col),'cell')
            %             col = col{1};
            %         end
            if DoDB
                putTriple(Tseq, row, col, val);
                putTriple(TseqDegT, col, colDeg, val);
                putTriple(TseqFieldT, colField, colDeg, val);
            else
                Tseq = Tseq + Assoc(row,col,val);
                TseqDegT = TseqDegT + Assoc(col,colDeg,1); % SUM collisions
                TseqFieldT = TseqFieldT + Assoc(col,colDeg,1); % SUM collisions
            end
            val = '';
        end
    else
        % Sequence Line - gather sequence in val
        val = [val Line];
    end
    Line = fgetl(F);
end
% Last sequence
if DoPutRawSequence && ~strcmp(val,'')
    row = [SeqID nl];
    col = ['seq' nl];
    colNumBases = ['num' nl];
    numBases = numel(val);
    statNumBasePut = statNumBasePut + numBases;
    statNumSeqPut = statNumSeqPut + 1;
    val = [val nl];
    valNumBases = sprintf('%d\n',numBases);
    if DoDB
        putTriple(TseqRaw, row, col, val);
        putTriple(TseqRawNumBases, row, colNumBases, valNumBases); % discount newline
    else
        TseqRaw = TseqRaw + Assoc(row,col,val);
        TseqRawNumBases = TseqRawNumBases + Assoc(row, colNumBases, valNumBases);
    end
end
fclose(F);
%clear nl 
statTimePut = toc;
statNum = 4;
row = repmat([Fastafile nl], 1, statNum);
col = sprintf('statTimePut|%09.1f\nstatNumSeqPut|%09d\nstatNumBasePut|%09d\nstatNumMetaPut|%09d\n',...
    statTimePut,statNumSeqPut,statNumBasePut,statNumMetaPut);
val = repmat(['1' nl], 1, statNum);
if DoDB
    putTriple(Tinfo,row,col,val);
else
    Tinfo = Tinfo + Assoc(row,col,val);
end