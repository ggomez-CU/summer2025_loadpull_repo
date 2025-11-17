function [inAtten, outAtten] = getAtten(tmpFreq,freqAtten)
    it1 = find(freqAtten(:,1) == tmpFreq);
    inAtten = freqAtten(it1,2);
    outAtten = freqAtten(it1,3);
end