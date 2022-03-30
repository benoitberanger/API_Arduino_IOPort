
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
    else if(cmd == "echo") {
      Serial.println(val);
    }
    else {
      Serial.println("WARNING:DELFALT:" + inputString);
    }

    // cleanup
    inputString    = "";
    stringComplete = false;
    action         = "";
    cmd            = "";
    val            = "";

  }

  /*
    // read the input on analog pin 0:
   // Convert the analog reading (which goes from 0 - 1023) to a voltage (0 - 5V):
   voltage_A0 = analogRead(A0) * (5.0 / 1023.0);
   // print out the value you read:
   Serial.print(voltage_A0, 3);
   Serial.print(voltage_A0+1,3);
   delay(1);
   */

}


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

    //    // add it to the inputString:
    //    inputString += inputChar;

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

boolean split_inputString() {
  boolean has_separtor = false;
  int position = -1;

  for(unsigned int idx=0; idx<inputString.length(); idx++ ) {
    if(inputString.charAt(idx) == separator) {
      position = idx;
      break;
    }
  }
  if(position == -1) {
    return false;
  }
  else {
    cmd = inputString.substring(0         ,position-1          );
    val = inputString.substring(position+1,inputString.length());
  }
}



