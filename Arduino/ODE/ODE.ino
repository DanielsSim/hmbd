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
 * Also, on a due, values entered numerically (e.g. "0.5") are automatically treated as
 * double. To get float, (float)0.5 needs to be used (improves speed by ~5% for float).
 * 
 * calculation time for the 1000 steps with the ODE included below:
 * arduino UNO / Nano: ~760 ms (~ 1300 steps / second)
 * arduino due: ~140 ms (~ 7000 steps / second)
 * arduion due with float (see comments above): ~115 ms (~8700 steps / second)
 */

const double dt=0.001;      // Timestep used by the algorithm
const int n=4;                // number of state variables in the ODE
int steps=0;                  // number of calculated steps
double t=0;                 // current time

double Y_current[n]={1, 0, 0, 0};    // Initial state of the ODE

double Y_temp[n];            // temp array for the ODE function output.
double K1[n], K2[n], K3[n], K4[n];   // arrays for the Runge-Kutta intermediate points

// ODE parameters:
const double c1=1;
const double c2=1;
const double d1=0.01;
const double d2=0.01;

// Debugging parameters:
long time_lastprintout = millis();


void setup() {
  // initialize Serial to output the integrator results.
  Serial.begin(9600);
}

void loop() {
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
  ODE(t + dt*0.5, Y_temp, K3);

  // K4 = Y_p(t0 + dt, Y_current + dt * K3)
  for (int i=0; i<n; i++) {
    Y_temp[i] = Y_current[i] + K3[i]*dt;
  }
  ODE(t + dt, Y_temp, K4);


  // Calculate new step:
  // Y_nextstep = Y_current + dt/6 * (K1 + 2*(K2+K3) + K4)
  for (int i=0; i<n; i++) {
    Y_current[i] = Y_current[i] + dt / 6.0 * (K1[i] + 2.0*(K2[i] + K3[i]) + K4[i]);
  }
  t=t+dt;
  steps++;
  
  
  
  // Print output each X calculated steps:
  if (steps>=1000) {
    Serial.print("state at ");
    Serial.print(t);
    Serial.print("s: ");
    for (int i=0; i<n; i++) {
      Serial.print(Y_current[i]);
      Serial.print(" ");
    }

    Serial.print(" calculation time: ");
    Serial.print(millis()-time_lastprintout);
    time_lastprintout=millis();
  
    Serial.println();
    
    steps=0;
  }
  
  //delay(10);
  
  
}

void ODE(double t, double Y[], double Y_p[]) {
  // simple 2-mass oscillator:
  // y = pos1, pos2, vel1, vel2
  Y_p[0]=Y[2];
  Y_p[1]=Y[3];
  Y_p[2]=-Y[0]*c1 + (Y[1]-Y[0])*c2 - Y[2]*d1;
  Y_p[3]=-(Y[1]-Y[0])*c2 - Y[3]*d2;
}
