%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Script of one step of preprocessing: smoothing
%  After reading the hyperspectral data and saved the data cubes
%  Method: Savitzky-Golay filtering
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
close all
clc

matDataPath = 'T:\AnalysisDroneData\ReflectanceCube\MATdataCube\CLMB GWAS 2019 Flight Data\100086_2019_07_18_16_55_39'; % path of the .mat data cubes
list = dir(fullfile(matDataPath, 'raw*.mat'));
    % get the correct order of the files
fileIdx = [];
for ii = 1:length(list)
    tempFile = list(ii).name;
    fileIdx  = [fileIdx str2double(tempFile(isstrprop(tempFile, 'digit')))];
end
[~, idx] = sort(fileIdx);
list = list(idx);

% load flags of wavelengths
load('T:\AnalysisDroneData\flagGoodWvlen.mat') % wavelength, flag

% window_size = 5;
% filter_b    = (1/window_size)*ones(1, window_size);
% filter_a    = 1;
% num_sample  = 1000;

parameters.order      = 2;
parameters.framelen   = 21;

num_sample = 500;

path_smooth = strrep(matDataPath, 'MATdataCube', 'SmoothDataCube');
path_smooth = [path_smooth, '\frame_length', num2str(parameters.framelen)];
if ~exist(path_smooth, 'dir')
    mkdir(path_smooth)
end
save(fullfile(path_smooth, 'parameters.mat'), 'parameters')

for iFile = 32:length(list)
	fileName       = list(iFile).name;
    load(fullfile(matDataPath, fileName)) %data
    [r, c, b]  = size(data);
    cubeName       = str2double(fileName(isstrprop(fileName, 'digit')));
    spectra        = reshape(data, r*c, b);
%     smooth_spectra = filter(filter_b, filter_a, spectra, [], 2);
    smooth_spectra = sgolayfilt(spectra', parameters.order, parameters.framelen);
    smooth_spectra = smooth_spectra';
    smooth_cube    = reshape(smooth_spectra, [r, c, b]);
    save(fullfile(path_smooth, [num2str(cubeName) '_smoothed.mat']), 'smooth_cube', '-v7.3')
    id             = randsample(r*c, num_sample);
    
    % plots
    figure, subplot(1,3,1), plot(wavelength, spectra(id, :), 'r'), ylim([0,1]), set(gca, 'FontSize', 16)
    title('Original spectra', 'FontSize', 15), xlabel('wavelength(nm)', 'FontSize', 17), ylabel('reflectance', 'FontSize', 17)
    
    subplot(1,3,2), plot(wavelength, smooth_spectra(id, :), 'b'), ylim([0,1]), set(gca, 'FontSize', 16)
    title('Smoothed spectra', 'FontSize', 15), xlabel('wavelength(nm)', 'FontSize', 17), ylabel('reflectance', 'FontSize', 17)
    
%     smooth_spectra_ = smooth_spectra(:,flag == 1);% remove "bad" bands
%     subplot(1,3,3), plot(wavelength(flag == 1), smooth_spectra_(id, :), 'g'), ylim([0,1]), set(gca, 'FontSize', 12)
    smooth_spectra_ = smooth_spectra.*repmat(flag', size(smooth_spectra,1),1);
	subplot(1,3,3), plot(wavelength, smooth_spectra_(id, :), 'g'), ylim([0,1]), set(gca, 'FontSize', 16)
    title('Noisy bands removed spectra', 'FontSize', 15), xlabel('wavelength(nm)', 'FontSize', 17), ylabel('reflectance', 'FontSize', 17)
    
    set(gcf, 'Position', get(0, 'Screensize'));
    saveas(gcf, fullfile(path_smooth, [num2str(cubeName) '_smoothed.png']), 'png')
    close
end
