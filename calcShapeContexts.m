function [scHist, a] = calcShapeContexts(boundary, nRadius, nTheta)
% Input:
%   boundary: n-by-2 point array;
%   nRadius, nTheta: numbers of log-polar bins;
% Output:
%   scHist: n-by-(nRadius*nTheta) array of features
%   a: the normalization coefficient

	nSampling = size(boundary, 1);
	X = boundary(:, 1);
	Y = boundary(:, 2);

	% This is not the best way of vectorization to compute distances, 
	% but DX and DY can be used later to get angles.
	DX = bsxfun(@minus, X, X');
	DY = bsxfun(@minus, Y, Y');

	dists = sqrt(DX.^2 + DY.^2);
	angles = atan2(DY, DX);

	% excludes diagonal elements
	meanDist = mean(dists(:)) / (1 - 1 / nSampling);

	% TODO: How to compute normalization coefficient?
	logBase = 1.5;
	a = (logBase ^ (.75*nRadius) - 1) / meanDist;  % normalize coefficient
	% +1 to deal with 0 distance
	dists = floor(log(a * dists + 1) / log(logBase));
	dists = max(dists, 1);
	dists = min(dists, nRadius);

	deltaAngle = 2 * pi / nTheta;
	angles = ceil((angles + pi) / deltaAngle);
	angles = max(angles, 1);

	nBin = nRadius * nTheta;
	scHist = zeros(nSampling, nBin);

	% to vectorize operations
	function idx1D = findIdx1D(idx)
		idx1D = sub2ind([nSampling nBin], (1:nSampling)', idx);
	end

	for i = 1:nSampling
		% each line of scHist: [t1r1, t1r2, ..., t2r1, t2r2, ...]
		idx = (angles(:,i) - 1) * nRadius + dists(:,i);
		idx1D = findIdx1D(idx);
		scHist(idx1D) = scHist(idx1D) + 1;
	end

	% excludes diagonal elements
	idx = (nTheta / 2 - 1) * nRadius + 1;
	scHist(:, idx) = scHist(:, idx) - 1;

	% normalizes histogram
	% scHist = scHist / (nSampling - 1);
end
