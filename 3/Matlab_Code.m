clc;
clear;
close all;

%% Load and Preprocess Image
[fileName, filePath] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files'}, 'Select an Image');
if fileName == 0
    error('No image selected.');
end
inputImage = imread(fullfile(filePath, fileName));
if size(inputImage, 3) == 3
    inputImage = rgb2gray(inputImage);
end
inputImage = im2double(inputImage);


thresholdGlobal = 0.5;
windowSize = 15;
constantAdaptive = 0.05;
edgeThreshold = 0.1;
seedCoords = [100, 150];
regionThreshold = 0.2;


binaryGlobal = global_thresholding(inputImage, thresholdGlobal);
thresholdOtsu = otsu_method(inputImage);
binaryOtsu = global_thresholding(inputImage, thresholdOtsu);
binaryAdaptive = adaptive_thresholding(inputImage, windowSize, constantAdaptive);
edgeOutput = edge_based_segmentation(inputImage, edgeThreshold);
regionMask = region_growing(inputImage, seedCoords, regionThreshold);


figure('Name', 'Image Segmentation Results', 'NumberTitle', 'off', 'Position', [100 100 1200 800]);

subplot(2, 3, 1);
imshow(inputImage);
title('Original Image');

subplot(2, 3, 2);
imshow(binaryGlobal);
title(['Global (T=', num2str(thresholdGlobal), ')']);

subplot(2, 3, 3);
imshow(binaryOtsu);
title(['Otsu (T=', num2str(thresholdOtsu, '%.3f'), ')']);

subplot(2, 3, 4);
imshow(binaryAdaptive);
title(['Adaptive (Size=', num2str(windowSize), ', C=', num2str(constantAdaptive), ')']);

subplot(2, 3, 5);
imshow(edgeOutput);
title(['Edge (Thresh=', num2str(edgeThreshold), ')']);

subplot(2, 3, 6);
imshow(regionMask);
title(['Region (Seed=[', num2str(seedCoords), '], Thresh=', num2str(regionThreshold), ')']);


function binImage = global_thresholding(inputImage, thresholdVal)
    binImage = inputImage > thresholdVal;
end

function threshVal = otsu_method(inputImage)
    [rows, cols] = size(inputImage);
    totalPixels = rows * cols;
    intensityHist = zeros(256, 1);
    for row = 1:rows
        for col = 1:cols
            val = round(inputImage(row,col) * 255) + 1;
            intensityHist(val) = intensityHist(val) + 1;
        end
    end
    intensityHist = intensityHist / totalPixels;
    cumSum = zeros(256, 1);
    cumMean = zeros(256, 1);
    cumSum(1) = intensityHist(1);
    cumMean(1) = 0;
    for i = 2:256
        cumSum(i) = cumSum(i-1) + intensityHist(i);
        cumMean(i) = cumMean(i-1) + (i-1) * intensityHist(i);
    end
    maxVariance = 0;
    threshVal = 0;
    globalMean = cumMean(256);
    for t = 1:256
        if cumSum(t) == 0 || cumSum(t) == 1
            continue;
        end
        w0 = cumSum(t);
        w1 = 1 - w0;
        mu0 = cumMean(t) / w0;
        mu1 = (globalMean - cumMean(t)) / w1;
        varianceBetween = w0 * w1 * (mu1 - mu0)^2;
        if varianceBetween > maxVariance
            maxVariance = varianceBetween;
            threshVal = (t - 1) / 255;
        end
    end
end

function binImage = adaptive_thresholding(inputImage, blockSize, subConstant)
    [rows, cols] = size(inputImage);
    binImage = zeros(rows, cols);
    halfSize = floor(blockSize / 2);
    for row = 1:rows
        for col = 1:cols
            rStart = max(1, row - halfSize);
            rEnd = min(rows, row + halfSize);
            cStart = max(1, col - halfSize);
            cEnd = min(cols, col + halfSize);
            localRegion = inputImage(rStart:rEnd, cStart:cEnd);
            localThresh = mean(localRegion(:)) - subConstant;
            binImage(row,col) = inputImage(row,col) > localThresh;
        end
    end
end

function edgeMap = edge_based_segmentation(inputImage, thresholdEdge)
    [rows, cols] = size(inputImage);
    edgeMap = zeros(rows, cols);
    kernelX = [-1 0 1; -2 0 2; -1 0 1];
    kernelY = [1 2 1; 0 0 0; -1 -2 -1];
    paddedImage = padarray(inputImage, [1 1], 'replicate');
    for row = 2:rows+1
        for col = 2:cols+1
            region = paddedImage(row-1:row+1, col-1:col+1);
            gradX = sum(sum(region .* kernelX));
            gradY = sum(sum(region .* kernelY));
            gradMag = sqrt(gradX^2 + gradY^2);
            edgeMap(row-1,col-1) = gradMag > thresholdEdge;
        end
    end
end

function regionOut = region_growing(inputImage, startPoint, diffThresh)
    [rows, cols] = size(inputImage);
    regionOut = zeros(rows, cols);
    visitedMask = zeros(rows, cols);
    neighborOffsets = [-1 0; 1 0; 0 -1; 0 1];
    processingQueue = [startPoint(1), startPoint(2)];
    startIntensity = inputImage(startPoint(1), startPoint(2));
    while ~isempty(processingQueue)
        pixel = processingQueue(1,:);
        processingQueue(1,:) = [];
        if visitedMask(pixel(1), pixel(2))
            continue;
        end
        visitedMask(pixel(1), pixel(2)) = 1;
        if abs(inputImage(pixel(1), pixel(2)) - startIntensity) <= diffThresh
            regionOut(pixel(1), pixel(2)) = 1;
            for k = 1:size(neighborOffsets,1)
                newRow = pixel(1) + neighborOffsets(k,1);
                newCol = pixel(2) + neighborOffsets(k,2);
                if newRow >= 1 && newRow <= rows && newCol >= 1 && newCol <= cols
                    if ~visitedMask(newRow, newCol)
                        processingQueue = [processingQueue; newRow newCol];
                    end
                end
            end
        end
    end
end
