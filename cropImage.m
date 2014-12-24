function cropped = cropImage(bw)
% Gets cropped image according to its largest bounding box.
% bw: binary image (0s indicate background)

    bb = regionprops(bw, 'BoundingBox');
    areas = cellfun(@(v) v(3) * v(4), {bb.BoundingBox}, 'UniformOutput', true);
	[~, idx] = max(areas);
	cropped = imcrop(bw, bb(idx).BoundingBox);
end
