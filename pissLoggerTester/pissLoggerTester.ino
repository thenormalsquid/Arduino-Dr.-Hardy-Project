#include <SD.h>

File myFile;

void setup()
{
  Serial.begin(9600);
  Serial.print("Initializing SD card...");
  pinMode(10, OUTPUT);

  if (!SD.begin(4)) {
    Serial.println("initialization failed!");
    return;
  }
  Serial.println("initialization done.");

  if (SD.exists("pisslog.txt")) {
    Serial.println("pisslog.txt exists.");
  }
  else {
    Serial.println("pisslog.txt doesn't exist.");
  }

  // open a new file and immediately close it:
   myFile = SD.open("pisslog.txt");
  if (myFile) {
    Serial.println("pisslog.txt:");
    
    // read from the file until there's nothing else in it:
    while (myFile.available()) {
    	Serial.write(myFile.read());
    }
    // close the file:
    myFile.close();

 }
}

void loop()
{

}



