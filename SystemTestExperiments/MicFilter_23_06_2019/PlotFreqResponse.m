%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate graph Freq Response - 8/07/2019          %
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

Sweep data save at:
HPFSweep_on HPF_on;
HPFSweep_off HPF_off;
%}

%% open data
load HPFSweep_on.mat
load HPFSweep_off.mat

%% Process data
[TFxy,Freq] = tfestimate(HPF_on.outputSignalSweep, HPF_on.micSignalSweep,[],[],[],3125000);
Mag = abs(TFxy);
HPF_on.MagdB = 20*log10(Mag);
HPF_on.Freq = Freq;

[TFxy,Freq] = tfestimate(HPF_off.outputSignalSweep, HPF_off.micSignalSweep,[],[],[],3125000);
Mag = abs(TFxy);
HPF_off.MagdB = 20*log10(Mag);
HPF_off.Freq = Freq;

%%
% figure(1)
% subplot (3,1,1);
% plot(HPF_on.timeVectorSweep,HPF_on.outputSignalSweep,'b')
% hold on
% scatter(HPF_on.timeVectorSweep,HPF_on.micSignalSweep,'filled','SizeData',3,'MarkerEdgeColor','r')
% alpha(.75)
% scatter(HPF_off.timeVectorSweep,HPF_off.micSignalSweep,'filled','SizeData',3,'MarkerEdgeColor','g')
% alpha(.25)
% hold off
% title('Time domain');
% axis tight
% xlabel('[sec]');
% ylabel('[volt]');

figure(1)
subplot (3,1,1);
plot(HPF_on.timeVectorSweep,HPF_on.outputSignalSweep)
hold on
plot(HPF_on.timeVectorSweep,HPF_on.micSignalSweep)
scatter(HPF_off.timeVectorSweep,HPF_off.micSignalSweep,'filled','SizeData',1)
alpha(.2)
hold off
%title('Time Domain');
title({'{\bf\fontsize{14} System Freqeuency Response}';''; '(a) Time Domain '})
axis tight
xlabel('Time (sec)');
ylabel('Amplitude (v)');
legend('Speaker','HPF on','HPF off');

% plot ranges
sweepStart = 5;
sweepEnd = 100;

subplot (3,1,2);
plot(HPF_on.Freq/1e3,HPF_on.MagdB);
hold on
plot(HPF_off.Freq/1e3,HPF_off.MagdB);
hold off
xlim([sweepStart sweepEnd])
xlabel('Frequency (kHz)')
ylim([-40 20])
ylabel('Magnitude (dB)')
grid on
legend('HPF on','HPF off')
title('(b) Magnitude Response');

subplot (3,1,3);
spectrogram(HPF_on.micSignalSweep,4096,4000,4096,3125000,'yaxis');
xlim([0 210]);
ylim([0 0.105]);
title('(c) Spectrogram (HPF on)');
