clear all
close all
clc

filename = ['C:\Users\grgo8200\Documents\GitHub\summer2025_loadpull_repo\data\PA_Spring2023\phaseAlignLoadPullBiasing2025-08-14_13_02_Freq8.9to11.9']
temp = CoupledLinePhaseClass(filename);
%%
% option 2
figure
temp = temp.plot_data_fit()
figure
plot(temp.freq,temp.datafit1(2,:)-temp.datafit2(2,:));
ylabel("Phase seperation (rad)")
title("90 degree seperation using Option 2")
xlabel("Frequency (GHz)")
hold on
yline(-pi)

%%
% option 1
yyaxis right
temp.plot_diff_normalized()
ylabel("Phase seperation (rad)")
title("90 degree seperation using Option 1")
xlabel("Frequency (GHz)")
yline(0)
ylim([-0.5 1.5])