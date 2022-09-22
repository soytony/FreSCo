% close all;
% clear;

% tmp_cloud_input1 = csvread('/home/tony/Documents/pointcloud_pca_test/cmake-build-debug/209.pcd_input.csv');
% tmp_cloud_input2 = csvread('/home/tony/Documents/pointcloud_pca_test/cmake-build-debug/215.pcd_output.csv');

% tmp_cloud_input1 = csvread('/home/tony/Desktop/selected_keyframes/output_bvm/001949.csv');
% tmp_cloud_input2 = csvread('/home/tony/Desktop/selected_keyframes/output_bvm/001159.csv');

% tmp_cloud_input1 = csvread('/home/tony/Documents/Datasets/MulRan/KAIST03/selected_keyframes/output_bvm/002139.csv');
% tmp_cloud_input2 = csvread('/home/tony/Documents/Datasets/MulRan/KAIST03/selected_keyframes/output_bvm/001800.csv');

tmp_cloud_input1 = csvread('/home/tony/Documents/Datasets/KITTI/08/selected_keyframes/output_bvm/000622.csv');
tmp_cloud_input2 = csvread('/home/tony/Documents/Datasets/KITTI/08/selected_keyframes/output_bvm/000019.csv');

% cloud_input1 = imresize(tmp_cloud_input1, [101, 101], 'nearest');
% cloud_input2 = imresize(tmp_cloud_input2, [101, 101], 'nearest');
cloud_input1 = imresize(tmp_cloud_input1, [101, 101], 'bilinear');
cloud_input2 = imresize(tmp_cloud_input2, [101, 101], 'bilinear');

input_fft1 = fft2(cloud_input1);
input_fft2 = fft2(cloud_input2);

figure;

subplot(3,3,1);
imagesc(cloud_input1);
title('Input BV 1');
subplot(3,3,2);
imagesc(cloud_input2);
title('Input BV 2');

subplot(3,3,4);
input_amp1 = abs(fftshift(input_fft1));
imagesc(input_amp1);
title('FFT 1');
subplot(3,3,5);
input_amp2 = abs(fftshift(input_fft2));
imagesc(input_amp2);
title('FFT 2');


diff = input_amp1 - input_amp2;
subplot(3,3,3);
imagesc(diff);
title('diff btw 1 and 2');


low_freq_part1_mat = applyGaussian(input_amp1(31:71, 31:71));
low_freq_part1 = low_freq_part1_mat(:);
low_freq_part2_mat = applyGaussian(input_amp2(31:71, 31:71));
low_freq_part2 = low_freq_part2_mat(:);

diff_cart = norm(low_freq_part1 - low_freq_part2);
diff_cosine = dot(low_freq_part1,low_freq_part2)/(norm(low_freq_part1)*norm(low_freq_part2));

fprintf("distance before rotation: cart: %f, cosine: %f\n", diff_cart, diff_cosine);

half_low_freq_part1 = input_amp1(31:71, 31:71);
half_low_freq_part2 = input_amp2(31:71, 31:71);

theta1 = computeComponentAngle(input_amp1);
theta2 = computeComponentAngle(input_amp2);

fprintf("theta1: %f\n", theta1);
fprintf("theta2: %f\n", theta2);

amp1_normed = imrotate(input_amp1, theta1, 'crop', 'bilinear');
amp2_normed = imrotate(input_amp2, theta2, 'crop', 'bilinear');

theta2_small = computeComponentAngle(amp2_normed)
amp2_normed_small = imrotate(input_amp2, theta2 + theta2_small, 'crop', 'bilinear');
theta2_small_small = computeComponentAngle(amp2_normed_small)

subplot(3,3,7);
imagesc(amp1_normed);
title('FFT 1 rotated');
subplot(3,3,8);
imagesc(amp2_normed);
title('FFT 2 rotated');


diff_whole = amp1_normed - amp2_normed;
low_freq_part1 = applyGaussian(amp1_normed(31:71, 31:71));
low_freq_part1 = low_freq_part1(:);
low_freq_part2 = applyGaussian(amp2_normed(31:71, 31:71));
low_freq_part2 = low_freq_part2(:);

diff_cart = norm(low_freq_part1 - low_freq_part2);
diff_cosine = dot(low_freq_part1,low_freq_part2)/(norm(low_freq_part1)*norm(low_freq_part2));
subplot(3,3,9);
imagesc(diff_whole);
title('diff btw 1 and 2 aft rotation');

fprintf("distance after rotation: cart: %f, cosine: %f\n", diff_cart, diff_cosine);


h=impixelinfo;%impixelinfo能够在当前绘图窗口（figure）中显示绘制图像的像素信息
set(h,'position',[10 10 200 50]);%显示框

%% draw cart to polar
figure;
subplot(2,3,1);
imagesc(low_freq_part1_mat);
title('low freq part of 1');

part1_pol = ImToPolar(low_freq_part1_mat, 0, 1, 20, 120);
part1_pol_mean = mean(part1_pol, 'all'); % not used
% part1_pol = part1_pol ./ part1_pol_mean;
subplot(2,3,2);
imagesc(part1_pol);
title('polarized low freq part of 1');

subplot(2,3,4);
imagesc(low_freq_part2_mat);
title('low freq part of 2');

part2_pol = ImToPolar(low_freq_part2_mat, 0, 1, 20, 120);
part2_pol_mean = mean(part2_pol, 'all'); %not used
% part2_pol = part2_pol ./ part2_pol_mean;
subplot(2,3,5);
imagesc(part2_pol);
title('polarized low freq part of 2');


% % compute fft for each row
% part1_pol_t = part1_pol';
% part2_pol_t = part2_pol';
% part1_pol_row_fft = (abs(fftshift(fft((part1_pol_t)))))';
% part2_pol_row_fft = (abs(fftshift(fft((part2_pol_t)))))';
% subplot(2,3,3);
% imagesc(part1_pol_row_fft);
% subplot(2,3,6);
% imagesc(part2_pol_row_fft);


max_corr = 1e10;
best_offset = 0;
for angle_offset = 0:119
    shifted_2 = circleShift(part2_pol, angle_offset);
    % log scale seems resulting better angle estimation
%     corr = norm(log(part1_pol) .* log(shifted_2)); % in log scale 
    corr = computeCosineSimilarity(log(part1_pol), log(shifted_2)); % cosine similarity 
    corr = computeL1Dist(log(part1_pol), log(shifted_2)); % cosine similarity 
%     corr = norm((part1_pol) .* (shifted_2)); % in log scale
    if corr < max_corr
        max_corr = corr;
        best_offset = angle_offset;
    end
end
fprintf("best offset: %d, best correlative score: %f\n", best_offset, max_corr);
key1 = mean((part1_pol), 2);
fresco_mean1 = mean((part1_pol), 'all');
key1 = key1 ./ fresco_mean1;

key2 = mean((part2_pol), 2);
fresco_mean2 = mean((part2_pol), 'all');
key2 = key2 ./ fresco_mean2;

std1 = std(part1_pol, 0, 2) ./ fresco_mean1;
std2 = std(part2_pol, 0, 2) ./ fresco_mean2;

key_diff = [key1-key2; std1-std2];
% key_diff(1) = 0;
% key_diff(2) = 0;

key_dist = norm(key_diff);
fprintf("key distance: %f\n", key_dist);


best_shifted_2 = circleShift(part2_pol, best_offset);
subplot(2,3,3);
imagesc(best_shifted_2);
title('2 at best shift');
subplot(2,3,6);
diff_after_shift = abs(best_shifted_2 - part1_pol);
imagesc(diff_after_shift);
title('diff btw 1 and shifted 2');


h=impixelinfo;%impixelinfo能够在当前绘图窗口（figure）中显示绘制图像的像素信息
set(h,'position',[10 10 200 50]);%显示框

%% applply gaussian to the image before computing distance can improve performance on small error on the rotation angle
function [img_out] = applyGaussian(img_in)
    sigma = 1;  %设定标准差值，该值越大，滤波效果（模糊）愈明显
    window = double(uint8(3*sigma)*2 + 1);  %设定滤波模板尺寸大小
    %fspecial('gaussian', hsize, sigma)产生滤波掩模
    G = fspecial('gaussian', window, sigma);
    img_out = imfilter(img_in, G, 'conv','replicate','same');
end

%% circle shift to the right
function [img_out] = circleShift(img_in, offset)
    rows = size(img_in, 1);
    cols = size(img_in, 2);
    
    img_out = zeros(rows, cols);
    
    for col_idx = 1:cols
        corr_col_idx = col_idx + offset;
        if corr_col_idx > cols
            corr_col_idx = corr_col_idx - cols;
        elseif corr_col_idx <= 0
            corr_col_idx = corr_col_idx + cols;
        end
        
        img_out(:, col_idx) = img_in(:, corr_col_idx);
    end
end

%% compute cosine similarity of two FreSC
function [similarity] = computeCosineSimilarity(img1, img2)
    [rows, cols] = size(img1);
    sum = 0;
    for col_idx = 1:cols
        col1 = img1(:, col_idx);
        col2 = img2(:, col_idx);
        sum = sum + norm(col1 .* col2) ./ (norm(col1) .* norm(col2));
    end
    
    similarity = sum ./ cols;
end

%% compute L1 dist btw two FreSC
function [dist] = computeL1Dist(img1, img2)
    diff = img1 - img2;
    dist = sum(sum(abs(diff)));
end