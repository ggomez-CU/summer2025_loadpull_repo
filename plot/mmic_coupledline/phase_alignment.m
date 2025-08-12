clear all
close all
clc

filename = ['/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/coupledline_samplers/MMIC_coupledline_phase2025-07-29_11_19_Freq12.0to8.0']
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