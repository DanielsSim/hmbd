abstract class MBObject {
  // superclass for all simulated objects
  float[] y; // state variables
  float[] yp; // dy/dt
  String name;

  MBObject(String textInput, String stateInput, int nStateVariables) {
    // example calls:
    // MBMassPoint2d: super(textInput, stateInput, 4);
    // MBSpring2d:    super(textInput, stateInput, 0);
    y = new float[nStateVariables];
    float[] y_input = convertToFloatArray(stateInput);
    for (int i=0; i<nStateVariables; i++) {
      if (i<y_input.length) {
        y[i] = y_input[i];
      } else {
        y[i] = 0.0;
      }
    }

    yp = new float[y.length];

    StringList textInputList = convertToStringList(textInput);
    this.name = textInputList.get(0);
  }
  
  
  // functions required for working simulation:
  
  void reset() {
    // reset all internal variables.
  }

  void update(float t) {
    // calculate all internal variables.
  }

  void calc_yp(float t) {
    // calculate yp based on current state and internal variables.
  }

  void plot() {
  }

  void printState() {
  }
  
  
  // helper functions for initialization:
  
  StringList convertToStringList(String input) {
    StringList output = new StringList();
    int index = input.indexOf(";");
    while (index>=0) {
      output.append( input.substring(0, index) );
      input = input.substring(index+1);
      index = input.indexOf(";");
    }
    output.append( input );
    return output;
  }
  
  float[] convertToFloatArray(String input) {
    if (input.length()>0) {
      StringList inputList = convertToStringList(input);
      float[] output = new float[inputList.size()];
      for (int i=0; i<inputList.size(); i++) {
        output[i] = Float.parseFloat(inputList.get(i));
      }
      return output;
    }
    else {
      return null;
    }
  }
}
