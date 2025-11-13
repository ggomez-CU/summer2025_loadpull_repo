clear all
close all
clc
 
%%
% filename = ['C:\Users\grgo8200\Documents\GitHub\summer2025_loadpull_repo\data\PA_Spring2023\phaseAlignLoadPullBiasing2025-08-14_13_02_Freq8.9to11.9']
filename = '/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/coupledline_samplers/MMIC_coupledline_phase2025-07-30_10_34_Freq12.0to8.0';
filename = '/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/PA_Spring2023/PhaseAlignment2025-08-14_14_44_Freq12.0to8.0/draincurrent_1.25mA';
temp = CoupledLinePhaseClass(filename);
%%
% option 2
figure
i = 1
for z = 50:1:50
    temp = temp.plot_data_fit2(z)
    phase1(:,:,i) = temp.phs1;
    phase2(:,:,i) = temp.phs2;
    i = i+1;
end
%%
figure

subplot(2,2,1)
plot(temp.freq,permute(phase2(:,1,:),[1 3 2]))
hold on
plot(temp.freq,permute(phase1(:,1,:),[1 3 2]))
plot(temp.freq,permute(phase1(:,1,:)-phase2(:,1,:),[1 3 2]))
subplot(2,2,2)
plot(temp.freq,permute(phase2(:,2,:),[1 3 2]))
hold on
plot(temp.freq,permute(phase1(:,2,:),[1 3 2]))
subplot(2,2,3)
plot(temp.freq,permute(phase2(:,3,:),[1 3 2]))
hold on
plot(temp.freq,permute(phase1(:,3,:),[1 3 2]))
subplot(2,2,4)
plot(temp.freq,permute(phase2(:,4,:),[1 3 2]))
hold on
plot(temp.freq,permute(phase1(:,4,:),[1 3 2]))
%%
figure
i = 1
for z = 40:1:60
    temp = temp.plot_data_fit3(z)
    phase11(:,:,i) = temp.phs1;
    phase21(:,:,i) = temp.phs2;
    i = i+1;
end
%%
figure
plot(temp.freq,temp.datafit1(2,:)-temp.datafit2(2,:));
fitting_line_data_idx = find(temp.datafit1(2,:)-temp.datafit2(2,:)>0);

fitting_line_data = temp.datafit1(2,fitting_line_data_idx)-temp.datafit2(2,fitting_line_data_idx);
hold on
coefficients = polyfit(temp.freq(fitting_line_data_idx), fitting_line_data, 1); 
% Extract the slope (first coefficient) 
a = coefficients(1); 
 
% Generate the values of the line of best fit 
y_fit = polyval(coefficients, temp.freq(fitting_line_data_idx)); 

 % Plot the line of best fit 
plot(temp.freq(fitting_line_data_idx), y_fit, '-', 'DisplayName', 'Line of Best Fit'); % Line of best fit 

ylabel("Phase seperation (rad)")
title("90 degree seperation using Option 2")
xlabel("Frequency (GHz)")
hold on
yline(pi)

%%
% option 1
yyaxis right
temp.plot_diff_normalized()
ylabel("Phase seperation (rad)")
title("90 degree seperation using Option 1")
xlabel("Frequency (GHz)")
yline(0)
ylim([-0.5 1.5])