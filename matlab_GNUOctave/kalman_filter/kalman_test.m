clear; clc; close all;

% Example Kalman Filter
% Daniel Heinrich, Jan 2017

% Set up parameters
% Assume values for Q and R:
R = 1;
Q = [0.001 0; 0 1e-6];

% Create variable "data":
testdata;

% The measurement data is in row 4:
meas = data(:,4);




% Initialize Kalman filter values:
F = [1 1; 0 1];
H = [1 0];
x = [0; 0];
P = Q;

% Initialize vector for results:
res_x = [0*meas 0*meas];
%res_P = 0*meas;

% Run Loop for Kalman filter for all measurements:
for k=1:length(meas)
  % prediction:
  x_pred = F * x;
  P_pred = F * P * F' + Q;
  % correction
  y = meas(k) - H * x_pred;
  S = H*P_pred*H' + R;
  K = P_pred*H'*S^-1;
  x = x_pred + K*y;
  P = P_pred - K*S*K';

  % save current state to results vector:
  res_x(k,:) = x';
  %res_P(k) = P;
end

% Plot results:
figure;
plot(meas, 'k.');
hold on;
plot(data(:,2), 'b', 'LineWidth', 2);
plot(res_x(:,1), 'r', 'LineWidth', 2);
%plot(res_x+res_P(1), 'r', 'LineWidth', 1);
%plot(res_x-res_P(1), 'r', 'LineWidth', 1);
axis([0 length(meas) -3 3]);
set(gca,'FontSize',14)
xlabel('measurements');
ylabel('value');
Q_str = '';
for i=1:size(Q,1)
  for j=1:size(Q,2)
    Q_str=[Q_str num2str(Q(i,j)) ','];
  end
  Q_str(end) = ';';
end
Q_str=Q_str(1:end-1);
title(['R=' num2str(R) ', Q=[' Q_str ']'], 'FontSize', 18);
legend('measurement', 'truth', 'estimate');

Q_str = strrep(Q_str, ',','_');
Q_str = strrep(Q_str, ';','_');
print(['plot_R' num2str(R) '_Q' Q_str '.png'],'-dpng');