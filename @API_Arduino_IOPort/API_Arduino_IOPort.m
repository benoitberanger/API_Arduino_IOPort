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
        max_message_size (1,1) double {mustBeInteger,mustBePositive} = 128;
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
        
        % -----------------------------------------------------------------
        % - Assert_isopen
        % -----------------------------------------------------------------
        function Assert_isopen(self)
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
        function varargout = Ping(self)
            self.Assert_isopen();
            self.FlushPurge();
            
            message = 'ping';
            self.lastmsg = message;
            
            [~   , t1, self.errmsg] = IOPort('Write', self.ptr, [self.lastmsg self.end_of_msg_char]);
            [data, t2, self.errmsg] = IOPort('Read' , self.ptr, 1, length('ok'));
            
            dt = (t2-t1)*1000;
            
            if ~strcmp('ok', char(data))
                self.status = 'ping:error';
                if nargout == 0
                    warning('Ping failed')
                else
                    varargout{1} = false;
                    varargout{2} = dt;
                end
            else
                self.status = 'ping:ok';
                if nargout == 0
                    fprintf('Ping took %1.3fms \n', dt)
                else
                    varargout{1} = true;
                    varargout{2} = dt;
                end
            end
            
        end % function
        
        % -----------------------------------------------------------------
        % - Echo
        % -----------------------------------------------------------------
        function varargout = Echo(self, message)
            self.Assert_isopen();
            self.FlushPurge();
            
            assert(ischar(message), 'message must be char')
            true_message = sprintf('echo%s%s', self.separator, message);
            assert(length(true_message) < self.max_message_size-length(['echo' self.separator]), 'message must be char with length < %d', self.max_message_size)
            self.lastmsg = true_message;
            
            [~   , t1, self.errmsg] = IOPort('Write', self.ptr, [self.lastmsg self.end_of_msg_char]);
            [data, t2, self.errmsg] = IOPort('Read' , self.ptr, 1, length(message));
            
            dt = (t2-t1)*1000;
            
            if ~strcmp(message, char(data))
                self.status = 'echo:error';
                if nargout == 0
                    warning('message sent and message received are different')
                else
                    varargout{1} = false;
                    varargout{2} = dt;
                end
            else
                self.status = 'echo:ok';
                if nargout == 0
                    fprintf('took %1.3fms to send ''%s'' and receive ''%s'' \n', dt, true_message, message)
                else
                    varargout{1} = true;
                    varargout{2} = dt;
                end
            end
            
        end % function
        
        % -----------------------------------------------------------------
        % - GetAnalog
        % -----------------------------------------------------------------
        function [value, dt] = GetAnalog(self, channel)
            self.Assert_isopen();
            self.FlushPurge();
            
            assert(isnumeric(channel) & all(round(channel)==channel) & all(abs(channel)==channel),...
                'channel must be a positive integer')
            true_message = sprintf('adc%s%s', self.separator, num2str(channel,'%d')); % [0 1 2] => '012'
            self.lastmsg = true_message;
            
            [~   , t1, self.errmsg] = IOPort('Write', self.ptr, [self.lastmsg self.end_of_msg_char]);
            [data, t2, self.errmsg] = IOPort('Read' , self.ptr, 1 , 2*length(channel)); % 10 bits will be sent using 2 bytes (16 bits)
            
            value = self.byte2volt(data,length(channel));
            dt = (t2-t1)*1000;
            
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
        function out = byte2volt( datain, nChan )
            
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
            % out =
            %        2.4682
            
            out = zeros(1, nChan);
            
            bin_vstack = dec2bin(datain,8); % 1 byte = 8 bit
            for idx = 1 : nChan
                
                bin_line = reshape(bin_vstack([idx*2-1 idx*2],:)',1,[]); % reshape the stack into line
                integer_adc = bin2dec(bin_line);                         % convert the binary into integer
                out(idx) = integer_adc * 5/1023;                         % Arduino ADC is 10bits so 1024 values, Vin = 5 Volts
                
            end
            
            
        end % function
        
    end
    
end % classef
