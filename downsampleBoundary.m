function boundary = downsampleBoundary(boundary, nSampling)
	len = size(boundary, 1);
	if nSampling > len
		error('downsampleBoundary:tooManySamplingPoints', ...
			'Number of sampling points is larger than length of boundary');
	end
	indexes = round(linspace(1, len, nSampling+1));
	boundary = boundary(indexes(1:end-1), :);
