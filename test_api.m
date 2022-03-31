clear
clc
IOPort('CloseAll')

api = API_Arduino_IOPort();
api.Open();

for i = 1 : 5
    api.Ping();
end

api.Echo('hello');
api.Echo('much_longer_messsage!');

channel = [0 1 2 3 4 5]; % index start at 0, 5 ADC on my model
for idx = 1 : length(channel)
    channelVect = channel(1) : channel(idx);
    [value, dt] = api.GetAnalog(channelVect);
    fprintf('took %1.3fms to fetch %d analog read \n', dt, length(channelVect))
end

api.Close();
