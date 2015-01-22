classdef HBListen
% Methods to react to EvtBufFull- the event that a HandleBuffer fills up.
%%
methods (Static)
    function ret = addFunDisp(hb)
        ret = hb.AddEvtBufFullHandler(@HBListen.funDisp);
    end
end
methods (Static,Access=private)
    function funDisp(hb,~)
    % Display all the buffers when full.
        for i = 1:hb.NumBuf
            fprintf('Dump #%2d, Buffer %2d, Length %2d: %s\n',hb.CountBufFull,i,hb.BufPos(i),hb.getBufCurrent(i));
        end
    end
end

%%
methods (Static)
    function ret = addFunSaveMat(hb,filebase)
    % Save buffer fill-ups to separate .mat files.
    % Pass a cell array of strings of length NumBuf as filebase.
    % Ex. {'blah.row'; 'blah.col'} will save files
    %   'blah.row.mat.1', 'blah.col.mat.1', 'blah.row.mat.2', 'blah.col.mat.2', ...
        if ~iscell(filebase) || size(filebase,1) ~= hb.NumBuf
            error('Please pass a NumBuf x 1 filebase cell array of strings.');
        end
        ret = hb.AddEvtBufFullHandler(HBListen.makeFunSaveMat(filebase));
    end
end
methods (Static,Access=private)
    function ret = makeFunSaveMat(filebase)
        ret = @funSaveMat;
        function funSaveMat(hb,~)
            
            % This copies data. Alternative is saving the hb object directly.
            for i = 1:hb.NumBuf
                buf = hb.getBufCurrent(i); %#ok<NASGU>
                save([filebase{i} '.mat.' num2str(hb.CountBufFull)], 'buf');
            end
        end
    end
end


%%
methods (Static)
    function ret = addFunPutDB_Seq(hb,TseqRaw,TseqRawNumBases)
        ret = hb.AddEvtBufFullHandler(HBListen.makeFunPutDB_Seq(TseqRaw,TseqRawNumBases));
    end
end
methods (Static,Access=private)
    function ret = makeFunPutDB_Seq(TseqRaw,TseqRawNumBases)
        ret = @funPutDB_Seq;
        function funPutDB_Seq(hb,~)
            row = hb.getBufCurrent(1);
            if isempty(row)
                return
            end
            sep = row(end);
            numseq = nnz(row==sep);
            col = repmat(['seq' sep],1,numseq);
            val = hb.getBufCurrent(2);
            putTriple(TseqRaw, row,col,val);
            
            colNumBases = repmat(['num' sep],1,numseq);
            valNumBases = hb.getBufCurrent(3);
            putTriple(TseqRawNumBases, row,colNumBases,valNumBases);
        end
    end
end


methods (Static)
    function ret = addFunPutDB_Header(hb,Tseq,TseqDegT,TseqFieldT)
        ret = hb.AddEvtBufFullHandler(HBListen.makeFunPutDB_Header(Tseq,TseqDegT,TseqFieldT));
    end
end
methods (Static,Access=private)
    function ret = makeFunPutDB_Header(Tseq,TseqDegT,TseqFieldT)
        ret = @funPutDB_Header;
        function funPutDB_Header(hb,~)
            row = hb.getBufCurrent(1);
            if isempty(row)
                return
            end
            sep = row(end);
            nummeta = nnz(row==sep);
            col = hb.getBufCurrent(2);
            val = repmat(['1' sep],1,nummeta);
            putTriple(Tseq, row,col,val);
            
            % pre-summing degree table
            Aorig = Assoc(col,row,1,@sum); % sums together columns with the same name
            Anum = putCol(sum(Aorig,2),['deg' char(10)]);
            A2 = num2str(Anum);
            put(TseqDegT,A2);
            
            % pre-summing field table
            [r, c, v] = find(Anum);
            r = Str2mat(r);
            for i=1:size(r,1)
                idx = find(r(i,:)=='|',1,'first');
                r(i,idx) = sep;
                r(i,idx+1:end) = char(0);
            end
            r = Mat2str(r);
            Anew = Assoc(r,c,v,@sum); % sums together columns with the same name
            put(TseqFieldT,num2str(Anew));
            %not as efficient alternative: colDeg = repmat(['deg' sep],1,nummeta);
        end
    end
end





end