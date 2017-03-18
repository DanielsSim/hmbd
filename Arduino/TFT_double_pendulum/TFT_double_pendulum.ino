/*
 *  ODE solver
 * 
 * This code implements the runge-kutta (4th order) algorithm to solve a system of 
 * ordinary differential equations (ODEs). The code requires a given time step dt
 * and will continue indefinitely as long as the arduino runs (unless an exit condition
 * is added).
 * 
 * The ODE needs to be implemented in state-representation. Instead of Matlab convention 
 * y'=f(y,t), the function ODE(t,y,y_p) is used, where t is a given time, y the state 
 * vector and y_p the array which will be updated.
 * 
 * Created: April 2015, Daniel Heinrich
 * Updated: August 2016, Daniel Heinrich: changed data type to double,
 * fixed errors on numerical constants (2.0 instead of 2)
 * released as CC BY-SA 4.0 licence, see https://creativecommons.org/licenses/by-sa/4.0/
 * 
 * Data type considerations: on most arduinos except due, double is treated as float
 * (4-bit precision). On a due, double is 8-bit precision. If you want to use float on
 * a due, open the sketch in a text editor, hit STRG+H and replace double with float.
 * (you can also use #define to swich data types easily, but it makes the code less 
 * readable so I decided against it)
 * NOTE: done in this sketch!
 * Also, on a due, values entered numerically (e.g. "0.5") are automatically treated as
 * double. To get float, (float)0.5 needs to be used (improves speed by ~5% for float).
 * 
 */

const float dt=0.05;      // Timestep used by the algorithm
const int n=4;                // number of state variables in the ODE
int steps=0;                  // number of calculated steps
float t=0;                 // current time

float Y_current[n]={3.14, 3.14, 0, 0};    // Initial state of the ODE

float Y_temp[n];            // temp array for the ODE function output.
float K1[n], K2[n], K3[n], K4[n];   // arrays for the Runge-Kutta intermediate points

// ODE parameters:
const float l=50;     // lever length
const float g=9.81;   // gravity
float posi=0;           // sleigh position
float vel=0;            // sleigh velocity
float accel=0;          // sleigh acceleration
float posi_old=0;
float vel_old=0;

// Keep track of real time:
long time_lastprintout = millis();
long time_delay = 0;

// variable for plotting:
int plotpos[6]={0,0,0,0,0,0};

// display / output
#include <UTFT.h>
extern uint8_t SmallFont[];
UTFT myGLCD(SSD1289,38,39,40,41);



void setup() {
  // initialize TFT:
  myGLCD.InitLCD();
  myGLCD.setFont(SmallFont);

  // initialize sleigh position:
  posi_old = analogRead(A0)/5.0;
  // output info string on display:
  myGLCD.clrScr();
  myGLCD.print("step time (ms):", 10, 220);
  
}

void loop() {

  // read analog input and update vel / accel values:
  posi = analogRead(A0)/5.0;
  vel = (posi - posi_old)/dt;
  accel = (vel - vel_old)/dt;
  posi_old = posi;
  vel_old = vel;

  // calculate another timestep: t0 --> t1

  // K1 = Y_p(t0, Y_current)
  ODE(t, Y_current, K1);
  
  // K2 = Y_p(t0 + dt/2, Y_current + dt/2 * K1)
  for (int i=0; i<n; i++) {
    Y_temp[i] = Y_current[i] + K1[i]*dt*0.5;
  }
  ODE(t + dt*0.5, Y_temp, K2);

  // K3 = Y_p(t0 + dt/2, Y_current + dt/2 * K2)
  for (int i=0; i<n; i++) {
    Y_temp[i] = Y_current[i] + K2[i]*dt*0.5;
  }
  ODE(t + dt*0.5, Y_temp, K2);

  // K4 = Y_p(t0 + dt, Y_current + dt * K3)
  for (int i=0; i<n; i++) {
    Y_temp[i] = Y_current[i] + K3[i]*dt;
  }
  ODE(t + dt, Y_temp, K3);


  // Calculate new step:
  // Y_nextstep = Y_current + dt/6 * (K1 + 2*(K2+K3) + K4)
  for (int i=0; i<n; i++) {
    Y_current[i] = Y_current[i] + dt / 6.0 * (K1[i] + 2.0*(K2[i] + K3[i]) + K4[i]);
  }
  t=t+dt;
  steps++;
  
  
  
  // Update state on display:
  if (1) {
    // erase old plot (way faster than clrScr()!):
    myGLCD.setColor(0,0,0);
    // plot sleigh:
    myGLCD.fillRect(plotpos[0]-10, plotpos[1]-10, plotpos[0]+10, plotpos[1]+10);
    // position of first mass:
    myGLCD.fillCircle(plotpos[2], plotpos[3], 10);
    myGLCD.drawLine(plotpos[0],plotpos[1],plotpos[2],plotpos[3]);
    // position of second mass:
    myGLCD.fillCircle(plotpos[4], plotpos[5], 10);
    myGLCD.drawLine(plotpos[4],plotpos[5],plotpos[2],plotpos[3]);

    // calculate new positions
    plotpos[0] = 60+posi;
    plotpos[1] = 120;
    plotpos[2] = 60 + posi + l * sin( Y_current[0] );
    plotpos[3] = 120 - l * cos( Y_current[0] );
    plotpos[4] = plotpos[2] + l * sin( Y_current[1] );
    plotpos[5] = plotpos[3] - l * cos( Y_current[1] );
    
    myGLCD.setColor(255,255,255);
    // plot sleigh:
    myGLCD.fillRect(plotpos[0]-10, plotpos[1]-10, plotpos[0]+10, plotpos[1]+10);
    // position of first mass:
    myGLCD.fillCircle(plotpos[2], plotpos[3], 10);
    myGLCD.drawLine(plotpos[0],plotpos[1],plotpos[2],plotpos[3]);
    // position of second mass:
    myGLCD.fillCircle(plotpos[4], plotpos[5], 10);
    myGLCD.drawLine(plotpos[4],plotpos[5],plotpos[2],plotpos[3]);

    // add calculation time to display
    myGLCD.printNumI(time_delay, 110, 220,3);
    
  }

  // Wait for real time to catch up:
  time_delay = millis() - time_lastprintout;
  
  delay(max(int(1.0/dt) - time_delay,1));
  time_lastprintout = millis();
  
}

void ODE(float t, float Y[], float Y_p[]) {

  // double-mass pendulum: angles on both masses:
  // y = pos1, pos2, vel1, vel2
  Y_p[0]=Y[2];
  Y_p[1]=Y[3];

  // precalculate sinus and cosinus values:
  float s12 = sin(Y[0]-Y[1]);
  float c12 = cos(Y[0]-Y[1]);
  float c12_sq = c12 * c12;
  float s1 = sin(Y[0]);
  float s2 = sin(Y[1]);
  float c1 = cos(Y[0]);
  float c2 = cos(Y[1]);

  // precalculate alpha and beta for speedier calculation:
  float alpha = - Y[3]*Y[3]*s12 + 2*g/l*s1 -2/l*c1*accel;
  float beta = Y[2]*Y[2]*s12 + g/l*s2 -1/l*c2*accel;
  
  Y_p[2]= 1 / (2-c12_sq) * (alpha - c12 * beta);
  Y_p[3]= 1 / (2-c12_sq) * (2*beta - c12 * alpha);
}
