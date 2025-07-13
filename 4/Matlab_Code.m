clc;
clear;
close all;

img = imread('Machine Parts.png');
imgGray = rgb2gray(img);

binImg = imgGray > 128;

sE = ones(3, 3);

opnImg = pDilate(pErode(binImg, sE), sE);
clsImg = pErode(pDilate(opnImg, sE), sE);
bndExt = binImg - pErode(binImg, sE);

figure('Name', 'Morph Ops');
subplot(2, 3, 1); imshow(binImg); title('Orig Bin');
subplot(2, 3, 2); imshow(opnImg); title('Opened');
subplot(2, 3, 3); imshow(clsImg); title('Closed');
subplot(2, 3, 4); imshow(bndExt); title('Boundary');

[r, c] = size(imgGray);
bPlanes = zeros(r, c, 8);
for kIdx = 1:8
    shftImg = floor(double(imgGray) / 2^(kIdx-1));
    bPlanes(:,:,kIdx) = mod(shftImg, 2);
end

figure('Name', 'Bit Planes');
for kIdx = 1:8
    subplot(2, 4, kIdx);
    imshow(bPlanes(:,:,kIdx));
    title(['Plane ', num2str(kIdx-1)]);
end

figure('Name', 'Enhanced Bit Planes');
for kIdx = 1:8
    currPln = bPlanes(:,:,kIdx);
    opnPln = pDilate(pErode(currPln, sE), sE);
    clsPln = pErode(pDilate(opnPln, sE), sE);
    subplot(2, 4, kIdx);
    imshow(clsPln);
    title(['Enh Bit ', num2str(kIdx-1)]);
end

function out = pErode(inImg, sElem)
    [imgR, imgC] = size(inImg);
    padSz = floor(size(sElem, 1) / 2);
    padImg = padarray(inImg, [padSz padSz], 1);
    out = zeros(size(inImg));
    
    for i = 1:imgR
        for j = 1:imgC
            imgReg = padImg(i:i+2*padSz, j:j+2*padSz);
            if all(imgReg(sElem == 1) == 1)
                out(i, j) = 1;
            end
        end
    end
end

function out = pDilate(inImg, sElem)
    [imgR, imgC] = size(inImg);
    padSz = floor(size(sElem, 1) / 2);
    padImg = padarray(inImg, [padSz padSz], 0);
    out = zeros(size(inImg));
    
    for i = 1:imgR
        for j = 1:imgC
            imgReg = padImg(i:i+2*padSz, j:j+2*padSz);
            if any(imgReg(sElem == 1) == 1)
                out(i, j) = 1;
            end
        end
    end
end