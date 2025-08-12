parentDir = '/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/PA_Spring2023/LoadPullBiasing2025-08-07_12_33_Freq8.0to12.0'; % Replace with your actual path

% Get a list of all files and folders in the parent directory
files = dir(parentDir);

% Filter out non-directory entries and the '.' and '..' entries
isDir = [files.isdir];
subFolders = files(isDir);
subFolderNames = {subFolders.name};
subFolderNames = subFolderNames(~ismember(subFolderNames, {'.', '..'}));

% Loop through each subfolder
for i = 1:length(subFolderNames)
    currentSubFolder = fullfile(parentDir, subFolderNames{i});
    data = DriveUpClass(currentSubFolder);
    data.generate_report(strcat(subFolderNames{i},'_loadpull'))
end

