%% First-Order System Simulation
% This script simulates the step response of a first-order dynamic system.
%
% Project: MATLAB Simulink Control Systems
% Tool: MATLAB
% Topic: Control systems, system dynamics, step response
%
% Transfer function concept:
% G(s) = K / (tau*s + 1)

clear;
clc;
close all;

%% System Parameters
K = 2.0;                 % System gain
tau = 1.5;               % Time constant [s]

tStart = 0;              % Start time [s]
tEnd = 10;               % End time [s]
dt = 0.01;               % Time step [s]

settlingBand = 0.02;     % 2 percent settling band

%% Input Validation
if K <= 0
    error('System gain K must be greater than zero.');
end

if tau <= 0
    error('Time constant tau must be greater than zero.');
end

if dt <= 0 || tEnd <= tStart
    error('Check simulation time settings.');
end

%% Time Vector
time = tStart:dt:tEnd;

%% Step Response
% First-order step response:
% y(t) = K * (1 - exp(-t/tau))
response = K * (1 - exp(-time / tau));

%% Theoretical Reference Values
targetValue = K;
timeConstantValue = 0.632 * targetValue;
riseValue90 = 0.90 * targetValue;
settlingLowerLimit = targetValue * (1 - settlingBand);
settlingUpperLimit = targetValue * (1 + settlingBand);

theoreticalRiseTime90 = -tau * log(1 - 0.90);
theoreticalSettlingTime2 = -tau * log(settlingBand);

%% Performance Metrics
finalValue = response(end);
steadyStateError = targetValue - finalValue;

riseIndex = find(response >= riseValue90, 1, 'first');

if isempty(riseIndex)
    riseTime90 = NaN;
else
    riseTime90 = time(riseIndex);
end

% Settling time is the first time after which the response remains inside
% the settling band.
outsideSettlingBand = response < settlingLowerLimit | response > settlingUpperLimit;
lastOutsideIndex = find(outsideSettlingBand, 1, 'last');

if isempty(lastOutsideIndex)
    settlingTime = time(1);
elseif lastOutsideIndex < length(time)
    settlingTime = time(lastOutsideIndex + 1);
else
    settlingTime = NaN;
end

%% Plot Step Response
figure('Name', 'First-Order System Step Response');

plot(time, response, 'b', 'LineWidth', 2);
hold on;

yline(targetValue, '--k', 'Final Value', 'LineWidth', 1.5);
yline(timeConstantValue, '--m', '63.2% Value', 'LineWidth', 1);
yline(riseValue90, '--r', '90% Value', 'LineWidth', 1);
yline(settlingLowerLimit, ':g', '2% Settling Lower Limit', 'LineWidth', 1);
yline(settlingUpperLimit, ':g', '2% Settling Upper Limit', 'LineWidth', 1);

xline(tau, '--m', 'Time Constant', 'LineWidth', 1);

if ~isnan(riseTime90)
    xline(riseTime90, '--r', '90% Rise Time', 'LineWidth', 1);
end

if ~isnan(settlingTime)
    xline(settlingTime, '--g', 'Settling Time', 'LineWidth', 1);
end

grid on;
xlabel('Time [s]');
ylabel('System Output');
title('First-Order System Step Response');
legend('Step Response', 'Location', 'southeast');

%% Display Results
fprintf('First-Order System Simulation Results:\n');
fprintf('--------------------------------------\n');
fprintf('System gain K: %.2f\n', K);
fprintf('Time constant tau: %.2f s\n', tau);
fprintf('Final simulated value at %.2f s: %.4f\n', tEnd, finalValue);
fprintf('Target final value: %.4f\n', targetValue);
fprintf('Time constant value, 63.2%%: %.4f\n', timeConstantValue);
fprintf('90%% rise time, simulated: %.2f s\n', riseTime90);
fprintf('90%% rise time, theoretical: %.2f s\n', theoreticalRiseTime90);
fprintf('2%% settling time, simulated: %.2f s\n', settlingTime);
fprintf('2%% settling time, theoretical: %.2f s\n', theoreticalSettlingTime2);
fprintf('Steady-state error at %.2f s: %.4f\n', tEnd, steadyStateError);
