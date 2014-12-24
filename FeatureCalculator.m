classdef FeatureCalculator < handle
	properties
	exemplarDB;
	shapeContexts;
	featureSelector = [];  % a 1-by-nFeatures indicator vector;
	nDimSelected;
	featureRange;  % for normalization
	nPoints;
	end

	properties (Constant)
	DIM = [8 * 12;  % OM
		64 * 2; 64; 64;  % CS - CS_CCS, CS_CDS, CS_TAS
		64; 64; 64;  % FD - FD_CCS, FD_CDS, FD_TAS
		14;  % HU
		100;  % SC
		0];  % PF
	TYPE = {'OM';
		'CS_CCS'; 'CS_CDS'; 'CS_TAS';
		'FD_CCS'; 'FD_CDS'; 'FD_TAS';
		'HU';
		'SC';
		'PF'};
	N_DIM = sum(FeatureCalculator.DIM);
	end

	methods
	function obj = FeatureCalculator(exemplarDB, varargin)
		p = inputParser;
		addRequired(p, 'exemplarDB');
		addParamValue(p, 'shapeContextsCalculator', [], ...
			@(x) isequal(class(x), 'ShapeContextsCalculator'));
		addParamValue(p, 'featureRange', [], @isstruct);
		parse(p, exemplarDB, varargin{:});

		obj.exemplarDB = p.Results.exemplarDB;

		shapeContextsCalculator = p.Results.shapeContextsCalculator;
		if isempty(shapeContextsCalculator)
			% shape contexts preparation:
			shapeContextsCalculator = ShapeContextsCalculator('K', 800); % FIXME
			shapeContextsCalculator.computeShapemes(exemplarDB);
			% caching to avoid time-consuming computation
			save('shapeContextsCalculator.mat', 'shapeContextsCalculator');
		end
		obj.shapeContexts = shapeContextsCalculator.shapeContextsFFactory();
		obj.nPoints = shapeContextsCalculator.nPoints;

		obj.featureRange = p.Results.featureRange;
	end

	function features = calculate(obj, varargin)
	% useSelector: whether to use featureSelector
	% indicesToCalc: an vector of length n,
	%   only given indices in the collection will be calculated;
	% features: n-by-d array representing the feature vector,
	%   where d is the length of `[feature_1 feature_2 ... feature_n]`.
		db = obj.exemplarDB;
		nImages = db.nImages;

		p = inputParser;
		addParamValue(p, 'useSelector', false, @islogical);
		addParamValue(p, 'indicesToCalc', 1:nImages, @isnumeric);
		parse(p, varargin{:});

		useSelector = p.Results.useSelector;
		indicesToCalc = p.Results.indicesToCalc;

		if useSelector
			assert(~isempty(obj.featureSelector), ...
				'The `featureSelector` field has not been set');
			nDim = obj.nDimSelected;
		else
			nDim = FeatureCalculator.N_DIM;
		end

		nToCalc = length(indicesToCalc);
		features(nToCalc, nDim) = 0;  % init

		printInPlace = printUtility('Processing %d images: #', nToCalc);

		for i = 1:nToCalc
			if mod(i, 50) == 0
				printInPlace(i);
			end

			cachingPath = db.cachingPathAt(indicesToCalc(i));
			if exist(cachingPath, 'file')
				feat = readFromFile(cachingPath);
			else
				bw = db.bwAt(indicesToCalc(i));
				boundary = getBoundary(bw);
				if size(boundary, 1) < obj.nPoints * 1.75
					scale = obj.nPoints * 2 / size(boundary, 1);
					boundary = getBoundary(imresize(bw, scale));
				end

				OM = occupancyMap(bw, 12, 8);
				[CS_CCS, CS_CDS, CS_TAS] = contourSignature(boundary, 64);
				[FD_CCS, FD_CDS, FD_TAS] = ...
					fourierDescriptor(CS_CCS, CS_CDS, CS_TAS);
				[HU_A, HU_B] = huMoments(bw, boundary);
				SC = obj.shapeContexts(boundary);
				% PF = poissonFeatures(PF);
				PF = []; % FIXME

				feat = [OM, ...
					CS_CCS, CS_CDS, CS_TAS, ...
					FD_CCS, FD_CDS, FD_TAS, ...
					HU_A, HU_B, ...
					SC, ...
					PF];

				writeToFile(cachingPath, feat);
			end

			if useSelector
				% dimension reduction
				features(i, :) = feat(obj.featureSelector);
			else
				features(i, :) = feat;
			end
		end
	end

	function [] = setFeatureSelector(obj, featureSelector)
	% Does some extra work when setting the `featureSelector` field.
	% (Subclassing `hgsetget` is too cumbersome to implement.)

		selector = featureSelector;
		DIM = FeatureCalculator.DIM;
		% checks whether any feature type has never been used
		for j = 1:length(DIM)
			if all(selector(1:DIM(j)) == 0)
				fprintf('Feature type #%d has not been used!\n', j)
			end
			selector(1:DIM(j)) = [];
		end

		obj.featureSelector = featureSelector;
		obj.nDimSelected = sum(featureSelector);
	end

	function [] = setFeatureRange(obj, features)
		fMin = min(features);
		fMax = max(features);
		fRange = fMax - fMin;
		fMean = mean(features);
		fSD = std(features);

		obj.featureRange = struct('min', fMin, 'max', fMax, ...
			'range', fRange, 'mean', fMean, 'sd', fSD);
	end

	function [newFeatures] = normalizeLerp(obj, features)
		assert(~isempty(obj.featureRange));
		newFeatures = bsxfun(@rdivide, ...
			bsxfun(@minus, features, obj.featureRange.min), obj.featureRange.range);
	end

	function [newFeatures, normalizeF] = normalizeGaussian(obj, features)
		assert(~isempty(obj.featureRange));
		newFeatures = bsxfun(@rdivide, ...
			bsxfun(@minus, features, obj.featureRange.mean), obj.featureRange.sd);
	end
	end

	methods (Static)
	function mask = makeFeatureMask()
		persistent featureMask
		if ~isempty(featureMask)
			mask = featureMask;
			return;
		end

		selector = [];  % 1-by-d
		NONE = false(1, FeatureCalculator.N_DIM);

		function x = lambda(d)
			selector = [xor(selector, selector), true(1, d)];
			x = NONE;
			x(1:length(selector)) = selector;
		end
	
		selectors = arrayfun(@lambda, FeatureCalculator.DIM, ...
			'UniformOutput', false);
		featureMask = cell2struct(selectors, FeatureCalculator.TYPE, 1);

		featureMask.CS = ...
			featureMask.CS_CCS | featureMask.CS_CDS | featureMask.CS_TAS;
		featureMask.FD = ...
			featureMask.FD_CCS | featureMask.FD_CDS | featureMask.FD_TAS;
		featureMask.ALL = ~NONE;
		mask = featureMask;
	end
	end
end

function [] = writeToFile(filePath, feat)
	fid = fopen(filePath, 'w');
	assert(length(feat) == FeatureCalculator.N_DIM);
	fwrite(fid, feat, 'double');
	fclose(fid);
end

function feat = readFromFile(filePath)
	fid = fopen(filePath, 'r');
	feat = fread(fid, FeatureCalculator.N_DIM, 'double')';  % transposed
	fclose(fid);
end
