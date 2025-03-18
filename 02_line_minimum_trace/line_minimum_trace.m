%#########################################################################################
%
% line_minimum_trace.m
%
% This script calculates the Line of Minimum Trace for:
% - Vertical joints staggering properties
% - Horizontal bed joint characteristics
% - Wall leaf connections of a masonry wall
%
% Requirements:
% - Binary format image (stones labeled as black pixels, mortar as white)
% - Wall dimensions (ensure consistent units)
%
% Authors: Mati Ullah Shah, Savvas Saloustros, and Katrin Beyer
% Contact: mati.shah@epfl.ch
% Last modified: 13 March 2025
%
% ---------------------------------------------------------------------------------------
% Note: 
% - The shortest path calculation uses the `bwgraph` function, originally published by 
%   George Abrahams under the MIT License. 
% - A slight modification has been made to include the alpha weighing factor, 
%   which accounts for the ratio of fracture energies of the stone-mortar interface to mortar.
% - For further details on the `bwgraph` function, visit:
%   https://github.com/WD40andTape/
%
%#########################################################################################

close all
clear
clc

%% ################## USER INPUT REQUIRED BELOW ########################################

% Specify the folder path containing the binary image
image_file_path = '.\...\image.png';

% Specify the folder path where to store the results
output_folder_path = '.\...\output folder';


%%

% Enter the 2D panel dimensions
real_length = 149; 

real_height = 140;


% Enter number of line of minimum trace (LMT)
number_LMT = 1;

% interface weight is the alpha value (choose between 0.1 and 1)
interface_weight = 1;

% For Line of minimum trace : 
% - Vertical joints staggering properties, set calculate_LMT = 0
% - Horizontal bed joint characteristics, set  calculate_LMT = 1
% - Wall leaf connections of a masonry wall, set calculate_LMT = 2
calculate_LMT = 1;


% Adjust image boundaries to avoid LMT detection near edges,
% Boundary_margin is number of pixels. default value set to 5
boundary_margin = 5; 

% For manually selecting points to draw line of minimum trace, set draw_LMT = 0 
% For automatic drawing of line of minimum trace, set draw_LMT = 1
draw_LMT = 0;


%%

% Only required for drawing automatic line of minimum trace 

% Specify the coordinates/pixels for starting points 
start_node_x = 80;

start_node_y = 80;

% Specify the distance(in pixels) between two points on panel between two
% line of minimum trace 
next_node_x = 100;

next_node_y = 100;



%% ################## USER INPUT REQUIRED ABOVE ##########################################

% Read the binary image
image  = imread(image_file_path);

if calculate_LMT == 1
    image(:, 1:boundary_margin) = 1;     
    image(:, end-boundary_margin:end) = 1;
    image(1:boundary_margin, :) = 0;     
    image(end-boundary_margin:end, :) = 0; 

else

    image(:, 1:boundary_margin) = 0;          
    image(:, end-boundary_margin:end) = 0;     
    image(1:boundary_margin, :) = 1;                         
    image(end-boundary_margin:end, :) = 1; 

end

% Wait for user to click on two points
figure;
imshow(image);
title('Click on the image to select two points');
hold on

G=bwgraph(image,'InterfaceWeight',interface_weight);
sz=size(image);

pixel_length =sz(2); %... (corresponding length in pixels)

pixel_height =sz(1); %... (corresponding height in pixels)


% Calculate the scale factors for length and height
length_scale_factor = real_length / pixel_length;

height_scale_factor = real_height / pixel_height;



%% 
for i=1:number_LMT

    if draw_LMT == 0
        
        [x, y] = ginput(2);

        start_point = round([y(1), x(1)]);

        end_point = round([y(2), x(2)]);

    else

      start_point = [1,1+start_node_x];

      end_point = [pixel_height ,1+start_node_y];

    end

        source = sub2ind( sz, start_point(1,1),start_point(1,2) );

        target = sub2ind( sz, end_point(1,1), end_point(1,2) );
        
        % Calculate shortest path between start and end points
        P = shortestpath( G, source, target );
        
        % Calculate the respective pixels for each node in the path.
        [ Pi, Pj ] = ind2sub( sz, P );

       
        % Plot the shortest path
        plot( Pj, Pi, 'Color','r', 'LineWidth', 4 );

        plot(start_point(2), start_point(1), 'go', 'MarkerSize', 10, 'LineWidth', 2);


        plot(end_point(2), end_point(1), 'go', 'MarkerSize', 10, 'LineWidth', 2);

        title('Selected Points and Shortest Path');

        % Update the starting points for the next line
        start_node_x = start_node_x + next_node_x;

        start_node_y = start_node_y + next_node_y;

        % Scale the path coordinates to real-world units
        Pi=Pi*height_scale_factor;

        Pj=Pj*length_scale_factor;

        % Combine x and y coordinates into a matrix
        zigzagCoordinates = [Pj', Pi'];
        
        % Calculate the Euclidean distances between consecutive points
        distances = sqrt(sum(diff(zigzagCoordinates, 1, 1).^2, 2));
       
        % Sum up the distances to get the total length
        total_length(i) = sum(distances);   

end 


%% LMT calculation and results saving

% Compute LMT based on the selected option
if calculate_LMT == 0
    LMT_type = 'vertical';
    LMT_result = total_length / real_height;

elseif calculate_LMT == 1
    LMT_type = 'horizontal';
    LMT_result = total_length / real_length;

else
    LMT_type = 'wall_leaf_connection';
    LMT_result = total_length / real_height;

end

% Ensure LMT values are not less than 1
LMT_result(LMT_result < 1) = 1;

% Generate file names 
[~, baseName, ~] = fileparts(image_file_path);
outputImageName = sprintf('%s_%s_LMT.png', baseName, LMT_type);
outputDatafileName = sprintf('%s_%s_LMT.mat', baseName, LMT_type);

% Save results
imagePath = fullfile(output_folder_path, outputImageName);
saveas(gcf, imagePath);

dataPath = fullfile(output_folder_path, outputDatafileName);
save(dataPath, 'LMT_result');
