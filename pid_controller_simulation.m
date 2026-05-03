%% PID Controller Simulation
% This script simulates a PID-controlled first-order system.
%
% Project: MATLAB Simulink Control Systems
% Tool: MATLAB
% Topic: PID control, closed-loop response, control systems
%
% The script compares:
% - open-loop system response
% - closed-loop response with PID control

clear;
clc;
close all;

%% System Parameters
K = 1.0;                 % Plant gain
tau = 2.0;               % Plant time constant [s]

%% PID Parameters
Kp = 2.0;                % Proportional gain
Ki = 0.8;                % Integral gain
Kd = 0.2;                % Derivative gain

%% Simulation Parameters
tStart = 0;
tEnd = 10;
dt = 0.01;

setpoint = 1.0;

%% Controller Limits
controlMin = -5.0;
controlMax = 5.0;
integralMin = -2.0;
integralMax = 2.0;

derivativeFilterCoefficient = 0.9;

%% Input Validation
if K <= 0
    error('Plant gain K must be greater than zero.');
end

if tau <= 0
    error('Plant time constant tau must be greater than zero.');
end

if dt <= 0 || tEnd <= tStart
    error('Check simulation time settings.');
end

if setpoint == 0
    error('Setpoint must not be zero for percentage performance metrics.');
end

%% Time Vector
time = tStart:dt:tEnd;
numberOfSteps = length(time);

%% Open-Loop Response
openLoopResponse = K * setpoint * (1 - exp(-time / tau));

%% Closed-Loop PID Simulation
output = zeros(1, numberOfSteps);
errorSignal = zeros(1, numberOfSteps);
controlSignal = zeros(1, numberOfSteps);

proportionalTerm = zeros(1, numberOfSteps);
integralTerm = zeros(1, numberOfSteps);
derivativeTerm = zeros(1, numberOfSteps);

integralError = 0;
filteredDerivative = 0;

for index = 2:numberOfSteps
    errorSignal(index) = setpoint - output(index - 1);

    proportionalTerm(index) = Kp * errorSignal(index);

    integralError = integralError + errorSignal(index) * dt;
    integralError = max(min(integralError, integralMax), integralMin);
    integralTerm(index) = Ki * integralError;

   % Derivative on measurement helps avoid derivative kick.
% MATLAB indexing starts at 1, so index - 2 would be 0 when index = 2.
if index == 2
    measurementDerivative = 0;
else
    measurementDerivative = (output(index - 1) - output(index - 2)) / dt;
end

filteredDerivative = ...
    derivativeFilterCoefficient * filteredDerivative + ...
    (1 - derivativeFilterCoefficient) * measurementDerivative;

    derivativeTerm(index) = -Kd * filteredDerivative;

    rawControlSignal = ...
        proportionalTerm(index) + ...
        integralTerm(index) + ...
        derivativeTerm(index);

    controlSignal(index) = max(min(rawControlSignal, controlMax), controlMin);

    % First-order plant model:
    % dy/dt = (-y + K*u) / tau
    plantDerivative = (-output(index - 1) + K * controlSignal(index)) / tau;
    output(index) = output(index - 1) + plantDerivative * dt;
end

%% Performance Metrics
finalOutput = output(end);
steadyStateError = setpoint - finalOutput;

maximumOutput = max(output);
overshoot = max(0, ((maximumOutput - setpoint) / abs(setpoint)) * 100);

riseStartValue = 0.10 * setpoint;
riseEndValue = 0.90 * setpoint;

riseStartIndex = find(output >= riseStartValue, 1, 'first');
riseEndIndex = find(output >= riseEndValue, 1, 'first');

if isempty(riseStartIndex) || isempty(riseEndIndex)
    riseTime10To90 = NaN;
else
    riseTime10To90 = time(riseEndIndex) - time(riseStartIndex);
end

settlingBand = 0.02;
settlingLowerLimit = setpoint * (1 - settlingBand);
settlingUpperLimit = setpoint * (1 + settlingBand);

outsideSettlingBand = output < settlingLowerLimit | output > settlingUpperLimit;
lastOutsideIndex = find(outsideSettlingBand, 1, 'last');

if isempty(lastOutsideIndex)
    settlingTime = time(1);
elseif lastOutsideIndex < numberOfSteps
    settlingTime = time(lastOutsideIndex + 1);
else
    settlingTime = NaN;
end

%% Plot Results
figure('Name', 'PID Controller Simulation');

tiledlayout(3, 1);

nexttile;
plot(time, openLoopResponse, 'LineWidth', 2);
hold on;
plot(time, output, 'LineWidth', 2);
yline(setpoint, '--', 'Setpoint', 'LineWidth', 1.5);
grid on;
xlabel('Time [s]');
ylabel('System Output');
title('Open-Loop vs PID-Controlled Response');
legend('Open-Loop', 'PID-Controlled', 'Setpoint', 'Location', 'southeast');

nexttile;
plot(time, controlSignal, 'LineWidth', 2);
hold on;
yline(controlMax, '--', 'Upper Limit');
yline(controlMin, '--', 'Lower Limit');
grid on;
xlabel('Time [s]');
ylabel('Control Signal');
title('PID Control Signal');

nexttile;
plot(time, proportionalTerm, 'LineWidth', 1.5);
hold on;
plot(time, integralTerm, 'LineWidth', 1.5);
plot(time, derivativeTerm, 'LineWidth', 1.5);
grid on;
xlabel('Time [s]');
ylabel('PID Terms');
title('PID Term Contributions');
legend('P Term', 'I Term', 'D Term');

%% Display Results
fprintf('PID Controller Simulation Results:\n');
fprintf('----------------------------------\n');
fprintf('Plant gain K: %.2f\n', K);
fprintf('Plant time constant tau: %.2f s\n', tau);
fprintf('Kp: %.2f\n', Kp);
fprintf('Ki: %.2f\n', Ki);
fprintf('Kd: %.2f\n', Kd);
fprintf('Final output: %.4f\n', finalOutput);
fprintf('Steady-state error: %.4f\n', steadyStateError);
fprintf('Overshoot: %.2f %%\n', overshoot);
fprintf('10%%-90%% rise time: %.2f s\n', riseTime10To90);
fprintf('2%% settling time: %.2f s\n', settlingTime);
fprintf('Maximum control signal: %.2f\n', max(controlSignal));
fprintf('Minimum control signal: %.2f\n', min(controlSignal));
