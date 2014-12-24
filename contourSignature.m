function [CS_CCS, CS_CDS, CS_TAS] = contourSignature(boundary, dim)
	X = boundary(:, 2);
	Y = boundary(:, 1);
	ctrX = mean(X);
	ctrY = mean(Y);
	avgDist = mean(sqrt((X - ctrX) .^ 2 + (Y - ctrY) .^ 2));

	b = downsampleBoundary(boundary, dim);
	DX = (b(:, 2) - ctrX)';
	DY = (b(:, 1) - ctrY)';

	% coordinate signature
	CS_CCS = [DX DY] / avgDist;
	% distance signature
	CS_CDS = sqrt(DX .^ 2 + DY .^ 2) / avgDist;

	% calculates CS_TAS (tangent angle signature)
	Diff = [b(2:end, :); b(1, :)] - [b(end, :); b(1:end-1, :)];
	Diff = Diff(:, 2) ./ sqrt(sum(Diff .^ 2, 2));
	Diff(isnan(Diff)) = 0;
	CS_TAS = Diff';
end
