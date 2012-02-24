#include <Wire.h>
#include "RTClib.h"
#include <SD.h>


/*
  Thien-Bach Huynh 2/24/2012
  Radicalcakes
  Take this burrito and bomb it ya

  reserved pin       4 for CSB for microSD on Duemanilove -
  reserved pin      11 for MOSI (Master Out, Slave In) -  SPI
  reserved pin      12 for MISO (Master In, Slave Out) -  SPI
  reserved pin      13 for SCK (Clock Sync)            -  SPI
  reserved analog pin 2 for RTC
  reserved analog pin 3 for RTC
 */


RTC_Millis RTC;
const int chipSelect = 4;
File dataFile;

void setup()
{
  //be careful, RTC baud rate is 56700
  Serial.begin(9600);
  Serial.print("Initializing SD card...");
  // make sure that the default chip select pin is set to
  // output, even if you don't use it:
  pinMode(10, OUTPUT);
  
  // see if the card is present and can be initialized:
  if (!SD.begin(chipSelect)) {
    Serial.println("Card failed, or not present");
    // don't do anything more:
    return;
  }
  Serial.println("card initialized.");
  //begin the RTC time
  RTC.begin(DateTime(__DATE__, __TIME__));
}

void loop()
{
  // make a string for assembling the data to log:
  String dataString = "";
  
  //set Date to now
  DateTime now = RTC.now();

  // read three sensors and append to the string:
  for (int analogPin = 0; analogPin < 3; analogPin++) {
    int sensor = analogRead(analogPin);
    dataString += String(sensor);
    if (analogPin < 2) {
      dataString += ","; 
    }
  }

  //put conditional loop here to make it only open/write to file when an object
  //is in front of sensor
  // open the file. note that only one file can be open at a time,
  // so you have to close this one before opening another.
  dataFile = SD.open("pisslog.txt", FILE_WRITE);

  // if the file is available, write to it:
  if (dataFile) {
    //write date stuff to file
    dataFile.print(now.year(), DEC);
    dataFile.print('/');
    dataFile.print(now.month(), DEC);
    dataFile.print('/');
    dataFile.print(now.day(), DEC);
    dataFile.print(' ');
    dataFile.print(now.hour(), DEC);
    dataFile.print(':');
    dataFile.print(now.minute(), DEC);
    dataFile.print(':');
    dataFile.print(now.second(), DEC);
    dataFile.println();
    dataFile.println(now.unixtime());
    dataFile.println("----------------------------------------");
    dataFile.close();
    // print to the serial port too:
    Serial.println(dataString);
  }  
  // if the file isn't open, pop up an error:
  else {
    Serial.println("error opening pisslog.txt");
  } 
}









