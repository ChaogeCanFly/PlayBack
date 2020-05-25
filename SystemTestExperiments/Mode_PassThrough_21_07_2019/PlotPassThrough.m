%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate graph PassThrough - 10/07/2019           %
% Arkadi Rafalovich - % Arkadiraf@gmail.com         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
clear

% Setup description
%{
Mic Speaker distance 0.9m
Supply voltage to Speaker 12V
Mic gain 1, mic thresh 50%
Scan 1-100 khz HPF Filter Board at 48Khz, xi 0.5 second order 
Signal generated witch Chirp Box
Test with Vifa speaker.
Test with SMD microphone

Data:
analog_channel_0  - Mic Select
analog_channel_1  - Output Signal
%}

%% Open data
%Open Recording
%load HPF_Off.mat
%Open Recording

load PassThrough.mat

%% Variables

%time vector for plots
time_vector = ((1:1:size(analog_channel_0,1))/analog_sample_rate_hz)';

%sample time
Ts = 1/analog_sample_rate_hz;

% Remove Bias from signals
micSignal       =   analog_channel_0 - mean(analog_channel_0);
outputSignal    =   analog_channel_1 - mean(analog_channel_1);

%% Plot
figure(1); % time response
plot(time_vector,micSignal);
hold on
plot(time_vector,outputSignal);
hold off
title({'{\bf\fontsize{14} Switch Passthrough Mode}';''});
xlim([0.0867 0.0872]);
ylim([-1 1]);
xlabel('Time (sec)');
ylabel('Amplitude (v)');
legend('DSP In','DSP Out')
grid on

%% Plot
figure(1); % time response
plot(time_vector,micSignal);
hold on
plot(time_vector,outputSignal);
hold off
title({'{\bf\fontsize{14} Switch Passthrough Mode}';''});
xlim([0.0867 0.0872]);
ylim([-1 1]);
xlabel('Time (sec)');
ylabel('Amplitude (v)');
legend('DSP In','DSP Out')
grid on

%% plot with delay

figure(2); % time response
subplot(2,1,1)
plot(time_vector,micSignal);
hold on
plot(time_vector,outputSignal);
hold off
title({'{\bf\fontsize{14} Switch Passthrough Mode}';'';'(a) Sinc pulse view'});
xlim([0.0867 0.0872]);
ylim([-1 1]);
xlabel('Time (sec)');
ylabel('Amplitude (v)');
legend('DSP In','DSP Out')
grid on

subplot(2,1,2)
plot(micSignal(271600:271700));
hold on
plot(outputSignal(271600:271700));
hold off
title({'{(b) Delay zoom (samples)}'});
%xlim([0.0867 0.0872]);
ylim([-0.1 0.1]);
xlabel('Samples');
ylabel('Amplitude (v)');
legend('DSP In','DSP Out')
grid on

