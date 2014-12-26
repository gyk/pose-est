classdef RealExemplarDB < ExemplarDatabase
	properties (Constant)
	CAMS = {'C1', 'C2', 'C3'};
	CAMS_POS_MAP = struct('C1', 0, 'C2', 3, 'C3', 1);
	N_CAM_DIRS = 4;
	SILHOUETTE_SUFFIX = 'png';
	IM_PATTERN = ['(?<subject>S\d)\\(?<actionTrial>\w+_\d)', ...
		'\\(?<cam>C\d+)-(?<frame>\d+)\.'];
	MT_PATTERN = ['(?<subject>S\d)\\(?<actionTrial>[^\\]+)'];
	end

	methods
	function obj = RealExemplarDB()
		obj.images = retrieveFiles(CONFIG.SNAPSHOT_PATH, ...
			['*.', RealExemplarDB.SILHOUETTE_SUFFIX]);
		obj.nImages = numel(obj.images);
		obj.rotator = Rotator('Z', RealExemplarDB.N_CAM_DIRS);  % up: Z axis

		motionFiles = retrieveFiles(CONFIG.SNAPSHOT_PATH, 'coordinates.mat');
		poses = zeros(obj.nImages, 42);
		positions = zeros(obj.nImages, 3);
		for i = 1:length(motionFiles)
			mFile = motionFiles{i};
			mFilePath = fullfile(CONFIG.SNAPSHOT_PATH, mFile);
			load(mFilePath);  % for `coordinates` & `origins`
			mts = RealExemplarDB.parseMotionPath(mFile);

			for cam = RealExemplarDB.CAMS
				cam = cam{1};
				mts.cam = cam;
				chosen = obj.match(mts);
				poses(chosen, :) = obj.rotator.rotate(coordinates, ...
					RealExemplarDB.CAMS_POS_MAP.(cam));
				positions(chosen, :) = obj.rotator.rotate(origins, ...
					RealExemplarDB.CAMS_POS_MAP.(cam));
			end
		end
		obj.poses = poses;
		obj.positions = positions;
	end

	function [imPath] = imagePathAt(obj, i)
		imPath = obj.images{i};
	end

	function [bw] = bwAt(obj, i)
		imPath = obj.imagePathAt(i);
		bw = imread(fullfile(CONFIG.SNAPSHOT_PATH, imPath));
		if ~islogical(bw)
			bw = im2bw(bw);
		end
		bw = cropImage(bw);
	end

	function [pose] = poseAt(obj, i)
		pose = obj.poses(i, :);
	end

	function cachingPath = cachingPathAt(obj, i)
		imPath = obj.imagePathAt(i);
		cachingPath = fullfile(CONFIG.SNAPSHOT_PATH, ...
			strrep(imPath, SynthExemplarDB.SILHOUETTE_SUFFIX, 'cch'));
	end

	function [indicator] = match(obj, ims)
		pattern = RealExemplarDB.imagePathPattern(ims);
		indicator = ~cellfun(@isempty, regexp(obj.images, pattern));
	end
	end  % methods

	methods (Static)
	function [ims] = parseImagePath(imPath)
		ims = regexp(imPath, RealExemplarDB.IM_PATTERN, 'names');
	end

	function [mts] = parseMotionPath(mtPath)
		mts = regexp(mtPath, RealExemplarDB.MT_PATTERN, 'names');
	end

	function [pattern] = imagePathPattern(ims)
		function [ret] = setDefault(fld, def)
			if ~isfield(ims, fld) || isempty(ims.(fld))
				ret = def;
			else
				ret = ims.(fld);
			end
		end

		subject = setDefault('subject', '*');
		actionTrial = setDefault('actionTrial', '[\w+_\d]+');
		cam = setDefault('cam', 'C\d');
		frame = setDefault('frame', '\d+');

		suffix = ['\.', RealExemplarDB.SILHOUETTE_SUFFIX];
		pattern = [subject, '\\', actionTrial, '\\', ...
			cam, '-', frame, suffix];
	end
	end  % methods (Static)
end
