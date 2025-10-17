
clear all
close all
clc

addpath('C:\Users\grgo8200\repos\summer2025_loadpull_repo\plot2\Classes')
addpath('C:\Users\grgo8200\repos\summer2025_loadpull_repo\plot2\functions')

topLevelFolder = 'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\coupledline_samplers\LoadPullBiasing2025-08-26_09_03_Freq12.0to8.0\'; % or whatever, such as 'C:\Users\John\Documents\MATLAB\work'
files = dir(topLevelFolder);
dirFlags = [files.isdir];
subFolders = files(dirFlags);
subFolderNames = {subFolders(3:end).name};

LUTfolder = 'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\LUT2';
coupledline_data = DataTableClass({strcat(topLevelFolder,subFolderNames{1})},LUTfolder);

for i = 1:length(subFolderNames)
    coupledline_data = coupledline_data.add_data(strcat(topLevelFolder,subFolderNames(i)));
end

coupledline_data= coupledline_data.samplercoupling;

