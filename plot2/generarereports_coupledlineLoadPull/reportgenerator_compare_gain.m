filename = sprintf('compare_gain2ideal_flippedgain_%s',coupledline_data.LUTfolder(end-3:end));

import mlreportgen.ppt.*
ppt = Presentation(strcat('C:\Users\grgo8200\repos\summer2025_loadpull_repo\plot2\reports\',filename,'.pptx'));
titleSlide = add(ppt,'Title Slide');
replace(titleSlide,'Title','Compare Sampler voltage from gain cal vs ideal');

clc
for x = 1:size(coupledline_data.sampler_bias_list,2)-1
    for y = 1:size(coupledline_data.power_list,2)
        for z = 6
            
            colororder(coupledline_data.colors)
            [samp1raw,samp2raw,gamma] = coupledline_data.get_singlesweep( ...
                coupledline_data.freq_list(z), ...
                coupledline_data.power_list(y), ...
                [coupledline_data.sampler_bias_list(x), ...
                coupledline_data.sampler_bias_list(x+1)]);
            gaincal = coupledline_data.gaintable.get_gain( ...
                coupledline_data.freq_list(z), ...
                coupledline_data.power_list(y), ...
                [coupledline_data.sampler_bias_list(x), ...
                coupledline_data.sampler_bias_list(x+1)]);
            lineargaincal = coupledline_data.gaintable.get_lineargain( ...
                coupledline_data.freq_list(z), ...
                [coupledline_data.sampler_bias_list(x), ...
                coupledline_data.sampler_bias_list(x+1)]);
            fpb_fit =  coupledline_data.get_freqpowerbiasrow( ...
                coupledline_data.freq_list(z), ...
                coupledline_data.power_list(y), ...
                [coupledline_data.sampler_bias_list(x), ...
                coupledline_data.sampler_bias_list(x+1)]);
        
            if ~isempty(fpb_fit)

                powermW = 10^(fpb_fit.DUT_output_dBm_Mean/10);
                kappa = min([gaincal.kappa1,gaincal.kappa2]);
                   
                close all
                subplot(2,3,1)
                hold on
                expected = abs(gamma*exp(j*fpb_fit.Sampler1_phase)+exp(-j*fpb_fit.Sampler1_phase)).^2;
                set(gca,'ColorOrderIndex',1)
                plot(angle(gamma),expected)
                set(gca,'ColorOrderIndex',1)
                scatter(angle(gamma), 0.5*(samp1raw-gaincal.kappa1)./(gaincal.Av2_VpermW*(powermW)))
                set(gca,'ColorOrderIndex',1)
                scatter(angle(gamma), 0.5*(samp1raw-gaincal.kappa1)./(gaincal.Av2_VpermW*(powermW)),'*')
                title("Sampler 1")
                ylabel("Voltage")
                xlabel("Gamma phase (rad)")

                subplot(2,3,2)
                hold on
                expected = abs(gamma*exp(j*fpb_fit.Sampler2_phase)+exp(-j*fpb_fit.Sampler2_phase)).^2;
                set(gca,'ColorOrderIndex',1)
                plot(angle(gamma),expected)
                set(gca,'ColorOrderIndex',1)
                scatter(angle(gamma), 0.5*(samp2raw-gaincal.kappa2)./(gaincal.Av2_VpermW*(powermW)))
                title("Sampler 2")
                ylabel("Voltage")
                xlabel("Gamma phase (rad)")

                subplot(2,3,4)
                hold on
                expected = abs(gamma*exp(j*fpb_fit.Sampler1_phase)+exp(-j*fpb_fit.Sampler1_phase)).^2;
                set(gca,'ColorOrderIndex',1)
                plot(angle(gamma),expected)
                set(gca,'ColorOrderIndex',1)
                scatter(angle(gamma), 0.5*(samp1raw-gaincal.kappa1)./(lineargaincal.mean_Av1*(powermW)))
                title("Sampler 1 mean cal")
                ylabel("Voltage")
                xlabel("Gamma phase (rad)")

                subplot(2,3,5)
                hold on
                expected = abs(gamma*exp(j*fpb_fit.Sampler2_phase)+exp(-j*fpb_fit.Sampler2_phase)).^2;
                set(gca,'ColorOrderIndex',1)
                plot(angle(gamma),expected)
                set(gca,'ColorOrderIndex',1)
                scatter(angle(gamma), 0.5*(samp2raw-gaincal.kappa2)./(lineargaincal.mean_Av1*(powermW)))
                title("Sampler 2 mean cal")
                ylabel("Voltage")
                xlabel("Gamma phase (rad)")




                subplot(2,3,[3 6])
                set(gca,'ColorOrderIndex',1)
                hold on
                meangain = mean([lineargaincal.mean_Av1,lineargaincal.mean_Av2])
                calculated = sqrt(0.25*(samp1raw-gaincal.kappa1)./(gaincal.Av1_VpermW*(powermW)) +  0.25*(samp2raw-gaincal.kappa2)./(gaincal.Av2_VpermW*(powermW)) -1);
                linearcalculated = sqrt( 0.25*(samp1raw-lineargaincal.kappa1)./(lineargaincal.mean_Av1*(powermW)) +  0.25*(samp2raw-lineargaincal.kappa2)./(lineargaincal.mean_Av1*(powermW)) -1);
                meancalculated = sqrt( 0.25*(samp1raw-lineargaincal.kappa1)./(meangain*(powermW)) +  0.25*(samp2raw-lineargaincal.kappa2)./(meangain*(powermW)) -1);
                scatter(abs(gamma),abs(calculated))
                set(gca,'ColorOrderIndex',1)
                scatter(abs(gamma),abs(linearcalculated),'*')
                scatter(abs(gamma),abs(meancalculated),'.')
                ylabel('Calculated Output')
                xlabel('Magnitude Gamma')

                pngname = strcat('../png/slide_gaincal',num2str(x),num2str(y),num2str(z),'.png');
                saveas(gcf,pngname);
                close all

                content = {'Sampler Av ', {sprintf('Sampler 1: %.2g',gaincal.Av1_VpermW), ...
                    sprintf('Sampler 2: %.2g',gaincal.Av2_VpermW) , sprintf('Sampler 1 linear: %.2g',lineargaincal.mean_Av1), ...
                    sprintf('Sampler 2 linear: %.2g',lineargaincal.mean_Av2) },...
                    'Sampler Offset', {sprintf('Sampler 1: %.2g',lineargaincal.kappa1), ...
                    sprintf('Sampler 2: %.2g',lineargaincal.kappa2)},...
                    'RMSE ', {sprintf('Linear: %.2g',rmse(gamma(:),linearcalculated(:))), ...
                    sprintf('Individual: %.2g',rmse(gamma(:),calculated(:))) }};
                coupledline_slide = add(ppt,'Two Content');
                plot1 = Picture(pngname);
                sldietitle = sprintf('Coupled Line Performance At %.2f GHz, %2f dBm Output Power %.2f V mean sampler bias', ... 
                    coupledline_data.freq_list(z), ...
                    coupledline_data.power_list(y), ...
                    fpb_fit.SamplerV_Mean);
                replace(coupledline_slide,'Title',sldietitle);
                replace(coupledline_slide.Children(2),plot1);
                replace(coupledline_slide.Children(3),content);
            end
        end
    end
end

close(ppt);
rptview(ppt);

%
%% for this file the gateV is actually the SamplerV. I flipped the channels so it saved the data differently. I promise this is correct
[coupledline_data.freqpowerbiastable.SamplerBiasMeanbin,bins] = discretize(coupledline_data.freqpowerbiastable.SamplerV_Mean,5);

for i = 1:5
    biasTable = coupledline_data.freqpower(i);
    heatmap(biasTable,'frequency','SetPower','ColorVariable','RMSError')
    saveas(gcf,strcat('../png/bias_ideal',coupledline_data.LUTfolder(end-3:end),num2str(i),'.png'));
    coupledline_slide = add(ppt,'Title and Content');
    plot1 = Picture(strcat('../png/bias_ideal',coupledline_data.LUTfolder(end-3:end),num2str(i),'.png'));
    title = sprintf('Coupled Line Performance At %.2f V mean sampler bias', ... 
        mean(T.pb_fit.SamplerV_Mean));
    replace(coupledline_slide,'Title',title);
    replace(coupledline_slide,'Content',plot1);
end

close(ppt);
rptview(ppt);