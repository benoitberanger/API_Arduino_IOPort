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
        end_of_msg_char  (1,:) char                                  = sprintf('\n');
        def_port_linux   (1,:) char                                  = '/dev/ttyACM0'
        def_port_windows (1,:) char                                  = '<<TO BE DETERMINED>>'
        def_baudrate     (1,1) double {mustBeInteger,mustBePositive} = 115200
        
    end
    
    methods
        
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
                self.isopen = true;
                fprintf('Device opened : %s \n', self.port);
            else
                error(self.errmsg);
            end
            
        end % function
        
        
        % -----------------------------------------------------------------
        function Close(self)
            if self.isopen
                IOPort('Close', self.ptr);
                fprintf('Device closed : %s \n', self.port);
            else
                warning('Device ALREADY closed.')
            end
        end % function
        
        
        % -----------------------------------------------------------------
        function Echo(self, message)
            assert(ischar(message) && length(message) < self.max_message_size, 'message must be char with length < %d', self.max_message_size)
            self.assert_isopen();
            [~   , t1, self.errmsg] = IOPort('Write', self.ptr, [message self.end_of_msg_char]);
            [data, t2, self.errmsg] = IOPort('Read' , self.ptr, 1, length(message)+2);
            self.lastmsg = message;
            if ~strcmp(message, char(data(1:end-2)))
                error('message sent and message received are different')
            else
                fprintf('took %1.3fms to send and receive the message : %s \n', (t2-t1)*1000, message)
            end
        end
        
    end % methods
    
end % classef
