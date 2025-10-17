close all
clear GammaCoupled
coupledline_data = coupledline_data.samplercouplingfreq;
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
        
        subplot(1,2,1)
        hold on
        scatter(T.DUT_output_dBm,T.Sampler1_V,... 
            'DisplayName',replace(replace(coupledline_data.folder{x}(end-16:end),'_',' '),'\',''))
        set(gca,'yscale','log')
        xlabel("DUT Output Power")
        ylabel("Output V (mV)")
        title("Sampler 1")
        ylim([10^-3,1])
        xticks([0 5 10 15 20 25 30])
        grid on
        subplot(1,2,2)
        hold on
        scatter(T.DUT_output_dBm,T.Sampler2_V-offset.Sampler2_min(x), ...
            'DisplayName',replace(replace(coupledline_data.folder{x}(end-16:end),'_',' '),'\',''))
        set(gca,'yscale','log')
        xlabel("DUT Output Power")
        ylabel("Output V (mV)")
        title("Sampler 2")
        ylim([10^-10,1])
        xticks([0 5 10 15 20 25 30])
        grid on
        
    end
    rf = rowfilter(coupledline_data.data);
    T = coupledline_data.data(rf.frequency == coupledline_data.freq_list(y) & ...
        rf.GateV > coupledline_data.sampler_bias_list(1) & rf.GateV ...
        < coupledline_data.sampler_bias_list(2) ,:);

    GammaCoupled(:,y) = mean(T.GammaLoad);
end

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

