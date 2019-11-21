%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A script to plot sample spectra after getting the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear 
close all
clc

seed          = 3;
num_sample    = 100;
generate_flag = 0;

matDataPath = 'T:\AnalysisDroneData\ReflectanceCube\MATdataCube\CLMB GWAS 2019 Flight Data\100083_2019_06_25_15_59_59\';


list      = dir([matDataPath, 'raw*.mat']);
    % get the correct order of the files
fileIdx = [];
for ii = 1:length(list)
    tempFile = list(ii).name;
    fileIdx  = [fileIdx str2double(tempFile(isstrprop(tempFile, 'digit')))];
end
[~, idx] = sort(fileIdx);
list = list(idx);

path_savesample = strrep(matDataPath, 'MATdataCube', 'sampleSpectra');
if ~exist(path_savesample, 'dir')
    mkdir(path_savesample)
end

% load wavelength
path_wl = 'T:\AnalysisDroneData\ReflectanceCube\ReadableHDR\CLMB GWAS 2019 Flight Data';
load(fullfile(path_wl, 'wavelength')) %wavelength


if generate_flag == 1
        % rules for wavelength to be kept: 
    % 1. Keep those within 438nm-900nm (smaller than 438nm or greater than 900nm are considered noisy bands)
    % 2. Remove those within 753nm-766nm (02 absorption bands)
    % 3. Remove those within 813nm-827nm (H2O absorption bands)

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
    save(fullfile(matDataPath, 'flagGoodWvlen.mat'), 'flag', 'wavelength')
end

for i_File = 1:length(list)
    name_data = list(i_File).name;
    load(fullfile(matDataPath, name_data))

    spectra = reshape(data, [size(data,1)*size(data,2), size(data,3)]);
    rng(seed)
    idx = randsample(size(spectra, 1), num_sample);

    figure
%     set(gcf,'outerposition',get(0,'screensize'))
    plot(wavelength, spectra(idx, :), 'r')
    set(gca, 'FontSize', 16)
    xlabel('wavelength(nm)', 'fontsize', 17)
    ylabel('reflectance', 'fontsize', 17)
%    title('Original Spectra', 'fontsize',31)
    
%     subplot(1,2,2), plot(wavelength(find(flag == 1, 1),:), spectra(idx,find(flag == 1, 1)), 'b')
%     plot(wavelength(idxs(1):idxs(3),:), spectra(idx, idxs(1):idxs(3)), 'b'), hold on
%     plot(wavelength(idxs(4):idxs(5),:), spectra(idx, idxs(4):idxs(5)), 'b'), hold on
%     plot(wavelength(idxs(6):idxs(2),:), spectra(idx, idxs(6):idxs(2)), 'b')
%     set(gca,'FontSize',28)
%     xlabel('wavelength(nm)', 'fontsize', 30)
%     ylabel('reflectance', 'fontsize', 30)    
%     title('Spectra after Noisy Bands Removal', 'fontsize', 31)
    saveas(gcf, fullfile(path_savesample, strrep(name_data, '_rd_rf.mat', '.png')), 'png')
    close all
end
