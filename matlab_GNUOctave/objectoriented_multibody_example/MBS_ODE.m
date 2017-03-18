function yp = MBS_ODE(t,y)
    % state-space representation wrapper for the multibody system.
    % Daniel Heinrich, april 2016, http://hmbd.wordpress.com
    % released under CC BY-NC-SA licence.
    
    % get object stack as a global variable:
    global s
    
    % 1) set state in objects:
    for i=1:length(s)
      % which part of the state vector needs to be included is contained
      % in the s(#).i-vector, e.g. [1,2] for the first mass.
      set_state(s(i).o, y( s(i).i )); % set_state(obj,state)
    end
    
    % 2) update internal object state:
    for i=1:length(s)
      calc_int_state(s(i).o);
    end
    
    % 3) get yp vector:
    yp=y; % initialize variable (not necessarily required)
    for i=1:length(s)
      yp(s(i).i) = calc_yp(s(i).o);
    end
    
end
