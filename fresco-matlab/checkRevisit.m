%% check if this query is a revisit of formered visited place
function [is_revisit, min_dist] = checkRevisit(query_pose, db_poses, dist_thres)

num_dbs = size(db_poses, 1);

dists = zeros(1, num_dbs);
for ii=1:num_dbs
    dist = norm(query_pose - db_poses(ii, :));
    dists(ii) = dist;    
end

if ( min(dists) <= dist_thres ) 
    is_revisit = 1;
else
    is_revisit = 0;
end

min_dist = min(dists);

end
