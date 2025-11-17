% Import Power values

% EXAMPLE CALL: 
% freq = (table2array(importFreq([dataPath,'freq1.txt']))/1e9)';    % import frequencies from folder
% [inAtten, outAtten] = getAttenMeasData(freq);                     % get atten values for all those frequencies
function [inAtten, outAtten] = getAttenMeasData(tmpFreq)
    %{
    clear
    close all
    tmpFreq = 7:1:14;
    %}
    addpath('C:\Users\grgo8200\OneDrive - UCB-O365\Documents\Research\Impedance Sensing\IMS 2023 PA Integrated 90deg\SparameterData\GraceData') % SET TO FOLDER PATH OF SCRIPTS
    dataPath = 'C:\Users\grgo8200\OneDrive - UCB-O365\Documents\Research\Impedance Sensing\IMS 2023 PA Integrated 90deg\SparameterData\GraceData\'; % SET TO FOLDER PATH OF DATA FOLDERS (the folder names below are still good)

    [freq,Pavs_eng1,Pout_eng1] = importPowData([dataPath,'outAtten_20240228_test2\']);
    [~,Pavs_eng2,Pout_eng2] = importPowData([dataPath,'outAtten_20240229_test1\']);
    [~,Pavs_eng3,Pout_eng3] = importPowData([dataPath,'outAtten_20240229_test2\']);
    [~,Pavs_eng4,Pout_eng4] = importPowData([dataPath,'outAtten_20240229_test3\']);
    Pavs_eng = (Pavs_eng1 + Pavs_eng2 + Pavs_eng3 + Pavs_eng4)/4;
    Pout_eng = (Pout_eng1 + Pout_eng2 + Pout_eng3 + Pout_eng4)/4;
    outAtten_tmp = Pout_eng - Pavs_eng;
    %outAtten_tmp = mean(outAtten_tmp);

    [~,Pin_eng1,Pout_eng1] = importPowInData([dataPath,'inAtten_20240229_test1\']);
    [~,Pin_eng2,Pout_eng2] = importPowInData([dataPath,'inAtten_20240229_test2\']);
    [~,Pin_eng3,Pout_eng3] = importPowInData([dataPath,'inAtten_20240229_test3\']);
    Pin_eng = (Pin_eng1 + Pin_eng2 + Pin_eng3)/3;
    Pout_eng2_inAtten = (Pout_eng1 + Pout_eng2 + Pout_eng3)/3;

    [~,Pin_eng4,Pout_eng4] = importPowInData([dataPath,'probeAtten_20240229_test1\']);
    [~,Pin_eng5,Pout_eng5] = importPowInData([dataPath,'probeAtten_20240229_test2\']);
    [~,Pin_eng6,Pout_eng6] = importPowInData([dataPath,'probeAtten_20240229_test3\']);
    Pin_engProbe = (Pin_eng4 + Pin_eng5 + Pin_eng6)/3;
    Pout_engProbe = (Pout_eng4 + Pout_eng5 + Pout_eng6)/3;

    tmp = Pin_eng - (Pout_eng2_inAtten - outAtten_tmp);
    probeAtten_tmp = tmp - (Pin_engProbe - (Pout_engProbe - outAtten_tmp));
    
    probeAtten = mean(probeAtten_tmp)/2;
    inAtten_tmp = mean(tmp) + probeAtten;
    outAtten_tmp = mean(outAtten_tmp) + probeAtten;
    
    freqAtten = [freq/1e9, inAtten_tmp',outAtten_tmp'];
    
    error = mean(Pin_engProbe - inAtten_tmp - (Pout_engProbe - outAtten_tmp));
    %{
    figure
    plot(freq,error)
    grid on
    %}
    inAtten_tmp = inAtten_tmp;% + error;
    outAtten_tmp = outAtten_tmp;% - error;

    if length(tmpFreq) == 1
        [inAtten, outAtten] = getAtten(tmpFreq,freqAtten);
    else
        tmpInAtten = zeros(length(tmpFreq),1);
        tmpOutAtten = zeros(length(tmpFreq),1);
        for it1 = 1:1:length(tmpFreq)
            [tmpInAtten(it1),tmpOutAtten(it1)] = getAtten(tmpFreq(it1),freqAtten);
        end
        inAtten = tmpInAtten;
        outAtten = tmpOutAtten;
    end

    %inAtten = tmpInAtten;% + error;
    %outAtten = tmpOutAtten;% - error;
    %{
    figure
    hold on
    %plot(freq,mean(Pout_eng-Pavs_eng)-outAtten_tmp+inAtten-mean(Pin_eng))
    plot(tmpFreq,inAtten)
    plot(tmpFreq,outAtten)
    hold off
    grid on
    %}
end










