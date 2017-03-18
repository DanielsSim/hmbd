/*
 * Test the calculation time on an arduino for simple math operations and analog read
 * Daniel Heinrich, August 2016. 
 * released under a CC BY-SA 4.0 licence, see https://creativecommons.org/licenses/by-sa/4.0/
 */

#define dataType float

// the setup routine runs once when you press reset:
void setup() {
  // initialize serial communication at 9600 bits per second:
  Serial.begin(9600);  

  // set analog read resolution on due (standard: 10 bit - change to 12bit to increase resolution)
  // analogReadResolution(12);  // uncomment to activate, will not compile on non due/zero boards
}

// the loop routine runs over and over again forever:
void loop() {

  // variables for timekeeping:
  int t;
  int t2;
  // saving the calculation result:
  dataType result = 1; 

    

  // plus
  
  t=millis(); // get current time 
  for(long i=0;i<100000;i++) {
    result = result + (dataType)1.23;
  }
  t2 = millis()-t; // time for calculations
  
  // output results:
  Serial.print("time for 1 mio. plus calculations in s: ");
  Serial.println((float)t2 / 100.0); // 100.000 in ms --> 1 mio in s


  // minus
  
  t=millis(); // get current time 
  for(long i=0;i<100000;i++) {
    result = result - (dataType)1.23;
  }
  t2 = millis()-t; // time for calculations
  
  // output results:
  Serial.print("time for 1 mio. minus calculations in s: ");
  Serial.println((float)t2 / 100.0); // 100.000 in ms --> 1 mio in s


  // multiplication
  
  t=millis(); // get current time 
  for(long i=0;i<100000;i++) {
    result = result * (dataType)1.00001;
  }
  t2 = millis()-t; // time for calculations
  
  // output results:
  Serial.print("time for 1 mio. multiplications in s: ");
  Serial.println((float)t2 / 100.0); // 100.000 in ms --> 1 mio in s


  // division
  
  t=millis(); // get current time 
  for(long i=0;i<100000;i++) {
    result = result / (dataType)1.00001;
  }
  t2 = millis()-t; // time for calculations
  
  // output results:
  Serial.print("time for 1 mio. divisions in s: ");
  Serial.println((float)t2 / 100.0); // 100.000 in ms --> 1 mio in s


  // analog read
  int aval;
  t=millis(); // get current time 
  for(long i=0;i<10000;i++) {
    aval = analogRead(A0);
  }
  t2 = millis()-t; // time for calculations
  
  
  // output results:
  Serial.print("time for 1 mio. analog reads in s: ");
  Serial.println((float)t2 / 10.0); // 10.000 in ms --> 1 mio in s

  

  
  delay(10000);        // wait some time
  Serial.println(result);  
  // this is actually required or the compiler will reomve the for loops 
  // above as part of the optimization during compiling.

}
