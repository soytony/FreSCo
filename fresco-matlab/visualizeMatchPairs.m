function [] = visualizeMatchPairs(gt_poses_xy, match_idx_pairs)

    num_poses = size(gt_poses_xy, 1);
    map_poses = zeros(num_poses, 3);
    map_poses(:, 1:2) = gt_poses_xy;
    altitude_elevation = linspace(0, 100, num_poses)';
    map_poses(:,3) = map_poses(:,3) + altitude_elevation;

    num_matches = size(match_idx_pairs, 1);

    max_elevation = 0;
    min_elevation = 1e10;

    %% generate connections for each match pair
    connections = cell(num_matches, 5); % x1~x1, y1~y2, z1~z2, is_good, relative_elevation
    for idx = 1:num_matches
        query_idx = match_idx_pairs(idx, 1);
        match_idx = match_idx_pairs(idx, 2);
        is_good = match_idx_pairs(idx, 3);

        x = [map_poses(query_idx, 1); map_poses(match_idx, 1)];
        y = [map_poses(query_idx, 2); map_poses(match_idx, 2)];
        z = [map_poses(query_idx, 3); map_poses(match_idx, 3)];
        relative_elevation = abs(map_poses(query_idx, 3) - map_poses(match_idx, 3));

        if relative_elevation > max_elevation
            max_elevation = relative_elevation;
        end
        if relative_elevation < min_elevation
            min_elevation = relative_elevation;
        end

        connections{idx, 1} = x;
        connections{idx, 2} = y;
        connections{idx, 3} = z;
        connections{idx, 4} = is_good;
        connections{idx, 5} = relative_elevation;
    end

    %% plot map and all connections


    figure;
    fig_position = [10 10 800 720];
    fontsize = 18;
    fontname = 'Helvetica Neue';
    plot3(map_poses(:,1), map_poses(:,2), map_poses(:,3), 'LineWidth', 2.5, 'color',[0.25 0.25 0.25]);
%     view(-120, 70); % for kitti08
%   view(-100, 70);
    view(93, 70);
%     view(-30, 70);
    % xlabel('x', 'FontSize', fontsize, 'FontName', fontname);
    % xlabel('y', 'FontSize', fontsize, 'FontName', fontname);
    set(gcf, 'Position', fig_position);
    hold on

    for idx = 1:num_matches
        if (connections{idx, 4} == 1)
            this_elevation = connections{idx, 5};
            ratio =  1 - (this_elevation - min_elevation) / (max_elevation - min_elevation);
            alpha = (1-ratio) * 0.1 + ratio * 0.4;
            width = (1-ratio) * 1 + ratio * 4;
            patchline(connections{idx, 1},connections{idx, 2},connections{idx, 3},'linestyle','-','edgecolor','g','linewidth',width,'edgealpha',alpha);
    %         this_plot = plot3(connections{idx, 1}, connections{idx, 2}, connections{idx, 3}, 'g');
    %         this_plot.Color(4) = 0.5;
        else

            patchline(connections{idx, 1},connections{idx, 2},connections{idx, 3},'linestyle','-','edgecolor','r','linewidth',1,'edgealpha',0.5);
    %         plot3(connections{idx, 1}, connections{idx, 2}, connections{idx, 3}, 'r');
        end
        hold on;
    end

end