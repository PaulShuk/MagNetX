% The purpose of this file is to save the training data used for the transient 
% training with the MagNet Challenge 2 data. User needs to read the h5py file 
% and then select points per seqeunce to train according to size of the data seqeunce
% Contact: Shukai Wang, sw0123@princeton.edu, Princeton University
%% Clear previous varaibles and add the paths
clear % Clear variable in the workspace
clc % Clear command window
close all % Close all open figures
cd ..; % To go to the previous folder 

%% User defined directory
%%%%%%%%%%%%%%%%%%%%% PLEASE SELECT THE MATERIAL, SHAPE, DATASET TO ANALYZE%%%%%%%%%%%%%%%%%%%%%

Material = '3C90'; Shape = 'TX-25-15-10'; Dataset = 1;

path_root = [pwd, '\', Database, '\', Material, '\', Shape, '\Dataset', num2str(Dataset)]; % Path of the B-H csv files

save_name = '_Training_Tutorial.h5';

%% Set the style for the plots
addpath([pwd, '\' , Database , '\Tools\Scripts' ]) % Add the folder where the plotting scripts are located
[Xinit, Yinit, Xsize, Ysize, Nfont] = PlotStyle; close;
write_or_read = 1; % 1 to write 0 to read;

%% Initialize parameters
window = 80;
u_up = 4000; % Upper limit of the permeability.
u_low = 1; % Lower bound of u. Between 0 to 2000 is saturation
freq_level_start = 1;
freq_levels_stop = 7; 
rng(1); % Ensure reproducibility
%% Read the hdf5 files

% Freqeuncy: 50, 80, 125, 200, 320, 500, 800
array_length = [32016 20016 12816 8016 5008 3216 2016];
num_indices = [10000 6000 6000 1000 600 600 400];


%% Create training data
for i = freq_level_start : freq_levels_stop % Cover all frequencies

    file_name = fullfile(path_root, [Material, '_.h5']); % User define the path to the folder the h5 (from step_0) is located
    B_dataset = sprintf('/B_%d', i);
    H_dataset = sprintf('/H_%d', i);
    T_dataset = sprintf('/T_%d', i);

    num_row = size(h5read(file_name, B_dataset),1); % no. of rows of original dataset
    num_col = window;

    % Reading the processed h5 file which contains all the B, H and Temperature information
    B_all_data = h5read(file_name, B_dataset, [1, 1], [num_row, array_length(i) + window]); 
    H_all_data = h5read(file_name, H_dataset, [1, 1], [num_row, array_length(i) + window]);
    T_all_data = h5read(file_name, T_dataset, [1, 1], [num_row, 1]);

%% Obtain the seqeunces (M) to trian 
    % Calculate increamental permeability u
    B_perm = [B_all_data(:,end), B_all_data];
    H_perm = [H_all_data(:,end), H_all_data];
    u = (B_perm(:,2:end) -B_perm(:,1:end-1)) ./ (H_perm(:,2:end) -H_perm(:,1:end-1));
    u_inc = u/(4*pi*10^(-7));

    % Get rid of sequences where mu is inf or -inf 
    mask = isinf(u_inc) | isnan(u_inc); % Apply a mask to identify the rows
    rows = any(mask,2);
    rows_ind = find(~rows == 1);

    % Obtain the remaining sequneces to train
    B_down_data = B_all_data(rows_ind,:);
    H_down_data = H_all_data(rows_ind,:);
    T_down_data = T_all_data(rows_ind,1);
    u_inc = u_inc(rows_ind,:);

%% Select individual points to trian 

    num_row_down = size(B_down_data,1); % no. of rows of downsampled sequence dataset
    num_row_tot = num_row_down * num_indices(i); % Total no. of rows pre allocated

    % Preacclocate the matrices for each variable
    B_window = zeros(num_indices(i) ,num_col);
    H_window = zeros(num_indices(i) ,num_col);
    B_scalar = zeros(num_indices(i) ,1);
    H_scalar = zeros(num_indices(i) ,1);
    T = zeros(num_indices(i),1);
    B_scal = zeros(num_row_tot ,1);
    H_scal = zeros(num_row_tot ,1);
    T_scal = zeros(num_row_tot ,1);
    B_seq_f = zeros(num_row_tot,num_col); 
    H_seq_f = zeros(num_row_tot,num_col);

    indices = zeros(num_row_down ,num_indices(i));
    indices_normp = cell(num_row_down, 1); % Store indices of the saturation data points
    indices_satp = cell(num_row_down, 1);

    % Sorting indicies by looping through each row for saturated datapoints and the rest 
    for k = 1:num_row_down % We first iterate through the rows, and select all the indices

        indices_u{k} = find(u_inc(k, 1:length(u_inc(k,:))) > u_low & u_inc(k, 1:length(u_inc(k,:))) < u_up); % Find indices where values exceed saturation limit set by the user
        indices_u{k} = indices_u{k}(indices_u{k} > window);
        % Find remaining available indices excluding points already in range
        indices_all = window + 1 : length(u_inc(k,:)); % Excluding the first 'window' sized points
        indices_ava = setdiff(indices_all, indices_u{k}); % Remove taken indices

        % Determine how many more indices to sample given a tot no. of indices needed
        ind_need = num_indices(i) - length(indices_u{k});
        % If ind_need is negative, skip this iteration
        if ind_need < 0
            rows_random = sort(randperm(length(indices_u{k}), num_indices(i)));
            indices(k,:) = indices_u{k}(rows_random(:));
        else
            % Randomly sample from available indices 
            indices_rest = indices_ava(randperm(length(indices_ava), ind_need));
            % Combine saturated and additional indices
            indices(k, :) = sort([indices_u{k}, indices_rest]);
        end

        for j = 1: size(indices,2) % Given the indicies at each row k, select information related to the points of interests in indices()
            m = indices(k,j);
            B_window(j, :) = B_down_data(k, m - window : m - 1); 
            H_window(j, :) = H_down_data(k, m - window : m - 1);
            B_scalar(j, :) = B_down_data(k, m);  
            H_scalar(j, :) = H_down_data(k, m);
       
        end
        T = repmat(T_down_data(k), num_indices(i), 1);

        % Save the data with selected indicies for each row
        B_seq_f((k-1)*num_indices(i) + 1 : k* num_indices(i), 1:size(B_window,2)) = B_window;
        H_seq_f((k-1)*num_indices(i) + 1 : k* num_indices(i), 1:size(H_window,2)) = H_window;
        B_scal((k-1)*num_indices(i) + 1 : k* num_indices(i), 1) = B_scalar;
        H_scal((k-1)*num_indices(i) + 1 : k* num_indices(i), 1) = H_scalar;
        T_scal((k-1)*num_indices(i) + 1 : k* num_indices(i), 1) = T;
    end


%% Saving the data in hpy file
  
    h5create([path_root, '\' ,Material, save_name], ['/B_seq_f_', num2str(i)], size(B_seq_f'));
    h5create([path_root, '\' ,Material,save_name], ['/H_seq_f_', num2str(i)], size(H_seq_f'));
    h5create([path_root, '\' ,Material,save_name], ['/B_scal_', num2str(i)], size(B_scal'));
    h5create([path_root, '\' ,Material,save_name], ['/H_scal_', num2str(i)], size(H_scal'));
    h5create([path_root, '\' ,Material,save_name], ['/T_', num2str(i)], size(T_scal'));

    h5write([path_root, '\' ,Material,save_name], ['/B_seq_f_', num2str(i)], B_seq_f');
    h5write([path_root, '\' ,Material,save_name], ['/H_seq_f_', num2str(i)], H_seq_f');
    h5write([path_root, '\' ,Material,save_name], ['/B_scal_', num2str(i)], B_scal');
    h5write([path_root, '\' ,Material,save_name], ['/H_scal_', num2str(i)], H_scal');
    h5write([path_root, '\' ,Material,save_name], ['/T_', num2str(i)], T_scal');

    disp('The script has been executed successfully');

end

