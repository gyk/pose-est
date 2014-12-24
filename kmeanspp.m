function [L,C] = kmeanspp(X,k)
%KMEANS Cluster multivariate data using the k-means++ algorithm.
%   [L,C] = kmeans(X,k) produces a 1-by-size(X,2) vector L with one class
%   label per column in X and a size(X,1)-by-k matrix C containing the
%   centers corresponding to each class.

%   Version: 07/08/11
%   Authors: Laurent Sorber (Laurent.Sorber@cs.kuleuven.be)
%
%   References:
%   [1] J. B. MacQueen, "Some Methods for Classification and Analysis of 
%       MultiVariate Observations", in Proc. of the fifth Berkeley
%       Symposium on Mathematical Statistics and Probability, L. M. L. Cam
%       and J. Neyman, eds., vol. 1, UC Press, 1967, pp. 281-297.
%   [2] D. Arthur and S. Vassilvitskii, "k-means++: The Advantages of
%       Careful Seeding", Technical Report 2006-13, Stanford InfoLab, 2006.

L = [];
L1 = 0;
unfinished = 1;
while unfinished
    n = size(X,1);
    C = X(1+round(rand*(n-1)), :);
    L = ones(n, 1);
    for i = 2:k
        D = X-C(L, :);
        D = cumsum(sum(D.^2, 2));
        if D(end) == 0, C(i:k,:) = X(ones(1,k-i+1),:); return; end
        C(i,:) = X(find(rand < D/D(end),1),:);
        [~,L] = max(bsxfun(@minus, X*C', sum(C.^2, 2)'*0.5),[],2);
    end
    
    while any(L ~= L1)
        [u,~,L] = unique(L);   % remove empty clusters
        if length(u) ~= k
            unfinished = 1; break
        else
            unfinished = 0;
        end
        E = sparse(L,1:n, 1, k,n, n);  % transform label into indicator matrix
        C = (spdiags(1./sum(E,2),0,k,k) * E) * X;    % compute m of each cluster
        L1 = L;
        % assign samples to the nearest centers
        [~,L] = max(bsxfun(@minus, X*C', sum(C.^2, 2)'*0.5), [], 2);
    end
end
[~,~,L] = unique(L);