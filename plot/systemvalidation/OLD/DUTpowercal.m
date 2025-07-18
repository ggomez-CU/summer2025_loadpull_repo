clear all
close all
clc

folder = ['2025-07-14_12_12_Freq12.0to8.0'] %;...
    % '2025-07-09_16_18_Freq8.0to12.0'; ...
    % '2025-07-10_09_36_Freq8.0to12.0'; ...
    % '2025-07-10_20_57_Freq12.0to8.0'; ...
    % '2025-07-10_23_14_Freq12.0to8.0'; ...
    % '2025-07-11_01_30_Freq12.0to8.0'; ...
    % '2025-07-11_03_47_Freq12.0to8.0'; ...
    % '2025-07-11_06_04_Freq12.0to8.0'; ...
    % '2025-07-10_14_57_Freq12.0to8.0'];

%%
% for k = 1 : size(folder,1)
k = 1
    clear pm obw ibw iaw oaw freq frequencies data pna2pm_output pna2pm_input
    dname = strcat('../../data/systemvalidation/',folder(k,:));
    
    myFiles = dir(fullfile(dname,"*.json"));
    
    %%
    
    startPat = '_' + wildcardPattern + '_' + wildcardPattern + '_';
    endPat = 'GHz';
    for file_idx= 1:size(myFiles(:),1)
    % for file_idx= 1:10
        try
            freq(file_idx) = str2double(extractBetween(myFiles(file_idx).name,startPat,endPat)) ;
        catch
        end
    end
    %%
    [frequencies, idx] = sort(freq);
        
    for file_idx= 1:size(myFiles(:),1)
        try
            data(file_idx) = PowerCalClass(strcat(dname, '/', myFiles(idx(file_idx)).name)); 
        catch
        end
    end
    
    %%
    for idx = 1:1:(size(data,2))
        pm(:,idx) = data(idx).powermeter;
        iaw(:,idx) = data(idx).input_awave_dBm;
        ibw(:,idx) = data(idx).input_bwave_dBm;
        oaw(:,idx) = data(idx).output_awave_dBm;
        obw(:,idx) = data(idx).output_bwave_dBm;
    end
    
    pna2pm_input = -mean(iaw-pm)';
    pna2pm_output = -mean(obw-pm)';
    
    mkdir(strcat('..\..\data\deembed\',folder(k,:)));
    save(strcat('..\..\data\deembed\',folder(k,:),'\pna2pm_input.mat'), 'pna2pm_input'); 
    save(strcat('..\..\data\deembed\',folder(k,:),'\pna2pm_output.mat'), 'pna2pm_output');
    save(strcat('..\..\data\deembed\',folder(k,:),'\pm.mat'), 'pm');
    save(strcat('..\..\data\deembed\',folder(k,:),'\obw.mat'), 'obw');
    save(strcat('..\..\data\deembed\',folder(k,:),'\iaw.mat'), 'iaw');
    save(strcat('..\..\data\deembed\',folder(k,:),'\oaw.mat'), 'oaw');
    save(strcat('..\..\data\deembed\',folder(k,:),'\ibw.mat'), 'ibw');

% end

% %%
% thrusparam = sparameters('../../data/deembedsparam/LPSetup_Validation_2portthru_20250707_direct 4.s2p');
% outputsparam = sparameters('../../data/deembedsparam/Outputdeem2.s2p');
% output_thruloss = 10*log10(abs(permute(outputsparam.Parameters(1,2,:),[3 2 1])));
% thruloss = 10*log10(abs(permute(thrusparam.Parameters(1,2,:),[3 2 1])));
% 
% hold on
% plot(outputsparam.Frequencies(71:2:111)/1e9,output_thruloss(71:2:111))
% plot(thrusparam.Frequencies(301:20:701)/1e9,thruloss(301:20:701))
% 
% DUT2pm_output = -2*output_thruloss(71:1:111);
% DUT2pm_input = -2*output_thruloss(71:1:111);
% DUTthru = -2*thruloss(301:10:701)

% pna2pm_input = -mean(iaw-pm)';
% pna2pm_output = -mean(obw-pm)';
% 
% mkdir(strcat('C:\Users\grgo8200\Documents\AFRL_Testbench\data\deembed\',folder));
% save(strcat('C:\Users\grgo8200\Documents\AFRL_Testbench\data\deembed\',folder,'\pna2pm_input.mat'), 'pna2pm_input'); 
% save(strcat('C:\Users\grgo8200\Documents\AFRL_Testbench\data\deembed\',folder,'\pna2pm_output.mat'), 'pna2pm_output');
% save(strcat('C:\Users\grgo8200\Documents\AFRL_Testbench\data\deembed\',folder,'\pm.mat'), 'pm');
% save(strcat('C:\Users\grgo8200\Documents\AFRL_Testbench\data\deembed\',folder,'\obw.mat'), 'obw');
% save(strcat('C:\Users\grgo8200\Documents\AFRL_Testbench\data\deembed\',folder,'\iaw.mat'), 'iaw');
%%
%expected DUT plane is pm+outputthruloss
%pm is outputbwave + couplingfacter(freq)