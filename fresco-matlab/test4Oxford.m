bvm_dir = '/home/tony/Datasets/oxford/2019-01-11-13-24-51-radar-oxford-10k/selected_keyframes_2.00m/output_single_bev/csv/';
gt_pose_filename = '/home/tony/Datasets/oxford/2019-01-11-13-24-51-radar-oxford-10k/selected_keyframes_2.00m/keyframe_pose.csv';
sequence_name = 'Oxford';
best_threshold = [75; 0.000750000000000000];
is_load_cache_prefered = true;

createDescsAndRetrieve(bvm_dir, gt_pose_filename, sequence_name, best_threshold, is_load_cache_prefered);
drawPresicionRecallCurve(sequence_name);
