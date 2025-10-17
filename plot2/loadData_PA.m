
clear all
close all
clc

addpath('C:\Users\grgo8200\repos\summer2025_loadpull_repo\plot2\Classes')
addpath('C:\Users\grgo8200\repos\summer2025_loadpull_repo\plot2\functions')

topLevelFolder = 'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\PA_Spring2023\'
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

coupledline_data = coupledline_data.freqpowerbias_bL2dependent;

