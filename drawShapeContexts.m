function drawer = drawShapeContexts(imagePath, nRadius, nTheta, preprocessor)
	if ~exist('nRadius', 'var')
		nRadius = 5;
	end

	if ~exist('nTheta', 'var')
		nTheta = 12;
	end

	im = imread(imagePath);
	if exist('preprocessor', 'var')
		im = preprocessor(im);
	end

	if ~islogical(im)
		bw = im2bw(im);
	else
		bw = im;
	end

	bw = cropImage(bw);
	boundary = getBoundary(bw);
	bouSampled = downsampleBoundary(boundary, 200);
	% rotate 45 degrees clockwise
	bouSampled = [bouSampled(:, 2) -bouSampled(:, 1)];
	[scHist, a] = calcShapeContexts(bouSampled, nRadius, nTheta);
	

	%----------------8<----------------%
	function drawIt(idToShow)
		histArray = reshape(scHist(idToShow, :), nRadius, nTheta)';
		center = bouSampled(idToShow, :);
		% Plotting
		% draws log-polar diagram
		clf;
		subplot(1, 4, 1:3);
		set(gca, 'Box', 'on');
		axis equal;
		hold on;
		% draws circles
		radius_ = (1.5 .^ (1:nRadius) - 1) / a;
		theta_ = 0 : pi/50 : pi*2;
		xunit_ = cos(theta_);
		yunit_ = sin(theta_);
		for i = 1:nRadius
			line(center(1) + radius_(i) * xunit_, ...
				center(2) + radius_(i) * yunit_, ...
				'LineStyle', ':', 'Color', 'k', 'LineWidth', 1);
		end
		% draws spokes
		theta_ = (1:nTheta) * 2 * pi / nTheta;
		cos_ = [cos(theta_); zeros(1, nTheta)];
		sin_ = [sin(theta_); zeros(1, nTheta)];
		rmax = radius_(end);
		line(center(1) + rmax * cos_, center(2) + rmax * sin_, ...
			'LineStyle', ':', 'Color', 'k', 'LineWidth', 1);

		plot(bouSampled(:, 1), bouSampled(:, 2), 'r.', 'MarkerSize', 4);
		plot(center(1), center(2), 'yo');

		% draws 2d array
		subplot(1, 4, 4);
		imagesc(histArray);
		colormap(gray);
		xlabel('log r');
		ylabel('\theta');
		axis image;

		for i = 1:nTheta
			for j = 1:nRadius
				if ~histArray(i, j)
					continue;
				end
				text(j, i, sprintf('%d', histArray(i, j)), ...
					'Color', [153, 204, 0] / 255, ...
					'FontName', 'Consolas', ...
					'HorizontalAlignment', 'center', ...
					'FontAngle', 'italic');
			end
		end
		hold off;
	end
	%---------------->8----------------%
	
	drawer = @drawIt;
end
