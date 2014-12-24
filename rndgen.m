function [] = rndgen(option)
	switch option
	case 'default'
		% MATLAB's start-up setting
		seed = 5489;
	case 'shuffle'
		seed = sum(100 * clock);
	otherwise
		seed = option;
	end

	stream = RandStream('mt19937ar', 'Seed', seed);
	RandStream.setDefaultStream(stream);
end
