classdef (Abstract) MBS_object < handle
   % superclass for ALL MBS objects
   % Daniel Heinrich, april 2016, http://hmbd.wordpress.com
   % released under CC BY-NC-SA licence.
   
   properties
      state
      par
   end
   
   methods
      set_state(obj,state) % called from ODE_MBS function to set state within objects
      calc_int_state(obj) % called from ODE_MBS function to update internal state within objects
      yp = calc_yp(obj) % called from ODE_MBS function to receive new yp vector 
   end   
   
end
