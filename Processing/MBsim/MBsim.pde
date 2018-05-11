ODE ode; // includes all objects during simulation + integration algorithms

void setup() {
  size(600,400);
  
  // create and initialize objects:
  ode = new ODE();
  ode.addObject(new MBMassPoint2d("M1", "200;50", "0")); // 0 -> fixed to ground 
  ode.addObject(new MBMassPoint2d("M2", "300;50", "1"));
  ode.addObject(new MBMassPoint2d("M3", "300;150;10;0", "1")); // with initial velocity
  ode.addObject(new MBSpring2d("C1;M1;M2", "", "100;1;0.1")); // linked to M1 and M2
  ode.addObject(new MBSpring2d("C2;M2;M3", "", "100;1;0.1")); // linked to M2 and M3
  ode.initSimulation();
}

void draw() {
  // simulate one timestep:
  ode.rungeKutta(0.1);
   //<>//
  // output (plot and print):
  background(255);
  fill(150);
  for (MBObject o : ode.objects) {
    o.plot();
    o.printState();
  }
}
