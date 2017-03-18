% Impulse-based simulation
% example code
% Daniel Heinrich, August 2015
% Version 1.0

clear; clc; close all;

% This example code shows a simple n-mass pendulum, 
% simulated with an impulse-based approach


% simulation parameters:
dt = 0.001; % time step
tmax = 4; % max time
tol = 0.01; % collision tolerance
g = 10; % might also be 9.81

% set up a couple of objects:

% number of objects:
n=5;

% Now, let's initialize all objects:
% (for simplicity, we add the center point (fixed to ground) to our objects stack)
for i=1:n+1
    objects(i).l = 1; % lever length
    objects(i).pos=[1; 1] / sqrt(2) * (i-1); % position
    objects(i).vel=objects(i).pos*0;  % start with zero velocity
    objects(i).P=objects(i).pos*0;  % impulse
    objects(i).m=1;       % mass and inertia
    % also, we'll need to iterate, so let's create temporary position and velocity fields:
    objects(i).pos_new = objects(i).pos*0;
    objects(i).vel_new = objects(i).pos*0;
end

%
% now, our system is set up. Next: Dynamic simulation
%


% show live plot?
plot_on = 0;
% plot and output each x s:
dt_plot = 0.02;
n_plots = 0;
% initialize array for results:
results = zeros(round(tmax / dt_plot)-1, 2*(n+1));

tic

% loop over timesteps:
for t=0:dt:tmax
  
    % 1) initialize: calculate initial impulse (including external forces):
    for i=2:n+1 % update all moving objects
        % gravity: impulse = mass * g * length_timestep
        objects(i).P = objects(i).m * [0; -g] * dt;
    end
    
    % 2) calculate new movement + iterate until all collisions are resolved
    collisions = true;
    iterations = 0; % count iterations
    
    while collisions % iterate until all collisions are resolved
    
        % 2.1) calculate new velocity and position:
        for i=2:n+1 % check all moving objects
            % velocity: updated with impulse.
            objects(i).vel_new = objects(i).vel + objects(i).P / objects(i).m;
            % position: updated with new velocity:
            objects(i).pos_new = objects(i).pos + objects(i).vel_new * dt;
        end
        
        % 2.2) check collisions & boundary conditions (here: lever connections):
        collisions = false; % will be set true in for loop if iteration is required
        % lever has correct position between objects? Check!
        for i=2:n+1 % check all moving objects
            % calculate distance (vector and norm):
            distance = objects(i).pos_new - objects(i-1).pos_new;
            distance_norm = norm(distance);

            % 2.3) calculate impulse required to correct the boundary condition:
            if abs(distance_norm - objects(i).l)>tol;  % boundary condition violated!
                direction = distance / distance_norm;
                P = - (distance_norm - objects(i).l) * direction * objects(i).m/2 / dt;
                % Add to both objects connected to the lever (but mind the direction!):
                objects(i).P = objects(i).P + P;
                objects(i-1).P = objects(i-1).P - P;
                % Reiterate!:
                collisions = true;
            end
        end
        
        iterations = iterations+1;
    end
    
    % 3) update objects:
    for i=2:n+1
        objects(i).vel = objects(i).vel_new;
        objects(i).pos = objects(i).pos_new;
    end 
    
    % 4) model output (plot / results):
    if t >= (n_plots * dt_plot) % only output on some timesteps
        n_plots = n_plots+1;
        for i=1:n+1
            line(:,i)=objects(i).pos;
        end
        results(n_plots, :) = [line(1,:), line(2,:)];
        if plot_on
            hold off;
            plot(line(1,:), line(2,:), 'o-', 'LineWidth', 1.5);
            hold on;
            axis([-1 1 -1 1]*(n+2));
            axis equal;
            text(-n, n, ['t=' num2str(t) ' i=' num2str(iterations)]);
            drawnow;
        end
        t_plot = t;
    end
        
end

% Plot movement tracks:
h=figure;
for i=1:n+1
    plot(results(:,i), results(:,i+n+1), '-k', 'LineWidth', 1.5);
    hold on;
end
axis([-1 1 -1 1]*(n+2));
axis equal;
