clear all
close all 
clc


folder = 'C:\Users\grgo8200\Documents\GitHub\summer2025_loadpull_repo\data\systemvalidation\loadimpedance\2025-07-07_13_51_Freq8.0to12.0';

data = LoadFreqRawClass(folder);

for k = 1 : size(folder,1)
    filename = ['lookuptable_', str(data.freq(k)). '_GHz']
    
end