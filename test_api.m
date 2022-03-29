clear
clc
IOPort('CloseAll')

api = API_Arduino_IOPort();
api.Open();

api.Echo(repmat('a',[1 30]))

api.Close();
