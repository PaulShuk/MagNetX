% The purpose of this file is to convert the seperate sets of csv files
% into a single h5py file that stores all the raw B-H and T data. The data
% is also pre-processed for the save_training file
% Contact: Shukai Wang, sw0123@princeton.edu, Princeton University
%% Clear previous varaibles and add the paths
clear % Clear variable in the workspace
clc % Clear command window
close all % Close all open figures
cd ..; % To go to the previous folder 

%% User defined directory
%%%%%%%%%%%%%%%%%%%%% PLEASE SELECT THE MATERIAL, SHAPE, DATASET TO ANALYZE%%%%%%%%%%%%%%%%%%%%%
Database = 'Transient_Database'; Material = '3C90'; Shape = 'TX-25-15-10'; Dataset = 1;

path_root = [pwd, '\', Database, '\', Material, '\', Shape, '\Dataset', num2str(Dataset)];%, '\MagChallenge2']; % Path of this file
name = [Material, ' - ', Material, ' - Dataset ', num2str(Dataset)];


%% Initialize Parameters
window = 80;
freq_level_start = 1;
freq_levels_stop = 7; 


%% Read the csv file and pre-process the data

for i = freq_level_start : freq_levels_stop
    B_struct.(['B_', num2str(i)]) = readmatrix([path_root, '\' ,Material,'_', num2str(i),'_B']);
    H_struct.(['H_', num2str(i)]) = readmatrix([path_root, '\' ,Material,'_', num2str(i),'_H']);
    T_struct.(['T_', num2str(i)]) = readmatrix([path_root, '\' ,Material,'_', num2str(i),'_T']);

% Appending the first window size data in the begining for training data process
B_window = B_struct.(['B_', num2str(i)])(:,end-window+1:end);
B_struct.(['B_', num2str(i)]) = [B_window, B_struct.(['B_', num2str(i)])]; % Append the last window in front of the whole sequence 

H_window = H_struct.(['H_', num2str(i)])(:,end-window+1:end);
H_struct.(['H_', num2str(i)]) = [H_window, H_struct.(['H_', num2str(i)])]; % Append the last window in front of the whole sequence 

end

%% Save the data into h5py files
for i = freq_level_start : freq_levels_stop
    data_B = [];
    data_H = [];
    data_T = [];

    data_B =  B_struct.(['B_', num2str(i)]);
    data_H =  H_struct.(['H_', num2str(i)]);
    data_T =  T_struct.(['T_', num2str(i)]);

    h5create([path_root, '\' ,Material,'_.h5'], ['/B_', num2str(i)], size(data_B));
    h5create([path_root, '\' ,Material,'_.h5'], ['/H_', num2str(i)], size(data_H));
    h5create([path_root, '\' ,Material,'_.h5'], ['/T_', num2str(i)], size(data_T));


    h5write([path_root, '\' ,Material,'_.h5'], ['/B_', num2str(i)], data_B);
    h5write([path_root, '\' ,Material,'_.h5'], ['/H_', num2str(i)], data_H);
    h5write([path_root, '\' ,Material,'_.h5'], ['/T_', num2str(i)], data_T);
end

disp('The script has been executed successfully');



