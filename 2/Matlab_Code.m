clc;
clearvars;

% Reading the Koala image
I = imread('Koala.png');
I = double(I);  % Converting into double for processing

%  User Enter the noise density
density = input('Enter salt & pepper noise density (e.g., 0.3, 0.5, 0.7): ');

% Adding salt-and-pepper noise
noisy_img = imnoise(uint8(I), 'salt & pepper', density);
noisy_img = double(noisy_img);

% --------- Standard Median Filter ---------
mask = ones(3, 3);  % 3x3 window
padSize = floor(size(mask, 1) / 2);
paddedI = padarray(noisy_img, padSize, "replicate",'both');
[rows, cols] = size(noisy_img);
standard_result = zeros(rows, cols);

for i = 1:rows
    for j = 1:cols
        region = paddedI(i:i+2, j:j+2);
        standard_result(i, j) = median(region(:));
    end
end

% --------- Adaptive Median Filter ---------
max_window_size = 7;
adaptive_result = noisy_img;

for i = 1:rows
    for j = 1:cols
        window_size = 3;
        found = false;

        while window_size <= max_window_size && ~found
            pad = floor(window_size / 2);
            r_min = max(i - pad, 1);
            r_max = min(i + pad, rows);
            c_min = max(j - pad, 1);
            c_max = min(j + pad, cols);

            region = noisy_img(r_min:r_max, c_min:c_max);
            z_min = min(region(:));
            z_max = max(region(:));
            z_med = median(region(:));
            z_xy = noisy_img(i, j);

            A1 = z_med - z_min;
            A2 = z_med - z_max;

            if A1 > 0 && A2 < 0
                B1 = z_xy - z_min;
                B2 = z_xy - z_max;
                if B1 > 0 && B2 < 0
                    adaptive_result(i, j) = z_xy;
                else
                    adaptive_result(i, j) = z_med;
                end
                found = true;
            else
                window_size = window_size + 2;
            end
        end

        if ~found
            adaptive_result(i, j) = z_med;
        end
    end
end

% Calculating MSE
mse_standard = immse(uint8(standard_result), uint8(I));
mse_adaptive = immse(uint8(adaptive_result), uint8(I));

% Displaying the results --Original , Standard Median Filtered , Adaptive Median Filter
figure;
subplot(2, 2, 1), imshow(uint8(I)), title('Original Koala Image');
subplot(2, 2, 2), imshow(uint8(noisy_img)), title(['Noisy Image (', num2str(density * 100), '% noise)']);
subplot(2, 2, 3), imshow(uint8(standard_result)), title('Standard Median Filtered');
subplot(2, 2, 4), imshow(uint8(adaptive_result)), title('Adaptive Median Filtered');

% Displaying MSE results
fprintf('\nMSE Comparison for %.0f%% noise:\n', density * 100);
fprintf('Standard Median Filter MSE: %.2f\n', mse_standard);
fprintf('Adaptive Median Filter MSE: %.2f\n', mse_adaptive);
