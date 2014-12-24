function [FD_CCS, FD_CDS, FD_TAS] = fourierDescriptor(CS_CCS, CS_CDS, CS_TAS)
% Calculates Fourier Descriptor from Contour Signature.
	dim = size(CS_CDS, 2);
	
	ccsComplex = reshape(CS_CCS, dim, 2);
	ccsComplex = ccsComplex(:, 1) + ccsComplex(:, 2) * 1i;
	FD_CCS = abs(fft(ccsComplex))';

	FD_CDS = abs(fft(CS_CDS));

	FD_TAS = abs(fft(CS_TAS));
end	