function [] = drawPresicionRecallCurve(sequence_name)
results_dir = ['./pr_result/', sequence_name, '/'];
title_str = sequence_name;

%% Params 
fig_idx = 2;
figure(fig_idx); 
clf;

%% Main 
line_width = 4;
    
LineColors = colorcube(1);
LineColors = flipud(LineColors);

% load 
nCorrectRejectionsAll = load([results_dir 'num_true_neg.mat']);
nCorrectRejectionsAll = nCorrectRejectionsAll.num_true_neg;
nCorrectRejectionsForThisTopN = nCorrectRejectionsAll(1, :);

nFalseAlarmsAll = load([results_dir 'num_false_pos.mat']);
nFalseAlarmsAll = nFalseAlarmsAll.num_false_pos;
nFalseAlarmsForThisTopN = nFalseAlarmsAll(1, :);

nHitsAll = load([results_dir 'num_true_pos.mat']);
nHitsAll = nHitsAll.num_true_pos;
nHitsForThisTopN = nHitsAll(1, :);

nMissesAll = load([results_dir 'num_false_neg.mat']);
nMissesAll = nMissesAll.num_false_neg;
nMissesForThisTopN = nMissesAll(1, :);

% info 
nTopNs = size(nCorrectRejectionsAll, 1);
nThres = size(nCorrectRejectionsAll, 2);

% main 
Precisions = [];
Recalls = [];
Accuracies = [];
F1scores = [];
for ithThres = 1:nThres % as threshold increases, recall also increases
    nCorrectRejections = nCorrectRejectionsForThisTopN(ithThres);
    nFalseAlarms = nFalseAlarmsForThisTopN(ithThres);
    nHits = nHitsForThisTopN(ithThres);
    nMisses = nMissesForThisTopN(ithThres);

    nTotalTestPlaces = nCorrectRejections + nFalseAlarms + nHits + nMisses;

    Precision = nHits / (nHits + nFalseAlarms);
    Recall = nHits / (nHits + nMisses);
    Acc = (nHits + nCorrectRejections)/nTotalTestPlaces;
    F1score = 2 * Precision * Recall ./ (Precision + Recall);

    Precisions = [Precisions; Precision];
    Recalls = [Recalls; Recall];
    Accuracies = [Accuracies; Acc];            
    F1scores = [F1scores; F1score];
end

num_points = length(Precisions);
Precisions(1) = 1;
AUC = 0;
for ith = 1:num_points-1    
    small_area = 1/2 * (Precisions(ith) + Precisions(ith+1)) * (Recalls(ith+1)-Recalls(ith));
    AUC = AUC + small_area;
end


% tony added
% save precisons vector for this sequence
save([results_dir 'Precisions.mat'], 'Precisions');
save([results_dir 'Recalls.mat'], 'Recalls');
save([results_dir 'F1scores.mat'], 'F1scores');

% get index for maximum F1 Score
[max_f1score, f1score_idx] = max(F1scores);
fprintf("max_f1score: %f, idx: %d. \n", max_f1score, f1score_idx);

% draw 
figure(fig_idx); 
set(gcf, 'Position', [10 10 800 500]);

fontsize = 10; fontname = 'Helvetica Neue';
p = plot(Recalls, Precisions, 'LineWidth', line_width); % commonly x axis is recall
title(title_str, 'FontSize', fontsize, 'FontName', fontname);
xlabel('Recall', 'FontSize', fontsize, 'FontName', fontname); 
ylabel('Precision', 'FontSize', fontsize, 'FontName', fontname);
set(gca, 'FontSize', fontsize+5, 'FontName', fontname)
xticks([0 0.2 0.4 0.6 0.8 1.0])
xticklabels({'0','0.2','0.4','0.6','0.8','1'})
yticks([0 0.2 0.4 0.6 0.8 1.0])
yticklabels({'0','0.2','0.4','0.6','0.8','1'})

p(1).Color = LineColors(1, :);
p(1).MarkerEdgeColor = LineColors(1, :);
% axis equal;
xlim([0, 1]); ylim([0,1]);
grid on; grid minor;
hold on;


lgd = legend('FreSCo', 'Location', 'best');
lgd.FontSize = fontsize + 3;
lgd.FontWeight = 'bold';
lgd.FontName = 'Helvetica Neue';

grid minor;

name = 'prcurve';
print('-bestfit', name,'-dpdf')


end
