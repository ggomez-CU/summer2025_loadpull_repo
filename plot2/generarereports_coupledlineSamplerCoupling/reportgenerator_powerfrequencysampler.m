filename = sprintf('coupledline_dataSamplerCoupling_IVkappa_%s',coupledline_data.LUTfolder(end-3:end));

import mlreportgen.ppt.*
ppt = Presentation(strcat('C:\Users\grgo8200\repos\summer2025_loadpull_repo\plot2\reports\',filename,'.pptx'));
titleSlide = add(ppt,'Title Slide');
replace(titleSlide,'Title','Coupledline Compiled Data');

close all
clear GammaCoupled
coupledline_data = coupledline_data.samplercouplingfreq;
frequency = nan;
SetSamplerBias_low= nan;
Av1_VpermW= nan;
Av2_VpermW= nan;
DUT_output_mW= nan;
DUT_output_dBm= nan;
MeanSamplerBias = nan;
SamplerBiasV = nan;
kappa1= nan;
kappa2= nan;
SetOutputPower =nan;
gaintable = table(frequency, ...
            MeanSamplerBias, SamplerBiasV, SetSamplerBias_low, SetOutputPower, Av1_VpermW, Av2_VpermW,...
            DUT_output_mW, DUT_output_dBm, kappa1, kappa2);
mean_Av1 = nan;
mean_Av2 =nan;
min_dAv1vlaue =nan;
min_dAv2vlaue =nan;
min_dAv1pow =nan;
min_dAv2pow = nan;
lineargaintable = table(frequency, ...
            SetSamplerBias_low, mean_Av1,mean_Av2 , ...
    MeanSamplerBias, min_dAv1vlaue , ...
    min_dAv2vlaue , ...
    min_dAv1pow , ...
    min_dAv2pow, kappa1, kappa2);
for y = 1:size(coupledline_data.freq_list,2)
    for x = 1:size(coupledline_data.sampler_bias_list,2)-1

        hold on
        colororder(coupledline_data.colors)
        rf = rowfilter(coupledline_data.data);
        T = coupledline_data.data(rf.frequency == coupledline_data.freq_list(y) & ...
            rf.GateV > coupledline_data.sampler_bias_list(x) & rf.GateV ...
            < coupledline_data.sampler_bias_list(x+1) ,:);
        rf = rowfilter(coupledline_data.samplercouplingfreqtable);
        offset = coupledline_data.samplercouplingfreqtable(rf.frequency == coupledline_data.freq_list(y),:);
        
        % kappa1 = 1500*find_kappa(coupledline_data.diodeDCIV,offset.SamplerV_Mean(x))*ones(size(T.Sampler1_V,1),1)
        kappa2 =1000* offset.SamplerI_Mean(x)*ones(size(T.Sampler1_V,1),1);

        kappa1 = offset.Sampler1_min(x)*ones(size(T.Sampler1_V,1),1);
        % kappa2 = offset.Sampler2_min(x)*ones(size(Av2_VpermW,1),1);

        Av1_VpermW = (T.Sampler1_V-kappa2)./10.^(T.DUT_output_dBm/10);
        Av2_VpermW = (T.Sampler2_V-kappa2)./10.^(T.DUT_output_dBm/10);
        DUT_output_mW = 10.^(T.DUT_output_dBm/10);
        DUT_output_dBm = T.DUT_output_dBm;
        SetOutputPower = T.SetPower;

        [~,min_dAv1idx] = min(abs(gradient(Av1_VpermW)));
        [~,min_dAv2idx] = min(abs(gradient(Av2_VpermW)));
        mean_Av1 = mean(Av1_VpermW);
        mean_Av2 = mean(Av2_VpermW);
        min_dAv1vlaue = Av1_VpermW(min_dAv1idx);
        min_dAv2vlaue = Av2_VpermW(min_dAv2idx);
        min_dAv1pow = DUT_output_dBm(min_dAv1idx);
        min_dAv2pow = DUT_output_dBm(min_dAv2idx);
        MeanSamplerBias = mean(T.GateV)*ones(size(Av2_VpermW,1),1);
        SamplerBiasV = T.GateV;

        subplot(2,2,1)
        hold on
        scatter(T.DUT_output_dBm,T.Sampler1_V-kappa2,... 
            'DisplayName',replace(replace(coupledline_data.folder{x}(end-16:end),'_',' '),'\',''))
        set(gca,'yscale','log')
        xlabel("DUT Output Power")
        ylabel("Output V (mV)")
        title("Sampler 1")
        ylim([10^-3,10^-1])
        xticks([0 5 10 15 20 25 30])
        grid on

        subplot(2,2,2)
        hold on
        scatter(T.DUT_output_dBm,T.Sampler2_V-kappa2, ...
            'DisplayName',replace(replace(coupledline_data.folder{x}(end-16:end),'_',' '),'\',''))
        set(gca,'yscale','log')
        xlabel("DUT Output Power")
        ylabel("Sampler  (mW)")
        title("Sampler 2")
        ylim([10^-3,1])
        xticks([0 5 10 15 20 25 30])
        grid on

        subplot(2,2,3)
        hold on
        scatter(T.DUT_output_dBm, ...
            (T.Sampler1_V-kappa2)./10.^(T.DUT_output_dBm/10),... 
            'DisplayName',replace(replace(coupledline_data.folder{x}(end-16:end),'_',' '),'\',''),'MarkerEdgeColor', coupledline_data.colors(x))
        yline(mean_Av1,'Color', coupledline_data.colors(x))
        scatter(T.DUT_output_dBm(min_dAv1idx),min_dAv1vlaue,'filled','ColorVariable', coupledline_data.colors(x),'MarkerFaceColor',coupledline_data.colors(x))
        set(gca,'yscale','log')
        xlabel("DUT Output Power")
        ylabel("Sampler Gain (V/W)")
        title("Sampler 1")
        ylim([10^-10,1])
        % xticks([0 5 10 15 20 25 30])
        grid on

        subplot(2,2,4)
        hold on
        scatter(T.DUT_output_dBm,...
            (T.Sampler2_V-kappa2)./10.^(T.DUT_output_dBm/10), ...
            'DisplayName',replace(replace(coupledline_data.folder{x}(end-16:end),'_',' '),'\',''),'MarkerEdgeColor', coupledline_data.colors(x))
        yline(mean_Av2,'Color', coupledline_data.colors(x))
        scatter(T.DUT_output_dBm(min_dAv2idx),min_dAv2vlaue,'filled','ColorVariable', coupledline_data.colors(x),'MarkerFaceColor',coupledline_data.colors(x))
        set(gca,'yscale','log')
        xlabel("DUT Output Power")
        ylabel("Output V (mV)")
        title("Sampler 2")
        ylim([10^-10,1])
        % xticks([0 5 10 15 20 25 30])
        grid on
        
        frequency = coupledline_data.freq_list(y)*ones(size(Av2_VpermW,1),1);
        SetSamplerBias_low = coupledline_data.sampler_bias_list(x)*ones(size(Av2_VpermW,1),1);
        gaintable = [table(frequency, ...
            MeanSamplerBias, SamplerBiasV, SetSamplerBias_low, SetOutputPower, Av1_VpermW, Av2_VpermW,...
            DUT_output_mW, DUT_output_dBm, kappa1, kappa2); gaintable];
            frequency = coupledline_data.freq_list(y);
        SetSamplerBias_low = coupledline_data.sampler_bias_list(x);
        kappa1 = kappa1(1);
        kappa2 = kappa2(2);
        MeanSamplerBias = mean(T.GateV);
        if ~isempty(min_dAv1vlaue)
            lineargaintable = [lineargaintable; table(frequency, ...
                SetSamplerBias_low, mean_Av1,mean_Av2 , ...
                MeanSamplerBias, min_dAv1vlaue , ...
                min_dAv2vlaue , ...
                min_dAv1pow , ...
                min_dAv2pow, kappa1, kappa2)];
        end
    end

    pngfile = strcat('../png/samplergainbias',coupledline_data.LUTfolder(end-3:end),num2str(y),'.png');
    saveas(gcf,pngfile)
    coupledline_slide = add(ppt,'Title and Content');
    plot1 = Picture(pngfile);
    slidetitle = sprintf('Coupled Line Performance At %.2f GHz', ... 
        coupledline_data.freq_list(y));
    replace(coupledline_slide,'Title',slidetitle);
    replace(coupledline_slide,'Content',plot1);

    if y == 1
        subplot(2,2,1)
        hold off
        p1 = plot(1,1);
        set(p1, 'visible', 'off');
        set(gca, 'visible', 'off');
        subplot(2,2,3)
        hold off
        p1 = plot(1,1);
        set(p1, 'visible', 'off');
        set(gca, 'visible', 'off');
        subplot(2,2,4)
        hold off
        p1 = plot(1,1);
        set(p1, 'visible', 'off');
        set(gca, 'visible', 'off');
        subplot(2,2,2)
        lgd = legend
        fontsize(lgd,24,'points')
        pngfile = strcat('../png/legend.png');
        saveas(gcf,pngfile)
        coupledline_slide = add(ppt,'Title and Content');
        plot1 = Picture(pngfile);
        slidetitle = sprintf('Coupled Line Bias Legend');
        replace(coupledline_slide,'Title',slidetitle);
        replace(coupledline_slide,'Content',plot1);
    end

    close all
    rf = rowfilter(coupledline_data.data);
    T = coupledline_data.data(rf.frequency == coupledline_data.freq_list(y) & ...
        rf.GateV > coupledline_data.sampler_bias_list(1) & rf.GateV ...
        < coupledline_data.sampler_bias_list(2) ,:);
    GammaCoupled(:,y) = mean(T.GammaLoad);
end

save("../../data/GainTabledciv/gaintable","gaintable","lineargaintable")

%%



for x = 1:size(coupledline_data.sampler_bias_list,2)-1
    hold on
    colororder(coupledline_data.colors)
    rf = rowfilter(coupledline_data.samplercouplingfreqtable);
    T = coupledline_data.samplercouplingfreqtable(rf.SamplerV_Mean > coupledline_data.sampler_bias_list(x) & rf.SamplerV_Mean ...
        < coupledline_data.sampler_bias_list(x+1) ,:);

        
    scatter(T.frequency,T.Sampler1_Range)
    scatter(T.frequency,T.Sampler2_Range)

    pngfile = strcat('../png/samplergainfreq',coupledline_data.LUTfolder(end-3:end),num2str(x),'.png');
    saveas(gcf,pngfile)
    coupledline_slide = add(ppt,'Title and Content');
    plot1 = Picture(pngfile);
    slidetitle = sprintf('Coupled Line Performance At %.2f Mean Sampler Bias', ... 
        mean(T.SamplerV_Mean));
    replace(coupledline_slide,'Title',slidetitle);
    replace(coupledline_slide,'Content',plot1);
    close all
end

scatter(coupledline_data.freq_list,10*log10(GammaCoupled))

pngfile = strcat('../png/mismatch50.png');
saveas(gcf,pngfile)
coupledline_slide = add(ppt,'Title and Content');
plot1 = Picture(pngfile);
slidetitle = sprintf('Coupled Line Mismatch');
replace(coupledline_slide,'Title',slidetitle);
replace(coupledline_slide,'Content',plot1);
close all


close(ppt);
rptview(ppt);

