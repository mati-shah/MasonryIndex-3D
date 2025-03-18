function G = bwgraph( bw, Options )
%BWGRAPH Create a graph of connected pixels in 2D images or 3D volumes.
%  
%  This function constructs a graph representation of a binary image (2D or 
%  3D), where nodes correspond to pixels and edges represent connectivity 
%  between adjacent non-zero pixels. It can be used for shortest path 
%  analysis between points in the binary structure.
%
%  MODIFICATION:
%  This version extends the original function by incorporating an 
%  "InterfaceWeight" parameter, which influences edge weights based on 
%  adjacency to the stone-mortar interface. This allows preference 
%  adjustments for travel paths near the interface:
%    - InterfaceWeight = 1: Higher preference for paths along the 
%      stone-mortar interface.
%    - InterfaceWeight < 1: Encourages paths that stay close to the 
%      stone-mortar interface but also consider shorter distances.
%
%  INPUTS:
%  - bw                    Binary image, given as a 2D or 3D, numeric or 
%                          logical array. Non-zero pixels are considered 
%                          as mortar (white), while zero pixels are stones (black).
%  - Name-Value Arguments:
%    + Connectivity        Pixel connectivity, defining whether pixels are 
%                          connected via face, edge, or corner. For a 2D 
%                          image, valid values are 4 (edge) and 8 (corner), 
%                          while in 3D, 6 (face), 18 (edge), and 26 (corner) 
%                          are valid. Default is the maximum connectivity.
%    + NodeWeights         Node weights, provided as a numeric array of the 
%                          same size as bw. If omitted, Euclidean distance 
%                          is used as the default edge weight.
%    + InterfaceWeight     A scaling factor (0 to 1) applied to edges near 
%                          the stone-mortar interface. A value of 1 gives 
%                          equal preference to paths along the interface, 
%                          while values below 1 prioritize paths near but 
%                          not strictly on the interface. Default is 1.
%
%  OUTPUT:
%  - G                     A graph object where nodes correspond to 
%                          non-zero pixels in bw, and edges connect 
%                          adjacent pixels based on the specified connectivity. 
%                          Edge weights reflect either Euclidean distance 
%                          or adjusted values influenced by InterfaceWeight.
%
%  EXAMPLES:
%  Please refer to the accompanying documentation or example files.
% 
%  ORIGINAL SOURCE:
%  This function is a modification of bwgraph by George Abrahams.
%  - https://github.com/WD40andTape/bwgraph
%
%  Modifications include the addition of InterfaceWeight for path preference 
%  control in stone-mortar structures.
% 
%  LICENSE:
%  Published under the MIT License (see LICENSE.txt).
%
%  See also GRAPH, SHORTESTPATH, DISTANCES, BWDIST, CONNDE


    arguments
        bw logical { mustBeNonempty, mustBe2Dor3D }
        Options.NodeWeights double ...
            { mustBeSameSize( bw, Options.NodeWeights ) }
        Options.Connectivity (1,1) uint8 { mustBeValidConnectivity( ...
            bw, Options.Connectivity ) } = 3^ndims( bw )-1
        Options.InterfaceWeight (1,1) double { mustBePositive } = 1
    end

    sz = size( bw );
    dim = length( sz ); % 2D or 3D.

    % Create base, the IJ(K) offset to each neighbour as defined by conn.
    connMatrix = images.internal.getBinaryConnectivityMatrix( ...
        Options.Connectivity );
    connMatrix(2,2,dim-1) = 0; % Set the central index to 0.
    [ baseI, baseJ, baseK ] = ndgrid( -1 : 1 );
    % Apply a mask so that edges aren't calculated twice, i.e., once in 
    % each direction.
    if dim == 2
        mask = logical( [0 0 1; 0 0 1; 0 1 1] );
        connMatrix = connMatrix & mask;
        base = [ baseI(connMatrix), baseJ(connMatrix) ];
    else
        mask = false( 3, 3, 3 );
        mask(:,:,1) = [ 0 0 1; 0 0 1; 0 1 1 ];
        mask(:,:,2) = [ 0 0 1; 0 0 1; 0 1 1 ];
        mask(:,:,3) = [ 0 0 1; 0 1 1; 0 1 1 ];
        connMatrix = connMatrix & mask;
        base = [ baseI(connMatrix), baseJ(connMatrix), baseK(connMatrix) ];
    end
    conn = sum( connMatrix, 'all' );

    % Find IJ(K) indices of all non-zero elements of bw.
    if dim == 2
        [ I1, I2 ] = ind2sub( sz, find( bw ) );
        source = [ I1, I2 ];
    else
        [ I1, I2, I3 ] = ind2sub( sz, find( bw ) );
        source = [ I1, I2, I3 ];
    end
    % Clear temporary variables to save memory.
    clearvars I1 I2 I3
    % Add base indices to source indices to find all neighbours.
    n = size( source, 1 );
    source = repelem( source, conn, 1 );
    neighbours = source + repmat( base, n, 1 );
    % Remove invalid neighbours, i.e., those beyond the matrix boundaries.
    valid = all( neighbours > 0 & neighbours <= sz, 2 );
    source = source(valid,:);
    neighbours = neighbours(valid,:);
    % Calculate the Euclidean distances from source to neighbour.
    if ~isfield( Options, 'NodeWeights' )
        weights = vecnorm( base, 2, 2 );
        weights = repmat( weights, n, 1 );
        weights = weights(valid,:);
    end
    
    % Convert IJ(K) indices to linear indices.
    if dim == 2
        source = sub2ind( sz, source(:,1), source(:,2) );
        neighbours = sub2ind( sz, neighbours(:,1), neighbours(:,2) );
    else
        source =  sub2ind( sz, source(:,1), source(:,2), source(:,3) );
        neighbours = sub2ind( sz, ...
            neighbours(:,1), neighbours(:,2), neighbours(:,3) );
    end
    % Remove non-zero neighbours.
    valid = bw(neighbours) ~= 0;
    source = source(valid,:);
    neighbours = neighbours(valid,:);
    
    % Calculate weights.
    if ~isfield( Options, 'NodeWeights' )
        weights = weights(valid,:);
    else
        % Set edge weights to the average of the connecting node weights.
        weights = mean( Options.NodeWeights( [source neighbours] ), 2 );
    end

    % Adjust weights for interface edges.
    interface_weight = Options.InterfaceWeight;
    for i = 1:length(source)
        if is_interface(bw, source(i), sz, dim) || is_interface(bw, neighbours(i), sz, dim)
            weights(i) = weights(i) * interface_weight;
        end
    end
    
    % Clear bw input to save memory, as the graph object construction
    % is memory intensive.
    clearvars bw
    
    % Construct the graph object.
    numNodes = prod( sz );
    G = graph( source, neighbours, double( weights ), numNodes );
    
end

%% Validation functions

function mustBe2Dor3D( a )
    if ndims( a ) > 3 % ndims is always greater than 2.
        id = "bwgraph:Validators:MatrixNot2Dor3D";
        msg = "Must be either 2D or 3D.";
        throwAsCaller( MException( id, msg ) )
    end
end

function mustBeValidConnectivity( a, conn )
    id = "bwgraph:Validators:ConnectivityInvalid";
    if ismatrix( a ) && ~ismember( conn, [4 8] )
        msg = "Valid connectivities for a 2D array are 4 and 8.";
        throwAsCaller( MException( id, msg ) )
    elseif ndims( a ) == 3 && ~ismember( conn, [6 18 26] )
        msg = "Valid connectivities for a 3D array are 6, 18, and 26.";
        throwAsCaller( MException( id, msg ) )
    end
end

function mustBeSameSize( a, b )
    if ~isequal( size( a ), size( b ) )
        id = "bwgraph:Validators:IncompatibleSizeInputs";
        msg = "Must be the same size as bw.";
        throwAsCaller( MException( id, msg ) )
    end
end

function is_intf = is_interface(bw, idx, sz, dim)
    [I1, I2, I3] = ind2sub(sz, idx);
    if dim == 2
        neighbours = [
            I1-1, I2;
            I1+1, I2;
            I1, I2-1;
            I1, I2+1;
        ];
    else
        neighbours = [
            I1-1, I2, I3;
            I1+1, I2, I3;
            I1, I2-1, I3;
            I1, I2+1, I3;
            I1, I2, I3-1;
            I1, I2, I3+1;
        ];
    end
    
    valid = all(neighbours > 0 & neighbours <= sz, 2);
    neighbours = neighbours(valid, :);
    
    if dim == 2
        lin_neighbours = sub2ind(sz, neighbours(:,1), neighbours(:,2));
    else
        lin_neighbours = sub2ind(sz, neighbours(:,1), neighbours(:,2), neighbours(:,3));
    end
    
    is_intf = any(bw(lin_neighbours) == 0);
end
