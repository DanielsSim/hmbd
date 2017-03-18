/*
 Easy to use and rather fast SD card datalogger
 Daniel Heinrich, built from the standard and adafruit examples
 
 note: this is messy code and serves as a fast example. 
 Many options are commented out, add them if you want them.
 
 code in the public domain 	 
 */

// Alternative: use the standard SD library:
#include <SPI.h>
#include <SD.h>

// Use SDFat for the SD card library (appears to be required on my Teensy 3.5):
//#include <SPI.h>
//#include "SdFat.h"
//SdFatSdioEX SD;

// RTC libraries (use analog pins 4-5 on my shield):
//#include <Wire.h>
//#include "RTClib.h"
//RTC_DS1307 rtc;

/*
 * SD chip select pin.  Common values are:
 *
 * Arduino Ethernet shield, pin 4.
 * SparkFun SD shield, pin 8.
 * Adafruit SD shields and modules, pin 10.
 * Default SD chip select is the SPI SS pin.
 */
const uint8_t SD_CHIP_SELECT = SS;

int i_ = 1;
int t = 0;

File dataFile;



void setup()
{
  Serial.begin(57600);
  // make sure that the default chip select pin is set to
  // output, even if you don't use it:
  pinMode(SD_CHIP_SELECT, OUTPUT);
  
  // see if the card is present and can be initialized:
  if (!SD.begin()) {
    Serial.println("Card failed, or not present");
    // don't do anything more:
    return;
  }
  
  // if you want to use the RTC, initialize it (uncomment lines here and in the following code):
  //Wire.begin();
  //rtc.begin();  
  
  // modify either analogReadRes or analogReference if required:
  //analogReadRes(12);
  //analogReference(INTERNAL);


  // create a new file (code from the adafruit example, works great!)
  char filename[] = "LOGGER00.CSV";
  for (uint8_t i = 0; i < 100; i++) {
    filename[6] = i/10 + '0';
    filename[7] = i%10 + '0';
    if (! SD.exists(filename)) {
      // only open a new file if it doesn't exist
      dataFile = SD.open(filename, FILE_WRITE);
      break; // leave the loop!
    }
  }

  
  // if the file is available, write to it:
  if (dataFile) {
    //Serial.println("file opened");
    //dataFile.println("Add info on your ADC setting here. Ref. voltage / resolution?");
    //dataFile.println("Add info on your channels to the log file here.");

    // ADC present? Print the time to your log:
    /*
    DateTime now = rtc.now();

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
    dataFile.println("millis = " + String( millis() ) );    
    dataFile.println();
    */

    dataFile.println("time in ms, A0, A1, ...");
    dataFile.flush();
  }
  
}

void loop()
{
  // File is already open. Read many sensors and add them to the file.

  for (int i=1;i<1000;i++) {

    // read sensors and store in variables:
    long t1 = micros();
    int sensor1 = analogRead(A0);
    int sensor2 = analogRead(A1);
    long t2 = micros();

    // if the file is available, write to it:
    if (dataFile) {
      dataFile.print(t1);
      dataFile.print(",");
      dataFile.print(sensor1);
      dataFile.print(",");
      dataFile.println(sensor2);
    }
    long t3 = micros();
    

    // Debugging: output durations:
    Serial.print("time for analogRead: ");
    Serial.print(t2-t1);
    Serial.print(", csvwrite: ");
    Serial.println(t3-t2);

  }  
  
  // actually write data to the SD card:
  dataFile.flush();
}

