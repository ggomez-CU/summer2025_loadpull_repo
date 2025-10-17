clear all
close all 
clc

%%
% folder = '/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/systemvalidation/loadgain2025-07-31_17_00_Freq12.0to8.0'
folder = 'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\systemvalidation\loadgain2025-08-27_16_05_Freq10.0to8.0';
data = LoadFreqRawClass(folder);

%%
% thrusparam = sparameters('../../data/deembedsparam/LPSetup_Validation_2portthru_20250707_direct 4.s2p');
% thruloss = permute(thrusparam.Parameters(1,2,:),[3 2 1]);
% DUTthru = thruloss(301:10:701);
%%
for k = 1 : size(data.freq,2)
    filename = ['lookuptable_', num2str(data.freq(k)), '_GHz'];
    filepath = strcat('../../data/LUT2/',filename,'.mat');
    if isfile(filepath)
        LUT = load(filepath).LUT;
        col1 = [LUT(:,1); data.tunerload(:,k) ];
        col2 = [LUT(:,2); data.s11(:,k) ] ;
        [~, idx] = unique(col1);
        LUT = [ col1(idx), col2(idx)] ;
        save(strcat('../../data/LUT2/',filename,'.mat'), 'LUT');  
    else
        col1 = [data.tunerload(:,k) ];
        col2 = [data.s11(:,k) ] ;
        waves = [data.input_awave(:,k), ... 
            data.input_bwave(:,k), ... 
            data.output_awave(:,k), ... 
            data.output_bwave(:,k)]
        [~, idx] = unique(col1);
        LUT = [ col1(idx), col2(idx)] ;
        save(strcat('../../data/LUT2/',filename,'.mat'), 'LUT','waves'); 
    end
end
