filename = sprintf('PA_bL2based_IMSbL_%s',coupledline_data.LUTfolder(end-3:end));

import mlreportgen.ppt.*
ppt = Presentation(strcat('C:\Users\grgo8200\repos\summer2025_loadpull_repo\plot2',filename,'.pptx'));
titleSlide = add(ppt,'Title Slide');
replace(titleSlide,'Title','Coupledline Compiled Data');
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

            if ~isempty(fpb_fit) & length(gamma) > 10 & fpb_fit.RMSError >.001 & fpb_fit.RMSError <.1

                subplot(3,3,1)
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

                
                subplot(3,3,4)
                set(gca,'ColorOrderIndex',1)
                scatter(abs(gamma),abs(sqrt( 1/(2*fpb_fit.bL2*fpb_fit.ScaleFactorSampler1_Av)*(samp1raw-fpb_fit.ScaleFactorKappa1)+...
                1/(2*fpb_fit.bL2*fpb_fit.ScaleFactorSampler2_Av)*(samp2raw-fpb_fit.ScaleFactorKappa2) - 1)));
                ylabel('Calculated Output')
                xlabel('Magnitude Gamma')
                
                subplot(3,3,[2 3 5 6 8 9])  
                set(gca,'ColorOrderIndex',1)
                smithplot(sqrt( 1/(2*fpb_fit.bL2*fpb_fit.ScaleFactorSampler1_Av)*(samp1raw-fpb_fit.ScaleFactorKappa1)+...
                1/(2*fpb_fit.bL2*fpb_fit.ScaleFactorSampler2_Av)*(samp2raw-fpb_fit.ScaleFactorKappa2) - 1).*exp(1i*angle(gamma)));
                hold on
                set(gca, 'ColorOrderIndex', 1)
                for plotidx = 1:size(gamma,2)
                    smithplot(gamma(:,plotidx),'.','LineStyle', 'none' )
                end
            
                pngname = strcat('../png/slide_n',num2str(x),num2str(y),num2str(z),'.png');
                saveas(gcf,pngname);
                close all
                content = {'Sampler Av ', {sprintf('Sampler 1: %.3g', fpb_fit.ScaleFactorSampler1_Av), ...
                    sprintf('Sampler 2: %.3g', fpb_fit.ScaleFactorSampler2_Av) },...
                    'Kappa', {sprintf('Sampler 1: %.3g', fpb_fit.ScaleFactorKappa1), ...
                    sprintf('Sampler 2: %.3g', fpb_fit.ScaleFactorKappa2) },...
                    'Goodness Of fit ', {fpb_fit.GoodnessOfFit}, ....
                    'Range',  {sprintf('Sampler 1: %.3g', fpb_fit.Sampler1_Range), ...
                    sprintf('Sampler 2: %.3g', fpb_fit.Sampler2_Range) }, ....
                    'dBm Mean', {sprintf("DUT output %3g",fpb_fit.DUT_output_dBm_Mean), ....
                    sprintf("DUT input %3g",fpb_fit.DUT_input_dBm_Mean)}, ....
                    'RMS Error ', {sprintf("%3g",fpb_fit.RMSError)}, ...
                    'Max Error ', {sprintf("%3g",fpb_fit.MaxError)}};
                coupledline_slide = add(ppt,'Two Content');
                plot1 = Picture(pngname);
                title = sprintf('Coupled Line Performance At %.2f GHz, %2f dBm Output Power %.2f V mean sampler bias', ... 
                    coupledline_data.freq_list(z), ...
                    coupledline_data.power_list(y), ...
                    fpb_fit.SamplerV_Mean);
                replace(coupledline_slide,'Title',title);
                replace(coupledline_slide.Children(2),plot1);
                replace(coupledline_slide.Children(3),content);
            end
        end
    end
end

close(ppt);
rptview(ppt);


%%
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
        errorbar(T.frequency,T.RMSError,abs(T.RMSError-T.MinError),abs(T.RMSError-T.MaxError),"-o",'DisplayName',sprintf('RMS Error at %.2f dBm %P_{\rm{out}}',pow),'LineWidth',3)
        legend('location', 'best');
        xlabel("Frequency (GHz)")
        ylabel("Error (|$\Gamma$|)")
    end
end
legend('location', 'best');
xlim([8.4 12.4])
xticks(8.4:.5:12.4)