clear
clc
IOPort('CloseAll')

api = API_Arduino_IOPort();
api.Open();

for i = 1 : 5
    api.Ping();
end

api.Echo('hello')
api.Echo('much_longer_messsage')

api.Close();
