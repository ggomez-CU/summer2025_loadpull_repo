close all
[coupledline_data.freqpowerbiasbL2table.SamplerBiasMeanbin,bins] = discretize(coupledline_data.freqpowerbiasbL2table.SamplerV_Mean,12);

% The naming is not good. SamplerMeanV in this case is GateV for the
% coupled line it is actually the sampler bias mean.
for i = 3
    biasTable = coupledline_data.freqpowerbL(i);
    for pow = unique(biasTable.SetPower)' 
        % subplot(1,length(bins),i)
        hold on
        rf = rowfilter(biasTable);
        T = biasTable(biasTable.SetPower == pow,:);
        [~,sortidx] = sort(T.frequency);
        T = T(sortidx,:);
        % heatmap(biasTable,'frequency','SetPower','ColorVariable','MaxError')
        plot(T.frequency,T.RMSError,"-o",'DisplayName',sprintf('%.2f dBm P_{rm{out}}',pow),'LineWidth',3)
        plot(T.frequency,T.MaxError,"--*",'DisplayName',sprintf('%.2f dBm P_{rm{out}}',pow),'LineWidth',3)
        xlabel("Frequency (GHz)")
        ylabel("Error (|Gamma|)")
    end
end
lgd = legend('location', 'best');
lgd.Title.String = 'RMS Error | Max Error';
lgd.Interpreter = 'none'
lgd.Orientation = 'horizontal'
lgd.NumColumns = 2
xlim([8.4 12.4])
xticks(8.4:.5:12.4)

% This assumes wavelength in freespace for simplicity
clear frequency c wavelength f0 physical_line magG angleG clear phs
clear V1 clear V2 clear gamma gammaL i j

frequency = linspace(8.9,11.9,31)*10^9;
c = 299792458;
Eeff = 9.7;
wavelength = c./(frequency*sqrt(Eeff));
f0=10.4*10^9;
physical_line = .25* c./(f0*sqrt(Eeff));

magG = .5;
angleG = -180:5:180;
gammaL = magG.*exp(1i*angleG/180*pi)';

phs = 2*pi./wavelength*physical_line;

% Set phase 1 to 0 for all frequencies for simplicity
V1 = abs(gammaL+1).^2;
V2 = abs(gammaL.*exp(-1i*phs)+exp(1i*phs)).^2;
gamma = sqrt(abs(1/2*V1+1/2*V2-1));

% hold on
% subplot(2,2,1)
% plot(frequency,phs/pi*180);
% 
% subplot(2,2,2)
% hold on
% plot(angle,V1)
% plot(angle,V2)
% 
% subplot(2,2,3)
% plot(angle,gamma)
% 
% subplot(2,2,4)
plot(frequency./10^9,sqrt(sum(gamma-abs(gammaL)).^2/size(gammaL,1)),'--','DisplayName',"RMS Error Theoretical",'LineWidth',3)
