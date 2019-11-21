%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A script to automatically modify the .txt files to make them able to be
% read later on
% Saved files after running this script: 
% 1. a .hdr file which is "readable"
% 2. a .mat file which contains the parameters read from the original .hdr
% files
% for later envi data reader
% Author: Hudanyun Sheng
% hdysheng@ufl.edu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dbstop if error
clear; close all; clc

flirFlag  = 0; % set to 1 if dealing with flir data, set to 0 if dealing with hyperspectral data
dataFlag  = 'reflectance'; % values can be: 'reflectance', 'raw', 'ortho'
multi_ortho = 0;
if strcmpi(dataFlag, 'raw')
    rawdataFlag = 1;
end

originalPath    = 'T:\Box2\Drone Flight Data and Reference Files\Flight Data - All Sites\CLMB GWAS 2019 Flight Data\100086_2019_07_18_16_55_39\';

if flirFlag == 1
    originalPath = [originalPath, 'FLIR\'];   
end
modifiedHDRpath = strrep(originalPath, 'T:\Box2\Drone Flight Data and Reference Files\Flight Data - All Sites', 'T:\AnalysisDroneData\ReadableHDR');

% modifiedHDRpath = strrep(originalPath, 'T:\Box2', 'T:\Results\Analysis CLMB 2018 drone data\Readable HDR');
% originalPath = 'T:\Results\Analysis CLMB 2018 drone data\orthorectification\Hyperspectral_reflectance\Maria_Bradford_Switchgrass_Standplanting\100071_2018_10_31_16_29_53\parameter1\orFiles\';
% modifiedHDRpath = strrep(originalPath, 'orFiles', 'Readable HDR');

if strcmpi(dataFlag, 'reflectance')
	originalPath = strrep(originalPath, 'T:\Box2\Drone Flight Data and Reference Files\Flight Data - All Sites', 'T:\AnalysisDroneData\ReflectanceCube');
    modifiedHDRpath = strrep(originalPath, 'T:\AnalysisDroneData\ReflectanceCube', 'T:\AnalysisDroneData\ReflectanceCube\ReadableHDR');
elseif strcmpi(dataFlag, 'ortho')
	originalPath = strrep(originalPath, 'T:\Box2\Drone Flight Data and Reference Files\Flight Data - All Sites', 'T:\AnalysisDroneData\OrthoRectification');    
	if multi_ortho == 1
        originalPath = [originalPath, 'multi_ortho\'];
	end
    modifiedHDRpath = strrep(originalPath, 'T:\AnalysisDroneData\OrthoRectification', 'T:\AnalysisDroneData\OrthoRectification\ReadableHDR');
end

if ~exist(modifiedHDRpath, 'dir')
	mkdir(modifiedHDRpath)
end
list      = dir([originalPath, '*.hdr']);

%% get the correct order of the files
fileIdx = [];
for ii = 1:length(list)
    tempFile = list(ii).name;
% 	fileIdx  = [fileIdx str2double(list(ii).name(isstrprop(fileName, 'digit')))];
    fileIdx  = [fileIdx str2double(tempFile(isstrprop(tempFile, 'digit')))];
end
[~, idx] = sort(fileIdx);
list     = list(idx);

for i_File = 1:length(list)
    fileName = [originalPath, list(idx(i_File)).name];
    saveName = [modifiedHDRpath, list(idx(i_File)).name];
    fin = fopen(fileName);
    rawdata = textscan(fin, '%s', 'delimiter', '\n');%
    for ii = 1:length(rawdata{1,1})
        % get rid of ',' and ';' at the beginning of every line
        if ~ismember('map info', rawdata{1,1}{ii,1})
            rawdata{1,1}{ii,1} = strrep(rawdata{1,1}{ii,1}, ';', '');
            rawdata{1,1}{ii,1} = strrep(rawdata{1,1}{ii,1}, ',', '');
        end
        if startsWith(rawdata{1,1}{ii,1}, ',')
            rawdata{1,1}{ii,1} = strrep(rawdata{1,1}{ii,1}, ',', '');
        end
        if startsWith(rawdata{1,1}{ii,1}, ';')
            rawdata{1,1}{ii,1} = strrep(rawdata{1,1}{ii,1}, ';', '');
        end
        if ~isempty(strfind(rawdata{1,1}{ii,1}, '(m)'))
            rawdata{1,1}{ii,1} = strrep(rawdata{1,1}{ii,1}, '(m)', 'in m');
        end
        if ~isempty(strfind(rawdata{1,1}{ii,1}, '(ms)'))
            rawdata{1,1}{ii,1} = strrep(rawdata{1,1}{ii,1}, '(ms)', 'in ms');
        end
        if ~isempty(strfind(rawdata{1,1}{ii,1}, '(mm)'))
            rawdata{1,1}{ii,1} = strrep(rawdata{1,1}{ii,1}, '(mm)', 'in mm');
        end
        if ~isempty(strfind(rawdata{1,1}{ii,1}, '(um)'))
            rawdata{1,1}{ii,1} = strrep(rawdata{1,1}{ii,1}, '(um)', 'in mm');
        end
        if ~isempty(strfind(rawdata{1,1}{ii,1}, 'Avg.'))
            rawdata{1,1}{ii,1} = strrep(rawdata{1,1}{ii,1}, 'Avg.', 'Avg');
        end
        if ~isempty(strfind(rawdata{1,1}{ii,1}, 'Ortho GPS Offset')) && ~isempty(strfind(rawdata{1,1}{ii,1}, 'Positive'))
            rawdata{1,1}{ii,1} = strrep(rawdata{1,1}{ii,1}, '-', ' ');
        end
        
        if rawdataFlag == 0
            if ismember('CffHeader = ', rawdata{1,1}{ii,1})
                breakindex = ii;
            end

%             find the lines with wavelengths
            if ismember('wavelength = ', rawdata{1,1}{ii,1})
                index = ii;
            end
        end
    end
    parameters = rawdata{1,1};
    fclose(fin);

    fout = fopen(saveName, 'a');
    if rawdataFlag == 1
        for ii = 1:length(rawdata{1,1})%breakindex-1%
            fprintf(fout, '%s\r\n', rawdata{1,1}{ii,1} );
        end
    else
        for ii = 1:breakindex-1%
            fprintf(fout, '%s\r\n', rawdata{1,1}{ii,1});
        end
    end
    fclose(fout);
    save(strrep(saveName, '.hdr', '.mat'), 'parameters')
end
sound(sin(2*pi*25*(1:4000)/100))