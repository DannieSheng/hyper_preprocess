%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A script to automatically read hyperspectral data from HDR format and
% save in .mat files
% Author: Hudanyun Sheng
% hdysheng@ufl.edu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath('\\ece-azare-nas1.ad.ufl.edu\ece-azare-nas\Profile\hdysheng\Documents\MATLAB\Rhizotron code\droneData\ENVIreader')
dbstop if error
% clear;
close all; clc

original_data_flag = 0; % set to 1 if use original data, set to 0 if use preprocessed data, e.g. orthorectified data
flirFlag           = 0; % set to 1 if dealing with flir data, set to 0 if dealing with hyperspectral data
dataPath           = 'T:\Box2\Drone Flight Data and Reference Files\Flight Data - All Sites\CLMB GWAS 2019 Flight Data\100086_2019_07_18_16_55_39\';

if flirFlag == 1
    dataPath = [dataPath, '\FLIR\'];
else
    rR       = 670.641;%650;
    gR       = 538.939;%532;
    bR       = 480.901;%473;
end

if original_data_flag == 1 
    hdrPath     = strrep(dataPath, 'T:\Box2\Drone Flight Data and Reference Files\Flight Data - All Sites', 'T:\AnalysisDroneData\ReadableHDR');
    matDataPath = strrep(hdrPath, 'ReadableHDR', 'MATdataCube');
else
    dataPath    =  strrep(dataPath, 'T:\Box2\Drone Flight Data and Reference Files\Flight Data - All Sites', 'T:\AnalysisDroneData\ReflectanceCube'); 
    hdrPath     = strrep(dataPath, 'T:\AnalysisDroneData\ReflectanceCube', 'T:\AnalysisDroneData\ReflectanceCube\ReadableHDR');
    matDataPath = strrep(hdrPath, 'ReadableHDR', 'MATdataCube');
end
if ~exist(matDataPath, 'dir')
    mkdir(matDataPath)
end

list = dir([hdrPath, '*.hdr']);
band = [];

%% get the correct order of the files
fileIdx = [];
for ii = 1:length(list)
    tempFile = list(ii).name;
% 	fileIdx  = [fileIdx str2double(list(ii).name(isstrprop(fileName, 'digit')))];
    fileIdx  = [fileIdx str2double(tempFile(isstrprop(tempFile, 'digit')))];
end
[~, idx] = sort(fileIdx);
list     = list(idx);
% if the data is correct delete the line below
% list = list([1:2:end]);

%%
for i_File = 1:length(list)
    %% read and save data to .mat files
    fileName = strrep(list(i_File).name, '.hdr', '.mat');
    cubeName  = str2double(fileName(isstrprop(fileName, 'digit')));
    hdrFile = [hdrPath, list(i_File).name];
    dataFile = [dataPath, strrep(list(i_File).name, '.hdr', [ ])];
    [data,infoData] = enviread(dataFile, hdrFile);
	save([matDataPath, strrep(list(i_File).name, '.hdr', '.mat')], 'data','-v7.3')

    if flirFlag == 1
        dataRange(i_File, 1) = min(data(:));
        dataRange(i_File, 2) = max(data(:));
        flir_savePath = [matDataPath, num2str(cubeName), '\'];
        if ~exist(flir_savePath, 'dir')
            mkdir(flir_savePath)
        end
        for ii = 1:size(data, 3)
            imgData = data(:,:,ii);
            save([flir_savePath, num2str(cubeName+ii-1), '.mat'], 'imgData')
%             figure, imshow(imgData)
%             saveas(gcf, [flir_savePath, num2str(cubeName+ii-1) '.jpg'], 'jpg')
        end
        
    else    
     %% used only for hyperspectral data: save wavelengths and get a visualization with selected RGB bands
        load([hdrPath, strrep(list(i_File).name, '.hdr', '.mat')]) %parameters    
        % find the used wavelengths and save into parameters corresponding to
        % every image
        for ii = 1:length(parameters)
            if ismember('wavelength = {', parameters{ii,1})
                first = ii+1;
            end
            if ismember('}', parameters{ii,1})
                last = ii-1;
            end
        end    
        wavelength = [];
        for ii = first:last
            wavelength = [wavelength; str2num(parameters{ii,1})];
        end
        save([hdrPath, strrep(list(i_File).name, '.hdr', '.mat')], 'wavelength', 'parameters')
        disp(['Filename:', list(i_File).name, ', numBands:', num2str(length(wavelength))])
    
        %% plot data into RGB images
        index = [];
        [~, index(:,1)] = sort(abs(wavelength-rR));
        [~, index(:,2)] = sort(abs(wavelength-gR));
        [~, index(:,3)] = sort(abs(wavelength-bR));
    
        RGBdT = [];
        RGBd  = [];

        RGBdT = data(:,:,index(1,:));
    
        mint = min(RGBdT(:));
        maxt = max(RGBdT(:));
    
%     for band = 1:3
%         RGBdT(:,:,band) = mean(data(:,:,index(1:numBands(band),band)),3);
%     end

% 	RGBd  = 255*(RGBdT-minT)/maxT;
%     RGBd(:,:,1) = RGBd(:,:,1).^1.08;
%     RGBd(:,:,3) = RGBd(:,:,3).^1.15;
    
        RGBd = (RGBdT-mint)/(maxt-mint);
        figure, image(sqrt(RGBd)), axis image, axis off
% 	figure, imshow(uint8(RGBd.^1.1)), axis image
% 	save('mariaNormTerm_100032_2018_08_06_18_19_57.mat', 'minT', 'maxT')
        jpgName = strrep(fileName, '.mat', '_rgb.jpg');
        saveas(gcf, [matDataPath, jpgName], 'jpg')
        close all
    end
%     sound(sin(2*pi*25*(1:4000)/100))
end
if flirFlag == 1
    save([matDataPath,  'normValues.mat'], 'dataRange')
end