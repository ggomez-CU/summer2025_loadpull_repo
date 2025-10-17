close all

for frequency =  unique(coupledline_data.data.frequency)'

    rf = rowfilter(coupledline_data.data);
    T = coupledline_data.data(rf.frequency == frequency,:)
    
    scatter(T.DUT_output_dBm,T.PowerMeter)
    
    %% Drive up 50 Ohms
    T.GammaMag = abs(T.GammaLoad)
    rf = rowfilter(T);
    TT = T(rf.GammaMag < 0.105,:)
    scatter(TT.DUT_input_dBm,TT.Gain)
    scatter(TT.DrainI,TT.Gain)
    close all
    
    gatebiaslist = unique(round(TT.GateV,2));
    for i = 1:length(gatebiaslist)
        rf = rowfilter(TT);
        Tsingelbias = TT(rf.GateV > gatebiaslist(i) - 0.01 & rf.GateV < gatebiaslist(i) + 0.01,:);
        plot(Tsingelbias.DUT_output_dBm,Tsingelbias.PAE)
        hold on
    end
    waitforbuttonpress
end

for frequency =  unique(coupledline_data.data.frequency)'

    rf = rowfilter(coupledline_data.data);
    T = coupledline_data.data(rf.frequency == frequency,:)
    
    scatter(T.DUT_output_dBm,T.PowerMeter)
    
    %% Drive up 50 Ohms
    T.GammaMag = abs(T.GammaLoad)
    rf = rowfilter(T);
    TT = T(rf.GammaMag < 0.105,:)
    scatter(TT.DUT_input_dBm,TT.Gain)
    scatter(TT.DrainI,TT.Gain)
    close all
    
    gatebiaslist = unique(round(TT.GateV,2));
    for i = 1:length(gatebiaslist)
        rf = rowfilter(TT);
        Tsingelbias = TT(rf.GateV > gatebiaslist(i) - 0.01 & rf.GateV < gatebiaslist(i) + 0.01,:);
        plot(Tsingelbias.DUT_output_dBm,Tsingelbias.PAE)
        hold on
    end
    waitforbuttonpress
end