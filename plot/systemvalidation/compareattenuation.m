
pna2dutfolder = '..\..\data\deembedatten\2025-07-15_21_30_Freq12.0to8.0';
atten = CalibrationClass('..\..\data\errordata\20250717_2',pna2dutfolder );
other = CalibrationClass('..\..\data\errordata\1PORT_20250718',pna2dutfolder )

% subplot(1,3,1)
polar(0,0)
hold on
scatter(real(atten.error_directivity(1)),imag(atten.error_directivity(1)))
scatter(real(other.error_directivity(1)),imag(other.error_directivity(1)))

% subplot(1,3,2)
% scatter(real(atten.error_tracking),imag(atten.error_tracking))
% hold on
% scatter(real(other.error_tracking),imag(other.error_tracking))
% subplot(1,3,3)
% scatter(real(atten.error_match),imag(atten.error_match))
% hold on
% scatter(real(other.error_match),imag(other.error_match))


