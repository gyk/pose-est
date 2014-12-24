classdef Rotator
	properties (Access = private)
	numOfCams;
	rotationMatrices;
	axisRotated;
	end

	methods
	function obj = Rotator(up, nCams)
	% up: 'X', 'Y' or 'Z';
		obj.numOfCams = nCams;
		deltaAngle = 2 * pi / nCams;
		obj.rotationMatrices = cell(nCams - 1, 1);

		% When we generate silhouettes in MotionBuilder, the camera is rotated
		% counterclockwise, so here it should be done clockwise.
		for i = 1:nCams - 1
			theta = -deltaAngle * i;  % note the `-`
			mat = [cos(theta), -sin(theta);
				sin(theta), cos(theta)];
			
			obj.rotationMatrices{i} = mat;
		end

		up = upper(up) - 'W';
		temp = [2 3 1 2]';
		obj.axisRotated = temp([up, up + 1]);
	end

	function coords = rotate(obj, coords, camId)
		assert(mod(size(coords, 2), 3) == 0);
			
		if camId == 0
			return;
		end

		nJoints = size(coords, 2) / 3;

		% (R . p')' = p . R'
		rotMatrixT = obj.rotationMatrices{camId}';
		for i = 1:nJoints
			columns = obj.axisRotated + (i - 1) * 3;
			coords(:, columns) = ...
				coords(:, columns) * rotMatrixT;
		end

	end

	function coord = rotate1(obj, coord, camId)
		if camId == 0
			return
		end

		coord = reshape(coord, 3, 14);
		coord(obj.axisRotated, :) = obj.rotationMatrices{camId} * ...
			coord(obj.axisRotated, :);
		coord = reshape(coord, 1, 42);
	end
	end
end