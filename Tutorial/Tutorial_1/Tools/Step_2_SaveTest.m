% The purpose of this file is to save the Test data used for the transient 
% training with the MagNet Challenge 2 data. The data also comes from
% Step_0_CSVtoH5, the data save in testing consist of full length sequences.
% Different from Step_1_SaveTrain, the test file saves the full sequnces
% Contact: Shukai Wang, sw0123@princeton.edu, Princeton University
%% Clear previous varaibles and add the paths
clear % Clear variable in the workspace
clc % Clear command window
close all % Close all open figures
cd ..; % To go to the previous folder 

%% User defined directory
%%%%%%%%%%%%%%%%%%%%% PLEASE SELECT THE MATERIAL, SHAPE, DATASET TO ANALYZE%%%%%%%%%%%%%%%%%%%%%
Database = 'Transient_Database'; Material = '3C90'; Shape = 'TX-25-15-10'; Dataset = 1;

path_root = [pwd, '\', Database, '\', Material, '\', Shape, '\Dataset', num2str(Dataset)]; % Path of this file
name = [Material, ' - ', Shape, ' - Dataset ', num2str(Dataset)];
mat_name = [Material, '_', Shape, '_Data', num2str(Dataset)];
save_name = '_Testing_200_wholeseq_1.h5';


%% Set the style for the plots
addpath([pwd,'\',Database,'\Tools\Scripts']) % Add the folder where the scripts are located
[Xinit,Yinit,Xsize,Ysize,Nfont] = PlotStyle; close;

%% Initialize parameters
window = 80;
seqs_sel = 1;
rng(1);

%% Read the hdf5 files

array_length = [32016 20016 12816 8016 5008 3216 2016];

for i = 4:4
    file_name = fullfile(path_root, [Material, '_.h5']);
    B_dataset = sprintf('/B_%d', i);
    H_dataset = sprintf('/H_%d', i);
    T_dataset = sprintf('/T_%d', i);

    num_row = size(h5read(file_name, B_dataset),1);
    num_col = window;
    B_all_data = h5read(file_name, B_dataset, [1, 1], [num_row, array_length(i) + window]);
    H_all_data = h5read(file_name, H_dataset, [1, 1], [num_row, array_length(i) + window]);
    T_all_data = h5read(file_name, T_dataset, [1, 1], [num_row, 1]);


    % Calculate permeability u
    B_perm = [B_all_data(:,end), B_all_data];
    H_perm = [H_all_data(:,end), H_all_data];
  
    u =(B_perm(:,2:end) -B_perm(:,1:end-1)) ./ (H_perm(:,2:end) -H_perm(:,1:end-1));
    u_inc = u/(4*pi*10^(-7));

    % Get rid of No. of seqs where mu is inf or -inf 
    mask = isinf(u_inc) | isnan(u_inc); % Apply a mask to identify the rows
    rows = any(mask,2);
    rows_ind = find(~rows == 1); % select 1 for training data, 0 for unseen data


    % Take either the rest of the sequences or the selected sequences for test 
    rows_rand = sort(randperm(size(B_all_data, 1), seqs_sel)); 
    rows_rest = sort(setdiff(1:size(B_all_data, 1), rows_rand)); 
    B_down_data = B_all_data(rows_rand,:);
    H_down_data = H_all_data(rows_rand,:);
    T_down_data = T_all_data(rows_rand,1);

    num_row_test = length(B_down_data(:,1)); % no. of rows of data
    num_row_test_tot = num_row_test * array_length(i); % Total no. of rows pre allocated

    B_scal = zeros(num_row_test_tot ,1);
    H_scal = zeros(num_row_test_tot ,1);
    T_scal = zeros(num_row_test_tot ,1);
    B_seq_f = zeros(num_row_test_tot,num_col); 
    H_seq_f = zeros(num_row_test_tot,num_col);

    % Save all the data points in selected sequences
    for j = 1:num_row_test
        for k = 1:array_length(i)
            B_seq_f(j+num_row_test*(k-1),:) = B_down_data(j, k:k+num_col-1);
            H_seq_f(j+num_row_test*(k-1),:) = H_down_data(j, k:k+num_col-1);
            B_scal(j+num_row_test*(k-1)) = B_down_data(j, k+num_col);
            H_scal(j+num_row_test*(k-1)) = H_down_data(j, k+num_col);
            T_scal(j+num_row_test*(k-1)) = T_down_data(j);
        end
    end

%% Saving the full sequence data in hpy file
    h5create([path_root, '\' ,Material,save_name], ['/B_seq_f_', num2str(i)], size(B_seq_f'));
    h5create([path_root, '\' ,Material,save_name], ['/H_seq_f_', num2str(i)], size(H_seq_f'));
    h5create([path_root, '\' ,Material,save_name], ['/B_scal_', num2str(i)], size(B_scal));
    h5create([path_root, '\' ,Material,save_name], ['/H_scal_', num2str(i)], size(H_scal));
    h5create([path_root, '\' ,Material,save_name], ['/T_', num2str(i)], size(T_scal));

    h5write([path_root, '\' ,Material,save_name], ['/B_seq_f_', num2str(i)], B_seq_f');
    h5write([path_root, '\' ,Material,save_name], ['/H_seq_f_', num2str(i)], H_seq_f');
    h5write([path_root, '\' ,Material,save_name], ['/B_scal_', num2str(i)], B_scal);
    h5write([path_root, '\' ,Material,save_name], ['/H_scal_', num2str(i)], H_scal);
    h5write([path_root, '\' ,Material,save_name], ['/T_', num2str(i)], T_scal);
   
end
disp('The script has been executed successfully');

