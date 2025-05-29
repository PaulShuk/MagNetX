% The purpose of this file is to save the Test data used for evaluating the transient 
% model built from the MagNet Challenge 2 dataset. The data also comes from
% Step_0_CSVtoH5, the data save in testing consist of full length sequences.
% Different from Step_2_SaveTest, the test file saves 1,000 steps for 105
% sequences for evaluation purpose.
% Contact: Hyukjae Kwon, hk1715@princeton.edu, Princeton University
%% Clear previous varaibles and add the paths
clear % Clear variable in the workspace
clc % Clear command window
close all % Close all open figures
cd ..; % To go to the previous folder 

%%
%%%%%%%%%%%%%%%%%%%%% PLEASE SELECT THE MATERIAL, SHAPE, DATASET TO ANALYZE
Database = 'Transient_Database'; Material = '3C90'; Shape = 'TX-25-15-10'; Dataset = 1;

path_root = [pwd, '\', Database, '\', Material, '\', Shape, '\Dataset', num2str(Dataset)];%, '\MagChallenge2']; % Path of this file
name = [Material, ' - ', Shape, ' - Dataset ', num2str(Dataset)];
mat_name = [Material, '_', Shape, '_Data', num2str(Dataset)];

save_name = '_Testing_true';
test_name = '_Testing_padded';
rng(1);
%% Set the style for the plots
addpath([pwd,'\','MagNet_Database','\_Tools\Scripts']) % Add the folder where the scripts are located
[Xinit,Yinit,Xsize,Ysize,Nfont] = PlotStyle; close;

%% Initialize Parameters
freq_levels = 7;
window = 80;

%% Read the hdf5 files

array_length = [32016 20016 12816 8015 5008 3216 2016];
Test_length = 1000;

B_test_all = [];
H_test_all = [];
T_test_all = [];
H_test_all_past = [];

%% 
for seq_ratio = 0.1:0.2:0.9
    past_end_idx = Test_length * seq_ratio;
    
    B_test_freq = [];
    H_test_freq = [];
    T_test_freq = [];

    %% Read B/H/T data from hdf5 files
    for i = 1:7 %1:freq_levels
        tic;
    
        file_name = fullfile(path_root, [Material, '_', num2str(i), '.h5']);
        B_dataset = sprintf('/B_%d', i);
        H_dataset = sprintf('/H_%d', i);
        T_dataset = sprintf('/T_%d', i);
    
        num_row = size(h5read(file_name, B_dataset),1); % no. of rows of original dataset
        B_all_data = h5read(file_name, B_dataset, [1, 1], [num_row, array_length(i) + window]);
        H_all_data = h5read(file_name, H_dataset, [1, 1], [num_row, array_length(i) + window]);
        T_all_data = h5read(file_name, T_dataset, [1, 1], [num_row, 1]);
    
        idx_25 = find(T_all_data == 25);
        idx_50 = find(T_all_data == 50);
        idx_70 = find(T_all_data == 70);
    
        rand_idx_25 = idx_25(randperm(length(idx_25), 1));
        rand_idx_50 = idx_50(randperm(length(idx_50), 1));
        rand_idx_70 = idx_70(randperm(length(idx_70), 1));
        
        rand_indices = [rand_idx_25, rand_idx_50, rand_idx_70];
    
        Start_point = randi(array_length(i) - Test_length);
        
        B_test = B_all_data(rand_indices, Start_point:Start_point + Test_length - 1);
        H_test = H_all_data(rand_indices, Start_point:Start_point + Test_length - 1);
        T_test = T_all_data(rand_indices);
    
        B_test_freq = [B_test_freq; B_test];
        H_test_freq = [H_test_freq; H_test];
        T_test_freq = [T_test_freq; T_test];
    
    end
    H_test_freq_past = H_test_freq;
    H_test_freq_past(:, past_end_idx+1:end) = NaN;

    B_test_all = [B_test_all; B_test_freq];
    H_test_all = [H_test_all; H_test_freq];
    T_test_all = [T_test_all; T_test_freq];
    H_test_all_past = [H_test_all_past; H_test_freq_past];

end

%% Reorganize the B and H seqeunces such that each memeory length of the same sequnce can be compiled together

file_save_name = fullfile(path_root, [Material,save_name,'.h5']);
h5create(file_save_name, '/B_seq', size(B_test_all'));
h5create(file_save_name, '/H_seq', size(H_test_all'));
h5create(file_save_name, '/T', size(T_test_all'));

h5write(file_save_name, '/B_seq', B_test_all');
h5write(file_save_name, '/H_seq', H_test_all');
h5write(file_save_name, '/T', T_test_all');


file_test_name = fullfile(path_root, [Material,test_name,'.h5']);
h5create(file_test_name, '/B_seq', size(B_test_all'));
h5create(file_test_name, '/H_seq', size(H_test_all_past'));
h5create(file_test_name, '/T', size(T_test_all'));

h5write(file_test_name, '/B_seq', B_test_all');
h5write(file_test_name, '/H_seq', H_test_all_past');
h5write(file_test_name, '/T', T_test_all');











