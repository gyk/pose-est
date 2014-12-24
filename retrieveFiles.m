function fileList = retrieveFiles(root, pattern, atDepth, nFiles)
% Input:
%   root: root directory of files;
%   pattern: e.g. '*.jpg';
%   atDepth: only retrieves files at specific depth, and then stops.
%       0 (default value) means trusting the program to pick the depth;
%   nFiles: max number of files returned;
%       Inf (default value) means retrieving all files;
% 
% Output:
%   N-by-1 cell array of strings.

	if ~exist('nFiles', 'var')
		nFiles = Inf;
	end
	
	if ~exist('atDepth', 'var')
		atDepth = 0;
	end

	nFilesSoFar = 0;

	if atDepth == 0  % probes the depth
		for i = 1:10  % max depth
			fileList = retrieveFilesR('', i);
			if length(fileList) > 0
				break;
			end
		end
	else
		fileList = retrieveFilesR('', atDepth);
	end

	fileList = fileList(1:min(nFiles, nFilesSoFar));

	function fileList = retrieveFilesR(realPath, depth)
		if nFilesSoFar >= nFiles
			fileList = {};
			return;
		end

		dirPath = fullfile(root, realPath);
		if depth == 1
			fileList = dir(fullfile(dirPath, pattern));
			fileList = {fileList.name}';
			n = size(fileList, 1);
			nFilesSoFar = nFilesSoFar + n;

			% explicit for loop
			for i = 1:n
				fileList{i} = fullfile(realPath, fileList{i});
			end
		else
			dirData = dir(dirPath);
			dirList = {dirData([dirData.isdir]).name};  % excludes files

			% The first two items on the directory list are always '.' and '..'
			% unless you run `dir` from a root directory (e.g. 'D:\').
			if strcmp(dirList{1}, '.') && strcmp(dirList{2}, '..')
				dirList = dirList(3:end);
			end

			fileList = cellfun(@(d)  ...
				retrieveFilesR(fullfile(realPath, d), depth - 1), dirList, ...
					'UniformOutput', false)';
			fileList = vertcat(fileList{:});
		end
	end
end

function p = fullfile(q, p)
% An implementation faster than the built-in one, only works on Windows.
	if q
		p = [q '\' p];
	end
end
