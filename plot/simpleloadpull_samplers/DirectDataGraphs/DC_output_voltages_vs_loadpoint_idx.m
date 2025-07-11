addpath("C:\Users\grgo8200\LocalOnly\DiscreteIS\SubSixTestHybridBoard\subsixtest\data\simpleloadpull_samplers")
% fname = "2025-04-21_14_22_Freq3.0_Pow-30.0.json" %Bad data, port 2 was cal'ed with low power
% fname = "2025-04-24_10_56_Freq3.0_Pow-20.0.json"

fid = fopen(fname); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
val = jsondecode(str);

lpidx_list = fieldnames(val);

for i=1:length(lpidx_list)
    try
        sampler_2(i) = mean(val.(lpidx_list{end-i}).Sampler2)
        sampler_1(i) = mean(val.(lpidx_list{end-i}).Sampler1)
        mixer(i) = mean(val.(lpidx_list{end-i}).Mixer)
    catch
    end
end

plot_title = sprintf('Sampler Voltage outputs at %d dBm input power, %d GHz', (val.(lpidx_list{2}).InputPower_dBm_) , (val.(lpidx_list{2}).Frequency));

hold on
plot(sampler_1)
plot(sampler_2)
plot(mixer)
legend("sampler 1","sampler 2", "mixer")
xlabel("Load Point index (high to low gamma")
ylabel("DC sampler voltage (V)")
title(plot_title)