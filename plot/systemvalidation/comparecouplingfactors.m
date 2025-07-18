clear all
close all
clc

topLevelFolder = '../../data/deembedatten/'; % or whatever, such as 'C:\Users\John\Documents\MATLAB\work'
% Get a list of all files and folders in this folder.
files = dir(topLevelFolder);
% Get a logical vector that tells which is a directory.
dirFlags = [files.isdir];
% Extract only those that are directories.
subFolders = files(dirFlags); % A structure with extra info.
% Get only the folder names into a cell array.
subFolderNames = {subFolders(3:end).name} % Start at 3 to skip . and ..
% Optional fun : Print folder names to command window.
%%
figure
hold on
i = 1;
for k = length(subFolderNames)-3 : length(subFolderNames)
    figure(1)
	pna2pm_input(:,i) = load(strcat(topLevelFolder,subFolderNames{k},'/pna2pm_input.mat')).pna2pm_input;
    pna2pm_output(:,i) = load(strcat(topLevelFolder,subFolderNames{k},'/pna2pm_output.mat')).pna2pm_output;
	pna2dut_output(:,i) = load(strcat(topLevelFolder,subFolderNames{k},'/pna2dut_output.mat')).pna2dut_output;
    pna2dut_input(:,i) = load(strcat(topLevelFolder,subFolderNames{k},'/pna2dut_input.mat')).pna2dut_input;
    i = i+1;
end

%%
subplot(2,2,1)
hold on
plot(pna2pm_input-mean(pna2pm_input')')
subplot(2,2,2)
hold on
plot(pna2pm_output-mean(pna2pm_output')')
subplot(2,2,3)
hold on
plot(pna2dut_input-mean(pna2dut_input')')
subplot(2,2,4)
hold on
plot(pna2dut_output-mean(pna2dut_output')')