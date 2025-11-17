% Start thinking about how to compile all data
% this is gonna be not fun...
clear 
% [colorOptions, colorAssign, linewidth] = plotConfig(1,1.5);
close all

addpath('./adamCode/')

dataPath = 'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\SparameterData\';
freq = (table2array(readtable([dataPath,'GraceTestData_20240301_test1\freq1.txt']))/1e9)';
[inAtten, outAtten] = getAttenMeasData(freq);

% import measured Data
[pin_eng1, pout_eng1, pDC_eng1] = importFreqSweepData([dataPath,'GraceTestData_20240301_test1\']);
[pin_eng2, pout_eng2, pDC_eng2] = importFreqSweepData([dataPath,'GraceTestData_20240301_test2\']);
[pin_eng3, pout_eng3, pDC_eng3] = importFreqSweepData([dataPath,'GraceTestData_20240301_test1\']);
[pin_eng4, pout_eng4, pDC_eng4] = importFreqSweepData([dataPath, 'GraceTestData_20240301_test2\']);

%% set Nan to zeros
nan_indices1 = isnan(pin_eng3);
nan_indices2 = isnan(pout_eng3);
nan_indices3 = isnan(pDC_eng3);
pin_eng3(nan_indices1) = 0; 
pout_eng3(nan_indices2) = 0; 
pDC_eng3(nan_indices3) = 0; 

nan_indices1 = isnan(pin_eng4);
nan_indices2 = isnan(pout_eng4);
nan_indices3 = isnan(pDC_eng4);
pin_eng4(nan_indices1) = 0; 
pout_eng4(nan_indices2) = 0; 
pDC_eng4(nan_indices3) = 0; 

%% Average Data
pin_eng =  (pin_eng1 + pin_eng2 + pin_eng3 + pin_eng4)/4;
pout_eng = (pout_eng1 + pout_eng2 + pout_eng3 + pout_eng4)/4;
pDC = (pDC_eng1 + pDC_eng2 + pDC_eng3 + pDC_eng4)/4;

inAtten = repmat(inAtten',length(pin_eng(:,1)),1);
outAtten = repmat(outAtten',length(pin_eng(:,1)),1);

% Calculations
pOut = pout_eng - outAtten;
pIn = pin_eng - inAtten;

gain = pOut - pIn;

pOutWatts = 10.^(pOut/10)/1000;
pInWatts = 10.^(pIn/10)/1000;

PAE = 100*(pOutWatts - pInWatts)./pDC;

%% Need to track indicies with the closest input powers for frequency sweeps
pDes = 19;
% want to find indices where pIn is closest to 18 dBm
indexTmp = zeros(length(pIn(1,:)),1);
for it1 = 1:1:length(pIn(1,:))
    diff1 = abs(pIn(:,it1)-pDes);
    indexTmp(it1) = find(diff1 == min(diff1));
end

tmpPin = zeros(length(pIn(1,:)),1);
tmpPout = zeros(length(pIn(1,:)),1);
tmpGain = zeros(length(pIn(1,:)),1);
tmpPAE = zeros(length(pIn(1,:)),1);

for it1 = 1:1:length(pIn(1,:))
    tmpPin(it1) = pIn(indexTmp(it1),it1);
    tmpPout(it1) = pOut(indexTmp(it1),it1);
    tmpGain(it1) = gain(indexTmp(it1),it1);
    tmpPAE(it1) = PAE(indexTmp(it1),it1);
end

diff_pin = pDes - tmpPin;
figure
plot(freq,diff_pin)
grid on
xlabel('Frequency (GHz)')
ylabel('PinDiff (dB)')

%% Get Sim Data
SimDataDir = 'C:\Users\grgo8200\OneDrive - UCB-O365\Documents\Research\Impedance Sensing\IMS 2023 PA Integrated 90deg\SparameterData\GraceData';
addpath(SimDataDir)

freqSweep = importSimFreqSweep_BActrlAmp('Sim20dBmdata.txt');

maxFreq = max(freqSweep(:,1));

[index] = find(freqSweep(:,1) == maxFreq);
freqSim = freqSweep(1:(index(1)))/1e9;


freqSweep_Gain = freqSweep(1:(index(1)),2);
freqSweep_PAE = freqSweep((index(1)+1:index(2)),2);
freqSweep_Pout =freqSweep((index(2)+1:index(3)),2);

%% Plotting Frequency Sweeps
%}

figure
hold on
plot(freq,tmpGain,'color',colorOptions(1,:),'linewidth',linewidth)
plot(freq,tmpPAE,'color',colorOptions(2,:),'linewidth',linewidth)
plot(freq,tmpPout,'color',colorOptions(3,:),'linewidth',linewidth)

plot(freqSim,freqSweep_Gain,'--','color',colorOptions(1,:),'linewidth',linewidth)
plot(freqSim,freqSweep_PAE,'--','color',colorOptions(2,:),'linewidth',linewidth)
plot(freqSim,freqSweep_Pout,'--','color',colorOptions(3,:),'linewidth',linewidth)

hold off
ylim([0 35])
xlim([25 46])
grid on
xlabel('Frequency (GHz)')
ylabel('CW Measurement')
legend('Gain (dB)','PAE (%)', 'Pout (dBm)','orientation','horizontal')
set(gca,'Box','on');
set(gcf,'color','w');









