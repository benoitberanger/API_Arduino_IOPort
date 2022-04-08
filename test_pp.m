%% Init

clear
clc

assert( ~isempty(which('IOPort')), '"IOPort" not found : check Psychtooblox installation => http://psychtoolbox.org/' )

% just to make sure all devices are closed
% only useful in case case of crash or development
IOPort('CloseAll')


%% Open

api = API_Arduino_IOPort(); % create empy object
api.Open();


%% Send message

for message = 1 : 255
    
    api.SendByte(message);
    WaitSecs(0.001);
    api.SendByte(0);
    WaitSecs(0.001);
    
end


%% Cleanup

api.Close();
