%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate graph HPF Trigger Gains - 21/07/2019     %
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
Switch Freq 786 kHz
TrigPass_4000
Pause_20 ms
HPF 2_5kHz
Data:
analog_channel_0  - Mic Select
analog_channel_1  - Output Signal
%}

%% Open data
% Open Recording
% save recording to smaller package

% load HPF_Trigger_Gains.mat
% save HPF_Trigger_Gains_Small analog_sample_rate_hz analog_channel_0 analog_channel_1

load HPF_Trigger_Gains_Small.mat
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
% title({'{\bf\fontsize{14} Switch HPF Trigger Gains Mode}';'';'{Pause 20, Trigger Pass 4000}'});
% xlim([0.4 1.4]);
% ylim([-1.75 1.75]);
% xlabel('Time (sec)');
% ylabel('Amplitude (v)');
% legend('DSP In','DSP Out')
% grid on


%% plot

figure(2); % time response
subplot (3,1,1);
plot(time_vector,micSignal);
%hold on
%plot(time_vector,outputSignal);
%hold off
title({'{\bf\fontsize{14} Switch HPF Trigger Gains Mode}';'';'{(a) DSP In}'});
xlim([0.4 1.4]);
ylim([-1.75 1.75]);
xlabel('Time (sec)');
ylabel('Amplitude (v)');
%legend('DSP In','DSP Out')
grid on

subplot (3,1,2);
%plot(time_vector,micSignal);
%hold on
plot(time_vector,outputSignal,'r');
%hold off
title('(b) DSP Out');
xlim([0.4 1.4]);
ylim([-1.75 1.75]);
xlabel('Time (sec)');
ylabel('Amplitude (v)');
%legend('DSP In','DSP Out')
grid on

subplot (3,1,3);
plot(time_vector,micSignal);
hold on
plot(time_vector,outputSignal);
hold off
title('(c) Pulse Zoom');
xlim([1.225 1.23]);
ylim([-1.75 1.75]);
xlabel('Time (sec)');
ylabel('Amplitude (v)');
legend('DSP In','DSP Out')
grid on
