function [ xp ] = frictionmodel_ode( t, x )
    % ------------------------------------------------------------------------
    %
    % function frictionmodel_ode( t, x)
    % 
    % Daniel Heinrich, March 2013
    % Version 1.0
    %
    % Simple model of two masses, connected with a clutch with coulomb friction.
    % Model structure: J1 --- clutch --- J2.
    %
    % called by: frictionmodel_ode --> ODE solver
    % calls: -
    %
    %
    % ------------------------------------------------------------------------
    
  
   
    %
    % State vector:
    %
    
    % angles (in radians):
    phi1 = x(1);  % first mass
    phi2 = x(2);  % second mass
    
    % angular velocities (in rad/s):
    phip1 = x(3);  % first mass
    phip2 = x(4);  % second mass
    
  
  
    %
    % Model parameters:
    %

    % inertias (in kg*m^2)
    J1 = 1;
    J2 = 1;

    % external torques (in Nm):
    T1 = 20;
    T2 = -phip2*10;

    % maximum friction torque (in Nm):
    T_friction_max = 50*(t>1)*(t<2);
    
  
  
    %
    % Solving the friction equation
    %
  
    % calculating the friction torque (assuming a sticking state):
    T_friction = (T1*J2 - T2*J1) / (J1+J2);
    
    % Solving the friction condition between the two inertias.
    % A small tolerance will be added to cope with numerical inaccuracies in the variables.
    if or( T_friction>T_friction_max, phip1>phip2+1e-3 )    % current state: sliding into positive direction
        phipp1 = (T1 - T_friction_max) / J1;
        phipp2 = (T2 + T_friction_max) / J2;
    elseif or( T_friction<-T_friction_max, phip1<phip2-1e-3 )    % current state: sliding into negative direction
        phipp1 = (T1 + T_friction_max) / J1;
        phipp2 = (T2 - T_friction_max) / J2;
    else % current state: sticking
        phipp1 = (T1 + T2) / (J1 + J2);
        phipp2 = phipp1;
    % correction of speed differences due to the above error margin:
    if 1
      phip1=(phip1+phip2)/2;
      phip2=phip1;
    end
    end

    
    %
    % Output the state vector's derivation:
    %
    
    xp=[ phip1; phip2; phipp1; phipp2];
    
end

