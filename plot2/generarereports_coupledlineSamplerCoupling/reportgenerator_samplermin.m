% filename = sprintf('coupledline_dataSamplerCoupling_IVkappa_%s',coupledline_data.LUTfolder(end-3:end));
% 
% import mlreportgen.ppt.*
% ppt = Presentation(strcat('C:\Users\grgo8200\repos\summer2025_loadpull_repo\plot2\reports\',filename,'.pptx'));
% titleSlide = add(ppt,'Title Slide');
% replace(titleSlide,'Title','Coupledline Compiled Data');

close all
% clear GammaCoupledBias
% coupledline_data = coupledline_data.samplercouplingfreq;
% SetSamplerBias_low= nan;
% Av1_VpermW= nan;
% Av2_VpermW= nan;
% DUT_output_mW= nan;
% DUT_output_dBm= nan;
% MeanSamplerBias = nan;
% SamplerBiasV = nan;
% kappa1= nan;
% kappa2= nan;
% SetOutputPower =nan;
% gaintable = table(...
%             MeanSamplerBias, SamplerBiasV, SetSamplerBias_low, SetOutputPower, Av1_VpermW, Av2_VpermW,...
%             DUT_output_mW, DUT_output_dBm, kappa1, kappa2);
% mean_Av1 = nan;
% mean_Av2 =nan;
% min_dAv1vlaue =nan;
% min_dAv2vlaue =nan;
% min_dAv1pow =nan;
% min_dAv2pow = nan;
% lineargaintable = table(...
%             SetSamplerBias_low, mean_Av1,mean_Av2 , ...
%     MeanSamplerBias, min_dAv1vlaue , ...
%     min_dAv2vlaue , ...
%     min_dAv1pow , ...
%     min_dAv2pow, kappa1, kappa2);
for x = 1:size(coupledline_data.sampler_bias_list,2)-1
    colororder(coupledline_data.colors)
    rf = rowfilter(coupledline_data.data);
    T = coupledline_data.data(...
        rf.GateV > coupledline_data.sampler_bias_list(x) & rf.GateV ...
        < coupledline_data.sampler_bias_list(x+1) ,:);

    scatter(T.DUT_input_dBm,(T.Sampler1_V-T.Sampler1_V(1))./10.^(T.DUT_input_dBm/10))
    % set(gca,'yscale','log')
    waitforbuttonpress
end
