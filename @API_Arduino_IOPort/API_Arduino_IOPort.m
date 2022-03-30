classdef API_Arduino_IOPort < handle
    
    %======================================================================
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
    
    %======================================================================
    properties (Hidden, SetAccess=protected, GetAccess=protected)
        max_message_size (1,1) double {mustBeInteger,mustBePositive} = 32;
        separator        (1,:) char                                  = ':';
        end_of_msg_char  (1,:) char                                  = sprintf('\n');
        def_port_linux   (1,:) char                                  = '/dev/ttyACM0'
        def_port_windows (1,:) char                                  = '<<TO BE DETERMINED>>'
        def_baudrate     (1,1) double {mustBeInteger,mustBePositive} = 115200
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %======================================================================
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
        % - Open
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
        % - Close
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
        % - Ping
        % -----------------------------------------------------------------
        function success = Ping(self)
            self.assert_isopen();
            self.FlushPurge();
            
            message = 'ping';
            self.lastmsg = message;
            
            [~   , t1, self.errmsg] = IOPort('Write', self.ptr, [self.lastmsg self.end_of_msg_char]);
            [data, t2, self.errmsg] = IOPort('Read' , self.ptr, 1, length('ok'));
            
            if ~strcmp('ok', char(data))
                self.status = 'ping:error';
                warning('Ping failed')
                success = false;
            else
                self.status = 'ping:ok';
                fprintf('Ping took %1.3fms \n', (t2-t1)*1000)
                success = true;
            end
            
        end % function
        
        % -----------------------------------------------------------------
        % - Echo
        % -----------------------------------------------------------------
        function success = Echo(self, message)
            self.assert_isopen();
            self.FlushPurge();
            
            assert(ischar(message), 'message must be char')
            true_message = sprintf('echo%s%s', self.separator, message);
            assert(length(true_message) < self.max_message_size-length(['echo' self.separator]), 'message must be char with length < %d', self.max_message_size)
            self.lastmsg = true_message;
            
            [~   , t1, self.errmsg] = IOPort('Write', self.ptr, [self.lastmsg self.end_of_msg_char]);
            [data, t2, self.errmsg] = IOPort('Read' , self.ptr, 1, length(message));
            
            if ~strcmp(message, char(data))
                self.status = 'echo:error';
                warning('message sent and message received are different')
                success = false;
            else
                self.status = 'echo:ok';
                fprintf('took %1.3fms to send ''%s'' and receive ''%s'' \n', (t2-t1)*1000, true_message, message)
                success = true;
            end
            
        end % function
        
        % -----------------------------------------------------------------
        % - GetAnalog
        % -----------------------------------------------------------------
        function value = GetAnalog(self, channel)
            self.assert_isopen();
            self.FlushPurge();
            
            assert(isnumeric(channel) & isscalar(channel) & round(channel)==channel & abs(channel)==channel,...
                'channel must be a positive integer')
            true_message = sprintf('adc%s%d', self.separator, channel);
            self.lastmsg = true_message;
            
            [~   , t1, self.errmsg] = IOPort('Write', self.ptr, [self.lastmsg self.end_of_msg_char]);
            [data, t2, self.errmsg] = IOPort('Read' , self.ptr, 1 , 2); % 10 bits will be sent using 2 bytes (16 bits)
            
            value = self.byte2volt(data);
            
        end
        
        
    end % methods
    
    %======================================================================
    methods (Access=protected)
        
        % -----------------------------------------------------------------
        % - Purge
        % -----------------------------------------------------------------
        function Purge(self)
            IOPort('Purge', self.ptr);
        end % function
        
        % -----------------------------------------------------------------
        % - Flush
        % -----------------------------------------------------------------
        function Flush(self)
            IOPort('Flush', self.ptr);
        end % function
        
        % -----------------------------------------------------------------
        % - FlushPurge
        % -----------------------------------------------------------------
        function FlushPurge(self)
            IOPort('Flush', self.ptr);
            IOPort('Purge', self.ptr);
        end % function
        
    end % methods
    
    %======================================================================
    methods (Static, Access=protected)
        
        % -----------------------------------------------------------------
        % - byte2volt
        % -----------------------------------------------------------------
        function out = byte2volt( in )
            
            % in =
            %      1   249
            % bin_vstack =
            %   2×8 char array
            %     '00000001'
            %     '11111001'
            % bin_line =
            %     '0000000111111001'
            % integer_adc =
            %    505
            % voltage =
            %        2.4682
            % out =
            %        2.4682
            
            bin_vstack = dec2bin(in,8);           % 1 byte = 8 bin
            bin_line = reshape(bin_vstack',1,[]); % reshape the stack into line
            integer_adc = bin2dec(bin_line);      % convert the binary into integer
            out = integer_adc * 5/1023;           % Arduino ADC is 10bits so 1024 values, Vin = 5 Volts
            
        end % function
        
    end
    
end % classef
