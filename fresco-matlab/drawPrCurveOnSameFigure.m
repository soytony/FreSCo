% results_dir_fresco = './pr_result/KITTI08/';
% results_dir_sc = '../ScanContext/fast_evaluator/pr_result/KITTI 08/within 10m/';
% results_dir_lidariris = '../LidarIris/pr_result/KITTI 08/within 10m/';
% results_dir_lidarorb = '../LidarOrb/pr_result/KITTI 08 2m/within 10m/';

% results_dir_fresco = './pr_result/KAIST03/';
% results_dir_sc = '../ScanContext/fast_evaluator/pr_result/MulRan KAIST 03 2m/within 10m/';
% results_dir_lidariris = '../LidarIris/pr_result/MulRan KAIST 03 2m/within 10m/';
% results_dir_lidarorb = '../LidarOrb/pr_result/MulRan KAIST 03 2m/within 10m/';

results_dir_fresco = './pr_result/Oxford_01_11_13_24/';
results_dir_sc = '../ScanContext/fast_evaluator/pr_result/Oxford 01-11-13-24/within 10m/';
results_dir_lidariris = '../LidarIris/pr_result/Oxford 01-11-13-24/within 10m/';
results_dir_lidarorb = '../LidarOrb/pr_result/Oxford 01-11-13-24/within 10m/';

% results_dir_fresco = './pr_result/KAIST03/';
% results_dir_sc = '/home/tony/Documents/Kim-Scan-Context/scancontext/fast_evaluator/pr_result/MulRan KAIST 03/within 8m/';

% results_dir_fresco = './pr_result/Oxford_01_11_13_24/';
% results_dir_sc = '/home/tony/Documents/Kim-Scan-Context/scancontext/fast_evaluator/pr_result/Oxford 01-11-13-24/within 8m/';

%% load fresco precision and recall vector
precisions_fresco = load([results_dir_fresco, 'Precisions_1.mat']);
precisions_fresco = precisions_fresco.Precisions;
recalls_fresco = load([results_dir_fresco, 'Recalls_1.mat']);
recalls_fresco = recalls_fresco.Recalls;

%% load sc precison and recall vector
precisions_sc = load([results_dir_sc, 'Precisions_1.mat']);
precisions_sc = precisions_sc.Precisions;
recalls_sc = load([results_dir_sc, 'Recalls_1.mat']);
recalls_sc = recalls_sc.Recalls;


%% load lidar iris precison and recall vector
precisions_lidariris = load([results_dir_lidariris, 'Precisions_1.mat']);
precisions_lidariris = precisions_lidariris.Precisions;
recalls_lidariris = load([results_dir_lidariris, 'Recalls_1.mat']);
recalls_lidariris = recalls_lidariris.Recalls;


%% load lidar orb precison and recall vector
precisions_lidarorb = load([results_dir_lidarorb, 'Precisions_1.mat']);
precisions_lidarorb = precisions_lidarorb.Precisions;
recalls_lidarorb = load([results_dir_lidarorb, 'Recalls_1.mat']);
recalls_lidarorb = recalls_lidarorb.Recalls;


%% draw figure
num_methods = 2;
line_colors = [...
    0.0, 0.4, 1  ;...
    0.7, 0.1, 0.6;...
    0.0, 0.8, 0.0;...
    0.9, 0.7, 0.0
    ];
figure(FigIdx); 
set(gcf, 'Position', [10 10 800 600]);

line_width = 4;
% title_str = "KITTI 08";
% title_str = "MulRan KAIST 03";
title_str = "Oxford 01-11-13-24-51";

p_fresco = plot(recalls_fresco, precisions_fresco, 'LineWidth', line_width); % commonly x axis is recall
p_fresco.Color = line_colors(1, :);
p_fresco.MarkerEdgeColor = line_colors(1, :);

hold on;

p_sc = plot(recalls_sc, precisions_sc, 'LineWidth', line_width, 'LineStyle', '-'); % commonly x axis is recall
p_sc.Color = line_colors(2, :);
p_sc.MarkerEdgeColor = line_colors(2, :);

hold on;

p_iris = plot(recalls_lidariris, precisions_lidariris, 'LineWidth', line_width, 'LineStyle', '-'); % commonly x axis is recall
p_iris.Color = line_colors(3, :);
p_iris.MarkerEdgeColor = line_colors(3, :);


hold on;

p_orb = plot(recalls_lidarorb, precisions_lidarorb, 'LineWidth', line_width, 'LineStyle', '-'); % commonly x axis is recall
p_orb.Color = line_colors(4, :);
p_orb.MarkerEdgeColor = line_colors(4, :);

fontsize = 10; fontname = 'Helvetica Neue';
title(title_str, 'FontSize', fontsize, 'FontName', fontname);
xlabel('Recall', 'FontSize', fontsize, 'FontName', fontname); 
ylabel('Precision', 'FontSize', fontsize, 'FontName', fontname);
set(gca, 'FontSize', fontsize+5, 'FontName', fontname)
xticks([0 0.2 0.4 0.6 0.8 1.0])
xticklabels({'0','0.2','0.4','0.6','0.8','1'})
yticks([0 0.2 0.4 0.6 0.8 1.0])
yticklabels({'0','0.2','0.4','0.6','0.8','1'})



%% add legend to figure
lgd = legend('FreSCo(ours)','Scan Context', 'LiDAR Iris', 'LiDAR ORB', 'Location', 'best');

lgd.FontSize = fontsize + 3;
lgd.FontWeight = 'bold';
lgd.FontName = 'Helvetica Neue';