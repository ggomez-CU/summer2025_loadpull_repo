filename = sprintf('coupledline_bL2based_%s',coupledline_data.LUTfolder(end-3:end));

import mlreportgen.ppt.*
ppt = Presentation(strcat('C:\Users\grgo8200\repos\summer2025_loadpull_repo\plot2\reports\',filename,'.pptx'));
titleSlide = add(ppt,'Title Slide');
replace(titleSlide,'Title','Coupledline Compiled Data');

for x = 1:size(coupledline_data.sampler_bias_list,2)-1
    for y = 1:size(coupledline_data.power_list,2)
        for z = 1:size(coupledline_data.freq_list,2)
            
            colororder(coupledline_data.colors)
            [samp1raw,samp2raw,gamma] = coupledline_data.get_singlesweep( ...
                coupledline_data.freq_list(z), ...
                coupledline_data.power_list(y), ...
                [coupledline_data.sampler_bias_list(x), ...
                coupledline_data.sampler_bias_list(x+1)]);
            fpb_fit =  coupledline_data.get_freqpowerbiasrow( ...
                coupledline_data.freq_list(z), ...
                coupledline_data.power_list(y), ...
                [coupledline_data.sampler_bias_list(x), ...
                coupledline_data.sampler_bias_list(x+1)]);
        
            if ~isempty(fpb_fit) & length(gamma) > 10 & fpb_fit.RMSError > .001

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
                scatter(abs(gamma),abs(sqrt(fpb_fit.ScaleFactorSampler1_Av*samp1raw ...
                    +fpb_fit.ScaleFactorSampler2_Av*samp2raw +...
                     fpb_fit.ScaleFactorOffset)));
                ylabel('Calculated Output')
                xlabel('Magnitude Gamma')
                
                subplot(3,3,[2 3 5 6 8 9])  
                set(gca,'ColorOrderIndex',1)
                smithplot(sqrt(fpb_fit.ScaleFactorSampler1_Av*samp1raw ...
                    +fpb_fit.ScaleFactorSampler2_Av*samp2raw +...
                     fpb_fit.ScaleFactorOffset).*exp(j*angle(gamma)));
                hold on
                smithplot(1*exp(j*fpb_fit.Sampler1_phase*2),'Marker','square','Color',[0 0 0],'ClipData',0)
                smithplot(1*exp(j*fpb_fit.Sampler2_phase*2),'Marker','square','Color',[0 0 0],'ClipData',0)
                text(real(1.2*exp(j*fpb_fit.Sampler1_phase*2)),imag(1.2*exp(j*fpb_fit.Sampler1_phase*2)),'Sampler 1','HorizontalAlignment','center')
                text(real(1.2*exp(j*fpb_fit.Sampler2_phase*2)),imag(1.2*exp(j*fpb_fit.Sampler2_phase*2)),'Sampler 2','HorizontalAlignment','center')
                
                set(gca,'ColorOrderIndex',1)
                for plotidx = 1:size(gamma,2)
                    smithplot(gamma(:,plotidx),'.','LineStyle', 'none' )
                end
            
                saveas(gcf,strcat('../png/slide_n',num2str(x),num2str(y),num2str(z),'.png'));
                close all
                content = {'Sampler Av ', {sprintf('Sampler 1: %.3f', fpb_fit.ScaleFactorSampler1_Av), ...
                    sprintf('Sampler 2: %.3f', fpb_fit.ScaleFactorSampler1_Av) },...
                    'Sampler Offset (rather than -1)', {fpb_fit.ScaleFactorOffset},...
                    'Goodness Of fit ', {fpb_fit.GoodnessOfFit}, ....
                    'Sampler 1 Range', {fpb_fit.Sampler1_Range}, ....
                    'Sampler 2 Range', {fpb_fit.Sampler2_Range}, ....
                    'DUT output dBm Mean', {fpb_fit.DUT_output_dBm_Mean}, ....
                    'DUT input dBm Mean', {fpb_fit.DUT_input_dBm_Mean}, ....
                    'RMS Error ', {fpb_fit.RMSError}, ...
                    'Max Error ', {max(max(abs(gamma)-abs(sqrt(fpb_fit.ScaleFactorSampler1_Av*samp1raw ...
                    +fpb_fit.ScaleFactorSampler2_Av*samp2raw +...
                     fpb_fit.ScaleFactorOffset))))}};
                coupledline_slide = add(ppt,'Two Content');
                plot1 = Picture(strcat('../png/slide_new',num2str(x),num2str(y),num2str(z),'.png'));
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

% close(ppt);
% rptview(ppt);

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