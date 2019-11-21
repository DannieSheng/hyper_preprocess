function [imRGB] = showRGB(data, wavelength)
%a function to show the RGB visualization of hyperspectral images
%   Detailed explanation goes here
rR       = 670.641;%650;
gR       = 538.939;%532;
bR       = 480.901;%473;
index = [];
[~, index(:,1)] = sort(abs(wavelength-rR));
[~, index(:,2)] = sort(abs(wavelength-gR));
[~, index(:,3)] = sort(abs(wavelength-bR));

RGBdT = data(:,:,index(1,:));

mint = min(RGBdT(:));
maxt = max(RGBdT(:));

RGBd = (RGBdT-mint)/(maxt-mint);
imRGB = sqrt(RGBd);
end

