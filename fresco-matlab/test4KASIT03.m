bvm_dir = '/home/tony/Datasets/MulRan/KAIST03/selected_keyframes_2.00m/output_single_bev/csv/';
gt_pose_filename = '/home/tony/Datasets/MulRan/KAIST03/selected_keyframes_2.00m/keyframe_pose.csv';
sequence_name = 'KAIST03';
best_threshold = [50;0.000500000000000000];
is_load_cache_prefered = true;

createDescsAndRetrieve(bvm_dir, gt_pose_filename, sequence_name, best_threshold, is_load_cache_prefered);
drawPresicionRecallCurve(sequence_name);
