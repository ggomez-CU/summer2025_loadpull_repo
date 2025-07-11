clear all
close all
clc


DUT2pm_output = load('../../data/deembedsparam/DUT2pm_output.mat').DUT2pm_output;
DUTthru = load('../../data/deembedsparam/DUTthru.mat').DUTthru;
topLevelFolder = '../../data/deembed/'; % or whatever, such as 'C:\Users\John\Documents\MATLAB\work'
% Get a list of all files and folders in this folder.
files = dir(topLevelFolder);
% Get a logical vector that tells which is a directory.
dirFlags = [files.isdir];
% Extract only those that are directories.
subFolders = files(dirFlags); % A structure with extra info.
% Get only the folder names into a cell array.
subFolderNames = {subFolders(3:end).name} % Start at 3 to skip . and ..
% Optional fun : Print folder names to command window.
figure
hold on
for k = 1 : length(subFolderNames)
    figure(1)
	pna2pm_input = load(strcat('../../data/deembed/',subFolderNames{k},'/pna2pm_input.mat')).pna2pm_input;
    pna2pm_output = load(strcat('../../data/deembed/',subFolderNames{k},'/pna2pm_output.mat')).pna2pm_output;
    obw = load(strcat('../../data/deembed/',subFolderNames{k},'/obw.mat')).obw;
    oaw = load(strcat('../../data/deembed/',subFolderNames{k},'/oaw.mat')).oaw;
    iaw = load(strcat('../../data/deembed/',subFolderNames{k},'/iaw.mat')).iaw;
    ibw = load(strcat('../../data/deembed/',subFolderNames{k},'/ibw.mat')).ibw;
    pm = load(strcat('../../data/deembed/',subFolderNames{k},'/pm.mat')).pm;
    subplot(2,2,1)
    hold on
    plot(pna2pm_output)
    subplot(2,2,2)
    hold on
    plot(DUT2pm_output)
    subplot(2,2,3)
    hold on
    mean(pm')
    plot(mean(pm+DUT2pm_output'-obw))%-mean(pm'+DUT2pm_output-obw')')
    subplot(2,2,4)
    hold on
    mean(pm')
    plot(mean(pm'),mean(pm'-iaw'-mean(pm-iaw)'))

    figure(2)
    subplot(2,2,1)
    plot(iaw)
    subplot(2,2,2)
    plot(ibw)
    subplot(2,2,3)
    plot(oaw)
    subplot(2,2,4)
    plot(obw)
end