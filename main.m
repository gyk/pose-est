
%% Prepares dataset
db = RealExemplarDB();
shapeContextsCalculator = [];
if exist('shapeContextsCalculator.mat', 'file')
	load('shapeContextsCalculator.mat');
end
featCalculator = FeatureCalculator(db, ...
	'shapeContextsCalculator', shapeContextsCalculator);
n = db.nImages;

%% Split the database into training and testing sets
% sets the seed of random number generator, for debugging purpose:
rndgen('default');
indicesTR = false(n, 1);
indicesTR(randsample(n, floor(n / 2))) = true;
indicesTE = ~indicesTR;
indicesTR = find(indicesTR);
indicesTE = find(indicesTE);

% training
featsTR = featCalculator.calculate('indicesToCalc', indicesTR);
featCalculator.setFeatureRange(featsTR);
featsTR = featCalculator.normalizeLerp(featsTR);
posesTR = db.poses(indicesTR, :);
% testing
featsTE = featCalculator.calculate('indicesToCalc', indicesTE);
featsTE = featCalculator.normalizeLerp(featsTE);
posesTE = db.poses(indicesTE, :);
% saving
fprintf('\nPress Ctrl+C to cancel saving\n');
pause;
save('RealTrain.mat', 'featsTR', 'posesTR');
save('RealTest.mat', 'featsTE', 'posesTE');

%% Evaluates performance
matcher = ExhaustiveSearcher(featsTR);
[nearestIdx, ~] = knnsearch(matcher, featsTE, 'K', 1);
estPoses = posesTR(nearestIdx, :);
err = mean(poseDistance(estPoses, posesTE));
fprintf('NN regression: %f\n', err);
