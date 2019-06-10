/*
(Partial) implementation of Clavet et al (2005): "Particle-based Viscoelastic Fluid Simulation"
See https://hmbd.wordpress.com/2019/06/10/sph-fluid-simulation-in-processing/ for further documentation and animations.
Press Mouse to add fluid, change int model in line 11 to see different models.
*/

Fluid fluid;
float kernel_radius = 20; // 20 - speed OK, 8..10 - very slow
float timestep = 2;
int model = 2; // use 1 - 3 for different simulation models, see setup() for definitions
float stepsPerFrame = 1;

void setup() {
  size(400, 300);
  //fullScreen();
  colorMode(HSB);

  fluid = new Fluid(timestep, kernel_radius);

  // model 1: drop in zero gravity:
  if (model == 1) {
    stepsPerFrame = 20;
    timestep = 2;
    fluid.g = new PVector(0, 0); // deactivate gravity for debugging.
    for (float x = width * 0.4; x<(width * 0.6); x+=kernel_radius*0.25) {
      for (float y = height * 0.2; y<(height * 0.8); y+=kernel_radius*0.25) {
        fluid.particles.add(new Particle(x, y, false));
      }
    }
  }

  // model 2: dam break:
  if (model == 2) {
    stepsPerFrame = 2;
    timestep = 1;
    for (float x = width*0.1; x<width*0.3; x+=kernel_radius*0.25) {
      for (float y = height * 0.2; y<(height * 0.8); y+=kernel_radius*0.25) {
        fluid.particles.add(new Particle(x, y, false));
      }
    }
    createBorders();
  }

  // model 3: tube to fill:
  if (model == 3) {
    stepsPerFrame = 1;
    timestep = 1;
    for (float x = width * 0.25; x<width*0.45; x+=kernel_radius*0.25) {
      for (float y = height * 0.5; y<(height * 0.9); y+=kernel_radius*0.25) {
        fluid.particles.add(new Particle(x, y, false));
      }
    }
    createBorders();
    for (float y = height/2; y < height; y+=kernel_radius*0.1) {
      fluid.particles.add(new Particle(width*0.2, y, true));
      fluid.particles.add(new Particle(width*0.2 + kernel_radius * 0.1, y, true));
      fluid.particles.add(new Particle(width*0.5, y, true));
      fluid.particles.add(new Particle(width*0.5 + kernel_radius * 0.1, y, true));
    }
  }

  print("Particles: ");
  println(fluid.particles.size());
}

void draw() {
  background(255);

  if (mousePressed) {
    for (int i=1; i<5; i++) {
      fluid.particles.add(new Particle(mouseX + random(kernel_radius), mouseY + random(kernel_radius), false));
    }
  }


  for (int i=0; i<stepsPerFrame; i++) {
    fluid.step();
  }

  fluid.plot();
  //saveFrame("b1-######.png");
}

void createBorders() {
  for (float x=0; x < width; x+= kernel_radius * 0.1) {
    fluid.particles.add(new Particle(x, height, true));
  }
  for (float y=0; y < height; y+= kernel_radius * 0.1) {
    fluid.particles.add(new Particle(0, y, true));
    fluid.particles.add(new Particle(width, y, true));
  }
}
