%%%%
% A script to generate "good wavelength flag" file for a flight (for all data)
%%%%
clear 
close all
clc

seed = 3;

% data info
% year     = '2019';
% date     = '06_25';
% loc      = 'CLMB';
% planting = 'STND';
path_data = 'T:\AnalysisDroneData\ReflectanceCube\MATdataCube\CLMB GWAS 2019 Flight Data\100086_2019_07_18_16_55_39\';


list = dir([path_data, 'raw*.mat']);
name_data = list(randsample(length(list),1)).name;
load(fullfile(path_data, name_data)) % data

% load wavelength
path_wl = strrep(path_data, 'MATdataCube', 'ReadableHDR');
load(fullfile(path_wl, name_data)) %wavelength

% path_data = [path_data '56\'];
%% 
% rules for wavelength to be kept: 
% 1. Keep those within 438nm-900nm (smaller than 438nm or greater than 900nm are considered noisy bands)
% 2. Remove those within 753nm-766nm (02 absorption bands)
% 3. Remove those within 813nm-827nm (H2O absorption bands)

path_savesample = strrep(path_data, 'MATdataCube', 'sampleSpectra');

if ~exist(path_savesample, 'dir')
    mkdir(path_savesample)
end

list_wvs = [438, 900, 753, 766, 813, 827];
idxs     = [];
for i = 1:length(list_wvs)
    wv = list_wvs(i);
	[~,temp] = sort(abs(wavelength-wv), 'ascend');
    idxs(i) = temp(1:1);
end

flag = ones(size(wavelength));
flag(1:idxs(1),:)       = 0;
flag(idxs(2):end,:)     = 0;
flag(idxs(3):idxs(4),:) = 0;
flag(idxs(5):idxs(6),:) = 0;
save(fullfile(path_data, 'flagGoodWvlen.mat'), 'flag', 'wavelength')

num_pix = 500;
for i_File = 1:length(list)
    name_data = list(i_File).name;
    load(fullfile(path_data, name_data))
    % sample plot of before & after removel of bands
    spectra = reshape(data, [size(data,1)*size(data,2), size(data,3)]);
    rng(seed)
    idxs = randsample(size(spectra, 1),num_pix);
    figure
    set(gcf,'outerposition',get(0,'screensize'))
    subplot(1,2,1), plot(wavelength, spectra(idxs, :), 'r')
    xlabel('wavelength(nm)', 'fontsize', 15)
    ylabel('reflectance', 'fontsize', 15)
    title('Original Spectra', 'fontsize', 19)

    % wavelength_ = wavelength(find(flag == 1),:);
    % spectra_    = spectra(:,find(flag == 1));
    subplot(1,2,2), plot(wavelength(find(flag == 1),:), spectra(idxs,find(flag == 1)), 'b')
    xlabel('wavelength(nm)', 'fontsize', 15)
%     ylabel('reflectance', 'fontsize', 15)
    title('Spectra after "bad" bands removal', 'fontsize', 19)
    
    saveas(gcf, fullfile(path_savesample, strrep(name_data, '_rd_rf.mat', '.png')), 'png')
    close all
end
