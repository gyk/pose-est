function [huA, huB] = huMoments(im, bd)
% Calculates Hu's image moments (Hu1 ~ Hu8).
% See http://en.wikipedia.org/wiki/Image_moment for details.
% huA: area-based; huB: boundary-based.

	[sizey, sizex] = size(im);

	% According to the benchmark on Matlab 2010b, JIT optimized 
	% for-loop implementation is faster than that using several 
	% vectorized calculations (image size = 385 * 450).

	for isHuA = [1, 0]
		if isHuA
			M00 = 0;
			M10 = 0;
			M20 = 0;
			M30 = 0;
			M01 = 0;
			M11 = 0;
			M21 = 0;
			M02 = 0;
			M12 = 0;
			M03 = 0;

			% raw moments:
			for x = 1:sizex
				x2 = x*x;
				for y = 1:sizey
					if im(y, x) > 0
						y2 = y*y;
						
						M00 = M00 + 1;
						M10 = M10 + x;
						M20 = M20 + x2;
						M30 = M30 + x2*x;
						
						M01 = M01 + y;
						M11 = M11 + x*y;
						M21 = M21 + x2*y;
						
						M02 = M02 + y2;
						M12 = M12 + x*y2;
						
						M03 = M03 + y2*y;
					end
				end
			end
		else  % huB
			% Boundary = [
			%   (row1, col1),
			%   (row2, col2),
			%   ... _clockwise_
			%   (rown, coln),
			%   (row1, col1)]
			bd(end, :) = [];

			% raw moments:
			X = bd(:, 2);
			Y = bd(:, 1);
			X2 = X .^ 2;
			Y2 = Y .^ 2;
			M00 = size(bd, 1);
			M10 = sum(X);
			M20 = sum(X2);
			M30 = sum(X .* X2);
			M01 = sum(Y);
			M11 = sum(X .* Y);
			M21 = sum(X2 .* Y);
			M02 = sum(Y2);
			M12 = sum(X .* Y2);
			M03 = sum(Y .* Y2);
		end

		% central moments (for both):
		xbar = M10 / M00; xbar2 = xbar*xbar;
		ybar = M01 / M00; ybar2 = ybar*ybar;
		mu00 = M00;
		mu11 = M11 - xbar*M01;
		mu20 = M20 - xbar*M10;
		mu02 = M02 - ybar*M01;
		mu21 = M21 - 2*xbar*M11 - ybar*M20 ...
			+ 2*xbar2*M01;
		mu12 = M12 - 2*ybar*M11 - xbar*M02 ...
			+ 2*ybar2*M10;
		mu30 = M30 - 3*xbar*M20 + 2*xbar2*M10;
		mu03 = M03 - 3*ybar*M02 + 2*ybar2*M01;
		
		% scale invariant moments:
		if isHuA
			mu00_2 = mu00 * mu00;
			eta20 = mu20 / mu00_2;
			eta11 = mu11 / mu00_2;
			eta02 = mu02 / mu00_2;

			mu00_3over2 = mu00 ^ (5/2);
			eta30 = mu30 / mu00_3over2;
			eta21 = mu21 / mu00_3over2;
			eta12 = mu12 / mu00_3over2;
			eta03 = mu03 / mu00_3over2;
		else
			mu00_3 = mu00_2 * mu00;
			eta20 = mu20 / mu00_3;
			eta11 = mu11 / mu00_3;
			eta02 = mu02 / mu00_3;

			mu00_4 = mu00_3 * mu00;
			eta30 = mu30 / mu00_4;
			eta21 = mu21 / mu00_4;
			eta12 = mu12 / mu00_4;
			eta03 = mu03 / mu00_4;
		end

		% Hu moments (for both):
		hu2 = eta20 - eta02;
		hu31 = eta30 - 3*eta12;
		hu32 = 3*eta21 - eta03;
		hu41 = eta30 + eta12;
		hu42 = eta21 + eta03;
		
		hu = zeros(1, 7);
		hu(1) = eta20 + eta02;
		hu(2) = hu2^2 + (2 * eta11)^2;
		hu(3) = hu31 ^ 2 + hu32 ^ 2;  
		hu(4) = hu41 ^ 2 + hu42 ^ 2;
		hu(5) = hu31 * hu41 * (hu41^2 - 3 * hu42^2) + ... 
			hu32 * hu42 * (3 * hu41^2 - hu42^2);
		hu(6) = hu2 * (hu41^2 - hu42^2) + 4 * eta11 * hu41 * hu42;
		hu(7) = hu32 * hu41 * (hu41^2 - 3 * hu42^2) - ...
			hu31 * hu42 * (3 * hu41^2 - hu42^2);
		% hu(8) = eta11 * (hu41^2 - hu42^2) - hu2 * hu41* hu42;

		if isHuA
			huA = hu;
		else
			huB = hu;
		end
	end
end
	