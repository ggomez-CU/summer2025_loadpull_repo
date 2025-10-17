clear all
close all
clc

new_LUT = LUTClass('C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\LUT2')
old_LUT = LUTClass('C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\LUT1')

%% Plot
% old_LUT.generate_report('old_LUT')
new_LUT.generate_report('new_LUT')

%%
for x = 1:size(new_LUT.freq,2)
    for y = 1:size(new_LUT.LUT,1)
        s11_old = old_LUT.tuner2s11(new_LUT.LUT(y,1,x),new_LUT.freq(x)) ;
        s11_new = new_LUT.tuner2s11(new_LUT.LUT(y,1,x),new_LUT.freq(x)) ;
        try
            diff(y,x) = abs(s11_old-s11_new);
        catch
            diff(y,x) = nan;
        end
    end
end

%%
import mlreportgen.ppt.*
ppt = Presentation('compare2.pptx');

titleSlide = add(ppt,'Title Slide');
replace(titleSlide,'Title','Load Termination Report');

for x = 1:size(old_LUT.freq,2)
    figure()
    init = polar(0,0);
    hold on
    clear s11_old
    new_LUT.freq(x)
    for y = 1:size(new_LUT.LUT,1)
        s11_new(y) = new_LUT.tuner2s11(new_LUT.LUT(y,1,x),new_LUT.freq(x)) ;
        try
            s11_old(y) = old_LUT.tuner2s11(new_LUT.LUT(y,1,x),new_LUT.freq(x)) ;
        catch
            s11_old(y) = nan;
        end
    end

    % scatter(real(old_LUT.LUT(:,1,i)),imag(old_LUT.LUT(:,1,i)),"filled");
    scatter(real(s11_old),imag(s11_old),"filled");
    % scatter(real(new_LUT.LUT(:,1,i)),imag(new_LUT.LUT(:,1,i)),"filled");
    scatter(real(new_LUT.LUT(:,2,x)),imag(new_LUT.LUT(:,2,x)),"filled");
    delete(init)
    legend('Tuner Old','Measured Old','Tuner New', 'Measured New')
    saveas(gcf,strcat('png/LUT',num2str(x),'.png'));
    close all

    largesignalSlide = add(ppt,'Title and Picture');
    plot1 = Picture(strcat('png/LUT',num2str(x),'.png'));
    replace(largesignalSlide,'Title',strcat('Load termination plot at', num2str(old_LUT.freq(x)),'GHz'));
    replace(largesignalSlide,'Picture',plot1);
end

close(ppt);
rptview(ppt);

%%
for i = 1:size(old_LUT.freq,2)-1
    hold on
    plot(abs(old_LUT.LUT(1:12:end,2,i)-old_LUT.LUT(1:12:end,2,i+1)));
end