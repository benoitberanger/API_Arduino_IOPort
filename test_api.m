clear
clc
IOPort('CloseAll')

api = API_Arduino_IOPort();
api.Open();
WaitSecs(0.100);

for i = 1 : 10
    
    api.Ping();
    
end

for i = 1 : 10
    
    api.Echo(repmat('a',[1 10]))
    
end


api.Close();
