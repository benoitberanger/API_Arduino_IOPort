
/*************************************************************************/
// paramters
const long         baudrate       = 115200; // 300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200
const unsigned int bufferSize     = 32;     // make sure to not overflow the input string
const char         separator      = ':';    // <cmd><sep><val> such as 'echo:say_ok'

// variables
float              voltage_A0     = 0;      // voltage ADC A0
String             inputString    = "";     // a String to hold incoming data
bool               stringComplete = false;  // whether the string is complete
String             action         = "";     // this is the action the loop() function will perform
String             cmd            = "";     // command == action to execute when using a paramter
String             val            = "";     // value tu use foe the "cammand" == action

/*************************************************************************/
// the setup routine runs once when you press reset:
void setup() {

  // initialize serial communication at <badrate> bits per second:
  Serial.begin(baudrate);

  //inputString.reserve(bufferSize);

  // wait for serial port to connect. Needed for native USB port only
  while (!Serial) {
    ;
  }

}

/*************************************************************************/
// the loop routine runs over and over again forever:
void loop() {

  // fetch new "action" & clean string buffer
  if (stringComplete) {

    if (split_inputString()) {
      action = cmd;
    }
    else {
      action = inputString;
    }

    if(action == "ping") {
      Serial.println("ok");
    }
    else if(action == "echo") {
      Serial.println(val);
    }
    else if(action == "adc") {
      unsigned int adc = performADC(val);
      unsigned char bytes[2];
      uint_to_char2(adc, bytes);
      Serial.write(bytes, 2);
    }
    else {
      Serial.println("ERROR");
    }

    // cleanup
    inputString    = "";
    stringComplete = false;
    action         = "";
    cmd            = "";
    val            = "";

  }

}

/*************************************************************************/
/*
    SerialEvent occurs whenever a new data comes in the hardware serial RX. This
 routine is run between each time loop() runs, so using delay inside loop can
 delay response. Multiple bytes of data may be available.
 */
void serialEvent() {
  while (Serial.available()) {
    // get the new byte:
    char inputChar = (char)Serial.read();

    // check if string is not too long
    if (inputString.length() >= bufferSize) {
      inputString = ""; // flush it
    }

    // if the incoming character is a newline, set a flag so the main loop can
    // do something about it:
    if (inputChar == '\n') {
      stringComplete = true;
    }
    else {
      // add it to the inputString:
      inputString += inputChar;
    }
  }
}

/*************************************************************************/
// if the inputString has this format : cmd:val => extract 'cmd' & 'val'
bool split_inputString() {
  int position = -1;

  // find if the separator is inside the inputString
  for(unsigned int idx=0; idx<inputString.length(); idx++ ) {
    if(inputString.charAt(idx) == separator) {
      position = idx;
      break;
    }
  }

  if(position == -1) { // not found
    return false;
  }
  else { // found it, then extract cmd & val
    cmd = inputString.substring(0         ,position            );
    val = inputString.substring(position+1,inputString.length());
    return true;
  }

}

/*************************************************************************/
unsigned int performADC(const String channel) {
  if (channel == "0") {
    return analogRead(A0);
  }
  else if (channel == "0") {
    return analogRead(A0);
  }
  else if (channel == "1") {
    return analogRead(A1);
  }
  else if (channel == "2") {
    return analogRead(A2);
  }
  else if (channel == "3") {
    return analogRead(A3);
  }
  else if (channel == "4") {
    return analogRead(A4);
  }
  else if (channel == "5") {
    return analogRead(A5);
  }
  else {
    return 0;
  }
}

/*************************************************************************/
void uint_to_char2(const unsigned int adc, unsigned char bytes[]) {
  bytes[0] = (adc >> 8) & 0xFF;
  bytes[1] = adc & 0xFF;
}
