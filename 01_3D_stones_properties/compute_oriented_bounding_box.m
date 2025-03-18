function  [dimension1,bounding_box_volume1, aspect_ratio1, elongation1, flatness1] = compute_oriented_bounding_box(meshData)
% Function to compute the orieneted bounding box of the objects and its geometric properties such aspect ratio, elongation, and flatness index

    % Center the data
    centered_data = meshData.Vertices - mean(meshData.Vertices);
    
    % Perform PCA
    cov_matrix = cov(centered_data);
    [eigenvectors, eigenvalues] = eig(cov_matrix);
    
    % Align data with principal components
    aligned_data = centered_data * eigenvectors;
    
    % Calculate dimensions of the oriented bounding box
    min_coords = min(aligned_data);
    max_coords = max(aligned_data);
    dimension1 = max_coords - min_coords;
    bounding_box_volume1 = prod(dimension1);
    
    % Calculate aspect ratio, elongation, and flatness
    dims_sorted = sort(dimension1);

    aspect_ratio1= dims_sorted(1) / dims_sorted(3);
    elongation1 = dims_sorted(2) / dims_sorted(3);
    flatness1 = dims_sorted(1) / dims_sorted(2);
    dimension1=dims_sorted;
    
end

