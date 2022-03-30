classdef API_Arduino_IOPort < handle
    
    properties (SetAccess=protected)
        
        % set using methods
        port     char    = ''    % this is pointer
        baudrate double  = []    %
        
        % internal variables
        isopen   logical = false %
        status   char    = ''    % this is the current state of the API
        errmsg   char    = ''    % from IOPort
        ptr      double  = []    % pointer to the device
        lastmsg  char    = ''    % last message sent withe IOPort('Write',msg)
        
    end
    
    properties (Hidden, SetAccess=protected, GetAccess=protected)
        max_message_size (1,1) double {mustBeInteger,mustBePositive} = 32;
        separator        (1,:) char                                  = ':';
        end_of_msg_char  (1,:) char                                  = sprintf('\n');
        def_port_linux   (1,:) char                                  = '/dev/ttyACM0'
        def_port_windows (1,:) char                                  = '<<TO BE DETERMINED>>'
        def_baudrate     (1,1) double {mustBeInteger,mustBePositive} = 115200
        
    end
    
    methods (Access=public)
        
        % -----------------------------------------------------------------
        %                           Constructor
        % -----------------------------------------------------------------
        function self = API_Arduino_IOPort(varargin)
            % pass
        end % function
        
        function assert_isopen(self)
            assert(self.isopen, 'device not opened')
        end % function
        
        
        % -----------------------------------------------------------------
        function Open(self, port, baudrate)
            
            if self.isopen
                error('device already opened')
            end
            
            % baudrate
            if nargin < 3
                self.baudrate = self.def_baudrate;
            else
                self.baudrate = baudrate;
            end
            
            % port
            if nargin < 2
                if IsLinux
                    self.port = self.def_port_linux;
                end
                if IsWindows
                    self.port = self.def_port_windows;
                end
            else
                self.port = port;
            end
            
            [self.ptr, self.errmsg] = IOPort('OpenSerialPort', self.port, sprintf('BaudRate=%d', self.baudrate));
            if isempty(self.errmsg)
                self.FlushPurge();
                self.isopen = true;
                self.status = 'ready';
                fprintf('Device opened : %s \n', self.port);
            else
                self.status = 'open:error';
                error(self.errmsg);
            end
            
        end % function
        
        
        % -----------------------------------------------------------------
        function Close(self)
            if self.isopen
                self.FlushPurge();
                IOPort('Close', self.ptr);
                fprintf('Device closed : %s \n', self.port);
            else
                warning('Device ALREADY closed.')
            end
            self.status = 'closed';
        end % function
        
        
        % -----------------------------------------------------------------
        function Ping(self)
            self.assert_isopen();
            self.FlushPurge();
            
            message = 'ping';
            self.lastmsg = message;
            [~   , t1, self.errmsg] = IOPort('Write', self.ptr, [self.lastmsg self.end_of_msg_char]);
            [data, t2, self.errmsg] = IOPort('Read' , self.ptr, 1, length('ok')+2);
            if ~strcmp('ok', char(data(1:end-2)))
                self.status = 'ping:error';
                warning('Ping failed')
            else
                self.status = 'ping:ok';
                fprintf('Ping took %1.3fms \n', (t2-t1)*1000)
            end
        end
        
        % -----------------------------------------------------------------
        function Echo(self, message)
            self.assert_isopen();
            self.FlushPurge();
            
            assert(ischar(message), 'message must be char')
            true_message = sprintf('echo%s%s', self.separator, message);
            
            assert(length(true_message) < self.max_message_size-length(['echo' self.separator]), 'message must be char with length < %d', self.max_message_size)
            
            self.lastmsg = true_message;
            [~   , t1, self.errmsg] = IOPort('Write', self.ptr, [self.lastmsg self.end_of_msg_char]);
            [data, t2, self.errmsg] = IOPort('Read' , self.ptr, 1, length(true_message)+2);
            char(data)
            if ~strcmp(true_message, char(data(1:end-2)))
                self.status = 'echo:error';
                warning('message sent and message received are different')
            else
                self.status = 'echo:ok';
                fprintf('took %1.3fms to send and receive the message : %s \n', (t2-t1)*1000, true_message)
            end
        end
        
    end % methods
    
    methods (Access=protected)
        
        % -----------------------------------------------------------------
        function Purge(self)
            IOPort('Purge', self.ptr);
        end
        
        % -----------------------------------------------------------------
        function Flush(self)
            IOPort('Flush', self.ptr);
        end
        
        % -----------------------------------------------------------------
        function FlushPurge(self)
            IOPort('Flush', self.ptr);
            IOPort('Purge', self.ptr);
        end
        
    end % methods
    
end % classef
