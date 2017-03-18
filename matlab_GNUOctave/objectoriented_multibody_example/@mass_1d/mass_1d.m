classdef mass_1d < MBS_object
   % 1d mass object
   % Daniel Heinrich, april 2016, http://hmbd.wordpress.com
   % released under CC BY-NC-SA licence.
 
   properties
      % also inherits state and par properties from parent class
      force % current force on the object
   end

   methods
      function obj = mass_1d(m)
         % Object constructor: requires object mass and initial position + vel.
         obj.state=[0;0]; % state(1) = position, state(2) = velocity
         obj.par=m; % sole parameter: mass
         obj.force=0; % initial force: set to zero.
      end

      function set_state(obj,state)
         % called from MBS_ODE wrapper function

         obj.state = state;
         obj.force = 0; % reset force!
      end

      function calc_int_state(obj)
         % called from MBS_ODE wrapper function
         % do nothing.
      end

      function yp = calc_yp(obj)
         % called from MBS_ODE wrapper function
         % calculate yp based on "state" vector:
         yp = [obj.state(2); obj.force / obj.par];
      end

      function obj = add_force(obj, force)
         % called from connected objects (e.g. spring_1d)
        obj.force = obj.force + force;
      end
   end
end
