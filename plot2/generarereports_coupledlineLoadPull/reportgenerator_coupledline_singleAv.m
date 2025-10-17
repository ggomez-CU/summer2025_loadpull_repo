filename = sprintf('coupledline_data_Av10-9_%s',coupledline_data.LUTfolder(end-3:end));

import mlreportgen.ppt.*
ppt = Presentation(strcat('C:\Users\grgo8200\repos\summer2025_loadpull_repo\plot2\reports\',filename,'.pptx'));
titleSlide = add(ppt,'Title Slide');
replace(titleSlide,'Title','Coupledline Compiled Data');
% replace(titleSlide,'Subtitle',coupledline_data.dateandtime);
RMSError = nan;
ScaleFactorSampler1_Av = nan;
ScaleFactorSampler2_Av = nan;
ScaleFactorOffset = nan;
SamplerV_Mean = nan;
pb_fit = coupledline_data.get_freqpowerbiasrow( ...
                10.9, ...
                1,[0,0]);
pb_fit{1,:} = nan
rmserrortable = table(RMSError, ...
        nan, ...
        nan, ...
        nan, nan,pb_fit);

for x = 1:size(coupledline_data.sampler_bias_list,2)-1
    for y = 1:size(coupledline_data.power_list,2)
        pb_fit =  coupledline_data.get_freqpowerbiasrow( ...
                10.9, ...
                coupledline_data.power_list(y), ...
                [coupledline_data.sampler_bias_list(x), ...
                coupledline_data.sampler_bias_list(x+1)]);

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
        
            if ~isempty(fpb_fit)
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
                scatter(abs(gamma),abs(sqrt(pb_fit.ScaleFactorSampler1_Av*samp1raw ...
                    +pb_fit.ScaleFactorSampler2_Av*samp2raw +...
                     pb_fit.ScaleFactorOffset)));
                ylabel('Calculated Output')
                xlabel('Magnitude Gamma')
                
                subplot(3,3,[2 3 5 6 8 9])  
                set(gca,'ColorOrderIndex',1)
                smithplot(sqrt(pb_fit.ScaleFactorSampler1_Av*samp1raw ...
                    +pb_fit.ScaleFactorSampler2_Av*samp2raw +...
                     pb_fit.ScaleFactorOffset).*exp(j*angle(gamma)));
                hold on
                smithplot(1*exp(j*fpb_fit.Sampler1_phase*2),'Marker','square','Color',[0 0 0],'ClipData',0)
                smithplot(1*exp(j*fpb_fit.Sampler2_phase*2),'Marker','square','Color',[0 0 0],'ClipData',0)
                text(real(1.2*exp(j*fpb_fit.Sampler1_phase*2)),imag(1.2*exp(j*fpb_fit.Sampler1_phase*2)),'Sampler 1','HorizontalAlignment','center')
                text(real(1.2*exp(j*fpb_fit.Sampler2_phase*2)),imag(1.2*exp(j*fpb_fit.Sampler2_phase*2)),'Sampler 2','HorizontalAlignment','center')
                
                set(gca,'ColorOrderIndex',1)
                for plotidx = 1:size(gamma,2)
                    smithplot(gamma(:,plotidx),'.','LineStyle', 'none' )
                end
                RMSError = rmse(abs(gamma(:)),sqrt(pb_fit.ScaleFactorSampler1_Av*samp1raw(:) ...
                        +pb_fit.ScaleFactorSampler2_Av*samp2raw(:) +...
                         pb_fit.ScaleFactorOffset))
                rmserrortable = [rmserrortable; table(RMSError, ...
                    coupledline_data.freq_list(z), ...
                    coupledline_data.power_list(y), ...
                    coupledline_data.sampler_bias_list(x), ...
                    coupledline_data.sampler_bias_list(x+1),pb_fit)];
                saveas(gcf,strcat('../png/slidemean',num2str(x),num2str(y),num2str(z),'.png'));
                close all
                content = {'Sampler Av ', {sprintf('Sampler 1: %.3f', pb_fit.ScaleFactorSampler1_Av), ...
                    sprintf('Sampler 2: %.3f', pb_fit.ScaleFactorSampler2_Av) },...
                    'Sampler Offset (rather than -1)', {pb_fit.ScaleFactorOffset},...
                    'Sampler 1 Range', { sprintf('%.5f',fpb_fit.Sampler1_Range)}, ....
                    'Sampler 2 Range', { sprintf('%.5f',fpb_fit.Sampler2_Range)}, ....
                    'DUT output dBm Mean', { sprintf('%.5f',fpb_fit.DUT_output_dBm_Mean)}, ....
                    'DUT input dBm Mean', { sprintf('%.5f',fpb_fit.DUT_input_dBm_Mean)}, ....
                    'RMS Error ' sprintf('%.5f',RMSError),                          };
                coupledline_slide = add(ppt,'Two Content');
                plot1 = Picture(strcat('../png/slidemean',num2str(x),num2str(y),num2str(z),'.png'));
                title = sprintf('Coupled Line Performance At %.2f GHz, %2f dBm Output Power %.2f V mean sampler bias', ... 
                    coupledline_data.freq_list(z), ...
                    coupledline_data.power_list(y), ...
                    pb_fit.SamplerV_Mean);
                replace(coupledline_slide,'Title',title);
                replace(coupledline_slide.Children(2),plot1);
                replace(coupledline_slide.Children(3),content);
            end
        end
    end
end

%%
% [temp.freqpowerbiastable.SamplerBiasMeanbin,bins] = discretize(temp.rmserrortable.SamplerV_Mean,5);
% heatmap(temp.freqpowerbiastable,'frequency','SamplerBiasMeanbin','ColorVariable','RMSError')


rmserrortable = renamevars(rmserrortable,["Var2","Var3","Var4","Var5"], ...sav
                 ["Frequency","SetPower","Bias_Low","Bias_high"])

%%
rf = rowfilter(rmserrortable);
biaslowlist = unique(rmserrortable.Bias_Low)';
for i = 1:size(biaslowlist,2)-1
    T = rmserrortable(rf.Bias_Low == biaslowlist(i),:);
    heatmap(T,'Frequency','SetPower','ColorVariable','RMSError')
    saveas(gcf,strcat('../png/bias_singleAv',num2str(i),'.png'));

    coupledline_slide = add(ppt,'Title and Content');
    plot1 = Picture(strcat('../png/bias_singleAv',num2str(i),'.png'));
    title = sprintf('Coupled Line Performance At %.2f V mean sampler bias', ... 
        mean(T.pb_fit.SamplerV_Mean));
    replace(coupledline_slide,'Title',title);
    replace(coupledline_slide,'Content',plot1);

end

rmsfilename = sprintf('rmserrortable_singleAv%s.mat',coupledline_data.LUTfolder(end-3:end))
save(rmsfilename,"rmserrortable")

close(ppt);
rptview(ppt);