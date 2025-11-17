function [freq,Pin_eng,Pout_eng] = importPowData(dataPath)
    Pin_eng = importAttenPower([dataPath,'PavsFund_eng1.txt']);
    Pout_eng = importAttenPower([dataPath,'PoutFund_eng1.txt']);
    freq = importAttenFreq([dataPath,'freq1.txt']);
end