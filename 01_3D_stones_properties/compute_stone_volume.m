function volume = compute_stone_volume(meh_data)
% Function to calculate the volume of the mesh

    volume = 0;

    for i = 1:size(meh_data.Faces, 1)

        tri = meh_data.Faces(i, :);
        x = meh_data.Vertices(tri(1), :);
        y = meh_data.Vertices(tri(2), :);
        z = meh_data.Vertices(tri(3), :);
        partialVol = det([x; y; z]) / 6;
        volume = volume + partialVol;
        
    end
end