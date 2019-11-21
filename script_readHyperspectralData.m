%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A script to automatically read hyperspectral data from HDR format and
% save in .mat files
% Author: Hudanyun Sheng
% hdysheng@ufl.edu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath('\\ece-azare-nas1.ad.ufl.edu\ece-azare-nas\Profile\hdysheng\Documents\MATLAB\Rhizotron code\droneData\ENVIreader')
dbstop if error
clear;
close all; clc

flirFlag    = 0; % set to 1 if dealing with flir data, set to 0 if dealing with hyperspectral data
dataFlag    = 'reflectance'; % values can be: 'reflectance', 'raw', 'ortho'
multi_ortho = 0;
dataPath    = 'T:\Box2\Drone Flight Data and Reference Files\Flight Data - All Sites\CLMB GWAS 2019 Flight Data\100086_2019_07_18_16_55_39\';

if flirFlag == 1
    dataPath = [dataPath, '\FLIR\'];
else
    rR       = 670.641;%650;
    gR       = 538.939;%532;
    bR       = 480.901;%473;
end

if strcmpi(dataFlag, 'reflectance')
    dataPath    = strrep(dataPath, 'T:\Box2\Drone Flight Data and Reference Files\Flight Data - All Sites', 'T:\AnalysisDroneData\ReflectanceCube'); 
    hdrPath     = strrep(dataPath, 'T:\AnalysisDroneData\ReflectanceCube', 'T:\AnalysisDroneData\ReflectanceCube\ReadableHDR');
elseif strcmpi(dataFlag, 'ortho')
    dataPath    = strrep(dataPath, 'T:\Box2\Drone Flight Data and Reference Files\Flight Data - All Sites', 'T:\AnalysisDroneData\OrthoRectification'); 
	if multi_ortho == 1
        dataPath = [dataPath, 'multi_ortho\'];
	end
    hdrPath     = strrep(dataPath, 'T:\AnalysisDroneData\OrthoRectification', 'T:\AnalysisDroneData\OrthoRectification\ReadableHDR');
else
	hdrPath     = strrep(dataPath, 'T:\Box2\Drone Flight Data and Reference Files\Flight Data - All Sites', 'T:\AnalysisDroneData\ReadableHDR');
end
matDataPath = strrep(hdrPath, 'ReadableHDR', 'MATdataCube');
    
 if ~exist(matDataPath, 'dir')
    mkdir(matDataPath)
end

list = dir([hdrPath, '*.hdr']);
% get the correct order of the files
fileIdx = [];
for ii = 1:length(list)
    tempFile = list(ii).name;
    fileIdx  = [fileIdx str2double(tempFile(isstrprop(tempFile, 'digit')))];
end
[~, idx] = sort(fileIdx);
list     = list(idx);

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
%         index = [];
%         [~, index(:,1)] = sort(abs(wavelength-rR));
%         [~, index(:,2)] = sort(abs(wavelength-gR));
%         [~, index(:,3)] = sort(abs(wavelength-bR));
%     
%         RGBdT = [];
%         RGBd  = [];
% 
%         RGBdT = data(:,:,index(1,:));
%     
%         mint = min(RGBdT(:));
%         maxt = max(RGBdT(:));    
%         RGBd = (RGBdT-mint)/(maxt-mint);
%         figure, image(sqrt(RGBd)), axis image, axis off
        imRGB = showRGB(data, wavelength);
        save([matDataPath, strrep(fileName, '.mat', '_rgb.mat')], 'imRGB')
        figure, image(imRGB), axis image, axis off
        truesize
        saveas(gcf, [matDataPath, strrep(fileName, '.mat', '_rgb.png')], 'png')
        close all
    end
end
if flirFlag == 1
    save([matDataPath,  'normValues.mat'], 'dataRange')
end