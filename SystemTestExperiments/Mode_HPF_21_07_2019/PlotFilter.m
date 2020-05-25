%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate graph Switch filter - 21/07/2019         %
% Arkadi Rafalovich - % Arkadiraf@gmail.com         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
clear

%% Setup description
%{
Mic Speaker distance 0.5m
Supply voltage to Speaker 12V
Mic gain 4, mic thresh 50%
Scan 1-100 khz HPF Filter Board at 48Khz, xi 0.5 second order 
Op-Amp Speaker Gain is set to 1 (no gain, verified with scope) 
Test with Vifa speaker.
Test with SMD microphone

Data:
analog_channel_0  - Mic Select
analog_channel_1  - Output Signal
%}

%% open data
load HPFSweep_2.mat
load HPFSweep_8.mat

%% Process data
[TFxy,Freq] = tfestimate(HPF_2.micSignalSweep, HPF_2.outputSignalSweep,[],[],[],3125000);
Mag = abs(TFxy);
HPF_2.MagdB = 20*log10(Mag);
HPF_2.Freq = Freq;

[TFxy,Freq] = tfestimate(HPF_8.micSignalSweep, HPF_8.outputSignalSweep,[],[],[],3125000);
Mag = abs(TFxy);
HPF_8.MagdB = 20*log10(Mag);
HPF_8.Freq = Freq;

%%
% figure(1)
% subplot (3,1,1);
% plot(HPF_2.timeVectorSweep,HPF_2.outputSignalSweep,'b')
% hold on
% scatter(HPF_2.timeVectorSweep,HPF_2.micSignalSweep,'filled','SizeData',3,'MarkerEdgeColor','r')
% alpha(.75)
% scatter(HPF_8.timeVectorSweep,HPF_8.micSignalSweep,'filled','SizeData',3,'MarkerEdgeColor','g')
% alpha(.25)
% hold off
% title('Time domain');
% axis tight
% xlabel('[sec]');
% ylabel('[volt]');

figure(1)
subplot (3,1,1);
plot(HPF_2.timeVectorSweep,HPF_2.micSignalSweep)
hold on
plot(HPF_2.timeVectorSweep,HPF_2.outputSignalSweep)
hold off
%title('Time Domain');
title({'{\bf\fontsize{14} Switch High Pass Filter}';''; '(a) HPF 50kHz 2 Order'})
%axis tight
xlim([0 0.225]);
ylim([-1.25 1.25]);
xlabel('Time (sec)');
ylabel('Amplitude (v)');
legend('DSP In','DSP Out');
grid on

subplot (3,1,2);
plot(HPF_8.timeVectorSweep,HPF_8.micSignalSweep)
hold on
plot(HPF_8.timeVectorSweep,HPF_8.outputSignalSweep)
hold off
%title('Time Domain');
title({'(b) HPF 50kHz 8 Order'})
%axis tight
xlim([0 0.225]);
ylim([-1.25 1.25]);
xlabel('Time (sec)');
ylabel('Amplitude (v)');
legend('DSP In','DSP Out');
grid on

% plot ranges
sweepStart = 5;
sweepEnd = 100;

subplot (3,1,3);
plot(HPF_2.Freq/1e3,HPF_2.MagdB);
hold on
plot(HPF_8.Freq/1e3,HPF_8.MagdB);
hold off
xlim([sweepStart sweepEnd])
xlabel('Frequency (kHz)')
ylim([-60 10])
ylabel('Magnitude (dB)')
grid on
legend('order 2','order 8')
title('(c) Filter Estimate');
