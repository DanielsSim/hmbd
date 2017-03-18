function [res_x, res_P] = kalman(F, H, R, Q, t_meas, meas)
% Example Kalman Filter
% Daniel Heinrich, Jan 2017

% Initialize Kalman filter values:

x = meas( 1 ) * H';
P = Q;

% Initialize vector for results:
res_x = zeros( length(meas), length(F) );
res_P = zeros( length(meas), length( F )^2 );

% Loop variables k and t:
k = 1;
t = t_meas( 1 )-1;

% Run Loop for Kalman filter for all measurement data points:
while ( k < length( meas ) )
  % prediction:
  x_pred = F * x;
  P_pred = F * P * F' + Q;
  t = t + 1;

  % correction
  y = meas(k) - H * x_pred;
  S = H * P_pred * H' + R;
  K = P_pred * H' * S^-1;
  x = x_pred + K * y;
  P = P_pred - K * S * K';

  k = k + 1;
  
  % save current state to results vector:
  res_x(k,:) = x';
  for i=1:length(F)
    for j=1:length(F)
      res_P(k,(i-1)*length(F)+j) = P(i,j);
    end
  end
end

