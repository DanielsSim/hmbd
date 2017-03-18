clear all; clc;
% test environment for object-oriented MBS
% Daniel Heinrich, april 2016, http://hmbd.wordpress.com
% released under CC BY-NC-SA licence.


%% create object stack (make it global!):
global s;

% create two masses and one spring:
s(1).o = mass_1d(1);
s(1).i = [1,2];
s(2).o = mass_1d(1);
s(2).i = [3,4];
s(3).o = spring_1d(10,s(1).o, s(2).o);
s(3).i = [];

%% simulate:
tic
[t,y] = ode45(@MBS_ODE, [0 10], [1;0;0;0]);
toc

%% plot positions:
plot(t,y(:,1),'k','LineWidth',2);
hold on;
plot(t,y(:,3),'r','LineWidth',2);
grid on;
xlabel('time in s');
ylabel('position in m');


%% Add a third mass and a second spring to the stack:
s(4).o = mass_1d(0.2);
s(4).i = [5,6];
s(5).o = spring_1d(5,s(2).o, s(4).o);
s(5).i = [];

%% simulate:
tic
[t,y] = ode45(@MBS_ODE, [0 10], [1;0;0;0;0;10]);
toc

%% plot positions:
figure;
plot(t,y(:,1),'k','LineWidth',2);
hold on;
plot(t,y(:,3),'r','LineWidth',2);
grid on;
plot(t,y(:,5),'b','LineWidth',2);
grid on;
xlabel('time in s');
ylabel('position in m');
