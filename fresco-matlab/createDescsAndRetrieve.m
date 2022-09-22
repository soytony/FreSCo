function [] = createDescsAndRetrieve(bvm_dir, gt_pose_filename, sequence_name, best_threshold, is_load_cache_prefered)

% bvm_dir = '/media/tony/mas_linux/Datasets/kitti/08/selected_keyframes_2m/output_bvm/';
% gt_pose_filename = '/media/tony/mas_linux/Datasets/kitti/08/selected_keyframes_2m/keyframe_pose.csv';

% bvm_dir = '/home/tony/Datasets/MulRan/KAIST03/selected_keyframes_2.00m/output_single_bev/csv/';
% gt_pose_filename = '/home/tony/Datasets/MulRan/KAIST03/selected_keyframes_2.00m/keyframe_pose.csv';

all_csv_files = dir([bvm_dir '*.csv']);
num_keyframes = length(all_csv_files);


LOOP_FRAME_INTERVAL = 100;
REVISIT_DIST_THRESH = 10.0;


% variables for drawing PR curve 
cosine_thresholds_fine = linspace(0, 0.002, 41);
cosine_thresholds_corse = linspace(0.002, 0.010, 9); 
cosine_thresholds = [cosine_thresholds_fine, cosine_thresholds_corse];

fresco_thresholds_fine = linspace(0, 200, 41);
fresco_thresholds_corse = linspace(200, 1000, 9); 
fresco_thresholds = [fresco_thresholds_fine, fresco_thresholds_corse];

thresholds = [fresco_thresholds; cosine_thresholds];

num_thresholds = size(cosine_thresholds, 2);

% best threshold is achieved at max F1 score
% best_threshold = [100;0.00100000000000000];
% best_threshold = [50;0.000500000000000000];

%% load ground truth poses
fprintf("Loading keyframe ground truth poses from file %s \n", gt_pose_filename);
gt_poses = csvread(gt_pose_filename); % (x, y, z, roll, pith, yaw)

%% load keys and frescos from local file or compute them now
cache_dir = ['./cached_descriptors/', sequence_name, '/'];
if((~7 == exist(cache_dir, 'dir')))
    mkdir(cache_dir);
end
keys_path = strcat(cache_dir, 'cell_keys.mat');
frescos_path = strcat(cache_dir, 'cell_frescos.mat');
is_cache_present = exist(keys_path, 'file') && exist(frescos_path, 'file');

if is_load_cache_prefered && is_cache_present
    fprintf("Loading keys and frescos from cached files. \n");
    cell_keys_tmp = struct2cell(load(keys_path));
    cell_keys = cell_keys_tmp{1};
    cell_fresco_tmp = struct2cell(load(frescos_path));
    cell_fresco = cell_fresco_tmp{1};

else
    % to save keys and fresco descriptor
    cell_keys = cell(num_keyframes, 1);
    cell_fresco = cell(num_keyframes, 1);

    fprintf("Generating keys and frescos. \n");
    h = waitbar(0,'Generating keys and frescos.');
    title_handle = get(findobj(h,'Type','axes'),'Title');
    set(title_handle,'FontName','Helvetica Neue')

    t_total_fveb = 0;
    for i = 1:num_keyframes
        wait_msg = ['Generating keys and frescos. ', num2str(i/num_keyframes*100, '%2.2f'),'%'];
        waitbar(i/num_keyframes, h, wait_msg)
        
        tmp_cloud_input = csvread([bvm_dir all_csv_files(i).name]);
        
        t_fbev_start = clock;

        % down sampling
        cloud_input = imresize(tmp_cloud_input, [101, 101], 'bilinear');

        input_fft = fft2(cloud_input);
        input_amp = abs(fftshift(input_fft));

        low_freq_part_mat = applyGaussian(input_amp(31:71, 31:71));
        this_part_pol = ImToPolar(low_freq_part_mat, 0, 1, 20, 120);
        
        this_part_pol_log = log(this_part_pol);
        
        this_key = mean((this_part_pol_log), 2); 
        
        fresco_mean = mean(this_part_pol_log, 'all');
        this_key = this_key ./ fresco_mean; % normalization

%         this_key(1) = this_key(1) .* 0.5;
%         this_key(2) = this_key(2) .* 0.5;
        this_std = std(this_part_pol_log, 0, 2) ./ fresco_mean;
        
%         this_std(1) = this_std(1) .* 0.5;
%         this_std(2) = this_std(2) .* 0.5;

        cell_keys{i} = [this_key; this_std];
        cell_fresco{i} = this_part_pol_log;
        
        t_fbev_end = clock;
        duration = etime(t_fbev_end, t_fbev_start) * 1e3;
        t_total_fveb = t_total_fveb + duration;
        % fprintf("[TIME] %dth Fresco Gen: %d ms. \n", i, duration);
    end
    delete(h);
    t_total_fveb = t_total_fveb / num_keyframes;
    fprintf("[TIME] Average Fresco Gen: %d ms. \n", t_total_fveb);
    
end
% update cache
save(keys_path, 'cell_keys');
save(frescos_path, 'cell_fresco');

mat_keys = zeros(size(cell_keys, 1), size(cell_keys{1}, 1)); % for kd tree input
for tmp_i = 1:size(cell_keys, 1)
    mat_keys(tmp_i, :) = cell_keys{tmp_i}';
end


%% compute similarities
cell_matches = cell(num_keyframes, 1);

fprintf("Computing similarities. \n");
h = waitbar(0,'Computing similarities.');
title_handle = get(findobj(h,'Type','axes'),'Title');
set(title_handle,'FontName','Helvetica Neue')

t_total_query_start = clock;
for query_idx = 1:num_keyframes
    wait_msg = ['Computing similarities. ', num2str(query_idx/num_keyframes*100, '%2.2f'),'%'];
    waitbar(query_idx/num_keyframes, h, wait_msg)
    
    end_db_idx = query_idx - LOOP_FRAME_INTERVAL;
    if end_db_idx <= 0
        continue;
    end
    
    query_key = mat_keys(query_idx, :);
    query_fresco = cell_fresco{query_idx};
    
    % using kd tree to do key retrieval
    tree = createns(mat_keys(1:end_db_idx, :), 'NSMethod', 'kdtree'); % Create object to use in k-nearest neighbor search
    key_candidates = knnsearch(tree, query_key, 'K', 20); 
    
    % traverse all candidates, compute fresco distance
    key_dists_sorted = zeros(size(key_candidates, 1), 6);
    for entry_idx = 1:size(key_candidates, 2)
        candidate_idx = key_candidates(1, entry_idx);
        candidate_fresco = cell_fresco{candidate_idx};
        [angle_offset, fresco_dist] = computeFrescoDist(query_fresco, candidate_fresco);
        cosine_row_dist = computeCosineDistRowWise(query_fresco, circleShift(candidate_fresco, angle_offset));
        cosine_col_dist = computeCosineDistColWise(query_fresco, circleShift(candidate_fresco, angle_offset));
        mean_frsco = mean(query_fresco, 'all');
%         key_dists_sorted(entry_idx, 3) = fresco_dist./mean_frsco;
        key_dists_sorted(entry_idx, 1) = candidate_idx;
        key_dists_sorted(entry_idx, 2) = 0; % not used
        key_dists_sorted(entry_idx, 3) = fresco_dist; %L1 DIST
        key_dists_sorted(entry_idx, 4) = cosine_row_dist;
        key_dists_sorted(entry_idx, 5) = cosine_col_dist;
        key_dists_sorted(entry_idx, 6) = angle_offset * 3.0;
    end
    
    cell_matches{query_idx} = key_dists_sorted;
end
delete(h);

t_total_query_end = clock;
avg_duration_query = etime(t_total_query_end, t_total_query_start) / num_keyframes * 1e3;
fprintf("[TIME] Average Query: %d ms \n", avg_duration_query);

%% get final match result

num_true_pos = zeros(1, num_thresholds); 
num_false_pos = zeros(1, num_thresholds); 
num_true_neg = zeros(1, num_thresholds); 
num_false_neg = zeros(1, num_thresholds);

fprintf("Getting evaluation result. \n");
h = waitbar(0,'Getting evaluation result. ');
title_handle = get(findobj(h,'Type','axes'),'Title');
set(title_handle,'FontName','Helvetica Neue')

match_result = zeros(num_keyframes, 6); % matched_idx, fresco_dist, cosine_angle, angle_offset, gt_distance
% used to visualize revisitness on map
match_idx_pairs = [];
% travser all matched result, and find the best one as the final matched keyframe
for query_idx = 1 : num_keyframes
    wait_msg = ['Getting evaluation result. ', num2str(query_idx/num_keyframes*100, '%2.2f'),'%'];
    waitbar(query_idx/num_keyframes, h, wait_msg)
    
    % check revisitness
    query_pose = gt_poses(query_idx, 2:3); % x,y coords of query frame
    history_poses = gt_poses(1:max(1, query_idx - LOOP_FRAME_INTERVAL), 2:3); % history x,y coords
    [is_revisit, min_dist] = checkRevisit(query_pose, history_poses, REVISIT_DIST_THRESH);
    
    
    candidates = cell_matches{query_idx};
    num_candidates = size(candidates, 1);
    
    min_fresco_dist = 1e10;
    min_cosine_row_dist = 1e10;
    min_cosine_col_dist = 1e10;
    best_idx = -1;
    matched_idx = -1;
    matched_angle_offset = 0;
    % select the candidate with smallest fresco distance
    for entry_idx = 1:num_candidates
        if candidates(entry_idx, 3) < min_fresco_dist % use L1 dist
            best_idx = candidates(entry_idx, 1);
            min_fresco_dist = candidates(entry_idx, 3);
            min_cosine_row_dist = candidates(entry_idx, 4);
            min_cosine_col_dist = candidates(entry_idx, 5);
            matched_angle_offset = candidates(entry_idx, 6);
        end
    end
    
    for thres_idx = 1:num_thresholds
        accepted = 0;
        this_thres_pair = thresholds(:, thres_idx);
        if (min_fresco_dist <= this_thres_pair(1,1) && min_cosine_row_dist <= this_thres_pair(2,1))
            accepted = 1;
        end
        
        if (accepted == 1)
            query_pose = gt_poses(query_idx, 2:3); % x,y coords of query frame
            match_pose = gt_poses(best_idx, 2:3);
            if (computePoseDist(query_pose, match_pose) <= REVISIT_DIST_THRESH) 
                % true pos
                num_true_pos(1, thres_idx) = num_true_pos(1, thres_idx) + 1;
            else
                % false pos
                num_false_pos(1, thres_idx) = num_false_pos(1, thres_idx) + 1;
                if (thres_idx == 11)
                    fprintf("false pos: query %d, match %d\n", query_idx, best_idx);
                end
            end
        else
            if (is_revisit == 1)
                % false neg
                num_false_neg(1, thres_idx) = num_false_neg(1, thres_idx) + 1;
            else
                % true neg
                num_true_neg(1, thres_idx) = num_true_neg(1, thres_idx) + 1;
            end
            
        end
    end
    
    % save result at best threshold
    if min_fresco_dist <= best_threshold(1,1) && min_cosine_row_dist <= best_threshold(2,1)
        matched_idx = best_idx;
        
        query_pose = gt_poses(query_idx, 2:3); % x,y coords of query frame
        match_pose = gt_poses(best_idx, 2:3);
        
        is_good = (computePoseDist(query_pose, match_pose) <= REVISIT_DIST_THRESH);
        match_idx_pairs = [match_idx_pairs; query_idx, matched_idx, is_good];
    else
%         fprintf("No matched keyframe found for query keyframe: %d \n", query_idx);
    end
    
    match_result(query_idx, 1) = matched_idx;
    match_result(query_idx, 2) = min_fresco_dist;
    match_result(query_idx, 3) = min_cosine_row_dist;
    match_result(query_idx, 4) = min_cosine_col_dist;
    match_result(query_idx, 5) = matched_angle_offset;
end
delete(h);

%% visualization
visualizeMatchPairs(gt_poses(:, 2:3), match_idx_pairs);

%% save the precision-recall result
pr_dir = ['./pr_result/', sequence_name, '/'];
if((~7 == exist(pr_dir, 'dir')))
    mkdir(pr_dir);
end
save(strcat(pr_dir, 'num_true_pos.mat'), 'num_true_pos');
save(strcat(pr_dir, 'num_true_neg.mat'), 'num_true_neg');
save(strcat(pr_dir, 'num_false_pos.mat'), 'num_false_pos');
save(strcat(pr_dir, 'num_false_neg.mat'), 'num_false_neg');

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

%% compute fresco distance
function [best_offset, fresco_dist] = computeFrescoDist(fresco1, fresco2)
    fresco_dist = 1e10;
    best_offset = 0;
    for angle_offset = 0:59 % since the fft img is symmetrical wrt the center point
        shifted_fresco2 = circleShift(fresco2, angle_offset);
        % log scale seems resulting better angle estimation
        corr = computeL1Dist(log(fresco1), log(shifted_fresco2)); % L1 dist 
        if corr < fresco_dist
            fresco_dist = corr;
            best_offset = angle_offset;
        end
    end
end

%% compute cosine distance row-wise
function [dist] = computeCosineDistRowWise(fresco1, fresco2)
    rows = size(fresco1, 1);
    
    sum = 0;
    for row_idx = 1 : rows
        a = fresco1(row_idx, :);
        b = fresco2(row_idx, :);
        cosine_value = dot(a, b) ./ (norm(a) .* norm(b));
        sum = sum + cosine_value;
    end
    
    dist = 1.0 - (sum ./ rows);
end

%% compute cosine distance col-wise
function [dist] = computeCosineDistColWise(fresco1, fresco2)
    cols = size(fresco1, 2);
    
    sum = 0;
    for col_idx = 1 : cols
        a = fresco1(:, col_idx);
        b = fresco2(:, col_idx);
        cosine_value = dot(a, b) ./ (norm(a) .* norm(b));
        sum = sum + cosine_value;
    end
    
    dist = 1.0 - (sum ./ cols);
end

%% compute pose dist
function [pose_dist] = computePoseDist(pose1, pose2)
    pose_dist = norm(pose1 - pose2);
end


end