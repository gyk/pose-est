function boundary = getBoundary(bw)
% Gets the boundary of a binary image.
% bw: binary image
	boundaries = bwboundaries(bw, 8, 'noholes');

	% Returns the longest boundary.
	sizeR = cellfun(@(b) size(b, 1), boundaries, 'UniformOutput', true);
	[~, id] = max(sizeR);
	boundary = boundaries{id};
end
