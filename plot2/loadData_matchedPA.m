
clear all
close all
clc

addpath('C:\Users\grgo8200\repos\summer2025_loadpull_repo\plot2\Classes')
addpath('C:\Users\grgo8200\repos\summer2025_loadpull_repo\plot2\functions')

topLevelFolder = 'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\PA_Spring2023\DriveUp\LoadPullBiasing2025-08-07_15_40_Freq8.0to12.0_DU\'
% it has to have the stupid \ at the end
files = dir(topLevelFolder);
dirFlags = [files.isdir];
subFolders = files(dirFlags);
subFolderNames = {subFolders(3:end).name};

LUTfolder = 'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\LUT2';
coupledline_data = DataTableClass({strcat(topLevelFolder,subFolderNames{1})},LUTfolder);

for i = 1:length(subFolderNames)
    tempfolder = subFolderNames{i};
    if tempfolder(1:4) == "Load"
        files = dir(strcat(topLevelFolder,subFolderNames{i}));
        dirFlags = [files.isdir];
        subFolders = files(dirFlags);
        subsubFolderNames = {subFolders(3:end).name};
        for j = 1:length(subsubFolderNames)
            coupledline_data = coupledline_data.add_data(strcat(topLevelFolder,subFolderNames(i),'\',subsubFolderNames(j)));
        end
    else
        coupledline_data = coupledline_data.add_data(strcat(topLevelFolder,subFolderNames(i)));
    end
end

%%
close all
clear MaxPAE Maxoutput
hold on
biasV = round(1.7:0.05:1.9,2);
for bias_idx = 1:length(biasV)
    TT = rowfilter(coupledline_data.data);
    filtered_data = coupledline_data.data(round(coupledline_data.data.GateV,3)==biasV(bias_idx),:);
    freq_list = unique(filtered_data.frequency);
    for freq_idx = 3:length(freq_list)
        TT = rowfilter(filtered_data);
        freq_data = filtered_data(filtered_data.frequency==freq_list(freq_idx),:);
        [maxfreq, idx] = max(freq_data.PAE);
        output_power = freq_data.DUT_output_dBm(idx);
        input_power = freq_data.DUT_input_dBm(idx);
        MaxPAE(:,freq_idx-2,bias_idx) = [maxfreq,output_power,input_power,freq_list(freq_idx)]  
    
        [output_power, idx] = max(freq_data.DUT_output_dBm);
        maxfreq = freq_data.PAE(idx);
        input_power = freq_data.DUT_input_dBm(idx);
        Maxoutput(:,freq_idx-2,bias_idx) = [maxfreq,output_power,input_power,freq_list(freq_idx)]  
    
    end
    subplot(1,2,1)
    hold on
    yyaxis left
    plot(MaxPAE(4,:,bias_idx),MaxPAE(1,:,bias_idx))
    yyaxis right
    plot(MaxPAE(4,:,bias_idx),MaxPAE(2,:,bias_idx))

    subplot(1,2,2)
    hold on
    yyaxis left
    plot(Maxoutput(4,:,bias_idx),Maxoutput(1,:,bias_idx))
    yyaxis right
    plot(Maxoutput(4,:,bias_idx),Maxoutput(2,:,bias_idx))
end

for idx_dev = 1:size(Maxoutput,3)
    output_deviation(idx_dev) = max(Maxoutput(2,:,idx_dev))-min(Maxoutput(2,:,idx_dev));
end

sim_data = readmatrix('C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\simulated\simulatedPout24mA.txt');
freq = sim_data(:,1);
sim_data = sim_data(:,2:end);
peakout= max(sim_data,[],2);
sim_data = readmatrix('C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\simulated\simulatedPAE24mA.txt');
sim_data = sim_data(:,2:end);
peakPAE = max(sim_data,[],2);

[~,mindidx]=min(output_deviation);

%1.75 in test is 24mA

figure
hold on
plot(MaxPAE(4,:,mindidx),MaxPAE(1,:,mindidx),'LineWidth',3)
plot(freq(9:15),peakPAE(9:15),'LineWidth',3)
ylabel("PAE (/%)")
yyaxis right
plot(freq(9:15),peakout(9:15),'LineWidth',3)
plot(Maxoutput(4,:,mindidx),Maxoutput(2,:,mindidx),'LineWidth',3)
xlabel("Frequency (GHz)")
ylabel("Output Power (dBm)")
ylim([27 30.5])
yticks(27:.5:30.5)
ax = gca;
ax.YAxis(1).Color = 'k';
ax.YAxis(2).Color = 'k';
grid on

figure
hold on
plot(MaxPAE(4,:,mindidx),MaxPAE(1,:,mindidx),'LineWidth',3)
plot(freq(9:15),peakPAE(9:15),'LineWidth',3)
ylabel("PAE (/%)")
ylim([25 45])
yyaxis right
plot(freq(9:15),peakout(9:15),'LineWidth',3)
plot(Maxoutput(4,:,mindidx),Maxoutput(2,:,mindidx),'LineWidth',3)
xlabel("Frequency (GHz)")
ylabel("Output Power (dBm)")
ylim([28.5 30.5])
yticks(28.5:.5:30.5)
ax = gca;
ax.YAxis(1).Color = 'k';
ax.YAxis(2).Color = 'k';
grid on
