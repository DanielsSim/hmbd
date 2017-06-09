// Due_Oscilloscope 
// Oscilloscope on an Arduino Due with a TFT display
// (requires both the UTFT and URTouch libraries from Henning Karlsen
// and is loosely based on the example sketches for both libraries.)
// Might also work on Teensy 3.x boards (not tested).
// Daniel Heinrich, February 2017, V1.0
// released as CC BY-SA 4.0 licence, see https://creativecommons.org/licenses/by-sa/4.0/

// TFT Libraries:
#include <UTFT.h>
#include <URTouch.h>

// SD Card Libraries:
#include <SPI.h>
#include <SD.h>

// main use for live plots: try 300 or 512 values
// main use for data logging: try 2000 .. 6000 values
#define nMeasuredValues 300

// UTFT: Declare which fonts we will be using
extern uint8_t SmallFont[];

// Remember to change the model parameter to suit your display module!
UTFT myGLCD(SSD1289, 38, 39, 40, 41);
URTouch  myTouch(18, 17, 16, 15, 14);

// global variables for the oscilloscope code:
uint16_t measuredValues[5][nMeasuredValues]; // variable to store measured values
long timeValues[nMeasuredValues];
boolean channelActive[5] = {0, 0, 0, 0, 0};
const int channels[5] = {A0, A1, A8, A9, A10}; // the Channels used for the oscilloscope
int delayValue = 100; // sets the delay between measurements

// variables required for plotting:
const int channelColor[5][3] = {{255, 255, 255}, {255, 0, 0}, {0, 255, 0}, {0, 0, 255}, {255, 255, 0}};
int scaleFactor = 1;

// menu options
boolean logActive = false;
boolean continuosDisplay = false;
boolean enableDisplay = true;
boolean addFft = false; // not implemented yet

// variables for SD logging (variable logActive):
File dataFile;
const int chipSelect = 21;
boolean isSdAvailable = false;

// trigger function variables:
const int maxTriggerDelay = 2000;
const int triggerDelta = 200;

// plotting global variables:
int x_previous = 0;


void setup()
{
  // some LCD require a short bootup time:
  // delay(100);
  
  // Setup the LCD:
  myGLCD.InitLCD();
  myGLCD.setFont(SmallFont);
  
  // Setup Touch Library:
  myTouch.InitTouch();
  myTouch.setPrecision(PREC_MEDIUM);

  // Set AnalogReadResolution
  analogReadResolution(12);
  
  // Setup plot window:
  showMenu();
  drawAxis();
}



void loop()
{

  // A: Detect starting point for display:
  if (!continuosDisplay) {
    long tStart = millis();
    int minMeasurement = 1e6;
    int sumMeasurement = 0;
    
    while (millis() < tStart + maxTriggerDelay) {
      // add Values to this variable for all active channels
      sumMeasurement = 0; 
      for (int j=0; j<5; j++) {
        if (channelActive[j]) {
          sumMeasurement += analogRead(channels[j]);
        }
      }

      if (sumMeasurement > minMeasurement + triggerDelta) {
        break;
      }
      if (sumMeasurement < minMeasurement) {
        minMeasurement = sumMeasurement;
      }
      
    }
  }

  
  
  // B: measure Data:
  for (int i=0; i<nMeasuredValues; i++) {
    timeValues[i] = micros();
    for (int j=0; j<5; j++) {
      if (channelActive[j]) {
        measuredValues[j][i] = analogRead(channels[j]);
      }
    }
    delayMicroseconds(delayValue);
    if (continuosDisplay) {
      plotDataPoints(i);
    }
  }



  // C: update plot
  if (!continuosDisplay) {
    // Plot results to graph
    for (int i=1; i<nMeasuredValues; i++) {
      plotDataPoints(i);
    }
  }
  // update time scale information
  myGLCD.setColor(50,50,50);
  myGLCD.print(String( (timeValues[nMeasuredValues-1]-timeValues[0]) / 1000 ), RIGHT, 225);
  // fix data to SD (in case of logging)
  if (logActive) dataFile.flush();


  
  // D: Touch input available?
  if (myTouch.dataAvailable()) {
    myTouch.read();
    int x=myTouch.getX();
    int y=myTouch.getY();

    // outer border of screen? --> rescale axis
    if (y<40) scaleFactor = scaleFactor*2;
    if (y>200) scaleFactor = max(scaleFactor/2, 1);
    if (x<40) delayValue = max(delayValue/2, 1);
    if (x>280) delayValue = delayValue*2;
    // center? --> show menu
    if ( (y>40) && (y<200) && (x>40) && (x<280) ) {
      showMenu();
    }
    
    // Redraw plot window:
    drawAxis();
  }
  
}



void plotDataPoints(int i)
{
  // plots all data points for column i of measuredValues[:][i]
  int x = i * 300 / nMeasuredValues;
  int y = 0;

  if (logActive) {
    dataFile.println("");
    dataFile.print(timeValues[i]);
  }

  if ( (x_previous != x) && (enableDisplay) ) {
    // clear this part of the screen:
    myGLCD.setColor(0,0,0);
    myGLCD.drawLine(x+20, 0, x+20, 220);
  }
  x_previous = x;
  
  for (int j=0; j<5; j++) {
    if (channelActive[j]) {
      if ( enableDisplay) {
        y = measuredValues[j][i]*185*scaleFactor/4095;
        y = min(y, 220);
        myGLCD.setColor(channelColor[j][0], channelColor[j][1], channelColor[j][2] );
        myGLCD.drawPixel(x+20, 220-y);
      }
      
      if (logActive) {
        dataFile.print(",");
        dataFile.print(measuredValues[j][i]);
      }
    }
  }
}



void startLogging()
{
  if (!isSdAvailable) {
    if (SD.begin(chipSelect)) {
      isSdAvailable = true;
    }
    else {
      // SD initialization didn't work --> don't log!
      logActive = false;
    }
  }

  
  if (isSdAvailable) {
    // close previous log:
    if (dataFile) dataFile.close();
    
    // create a new file (code from Adafruit datalogger shield example)
    char filename[] = "LOGGER00.CSV";
    for (uint8_t i = 0; i < 100; i++) {
      filename[6] = i/10 + '0';
      filename[7] = i%10 + '0';
      if (! SD.exists(filename)) {
        // only open a new file if it doesn't exist
        dataFile = SD.open(filename, FILE_WRITE);

        // create short header:
        dataFile.print("time_ns");
        for (int j = 0; j<5; j++) {
          if (channelActive[j]) {
            dataFile.print(",");
            dataFile.print(channels[j]);
          }
        }
        dataFile.println("");
        
        break; // leave the loop!
      }
    }

    // output log name
    myGLCD.clrScr();
    myGLCD.setColor(255,255,255);
    myGLCD.print("Logfile created:", 20, 20);
    myGLCD.print(filename, 20, 40);
    delay(1000);
  }
}



void drawAxis()
{
  myGLCD.clrScr();
  
  // Draw Axis
  myGLCD.setColor(100,100,100);
  for (int i=0; i<5; i++) {
    myGLCD.drawLine(15, 220-i*55, 19, 220-i*55);
    myGLCD.print(String(i), 5, 216-i*55);
  }
  myGLCD.drawLine(19, 0, 19, 220); 
  myGLCD.print("0", 15, 225);
  myGLCD.print("t in ms", CENTER, 225);
  //myGLCD.drawLine(319, 0, 319, 220);

  myGLCD.print("V/", 0, 20);
  myGLCD.print(String(scaleFactor), 2, 32);
}


void chooseColor(boolean active) {
  // Used for menu: chooses green if true, else red
  if (active) {
    myGLCD.setColor(0,255,0);
  }
  else {
    myGLCD.setColor(255,0,0);
  }
}



void showMenu()
{
  myGLCD.clrScr();
  
  // Draw Channel Buttons:
  myGLCD.setColor(255,255,255);
  myGLCD.print("Active Channels:", 10, 5);
  for (int i=0; i<5; i++) {
    chooseColor( channelActive[i] );
    myGLCD.drawRoundRect (10+(i*60), 20, 60+(i*60), 60);
    myGLCD.setColor(channelColor[i][0], channelColor[i][1], channelColor[i][2] );
    myGLCD.printNumI(i+1, 25+(i*60), 35);
  }

  // Additional options:
  chooseColor( logActive );
  myGLCD.drawRoundRect (10, 80, 180, 120);
  myGLCD.print("Log Data to SD",25,95);
  
  chooseColor( continuosDisplay );
  myGLCD.drawRoundRect (10, 130, 180, 170);
  myGLCD.print("Continuos mode",25,145);

  chooseColor( enableDisplay );
  myGLCD.drawRoundRect (10, 180, 180, 220);
  myGLCD.print("enable live plot",25,195);

  delay(500); // short delay until touch input is accepted

  while (true) {
    delay(1);
    if (myTouch.dataAvailable()) {
      break;    
    }
  }

  myTouch.read();
  int x=myTouch.getX();
  int y=myTouch.getY();

  if ((y>20) && (y<60)) {
    for (int i=0; i<5; i++) {
      if ( (x>(10+(i*60))) && (x<(60+(i*60))) ) {
        channelActive[i] = 1 - channelActive[i]; // (true -> false, false -> true)
      }
    }
  }
  if ((x>10) && (x<180)) {
    if ((y>80) && (y<120)) {
      logActive = !logActive;
    }
    if ((y>130) && (y<170)) {
      continuosDisplay = !continuosDisplay;
    }
    if ((y>180) && (y<220)) {
      enableDisplay = !enableDisplay ;
    }
  }

  if (logActive) startLogging();
}

