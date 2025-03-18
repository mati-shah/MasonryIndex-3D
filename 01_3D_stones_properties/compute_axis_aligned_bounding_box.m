function  [dimension2,bounding_box_volume2, aspect_ratio2, elongation2, flatness2]  = compute_axis_aligned_bounding_box(meshData)
% Function to compute the axis aligned bounding box of the object and its geometric properties such aspect ration, elongation, and flatness index
    
    minXYZ = min(meshData.Vertices);
    maxXYZ = max(meshData.Vertices);
    dimension2 = maxXYZ  -  minXYZ ;
    bounding_box_volume2 = prod(dimension2);

    % Calculate aspect ratio, elongation, and flatness
    dims_sorted = sort(dimension2);
    aspect_ratio2= dims_sorted(1) / dims_sorted(3);
    elongation2 = dims_sorted(2) / dims_sorted(3);
    flatness2 = dims_sorted(1) / dims_sorted(2);
    dimension2=dims_sorted;

end
