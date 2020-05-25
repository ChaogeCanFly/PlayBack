%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate graph HPF Trigger - 21/07/2019           %
% Arkadi Rafalovich - % Arkadiraf@gmail.com         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
clear

% Setup description
%{
Mic Speaker distance 0.9m
Supply voltage to Speaker 12V
Mic gain 2, mic thresh 50%
Signal generated witch Chirp Box recorded bat signal
Test with Vifa speaker.
Test with SMD microphone
Switch HPF 2_5kHz
default TrigPass 4000
Data:
analog_channel_0  - Mic Select
analog_channel_1  - Output Signal
%}

%% Open data
%Open Recording
%load HPF_Off.mat
%Open Recording

load Trigger_SPK_ON_10Pause.mat
% load Trigger_SPK_ON_20Pause.mat
% load Trigger_SPK_ON_20Pause_Trig6000.mat
% load Trigger_SPK_ON_20Pause_Trig10000.mat

%% Variables

%time vector for plots
time_vector = ((1:1:size(analog_channel_0,1))/analog_sample_rate_hz)';

%sample time
Ts = 1/analog_sample_rate_hz;

% % copy signals
% micSignal       =   analog_channel_0;
% outputSignal    =   analog_channel_1;

% % Remove Bias from signals
 micSignal       =   analog_channel_0 - mean(analog_channel_0);
 outputSignal    =   analog_channel_1 - mean(analog_channel_1);

%% Plot
% figure(1); % time response
% plot(time_vector,micSignal);
% hold on
% plot(time_vector,outputSignal);
% hold off
% title({'{\bf\fontsize{14} Switch HPF Trigger Mode}';'';'{Pause 20, Trigger Pass 4000}'});
% %xlim([0.26 0.42]);
% ylim([-1.75 1.75]);
% xlabel('Time (sec)');
% ylabel('Amplitude (v)');
% legend('DSP In','DSP Out')
% grid on


%% plot multiple data sets

load Trigger_SPK_ON_10Pause.mat
% % Remove Bias from signals
micSignal       =   analog_channel_0 - mean(analog_channel_0);
outputSignal    =   analog_channel_1 - mean(analog_channel_1);
 
figure(2); % time response
subplot (3,1,1);
plot(time_vector,micSignal);
hold on
plot(time_vector,outputSignal);
hold off
title({'{\bf\fontsize{14} Switch HPF Trigger Mode}';'';'{(a) Pause 10 [ms], Trigger Pass 4000 [samples]}'});
xlim([0.26 0.42]);
ylim([-1.75 1.75]);
xlabel('Time (sec)');
ylabel('Amplitude (v)');
legend('DSP In','DSP Out')
grid on

% open next data set
load Trigger_SPK_ON_20Pause_Trig6000.mat
% % Remove Bias from signals
micSignal       =   analog_channel_0 - mean(analog_channel_0);
outputSignal    =   analog_channel_1 - mean(analog_channel_1);

subplot (3,1,2);
plot(time_vector,micSignal);
hold on
plot(time_vector,outputSignal);
hold off
title('(b) Pause 20 [ms], Trigger Pass 6000 [samples]');
xlim([0.179 0.179+0.1600]);
ylim([-1.75 1.75]);
xlabel('Time (sec)');
ylabel('Amplitude (v)');
legend('DSP In','DSP Out')
grid on

subplot (3,1,3);
plot(time_vector,micSignal);
hold on
plot(time_vector,outputSignal);
hold off
title('(c) Close up view: Pause 20 [ms], Trigger Pass 6000 [samples]');
xlim([0.191 0.2]);
ylim([-1.75 1.75]);
xlabel('Time (sec)');
ylabel('Amplitude (v)');
legend('DSP In','DSP Out')
grid on
