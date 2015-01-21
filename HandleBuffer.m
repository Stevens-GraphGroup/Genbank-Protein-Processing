classdef HandleBuffer < handle
% Holds a buffer of data that will automatically call functions when it fills
% before restarting its buffer. Fixed size buffer, never cleared.
properties (SetAccess=private)
    % Vector; Raw Buffer.
    Buf@char %todo: make private
    % Scalar constant; max capacity of any single buffer
    BufCap %@uint64 
    % Vector; position of last data inserted
    BufPos
    % Free space remaining is bufCap-bufPos+1
    %FunClearBuf % function handle to call when buffer fills up.
    
    % Scalar; number of times buffer filled up & fired event (or manually fired)
    CountBufFull = 0; 
    
    % Scalar constant; number of buffers
    NumBuf
end

properties (Dependent) %SetAccess=immutable?
    % The number of free positions remaining in the buffer.
    BufFree;
end

events
    EvtBufFull
end

methods
    function hb = HandleBuffer(numbufs,cap)
    % Constructor to create numbufs buffer with capacity cap.
        hb.NumBuf = numbufs;
        hb.BufPos = zeros(numbufs,1);
        if ~isscalar(cap)
            error('cap must be scalar');
            %cap = repmat(cap,numbufs,1);
        end
        hb.Buf = repmat(blanks(cap),numbufs,1);
        hb.BufCap = cap;
        
        
    end
    
    function v = get.BufFree(this)
    % Vector return.
        v = this.BufCap-this.BufPos;
    end
    
    function v = getBufCurrent(this,i)
    % The current contents of buffer i.
        v = this.Buf(i,1:this.BufPos(i));
    end

    function appendChars1(this,data)
    % data should be a char string
        if (this.NumBuf ~= 1)
            error('HandleBuffer: Tried to append 1 data string but there are %d NumBuf',this.NumBuf);
        end
        numdata = numel(data);
        if this.BufFree < numdata
            if numdata > this.BufCap
                fprintf('Data of length %d is longer than BufCap %d: %s\n',numdata,this.BufCap,data(1:min(numdata,9)));
                return;
            end
            this.clearBuffer();
        end
        this.Buf(this.BufPos+1:this.BufPos+numdata) = data;
        this.BufPos = this.BufPos+numdata;
    end
    
    function appendChars2(this,data1,data2)
    % data should be a char string
        if (this.NumBuf ~= 2)
            error('HandleBuffer: Tried to append 2 data strings but there are %d NumBuf',this.NumBuf);
        end
        numdata = [numel(data1); numel(data2)];
        if any(this.BufFree < numdata)
            if any(numdata > this.BufCap)
                fprintf('Data 1 length %d; BufCap %d: %s...\n',numdata(1),this.BufCap,data1(1:min(numdata(1),9)));
                fprintf('Data 2 length %d; BufCap %d: %s...\n',numdata(2),this.BufCap,data2(1:min(numdata(2),9)));
                return;
            end
            this.clearBuffer();
        end
        this.Buf(1,this.BufPos(1)+1:this.BufPos(1)+numdata(1)) = data1;
        this.BufPos(1) = this.BufPos(1)+numdata(1);
        this.Buf(2,this.BufPos(2)+1:this.BufPos(2)+numdata(2)) = data2;
        this.BufPos(2) = this.BufPos(2)+numdata(2);
    end
    
    function appendChars3(this,data1,data2,data3)
    % data should be a char string
        if (this.NumBuf ~= 3)
            error('HandleBuffer: Tried to append 3 data strings but there are %d NumBuf',this.NumBuf);
        end
        numdata = [numel(data1); numel(data2); numel(data3)];
        if any(this.BufFree < numdata)
            if any(numdata > this.BufCap)
                fprintf('Data 1 length %d; BufCap %d: %s...\n',numdata(1),this.BufCap,data1(1:min(numdata(1),9)));
                fprintf('Data 2 length %d; BufCap %d: %s...\n',numdata(2),this.BufCap,data2(1:min(numdata(2),9)));
                fprintf('Data 3 length %d; BufCap %d: %s...\n',numdata(3),this.BufCap,data3(1:min(numdata(3),9)));
                return;
            end
            this.clearBuffer();
        end
        this.Buf(1,this.BufPos(1)+1:this.BufPos(1)+numdata(1)) = data1;
        this.BufPos(1) = this.BufPos(1)+numdata(1);
        this.Buf(2,this.BufPos(2)+1:this.BufPos(2)+numdata(2)) = data2;
        this.BufPos(2) = this.BufPos(2)+numdata(2);
        this.Buf(3,this.BufPos(3)+1:this.BufPos(3)+numdata(3)) = data3;
        this.BufPos(3) = this.BufPos(3)+numdata(3);
    end
    
    function clearBuffer(this)
    % increment CountBufFull, fire event, clear buffer
        this.CountBufFull = this.CountBufFull + 1;
        this.notify('EvtBufFull');
        this.BufPos(:) = 0;
    end
    
    % when buffer is full, functToCall will be called with two arguments:
    % 1) a reference to this HandleBuffer
    % 2) an EventData object with two fields: 
    %       Source: a cell array size 1 containing the HandleBuffer
    %       EventName: 'EvtBufFull'
    function ret = AddEvtBufFullHandler(HBuf,funcToCall)
        % do something with the data in HBuf
        ret = HBuf.addlistener('EvtBufFull',funcToCall);
    end

end


end