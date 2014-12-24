classdef ExemplarDatabase < handle
	properties
	images;
	poses;
	positions;
	nImages;
	rotator;
	end

	methods (Abstract)
	imagePathAt(obj, i);
	bwAt(obj, i);
	poseAt(obj, i);
	end
end
