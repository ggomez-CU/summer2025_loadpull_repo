
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

LUTfolder = 'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\LUT3';
coupledline_data = DataTableClass({strcat(topLevelFolder,subFolderNames{1})},LUTfolder);

for i = 1:length(subFolderNames)
    tempfolder = subFolderNames{i};
    if tempfolder(1:4) == "Load" %cant do phase bc no LUT
        files = dir(strcat(topLevelFolder,subFolderNames{i}));
        dirFlags = [files.isdir];
        subFolders = files(dirFlags);
        subsubFolderNames = {subFolders(3:end).name};
        for j = 1:length(subsubFolderNames)
            coupledline_data = coupledline_data.add_data(strcat(topLevelFolder,subFolderNames(i),'/',subsubFolderNames(j)));
        end
    else
        coupledline_data = coupledline_data.add_data(strcat(topLevelFolder,subFolderNames(i)));
    end
end

coupledline_data = coupledline_data.freqpowerbias_bL2dependent;

%%

xd = 1;
xplot = [];
yplot = [];
for x = 1:size(coupledline_data.sampler_bias_list,2)-1
    for y = 1:size(coupledline_data.power_list,2)
        for z = 1:size(coupledline_data.freq_list,2)
            
            colororder(coupledline_data.colors)
            [samp1raw,samp2raw,gamma] = coupledline_data.get_singlesweep( ...
                coupledline_data.freq_list(z), ...
                coupledline_data.power_list(y), ...
                [coupledline_data.sampler_bias_list(x), ...
                coupledline_data.sampler_bias_list(x+1)]);
            fpb_fit =  coupledline_data.get_freqpowerbiasbL2row( ...
                coupledline_data.freq_list(z), ...
                coupledline_data.power_list(y), ...
                [coupledline_data.sampler_bias_list(x), ...
                coupledline_data.sampler_bias_list(x+1)]);
            if ~isempty(fpb_fit) & length(gamma)> 10
                yplot = [yplot, fpb_fit.RMSError];
                xplot = [xplot,xd+1];
                xd = xd+1;
                figure(1)
                plot(xplot,yplot)
            end

            if ~isempty(fpb_fit) & length(gamma) > 10 & fpb_fit.RMSError >.001 & fpb_fit.RMSError <.03698

                % subplot(3,3,1)
                figure
                hold on
                ylabel('Sampler (mV)')
                xlabel('data sampler')
                set(gca,'ColorOrderIndex',1)
                plot(angle(gamma),samp1raw*1000); 
                set(gca,'ColorOrderIndex',1)
                plot(angle(gamma),samp2raw*1000,'--'); 
                
                [s1,samp1idx] = max(samp1raw(:));
                [s2,samp2idx] = min(samp2raw(:));
                g = gamma(:);
                arrow1 = get_arrow([angle(g(samp1idx)),s1*1000]);
                arrow2 = get_arrow([angle(g(samp2idx)),s2*1000]);
                quiver(arrow1(1),arrow1(2),arrow1(3),arrow1(4),"black",'LineWidth',2)
                text(arrow1(1)-arrow1(3)*.5,arrow1(2)-arrow1(4)*.5,'Sampler 1')
                quiver(arrow2(1),arrow2(2),arrow2(3),arrow2(4),"black",'LineWidth',2)
                text(arrow2(1)-arrow2(3)*.5,arrow2(2)-arrow2(4)*.5,'Sampler 2')
                grid on
                
                % subplot(3,3,4)
                figure
                set(gca,'ColorOrderIndex',1)
                scatter(abs(gamma),abs(sqrt( 1/(2*fpb_fit.bL2*fpb_fit.ScaleFactorSampler1_Av)*(samp1raw-fpb_fit.ScaleFactorKappa1)+...
                1/(2*fpb_fit.bL2*fpb_fit.ScaleFactorSampler2_Av)*(samp2raw-fpb_fit.ScaleFactorKappa2) - 1)),'filled','k');
                ylabel('Calculated Output')
                xlabel('Magnitude Gamma')
                grid on
                
                % subplot(3,3,[2 3 5 6 8 9])  
                figure
                set(gca,'ColorOrderIndex',1)
                polarplot(sqrt( 1/(2*fpb_fit.bL2*fpb_fit.ScaleFactorSampler1_Av)*(samp1raw-fpb_fit.ScaleFactorKappa1)+...
                1/(2*fpb_fit.bL2*fpb_fit.ScaleFactorSampler2_Av)*(samp2raw-fpb_fit.ScaleFactorKappa2) - 1).*exp(1i*angle(gamma)));
                hold on
                set(gca, 'ColorOrderIndex', 1)
                for plotidx = 1:size(gamma,2)
                    polarplot(gamma(:,plotidx),'.','LineStyle', 'none' )
                end
                rlim([0 1])
                pngname = strcat('../png/slide_n',num2str(x),num2str(y),num2str(z),'.png');
                saveas(gcf,pngname);
                close all
                PA = fpb_fit;
            end
        end
    end
end

%% Coupledline data
close all
clc

addpath('C:\Users\grgo8200\repos\summer2025_loadpull_repo\plot2\Classes')
addpath('C:\Users\grgo8200\repos\summer2025_loadpull_repo\plot2\functions')

files = [{'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\coupledline_samplers\LoadPullBiasing2025-08-21_19_33_Freq11.4to10.5\samplerbias_1.5V'}; ...
{'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\coupledline_samplers\LoadPullBiasing2025-08-21_14_35_Freq11.4to10.5\samplerbias_1.25V'}; ...
{'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\coupledline_samplers\LoadPullBiasing2025-08-21_10_06_Freq11.4to10.6\samplerbias_1.0V'};...
{'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\coupledline_samplers\LoadPullBiasing2025-08-22_00_31_Freq11.4to10.5\samplerbias_1.75V'};...
{'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\coupledline_samplers\LoadPullBiasing2025-08-22_05_30_Freq11.4to10.5\samplerbias_2.0V'}];

LUTfolder = 'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\LUT1';
gainfolder = 'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\GainTable2';

coupledline_data = DataTableClass(files(1),LUTfolder,gainfolder);

for i = 1:size(files,1)
    coupledline_data = coupledline_data.add_data(files(i));
end

coupledline_data = coupledline_data.freqpowerbias_bL2dependent;

%%

xd = 1;
xplot = [];
yplot = [];
fpb_fit_idx = 1;
for x = 1:size(coupledline_data.sampler_bias_list,2)-1
    for y = 1:size(coupledline_data.power_list,2)
        for z = 1:size(coupledline_data.freq_list,2)
            
            colororder(coupledline_data.colors)
            [samp1raw,samp2raw,gamma] = coupledline_data.get_singlesweep( ...
                coupledline_data.freq_list(z), ...
                coupledline_data.power_list(y), ...
                [coupledline_data.sampler_bias_list(x), ...
                coupledline_data.sampler_bias_list(x+1)]);
            fpb_fit =  coupledline_data.get_freqpowerbiasbL2row( ...
                coupledline_data.freq_list(z), ...
                coupledline_data.power_list(y), ...
                [coupledline_data.sampler_bias_list(x), ...
                coupledline_data.sampler_bias_list(x+1)]);
            if ~isempty(fpb_fit) & length(gamma)> 10
                yplot = [yplot, fpb_fit.RMSError];
                xplot = [xplot,xd+1];
                xd = xd+1;
                figure(1)
                plot(xplot,yplot)
            end

            if ~isempty(fpb_fit) & length(gamma) > 10 & fpb_fit.RMSError >.001 & fpb_fit.RMSError <.03698

                % subplot(3,3,1)
                figure
                hold on
                ylabel('Sampler (mV)')
                xlabel('data sampler')
                set(gca,'ColorOrderIndex',1)
                plot(angle(gamma),samp1raw*1000); 
                set(gca,'ColorOrderIndex',1)
                plot(angle(gamma),samp2raw*1000,'--'); 
                
                [s1,samp1idx] = max(samp1raw(:));
                [s2,samp2idx] = min(samp2raw(:));
                g = gamma(:);
                arrow1 = get_arrow([angle(g(samp1idx)),s1*1000]);
                arrow2 = get_arrow([angle(g(samp2idx)),s2*1000]);
                quiver(arrow1(1),arrow1(2),arrow1(3),arrow1(4),"black",'LineWidth',2)
                text(arrow1(1)-arrow1(3)*.5,arrow1(2)-arrow1(4)*.5,'Sampler 1')
                quiver(arrow2(1),arrow2(2),arrow2(3),arrow2(4),"black",'LineWidth',2)
                text(arrow2(1)-arrow2(3)*.5,arrow2(2)-arrow2(4)*.5,'Sampler 2')
                grid on
                
                % subplot(3,3,4)
                figure
                set(gca,'ColorOrderIndex',1)
                scatter(abs(gamma),abs(sqrt( 1/(2*fpb_fit.bL2*fpb_fit.ScaleFactorSampler1_Av)*(samp1raw-fpb_fit.ScaleFactorKappa1)+...
                1/(2*fpb_fit.bL2*fpb_fit.ScaleFactorSampler2_Av)*(samp2raw-fpb_fit.ScaleFactorKappa2) - 1)),'filled','k');
                ylabel('Calculated Output')
                xlabel('Magnitude Gamma')
                grid on
                
                % subplot(3,3,[2 3 5 6 8 9])  
                figure
                set(gca,'ColorOrderIndex',1)
                polarplot(sqrt( 1/(2*fpb_fit.bL2*fpb_fit.ScaleFactorSampler1_Av)*(samp1raw-fpb_fit.ScaleFactorKappa1)+...
                1/(2*fpb_fit.bL2*fpb_fit.ScaleFactorSampler2_Av)*(samp2raw-fpb_fit.ScaleFactorKappa2) - 1).*exp(1i*angle(gamma)));
                hold on
                set(gca, 'ColorOrderIndex', 1)
                for plotidx = 1:size(gamma,2)
                    polarplot(gamma(:,plotidx),'.','LineStyle', 'none' )
                end
                rlim([0 1])
                pngname = strcat('../png/slide_n',num2str(x),num2str(y),num2str(z),'.png');
                saveas(gcf,pngname);
                close all
                coupledline{fpb_fit_idx} = fpb_fit;
                fpb_fit_idx = fpb_fit_idx+1;
            end
        end
    end
end
%%
coupledline_data = coupledline_data.freqpowerbias
%%
[coupledline_data.freqpowerbiasbL2table.SamplerBiasMeanbin,bins] = discretize(coupledline_data.freqpowerbiasbL2table.SamplerV_Mean,5);

for i = 3:5
    biasTable = coupledline_data.freqpowerbL(i);
    for pow = unique(biasTable.SetPower)' 
        subplot(1,3,i-2)
        hold on
        rf = rowfilter(biasTable);
        T = biasTable(biasTable.SetPower == pow,:);
        [~, Tidx] = sort(T.frequency);
        T = T(Tidx,:);
        errorbar(T.frequency,T.RMSError,abs(T.RMSError-T.MinError),abs(T.RMSError-T.MaxError),'DisplayName',sprintf('Bias %.2f, Power %f',mean(T.SamplerV_Mean),pow))
    end
end
legend('location', 'best');

%%
% This assumes wavelength in freespace for simplicity
clear frequency c wavelength f0 physical_line magG angleG clear phs
clear V1 clear V2 clear gamma gammaL i j

frequency = linspace(8.9,11.9,31)*10^9;
c = 299792458;
wavelength = c./frequency;
f0=10.9*10^9;
line = .25* c./(f0); %at 10.4 GHz = 90 degree of SiC
phs = 2*pi./wavelength*line;
magG = .5;
angleG = -180:5:180;
gammaL = magG.*exp(1i*angleG/180*pi)';

% Set phase 1 to 0 for all frequencies for simplicity
V1 = abs(gammaL+1).^2;
V2 = abs(gammaL.*exp(-1i*phs)+exp(1i*phs)).^2;
gamma = sqrt(abs(1/2*V1+1/2*V2-1));

plot(frequency./10^9,sqrt(sum(gamma-abs(gammaL)).^2/size(gammaL,1)),'--','DisplayName',"RMS Error Theoretical",'LineWidth',3)
xlabel("Frequency (GHz)")
ylabel("RMS Error |Gamma_load|")