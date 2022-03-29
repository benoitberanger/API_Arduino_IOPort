clear
clc
IOPort('CloseAll')

[handle, errmsg] = IOPort('OpenSerialPort', '/dev/ttyACM0', 'BaudRate=115200');
% IOPort('Read', handle);
% IOPort('Flush', handle);
% IOPort('Purge', handle);
% while ~KbCheck
%     if IOPort('BytesAvailable',handle) > 0
%         [data] = IOPort('Read', handle, 1, 5*2);
%         fprintf('%s %s\n', char(data(1:5)), char(data(6:10)))
% %         [data] = IOPort('Read', handle, 1, 10);
% %         fprintf('%s\n', char(data))
%     end
% end

msg = 'Hello world';
% msg = 'say_ok';

% val=IOPort('BytesAvailable',handle);
% if val > 0; IOPort('Read',handle); end
% IOPort('Flush',handle);


for i = 1 : 10
    tic
    IOPort('Write', handle, sprintf('%s\n', msg));
    data = IOPort('Read', handle, 1, length(msg)+2);
    char(data)
%     data = IOPort('Read', handle);
%     char(data)
    toc*1000
end

IOPort('Close', handle);
