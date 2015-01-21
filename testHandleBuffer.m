%%
ARRMAX = 20;
ARR = blanks(20);
ARRpos = 1; % position of first free character.
% save the position of the last start

F = fopen('testHandleBuffer.txt','r');
line = fgetl(F);
while line ~= -1
    linesize = numel(line);
    if linesize > ARRMAX - ARRpos
        fprintf('%s|\n',ARR(1:ARRpos-1));
        ARRpos=1;
        if linesize > ARRMAX - ARRpos
            fprintf('TOO BIG (%d length): %s',linesize,line);
            line = fgetl(F);
            continue;
        end
    end
    ARR(ARRpos:ARRpos+linesize-1) = line;
    ARR(ARRpos+linesize)=',';
    ARRpos=ARRpos+linesize+1;
    line = fgetl(F);
end
fclose(F);


%% Now with HandleBuffer
hb = HandleBuffer(1,20);
%hb.AddEvtBufFullHandler(@(x,~) disp(x.BufCurrent));
HBListen.addFunDisp(hb);
HBListen.addFunSaveMat(hb,{'testfb'});

F = fopen('testHandleBuffer.txt','r');
line = fgetl(F);
while line ~= -1
    hb.appendChars1([line ',']);
    line = fgetl(F);
end
fclose(F);
hb.clearBuffer();
