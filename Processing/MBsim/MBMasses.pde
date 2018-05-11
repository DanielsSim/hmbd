class MBMassPoint2d extends MBObject {

  float[] force;
  float m;
  float m_inv;

  MBMassPoint2d(String textInput, String stateInput, String parInput) {
    super(textInput, stateInput, 4);
    
    force = new float[2];

    float[] par = convertToFloatArray(parInput);
    m = par[0];
    if (m>0) {
      m_inv = 1/m;
    } else {
      m_inv = 0;
    }
  }

  void reset() {
    force[0] = 0;
    force[1] = 9.81*m;
  }

  void update(float t) {
  }

  void calc_yp(float t) {
    //float posx = y[0];
    //float posy = y[1];
    float velx = y[2];
    float vely = y[3];

    yp[0] = velx;
    yp[1] = vely;
    yp[2] = force[0] * m_inv;
    yp[3] = force[1] * m_inv;
  }

  void plot() {
    ellipse(y[0], y[1], 10, 10);
    text(name, y[0]+10, y[1]);
  }

  void printState() {
    print(name);
    print(": ");
    for (int i=0; i<4; i++) {
      print(y[i]);
      print("  ");
    }
    print(force[0]);
    print("  ");
    print(force[1]);
    println("");
  }
}
