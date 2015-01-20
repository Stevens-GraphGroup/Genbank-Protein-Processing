classdef HandleBuffer < handle
% Holds a buffer of data that will automatically call functions when it fills
% before restarting its buffer. Fixed size buffer, never cleared.
properties (SetAccess=private)
    Buf@char
    BufCap %@uint64
    BufPos = 0; % position of last data inserted
    % Free space remaining is bufCap-bufPos+1
    %FunClearBuf % function handle to call when buffer fills up.
end

properties (Dependent) %SetAccess=immutable?
    BufFree;
    BufCurrent;
end

events
    EvtBufFull
end

methods
    % Constructor to create buffer with size
    function hb = HandleBuffer(cap)
        hb.BufCap = cap;
        hb.Buf = blanks(cap);
    end
    
    function v = get.BufFree(this)
        v = this.BufCap-this.BufPos;
    end
    
    function v = get.BufCurrent(this)
        v = this.Buf(1:this.BufPos);
    end

    % data should be a char string.
    function appendChars(this,data)
        % notify event if EvtBufFull before clearing Buf
        numdata = numel(data);
        if this.BufFree < numdata
            if numdata > this.BufCap
                fprintf('Data of length %d is longer than BufCap %d: %s\n',numdata,this.BufCap,data);
                return;
            end
            this.clearBuffer();
        end
        this.Buf(this.BufPos+1:this.BufPos+numdata) = data;
        this.BufPos = this.BufPos+numdata;
    end
    
    function clearBuffer(this)
        % notify
        this.notify('EvtBufFull');
        % clear buffer
        this.BufPos = 0;
    end
    
    % when buffer is full, functToCall will be called with two arguments:
    % 1) a reference to this HandleBuffer
    % 2) an EventData object with two fields: 
    %       Source: a cell array size 1 containing the HandleBuffer
    %       EventName: 'EvtBufFull'
    function AddEvtBufFullHandler(HBuf,funcToCall)
        % do something with the data in HBuf
        HBuf.addlistener('EvtBufFull',funcToCall);
    end

end


end