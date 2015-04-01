#include <Wire.h>

byte val = 0x02;    // Board ID (8)
int slave = 0x23;   // has to be an int.
byte count = 0;     // simple counter

void setup()
{
  Wire.begin(); // join i2c bus
  Serial.begin(9600);
}

void loop()
{
  Serial.println("Scan 3 registers");
  
  // Send CMD to Slave to read register.
  Wire.beginTransmission(0x23); // transmit to Slave. Have to do this each time.
  Wire.write(0);             // sends value byte
  Wire.endTransmission();     // stop transmitting
  delay(1);                  // need to give Slave time to fill ouput FIFO.
  
  // Issues a SLA_R request and triggers N reads before NACKing Slave.
  Wire.requestFrom(slave, 4);    // request N bytes from (int)slave

  // Flush buffer
  while(Wire.available())    // slave may send less than requested
  { 
    char c = Wire.read();    // receive a byte as character
    Serial.print(c, HEX);
    Serial.print(" ");
  }
  Serial.println("");
  delay(1);

  // Send CMD to Slave to read register.
  Wire.beginTransmission(0x23); // transmit to Slave
  Wire.write(2);             // sends value byte
  Wire.endTransmission();     // stop transmitting
  delay(1);                  // need to give Slave time to fill ouput FIFO.
  
  // Issues a SLA_R request and triggers N reads before NACKing Slave.
  Wire.requestFrom(slave, 12);    // request N bytes from (int)slave

  // Flush buffer
  while(Wire.available())    // slave may send less than requested
  { 
    char c = Wire.read();    // receive a byte as character
    Serial.print(c);
  }
  Serial.println("");
  delay(1);

  // Send CMD to Slave to read register.
  Wire.beginTransmission(0x23); // transmit to Slave
  Wire.write(3);             // sends value byte
  Wire.endTransmission();     // stop transmitting
  delay(1);                  // need to give Slave time to fill ouput FIFO.
  
  // Issues a SLA_R request and triggers N reads before NACKing Slave.
  Wire.requestFrom(slave, 16);    // request N bytes from (int)slave

  // Flush buffer
  while(Wire.available())    // slave may send less than requested
  { 
    char c = Wire.read();    // receive a byte as character
    Serial.print(c);
  }
  Serial.println("");
  Serial.println("");
  
  // Send CMD to Slave to set register. This could use an array for the data.
  Wire.beginTransmission(0x23); // transmit to Slave
  Wire.write(0x81);             // sends value byte
  Wire.write(count++);          // sends value byte
  Wire.endTransmission();       // stop transmitting
  
  delay(500);
}

