#define BAUDRATE   115200 // 300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200

/*************************************************************************/
// the setup routine runs once when you press reset:
void setup() {

  // initialize serial communication at <badrate> bits per second:
  Serial.begin(BAUDRATE);

  // set the digital pin as output:
  for (int pin=0; pin<10; pin++) {
    pinMode(pin+2, OUTPUT);
    digitalWrite(pin+2, LOW);
  }

  // wait for serial port to connect. Needed for native USB port only
  while (!Serial) {
    ;
  }

  // make sure the buffer is empty
  while (Serial.available() > 0) {
    Serial.read();
  }

}

/*************************************************************************/
// the loop routine runs over and over again forever:
void loop() {

  while (Serial.available() > 0) {
    byte rx = Serial.read();

    for (int pin=0; pin<10; pin++) {
      if(rx & (1 << pin)) { // check if bit up active in the byte
        digitalWrite(pin+2, HIGH);
      } 
      else {
        digitalWrite(pin+2, LOW);
      };
    }

  }

}

