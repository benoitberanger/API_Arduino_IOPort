#define BAUDRATE   115200 // 300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200
#define BUFFERSIZE    128 // make sure to not overflow the input string
#define SEPARATOR     ':' // <cmd><sep><val> such as 'echo:say_ok'

/*************************************************************************/
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
  Serial.begin(BAUDRATE);

  inputString.reserve(BUFFERSIZE);

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

    // check inputString format
    if (split_inputString()) {
      action = cmd;
    }
    else {
      action = inputString;
    }

    // ACTION switch

    if(action == "ping") {
      Serial.print("ok");
    }

    else if(action == "echo") {
      Serial.print(val);
    }

    else if(action == "adc") {
      for(int idx=0; idx<val.length(); idx++) {
        unsigned int adc = performADC(val.charAt(idx));
        unsigned char bytes[2];    // byte buffer
        uint_to_char2(adc, bytes); // fill 10bit message into 2 bytes buffer
        Serial.write(bytes, 2);    // send buffer
      }
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

    // if the incoming character is a newline, set a flag so the main loop can
    // do something about it:
    if (inputChar == '\n') {
      stringComplete = true;
    }
    else {

      // check if string is not too long
      if (inputString.length() >= BUFFERSIZE-1) {
        inputString = ""; // flush it
      }

      // add it to the inputString:
      inputString += inputChar;

    }
  }
}

/*************************************************************************/
// if the inputString has this format : cmd:val => extract 'cmd' & 'val'
bool split_inputString() {
  int position = -1;

  // find if the SEPARATOR is inside the inputString
  // there is builtin function/method for the, so need to code it...
  for(unsigned int idx=0; idx<inputString.length(); idx++ ) {
    if(inputString.charAt(idx) == SEPARATOR) {
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
unsigned int performADC(const char channel) {
  if      (channel == '0') {
    return analogRead(A0);
  }
  else if (channel == '1') {
    return analogRead(A1);
  }
  else if (channel == '2') {
    return analogRead(A2);
  }
  else if (channel == '3') {
    return analogRead(A3);
  }
  else if (channel == '4') {
    return analogRead(A4);
  }
  else if (channel == '5') {
    return analogRead(A5);
  }
  else {
    return 0;
  }
}

/*************************************************************************/
// adc is 10bits, and 1*8<10<2*8 => we will send 2 bytes
// adapted from https://stackoverflow.com/questions/3784263/converting-an-int-into-a-4-byte-char-array-c
void uint_to_char2(const unsigned int adc, unsigned char bytes[]) {
  bytes[0] = (adc >> 8) & 0xFF;
  bytes[1] = adc        & 0xFF;
}





