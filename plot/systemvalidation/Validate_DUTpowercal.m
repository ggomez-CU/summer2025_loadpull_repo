clear all
close all
clc

% dname = '../../data/systemvalidation/2025-07-09_16_18_Freq8.0to12.0';
% dname = '../../data/systemvalidation/2025-07-10_09_36_Freq8.0to12.0';
% dname = '../../data/systemvalidation/2025-07-09_14_28_Freq9.0to12.0';
% dname = '../../data/systemvalidation/2025-07-10_11_27_Freq8.0to12.0';
dname = '../../data/systemvalidation/2025-07-10_13_57_Freq8.0to12.0';
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

%%
% DUT2pm_input = load('../../data/deembedsparam/DUT2pm_input.mat').DUT2pm_input
DUT2pm_output = load('../../data/deembedsparam/DUT2pm_output.mat').DUT2pm_output;
DUTthru = load('../../data/deembedsparam/DUTthru.mat').DUTthru;
pna2pm_input = load('../../data/deembedsparam/pna2pm_input_hp.mat').pna2pm_input;
pna2pm_output = load('../../data/deembedsparam/pna2pm_output.mat').pna2pm_output;
validation07091618_inputpowerdBm = load('./validation07091618').validation07091618_inputpowerdBm;
sampleidx = load('sampleidx.mat').sampleidx;
%%
close all
figure
sgtitle("Error in of Actual-Expected")
subplot(3,2,1)
scatter(frequencies,pm'-pna2pm_output(:)-obw','k')
hold on
scatter(frequencies,mean(obw-pm)'-obw'+pm','b')
ylim([-0.1,0.1])
title("Output Coupling Error")

subplot(3,2,2)
scatter(frequencies,pm'-pna2pm_input(:)-iaw','k')
hold on
scatter(frequencies,mean(iaw-pm)'-iaw'+pm','b')
title("Input Coupling Error")
ylim([-0.1,0.1])

subplot(3,2,3)
scatter(frequencies,-mean(obw-pm)','b')
hold on
scatter(frequencies,pna2pm_output(:),'k')
title("Coupling Comparison Output")

subplot(3,2,4)
scatter(frequencies,-mean(iaw-pm)','b')
hold on
scatter(frequencies,pna2pm_input(:),'k')
title("Coupling Comparison Input")
legend('Direct Calculation', 'Precalibrated Calculation')
%%
subplot(3,2,5)
title("Output Coupling Error")
scatter(validation0710_inputpowerdBm,pm-pna2pm_output'-obw,'k')
hold on
scatter(validation0710_inputpowerdBm,mean(obw-pm)-obw+pm,'b')

subplot(3,2,6)
title("Input Coupling Error")
scatter(validation0710_inputpowerdBm,pm'-pna2pm_input-iaw'+DUTthru,'k')
hold on
scatter(validation0710_inputpowerdBm,mean(iaw-pm)'-iaw'+pm'+DUTthru,'b')

figure
title("Error: Actual - Expected")
subplot(1,2,1)
histogram(pm-(pna2pm_output'+obw))
hold on
histogram(mean(obw-pm)-obw+pm)

subplot(1,2,2)
histogram(pm-pna2pm_input'-iaw)
hold on
histogram(mean(iaw-pm)-iaw+pm)
%%
figure
sgtitle('Error Distibution') 
subplot(2,2,1)

boxplot(pm'-pna2pm_output-obw',validation0710_inputpowerdBm)
title("Output Power Error vs PNA power")
ylim([-.03,.03])

subplot(2,2,2)

boxplot(mean(obw-pm)'-obw'+pm',validation0710_inputpowerdBm)
title("Output Power Error Direct vs PNA power")
ylim([-.03,.03])

subplot(2,2,3)

sampleidx = sort([1:1:5 1:1:5 1:1:5 1:1:5 1:1:5 1:1:5 1:1:5 1:1:5 1:1:5 1:1:5 1:1:5])

boxplot(pm'-pna2pm_output-obw',sampleidx)
title("Output Power Error vs Sample Index")
ylim([-.03,.03])

subplot(2,2,4)

boxplot(mean(obw-pm)'-obw'+pm',sampleidx)
title("Output Power Error Direct vs Sample Index")
ylim([-.03,.03])

%%
figure
sgtitle('Error Distibution') 
subplot(2,2,1)

boxplot(pm'-pna2pm_input-iaw',validation0710_inputpowerdBm)
title("Input Power Error vs PNA power")
ylim([-.03,.03])

subplot(2,2,2)

boxplot(mean(iaw-pm)'-iaw'+pm',validation0710_inputpowerdBm)
title("Input Power Error Direct vs PNA power")
ylim([-.03,.03])

subplot(2,2,3)

boxplot(pm'-pna2pm_input-iaw',sampleidx)
title("Input Power Error vs Sample Index")
ylim([-.03,.1])

subplot(2,2,4)

boxplot(mean(iaw-pm)'-iaw'+pm',sampleidx)
title("Input Power Error Direct vs Sample Index")
ylim([-.03,.03])


%%
thrusparam = sparameters('../../data/deembedsparam/LPSetup_Validation_2portthru_20250707_direct 4.s2p');
outputsparam = sparameters('../../data/deembedsparam/Outputdeem2.s2p');
output_thruloss = 10*log10(abs(permute(outputsparam.Parameters(1,2,:),[3 2 1])));
thruloss = 10*log10(abs(permute(thrusparam.Parameters(1,2,:),[3 2 1])));

hold on
plot(outputsparam.Frequencies(71:2:111)/1e9,output_thruloss(71:2:111))
plot(thrusparam.Frequencies(301:20:701)/1e9,thruloss(301:20:701))

DUT2pm_output = -2*output_thruloss(71:1:111);
DUT2pm_input = -2*output_thruloss(71:1:111);
DUTthru = -2*thruloss(301:10:701)

pna2pm_input = -mean(iaw-pm)';
pna2pm_output = -mean(obw-pm)';

%%
%expected DUT plane is pm+outputthruloss
%pm is outputbwave + couplingfacter(freq)