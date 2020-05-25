%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate graph Auto Mode - 31/07/2019             %
% Arkadi Rafalovich - % Arkadiraf@gmail.com         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
clear

% Setup description
%{
Mic Speaker distance 0.5m
Chirper box
Mic gain 2, mic thresh 10%
Signal generated witch Chirp Box recorded bat signal
Switch Auto mode, passthrough
Data:
analog_channel_0  - Mic Select
analog_channel_1  - Output Signal
analog_channel_2  - Mic1
analog_channel_3  - Mic2
analog_channel_4  - Mic3
analog_channel_5  - Mic4
analog_channel_6  - Mic5
%}

%% Open data
% clc
% clear
% 
% % Open Recording
% % save recording to smaller package
% load LOG_3_Saleae.mat
% load log_3.mat
% 
% RecordEnd = 6e6;
% Rec.Select = analog_channel_0(1:RecordEnd) - mean(analog_channel_0);
% Rec.Out = analog_channel_1(1:RecordEnd) - mean(analog_channel_1);
% Rec.Mic1 = analog_channel_2(1:RecordEnd) - mean(analog_channel_2);
% Rec.Mic2 = analog_channel_3(1:RecordEnd) - mean(analog_channel_3);
% Rec.Mic3 = analog_channel_4(1:RecordEnd) - mean(analog_channel_4);
% Rec.Mic4 = analog_channel_5(1:RecordEnd) - mean(analog_channel_5);
% Rec.Mic5 = analog_channel_6(1:RecordEnd) - mean(analog_channel_6);
% %time vector for plots
% Rec.time = ((1:1:size(Rec.Mic1,1))/analog_sample_rate_hz)';
% 
% Rec.analog_sample_rate_hz = analog_sample_rate_hz;
% digSample = floor(digital_channel_0 * analog_sample_rate_hz / digital_sample_rate_hz);
% %generate digital data
% digital = 0;
% trigger = 0;
% triggers = [0; table(:,1)];
% for i=1:size(digSample,1)
%     digital = [digital ; (ones(digSample(i),1)*((1+(-1)^i)/2))];
%     trigger = [trigger ; (ones(digSample(i),1)*((1+(-1)^i)/2))/2 + triggers(round((i+1)/2))];
% end
% Rec.trigger = trigger(1:RecordEnd);
% Rec.digital = digital(1:RecordEnd);
% save LOG_3_Saleae_Small Rec

%%
clc
clear

load LOG_3_Saleae_Small.mat
%% Plot
figure(1); % time response

plot(Rec.time,Rec.Out/2,'r');
hold on
plot(Rec.time,Rec.Mic1/2 + 1,'y');
plot(Rec.time,Rec.Mic2/2 + 2,'m');
plot(Rec.time,Rec.Mic3/2 + 3,'b');
plot(Rec.time,Rec.Mic4/2 + 4,'c');
plot(Rec.time,Rec.Mic5/2 + 5,'k');
plot(Rec.time,Rec.trigger,'g');
hold off
grid on
title({'{\bf\fontsize{14} Auto Switch Mode}'});%%'';'{Mic gain 2,  Mic threshold 10%}'});
xlabel('Time (sec)');
ylabel('Amplitude/2 + Mic num bias (v)');
legend('DSP Out','Mic 1','Mic 2','Mic 3','Mic 4','Mic 5','Trigger');

figure(2);

plot(Rec.time,Rec.Select,'r');
hold on
plot(Rec.time,Rec.digital,'g');
hold off
grid on
title({'{\bf\fontsize{14} Auto Switch Mode - DSP Out}'});;%%'';'{Mic gain 2,  Mic threshold 10%}'});
xlabel('Time (sec)');
ylabel('Amplitude (v)');
legend('DSP Out','Trigger')

% 
% 
% title({'{\bf\fontsize{14} Switch HPF Trigger Gains Mode}';'';'{Pause 20, Trigger Pass 4000}'});
% xlim([0.4 1.4]);
% ylim([-1.75 1.75]);
% xlabel('Time (sec)');
% ylabel('Amplitude (v)');
% legend('DSP In','DSP Out')
% grid on
% 
% 
% %% plot
% 
% figure(2); % time response
% subplot (3,1,1);
% plot(time_vector,micSignal);
% %hold on
% %plot(time_vector,outputSignal);
% %hold off
% title({'{\bf\fontsize{14} Switch HPF Trigger Gains Mode}';'';'{DSP In}'});
% xlim([0.4 1.4]);
% ylim([-1.75 1.75]);
% xlabel('Time (sec)');
% ylabel('Amplitude (v)');
% %legend('DSP In','DSP Out')
% grid on
% 
% subplot (3,1,2);
% %plot(time_vector,micSignal);
% %hold on
% plot(time_vector,outputSignal,'r');
% %hold off
% title('DSP Out');
% xlim([0.4 1.4]);
% ylim([-1.75 1.75]);
% xlabel('Time (sec)');
% ylabel('Amplitude (v)');
% %legend('DSP In','DSP Out')
% grid on
% 
% subplot (3,1,3);
% plot(time_vector,micSignal);
% hold on
% plot(time_vector,outputSignal);
% hold off
% title('Pulse Zoom');
% xlim([1.225 1.23]);
% ylim([-1.75 1.75]);
% xlabel('Time (sec)');
% ylabel('Amplitude (v)');
% legend('DSP In','DSP Out')
% grid on
