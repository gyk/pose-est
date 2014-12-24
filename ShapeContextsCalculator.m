classdef ShapeContextsCalculator < handle
	properties
	nPoints;
	nRadius;
	nTheta;
	dCodebook;
	K;
	shapemes;
	end

	methods
	function obj = ShapeContextsCalculator(varargin)
	% K: the number of sampled points to compute shapemes
		p = inputParser;
		addParamValue(p, 'nPoints', 200, @isnumeric);
		addParamValue(p, 'nRadius', 5, @isnumeric);
		addParamValue(p, 'nTheta', 12, @isnumeric);
		addParamValue(p, 'dCodebook', 100, @isnumeric);
		addParamValue(p, 'K', 800, @isnumeric);
		parse(p, varargin{:});

		obj.nPoints = p.Results.nPoints;
		obj.nRadius = p.Results.nRadius;
		obj.nTheta = p.Results.nTheta;
		obj.dCodebook = p.Results.dCodebook;
		obj.K = p.Results.K;

	end

	function shapemes = computeShapemes(obj, exemplarDB)
	% Output:
	%   shapemes: dCodebook-by-(nRadius*nTheta) array

		db = exemplarDB;
		nImages = db.nImages;
		nPoints = obj.nPoints;
		nRadius = obj.nRadius;
		nTheta = obj.nTheta;
		K = min(nImages, obj.K);

		idx = sort(randsample(nImages, K))';
		SCSampled(K * nPoints, nRadius * nTheta) = 0;  % init

		indices = (1:nPoints)';
		for i = idx
			bw = db.bwAt(i);
			boundary = getBoundary(bw);

			if size(boundary, 1) < nPoints * 1.75
				scale = nPoints * 2 / size(boundary, 1);
				boundary = getBoundary(imresize(bw, scale));
			end

			boundary = downsampleBoundary(boundary, nPoints);
			SCSampled(indices, :) = calcShapeContexts(boundary, ...
				nRadius, nTheta);
			indices = indices + nPoints;
		end

		[~, shapemes] = kmeanspp(SCSampled, obj.dCodebook);
		obj.shapemes = shapemes;
	end

	function shapeContexts = shapeContextsFFactory(obj)
		% variables accessed in the closure
		nPoints = obj.nPoints;
		nRadius = obj.nRadius;
		nTheta = obj.nTheta;
		dCodebook = obj.dCodebook;
		knnObj = ExhaustiveSearcher(obj.shapemes);  % for k-NN classification

		function SC = shapeContextsF(boundary)
			boundary = downsampleBoundary(boundary, nPoints);
			% SC: nPoints-by-(nRadius*nTheta) array
			SC = calcShapeContexts(boundary, ...
				nRadius, nTheta);

			% shapeme quantization
			nearestInd = knnsearch(knnObj, SC);  % nPoints-by-1
			SC = histc(nearestInd', 1:dCodebook);  % 1-by-dCodebook
			SC = SC / nPoints;  % normalizes histogram
		end
		shapeContexts = @shapeContextsF;
	end

	end
end
