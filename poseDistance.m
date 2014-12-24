function d = poseDistance(pose1, pose2)
	[n, p] = size(pose1);
	[m, q] = size(pose2);
	assert(p == 42 && q == 42);  % number of points (14) * 3 = 42
	if n ~= m
		% must satisfy: n == 1 || m == 1
		D2 = bsxfun(@minus, pose1, pose2);
		D2 = D2 .^ 2;
		if m > n
			n = m;
		end
	else
		D2 = (pose1 - pose2) .^ 2;
	end
	d(n, 1) = 0;  % init
	
	if n == 1
		d = mean(sum(reshape(D2, 3, 14)) .^ .5);
		return
	end

	% The code block below is a vectorized (faster) version of:
	% for i = 1:n
	% 	d(i) = mean(sum(reshape(D2(i, :), 3, 14)) .^ .5);
	% end

	partial = sum(reshape(D2', 3, 14 * n)) .^ .5;
	d = mean(reshape(partial, 14, n))';	
end
