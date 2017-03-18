classdef spring_1d < MBS_object
   % 1d spring object
   % Daniel Heinrich, april 2016, http://hmbd.wordpress.com
   % released under CC BY-NC-SA licence.
 
   properties
      % also inherits state and par properties from parent class
      m1 % handle to 1st mass
      m2 % handle to 2nd mass
   end

   methods
      function obj = spring_1d(c, m1, m2)
         % Object constructor: requires spring rate and handles to two masses
         obj.state=[];
         obj.par=c;
         obj.m1=m1;
         obj.m2=m2;
      end
      
      function set_state(obj,state)
         % called from MBS_ODE wrapper function
         % do nothing (no state variables for the spring)
      end

      function calc_int_state(obj)
         % called from MBS_ODE wrapper function

         % calculate spring force:
         force = obj.par * (obj.m1.state(1) - obj.m2.state(1));

         % add force back to mass objects:
         add_force(obj.m1, -force);
         add_force(obj.m2, force);
      end
      
      function yp = calc_yp(obj)
         % called from MBS_ODE wrapper function
         % no state variables for the spring:
         yp = [];
      end
   end
end
