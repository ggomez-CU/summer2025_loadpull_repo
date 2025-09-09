parentDir = '/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/PA_Spring2023/LoadPullBiasing2025-08-07_15_40_Freq8.0to12.0';
% Get a list of all files and folders in the parent directory
files = dir(parentDir);

% Filter out non-directory entries and the '.' and '..' entries
isDir = [files.isdir];
subFolders = files(isDir);
subFolderNames = {subFolders.name};
subFolderNames = subFolderNames(~ismember(subFolderNames, {'.', '..'}));

report = 'report1';
% Loop through each subfolder
for i = 1:length(subFolderNames)
    currentSubFolder = fullfile(parentDir, subFolderNames{i});
    data = LoadPullClass2(currentSubFolder);
    if i == 1
        ppt = data.init_report_freq(report);
    end
    data.add2report_freq(ppt,i,replace(subFolderNames{i},'current_',' current '))
end

close(ppt);
rptview(ppt);

%%
parentDir = '/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/PA_Spring2023/LoadPullBiasing2025-08-11_10_30_Freq8.9to11.9';
% Get a list of all files and folders in the parent directory
files = dir(parentDir);

% Filter out non-directory entries and the '.' and '..' entries
isDir = [files.isdir];
subFolders = files(isDir);
subFolderNames = {subFolders.name};
subFolderNames = subFolderNames(~ismember(subFolderNames, {'.', '..'}));

report = 'report2';
% Loop through each subfolder
for i = 1:length(subFolderNames)
    currentSubFolder = fullfile(parentDir, subFolderNames{i});
    data = LoadPullClass2(currentSubFolder);
    if i == 1
        ppt = data.init_report_freq(report);
    end
    data.add2report_freq(ppt,i,replace(subFolderNames{i},'current_',' current '))
end

close(ppt);
rptview(ppt);



