classdef SynthExemplarDB < ExemplarDatabase
	properties (Constant)
	CAM_IDS = 0:23;
	N_CAMS = 24;
	SILHOUETTE_SUFFIX = 'jpg';
	IM_PATTERN = ['(?<subject>S\d)\\Mocap_Data\\(?<actionTrial>\w+_\d)', ...
		'\\(?<cam>C\d+)-(?<frame>\d+)\.'];
	MT_PATTERN = ['(?<subject>S\d)\\Mocap_Data_Packed\\(?<actionTrial>[^\.\\]+)', ...
		'\.', CONFIG.SYNTH_TR_SUFFIX];
	end

	methods
	function obj = SynthExemplarDB()
		obj.images = retrieveFiles(CONFIG.SILHOUETTE_PATH, ...
			['*.', SynthExemplarDB.SILHOUETTE_SUFFIX]);
		obj.nImages = numel(obj.images);
		obj.rotator = Rotator('Z', SynthExemplarDB.N_CAMS);  % up: Z axis

		motionFiles = retrieveFiles(CONFIG.HE_PATH, ...
			['*.', CONFIG.SYNTH_TR_SUFFIX, '.mat']);
		poses = zeros(obj.nImages, 42);
		motionDict = struct();  % hashtable-like
		for i = 1:length(motionFiles)
			mFile = motionFiles{i};
			mFilePath = fullfile(CONFIG.HE_PATH, mFile);
			load(mFilePath);  % for `coordinates`, `frameNo` & `origins`
			packed = struct('coordinates', coordinates, 'frameNo', frameNo);
			mts = SynthExemplarDB.parseMotionPath(mFile);
			motionDict.(mts.subject).(mts.actionTrial) = packed;
		end

		for i = 1:obj.nImages
			imPath = obj.images{i};
			ims = SynthExemplarDB.parseImagePath(imPath);
			frameID = str2num(ims.frame);
			packed = motionDict.(ims.subject).(ims.actionTrial);
			storedId = packed.frameNo(frameID);
			camId = str2num(ims.cam(2:end));
			p = packed.coordinates(storedId, :);

			% WORKAROUND:
			% For some unknown reason, we have to rotate the pose with additional 
			% 90 degrees to make it consistent with the silhouette.
			p = obj.rotator.rotate(p, ...
				mod(camId + SynthExemplarDB.N_CAMS / 4, SynthExemplarDB.N_CAMS));
			poses(i, :) = p;
		end

		obj.poses = poses;
	end

	function [imPath] = imagePathAt(obj, i)
		imPath = obj.images{i};
	end

	function [bw] = bwAt(obj, i)
		imPath = obj.imagePathAt(i);
		bw = imread(fullfile(CONFIG.SILHOUETTE_PATH, imPath));
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
		cachingPath = fullfile(CONFIG.SILHOUETTE_PATH, ...
			strrep(imPath, SynthExemplarDB.SILHOUETTE_SUFFIX, 'cch'));
	end

	function [indicator] = match(obj, ims)
		pattern = SynthExemplarDB.imagePathPattern(ims);
		indicator = ~cellfun(@isempty, regexp(obj.images, pattern));
	end
	end  % methods

	methods (Static)
	function [ims] = parseImagePath(imPath)
		ims = regexp(imPath, SynthExemplarDB.IM_PATTERN, 'names');
	end

	function [mts] = parseMotionPath(mtPath)
		mts = regexp(mtPath, SynthExemplarDB.MT_PATTERN, 'names');
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
		cam = setDefault('cam', 'C\d+');
		frame = setDefault('frame', '\d+');

		suffix = ['\.', SynthExemplarDB.SILHOUETTE_SUFFIX];
		pattern = [subject, '\\Mocap_Data\\', actionTrial, '\\', ...
			cam, '-', frame, suffix];
	end
	end  % methods (Static)
end
