class ODE {

  ArrayList<MBObject> objectsInput;
  MBObject[] objects;
  float[] state;
  int[] stateRefObject;
  int[] stateObjectIndex;
  float t;
  
  ODE() {
    objectsInput = new ArrayList<MBObject>();
    // all other variables are initialized with ODE.initSimulation();
  }
  
  void addObject(MBObject o) {
    objectsInput.add(o);
  }
  
  MBObject getObject(String name) {
    for (MBObject o:objectsInput) {
      if (name.equals(o.name)) {
        return o;
      }
    }
    return null;
  }

  void initSimulation() {
    // array instead of arrayList since size may not change during simulation.
    objects = new MBObject[objectsInput.size()];
    for (int i=0; i<objectsInput.size(); i++) {
      objects[i] = objectsInput.get(i);
    }
    // also create corresponding state arrays:
    createStateArrays();
    t = 0;
  }

  void createStateArrays() {
    // this function is called by the ODE constructor after all objects
    // have been transferred.

    int nStateVariables = 0;
    for (MBObject o : objects) {
      nStateVariables += o.y.length;
    }

    state = new float[nStateVariables];
    stateRefObject = new int[nStateVariables];
    stateObjectIndex = new int[nStateVariables];

    int iStateVariable = 0;

    for (int iObjects = 0; iObjects<objects.length; iObjects++) {
      MBObject o = objects[iObjects];
      for (int i=0; i<o.y.length; i++) {
        state[i + iStateVariable] = o.y[i];
        stateRefObject[i + iStateVariable] = iObjects; // stores: object #? belongs to state vector[?]
        stateObjectIndex[i + iStateVariable] = i; // stores: the object's state variable #? belongs to state vector[?]
      }
      iStateVariable += o.y.length;
    }
  }

  void dydt(float[] yp, float[] y, float t) {
    
    // 1) reset all objects
    for (int i=0; i<objects.length; i++) {
      objects[i].reset();
    }

    // 2) push state vector to objects
    for (int i=0; i<state.length; i++) {
      objects[stateRefObject[i]].y[stateObjectIndex[i]] = y[i];
    }

    // 3) update all objects internally:
    for (int i=0; i<objects.length; i++) {
      objects[i].update(t);
    }
    
    // 4) calculate each object's dy/dt vector:
    for (int i=0; i<objects.length; i++) {
      objects[i].calc_yp(t);
    }
    
    // 5) push calculated yp values back to overall yp vector.
    for (int i=0; i<state.length; i++) {
      yp[i] = objects[stateRefObject[i]].yp[stateObjectIndex[i]];
    }
  }

  void explicitEuler(float dt) {
    // Explicit Euler integration.
    // VERY INACCURATE - ONLY AS REFERENCE
    float[] dstate = new float[state.length];
    dydt(dstate, state, t);  

    for (int i=0; i<state.length; i++) {
      state[i] = state[i] + dstate[i] * dt;
    }
    
    t = t + dt;
  }
  
  void rungeKutta(float dt) {

    int n = state.length;
    float[] state_temp = new float[n];
    
    // K1 = dy/dt(t0, Y_current)
    float[] K1 = new float[state.length];
    dydt(K1, state, t);
    
    // K2 = dy/dt(t0 + dt/2, Y_current + dt/2 * K1)
    for (int i=0; i<n; i++) {
      state_temp[i] = state[i] + K1[i]*dt*0.5;    // is there a more compact way to do this?
    }
    float[] K2 = new float[state.length];
    dydt(K2, state_temp, t + 0.5*dt);
  
    // K3 = dy/dt(t0 + dt/2, Y_current + dt/2 * K2)
    for (int i=0; i<n; i++) {
      state_temp[i] = state[i] + K2[i]*dt*0.5;
    }
    float[] K3 = new float[state.length];
    dydt(K3, state_temp, t + 0.5*dt);
  
    // K4 = Y_p(t0 + dt, Y_current + dt * K3)
    for (int i=0; i<n; i++) {
      state_temp[i] = state[i] + K3[i]*dt;
    }
    float[] K4 = new float[state.length];
    dydt(K4, state_temp, t + dt);
  
    // Calculate new step:
    // Y_nextstep = Y_current + dt/6 * (K1 + 2*(K2+K3) + K4)
    for (int i=0; i<n; i++) {
      state[i] = state[i] + dt / 6.0 * (K1[i] + 2.0*(K2[i] + K3[i]) + K4[i]);
    }
    
    t = t + dt;
  } 
}
