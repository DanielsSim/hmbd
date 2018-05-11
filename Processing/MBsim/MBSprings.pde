class MBSpring2d extends MBObject {
  MBMassPoint2d m1;
  MBMassPoint2d m2;
  float length0;
  float c;
  float d;

  MBSpring2d(String textInput, String stateInput, String parInput) {
    super(textInput, stateInput, 0);
    
    // get masses to connect to:
    StringList textInputList = convertToStringList(textInput);
    m1 = (MBMassPoint2d) ode.getObject(textInputList.get(1));
    m2 = (MBMassPoint2d) ode.getObject(textInputList.get(2));
    
    // set parameters:
    float[] par = convertToFloatArray(parInput);
    this.length0 = par[0];
    this.c = par[1];
    this.d = par[2];
  }

  void update(float t) {
    float length_x = m1.y[0] - m2.y[0];
    float length_y = m1.y[1] - m2.y[1];
    float vel_x = m1.y[2] - m2.y[2];
    float vel_y = m1.y[3] - m2.y[3];

    float length_abs = sqrt(length_x*length_x + length_y*length_y);
    if (length_abs == 0) {
      length_abs = 1e-8;
    }
    float vel_abs = ( vel_x * length_x + vel_y * length_y ) / length_abs;

    float force_abs = c * (length_abs - length0) + d*(vel_abs);
    float force_x = length_x / length_abs * force_abs;
    float force_y = length_y / length_abs * force_abs;

    m1.force[0] -= force_x;
    m1.force[1] -= force_y;
    m2.force[0] += force_x;
    m2.force[1] += force_y;
  }

  void plot() {
    line(m1.y[0], m1.y[1], m2.y[0], m2.y[1]);
  }
}
