%###################################################################################################%%
%
% main_script.m
% This script computes the geometric properties of stones, including:
% - Elongation index
% - Aspect ratio
% - Flatness index
% - Stone dimensions (length, width, height)
% - Smallest bounding box dimensions and volume
% - Stone volume
% - Shape factor (rectangularity)
%
% The script reads stone data from .ply or .stl files, processes them, and saves the computed 
% geometric properties in a .csv file.
%
% User must specify:
% - inputFolderPath: Directory containing the stone mesh files (.ply or .stl).
% - outputFolderPath: Directory where the results will be saved.
% - csvFileName: Name of the output .csv file.
%
% Authors: Mati Ullah Shah, Savvas Saloustros, and Katrin Beyer
% Contact: mati.shah@epfl.ch
% Last modification date: 13 March, 2025
%
%%###################################################################################################%%
close all
clear
clc

%% ############################## USER INPUT REQUIRED BELOW  #########################################%%

% Define the input folder containing stone or object mesh data (.ply or .stl files)
input_folder_path='.\...\input_folder';

% Define the name of the output .csv file
csv_file_name = '\output_file_name .csv';

% Define the output directory to save the .csv file
output_folder_path = '.\..\output_folder';

% Specify file extension for stone mesh files
file_extension = '*.ply';

% Define unit conversion factor
unit_convert = 1;  % Change if input data is not in meters (e.g., 0.001 for mm → m)

%% ################################### USER INPUT REQUIRED ABOVE #####################################%%

files = dir(fullfile(input_folder_path, file_extension));

% Initialize arrays to store geometric indices
num_files = numel(files);
aspect_ratio_index = zeros(1, num_files);
elongation_index = zeros(1, num_files);
flatness_index = zeros(1, num_files);
stone_volume = zeros(1, num_files);
bounding_box_volume = zeros(1, num_files);
rectangularity = zeros(1, num_files);
file_names = {};


%% Process each file
for file_index = 1:num_files

    % Construct the full path to the file
    file_path = fullfile(input_folder_path, files(file_index).name);
    
    % Read the mesh data
    mesh_data = readSurfaceMesh(file_path);
    
    % Calculate volume 
    volume = compute_stone_volume(mesh_data);

    % Save stone volume
    stone_volume(file_index) = volume*unit_convert^3;

    % Calculate oriented bounding box
    [dimension1,bounding_box_volume1, aspect_ratio1, elongation1, flatness1] = compute_oriented_bounding_box(mesh_data);
    
    % Calculate axis aligned bounding bounding box
    [dimension2,bounding_box_volume2, aspect_ratio2, elongation2, flatness2] = compute_axis_aligned_bounding_box(mesh_data);
    


    % Convert dimensions to meters
    dimension1 = dimension1 * unit_convert;
    dimension2 = dimension2 * unit_convert;

    % Convert bounding box volume
    bounding_box_volume1 = bounding_box_volume1 * unit_convert^3;
    bounding_box_volume2 = bounding_box_volume2 * unit_convert^3;

    % Select the smallest bounding box and base on that compute geometric
    % parameters

    if bounding_box_volume1 < bounding_box_volume2

            lengths(file_index) = dimension1(3);
            widths(file_index) = dimension1(2);
            heights(file_index) = dimension1(1);
            bounding_box_volume(file_index) = bounding_box_volume1;
            aspect_ratio_index(file_index) = aspect_ratio1;
            elongation_index(file_index) = elongation1;
            flatness_index(file_index) = flatness1;
            rectangularity(file_index) = volume /bounding_box_volume1;
    else 

       
            lengths(file_index) = dimension2(3);
            widths(file_index) = dimension2(2);
            heights(file_index) = dimension2(1);
            bounding_box_volume(file_index) = bounding_box_volume2;
            aspect_ratio_index(file_index) = aspect_ratio2;
            elongation_index(file_index) = elongation2;
            flatness_index(file_index) = flatness2;
            rectangularity(file_index) = volume /bounding_box_volume2;
            
    end

% Saving stone name
file_names{end+1} = files(file_index).name;

end
 
%% Save results to a CSV file
full_path = fullfile(output_folder_path, csv_file_name);

% Create a table from the arrays
data_table = table(file_names', lengths', widths', heights', elongation_index', flatness_index', aspect_ratio_index', stone_volume', bounding_box_volume', rectangularity', ...
                  'VariableNames', {'Stone ID','Stone length [m]','Stone width [m]','stone height [m]','Elongation [-]', 'Flatness_index [-]', 'Aspect ratio [-]', 'Stone volume [m^3]','Bounding box volume [m^3]','Shape factor [-]'});

% Write the table to a .csv file
writetable(data_table, full_path);

