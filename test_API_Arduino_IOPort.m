%% Init

clear
clc

assert( ~isempty(which('IOPort')), '"IOPort" not found : check Psychtooblox installation => http://psychtoolbox.org/' )

% just to make sure all devices are closed
% only useful in case case of crash or development 
IOPort('CloseAll')


%% Test

api = API_Arduino_IOPort(); % create empy object
api.Open();

% do several Pings : Arduino may take some time to be fully initialized
for i = 1 : 5
    api.Ping();
end

channel = [0 1 2 3 4 5]; % index start at 0, and there are 5 ADC on my model from A0 to A5
for idx = 1 : length(channel)
    channelVect = channel(1) : channel(idx); % to get several channels (if needed) in a single command
    [value, dt] = api.GetAnalog(channelVect);
    fprintf('took %1.3fms to fetch %d analog read \n', dt, length(channelVect))
end

% This is juste a "demo" command.
% If someone wants to add a feature, the Echo part on the cpp code is a good start.
api.Echo('hello');
api.Echo('much_longer_messsage!');

% cleanup
api.Close();
