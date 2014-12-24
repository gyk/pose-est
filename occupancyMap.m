function feature = occupancyMap(im, nRow, nColumn)
    % Calculates occupancy map feature of the given image.
    im = cropImage(im);
    [r, c] = size(im);
    gridR = calcGrid(r, nRow);
    gridC = calcGrid(c, nColumn);
    feature = zeros(nRow, nColumn);
    
    baseR = 1;
    for i = 1:nRow
        baseR_ = baseR + gridR(i);
        baseC = 1;
        for j = 1:nColumn
            area = gridR(i) * gridC(j);
            baseC_ = baseC + gridC(j);
            feature(i, j) = sum(sum(im(baseR:(baseR_ - 1), ...
                baseC:(baseC_ - 1)))) / area;
            baseC = baseC_;
        end
        baseR = baseR_;
    end
    feature = feature(:)';
end

% PRIVATE
function grids = calcGrid(len, nGrid)
    w = floor(len / nGrid);
    r = mod(len, nGrid);
    grids = repmat(w, 1, nGrid);
    grids(1:r) = grids(1:r) + 1;
end