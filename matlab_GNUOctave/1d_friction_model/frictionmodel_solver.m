% ------------------------------------------------------------------------
%
% script frictionmodel_solver
% 
% Daniel Heinrich, March 2013
% Version 1.0
% 
% Solver for frictionmodel_ode
% (Simple model of two masses, connected with a clutch with coulomb friction)
%
% called by: user
% calls: ode45 (or any other ODE solver)
%        frictionmodel_ode
%
%
% ------------------------------------------------------------------------


clear; clc; close all;

%
% Preparations
%

% initial state:
y0=[0, 0, 0, 0];

% ODE solver settings:
[options] = odeset ('RelTol', 1e-6, 'AbsTol', 1e-6, 'InitialStep', 0.001, 'MaxStep', 0.1);
tmax=3;

%
% Integration
%
tic;
[t, y] = ode45(@frictionmodel_ode, [0 tmax], [y0], options);
toc;

%
% Plotting the results
%
figure;

% Subplot 1: Speeds
subplot(2,1,1);

plot(t, y(:, 3), 'k', 'LineWidth', 2);
hold on;
plot(t, y(:, 4), 'r', 'LineWidth', 2);

xlabel('time');
ylabel('speed in rad/s');
legend('inertia 1', 'inertia 2');

% Subplot 2: integration stepsize
subplot(2,1,2);

plot(t(1:end-1), diff(t), 'LineWidth', 2);

xlabel('time');
ylabel('integrator stepsize in s');