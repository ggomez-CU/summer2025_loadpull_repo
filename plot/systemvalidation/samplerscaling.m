for i = 1:size(data.loadpull_single,2)
    for j = 1:size(data.loadpull_single(i).powerlist,1)
        freq = data.loadpull_single(i).freq
        minimum = abs(mean(abs(data.loadpull_single(i).gammaload(:,5,j) ))).^2;
        maximum = abs(mean(abs(data.loadpull_single(i).gammaload(:,5,j))+1)).^2;
        range1 = abs(min(data.loadpull_single(i).sampler1(:,5,j))-(max(data.loadpull_single(i).sampler1(:,5,j))))
        range2 = abs(min(data.loadpull_single(i).sampler2(:,5,j))-(max(data.loadpull_single(i).sampler2(:,5,j))))
        samp1scale = (maximum - minimum)./range1;
        samp1offset = (maximum - minimum) -  mean(data.loadpull_single(i).sampler1(:,5,j));
        samp2scale = (maximum - minimum)./range2;
        samp2offset = (maximum - minimum) -  mean(data.loadpull_single(i).sampler2(:,5,j));
        samplerscaling(:,i,j) = [freq, data.loadpull_single(i).powerlist(j), samp1offset, samp1scale, samp2offset, samp2scale]; 
    end
end
