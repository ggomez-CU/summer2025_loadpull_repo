% import measured freqSweepData
function [pin,pout,pDC] = importFreqSweepData(dataPath)
    pin = importFreqSweep([dataPath,'PinFund_eng1.txt']);
    pout = importFreqSweep([dataPath,'PoutFund_eng1.txt']);
    
    Vg1 = importFreqSweep([dataPath,'Vg1_eng1.txt']);
    Vd1 = importFreqSweep([dataPath,'Vd1_eng1.txt']);
    Vg2 = importFreqSweep([dataPath,'Vg2_eng1.txt']);
    Vd2 = importFreqSweep([dataPath,'Vd2_eng1.txt']);
    Ig1 = importFreqSweep([dataPath,'Ig1_eng1.txt']);
    Id1 = importFreqSweep([dataPath,'Id1_eng1.txt']);
    Ig2 = importFreqSweep([dataPath,'Ig2_eng1.txt']);
    Id2 = importFreqSweep([dataPath,'Id2_eng1.txt']);

    pDC = Vg1.*Ig1 + Vd1.*Id1 + Vg2.*Ig2 + Vd2.*Id2;
end





















