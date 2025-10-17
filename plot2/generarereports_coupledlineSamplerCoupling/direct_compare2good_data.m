close all

frequency = 10.9;
power = 16;
bias_bin = [1.2, 1.3];

[samp1raw,samp2raw,gamma] = coupledline_data.get_singlesweep(frequency, power, bias_bin);
fpb_fit =  coupledline_data.get_freqpowerbiasrow(frequency, power, bias_bin);
idealcalculated = ((fpb_fit.ScaleFactorSampler1_Av*samp1raw ...
        +fpb_fit.ScaleFactorSampler2_Av*samp2raw +...
         fpb_fit.ScaleFactorOffset));

fpb_fit.ScaleFactorSampler1_Av
fpb_fit.ScaleFactorSampler2_Av
fpb_fit.ScaleFactorOffset
bL2 = 10^((power-30)/10) %in watts
Av1 = 1/(2*bL2*fpb_fit.ScaleFactorSampler1_Av)
Av2 = 1/(2*bL2*fpb_fit.ScaleFactorSampler2_Av)
k = -(fpb_fit.ScaleFactorOffset+1)*(bL2*mean([Av1,Av2]))
-k/(2*bL2*Av1)-k/(2*bL2*Av2)-1
load('samplercoupled_data.mat')
samplercoupled_data=samplercoupled_data.samplercouplingfreq;
rf = rowfilter(samplercoupled_data.data);
T = samplercoupled_data.data(rf.frequency == frequency & ...
    rf.GateV > bias_bin(1) & rf.GateV ...
    < bias_bin(2) ,:);
rf = rowfilter(samplercoupled_data.samplercouplingfreqtable);
offset = samplercoupled_data.samplercouplingfreqtable(rf.frequency == frequency,:);
                
kappa1 =min(T.Sampler1_V);
kappa2 =min(T.Sampler2_V);

Av1_VpermW = (T.Sampler1_V-kappa1)./10.^((T.DUT_output_dBm-30)/10);
Av2_VpermW = (T.Sampler2_V-kappa1)./10.^((T.DUT_output_dBm-30)/10);


%%
plot(Av2_VpermW)
hold on
plot(Av1_VpermW)
yline(Av1)
yline(Av2)

%%
reformatedcalculated = ((...
        1/2/(bL2*Av2)*(samp2raw) + ...
        1/2/(bL2*Av1)*(samp1raw) -k/(2*bL2*Av1)-k/(2*bL2*Av2)-1));
scatter(idealcalculated,reformatedcalculated)

%%
close all
scatter(samplercoupled_data.data.DUT_input_dBm,samplercoupled_data.data.Sampler1_V)
set(gca,'yscale','log')
yline(k)

%%
% at 50 V1 = V2 
T = samplercoupled_data.data
subplot(2,2,1)
scatter(10.^((T.DUT_input_dBm-30)/10),T.Sampler1_V)
hold on
scatter(10.^((T.DUT_input_dBm-30)/10),T.Sampler2_V)
subplot(2,2,2)
scatter(10.^((T.DUT_input_dBm-30)/10),T.Sampler2_V./T.Sampler1_V)
subplot(2,2,4)
scatter(abs(T.GateV),T.Sampler2_V./T.Sampler1_V)
subplot(2,2,3)
polarplot(T.GammaLoad,'*')
rlim([0,.3])

%%
bL2 = 10.^((coupledline_data.freqpowerbiastable.DUT_output_dBm_Mean-30)/10) %in watts
Av1 = 1./(2*bL2.*coupledline_data.freqpowerbiastable.ScaleFactorSampler1_Av)
Av2 = 1./(2*bL2.*coupledline_data.freqpowerbiastable.ScaleFactorSampler2_Av)
k = -(coupledline_data.freqpowerbiastable.ScaleFactorOffset+1).*(bL2.*Av1)

plot3(coupledline_data.freqpowerbiastable.SamplerV_Mean,coupledline_data.freqpowerbiastable.frequency,k)
zlim([0 .5])

%%
scatter3(coupledline_data.freqpowerbiastable.ScaleFactorOffset,coupledline_data.freqpowerbiastable.frequency,coupledline_data.freqpowerbiastable.DUT_output_dBm_Mean)