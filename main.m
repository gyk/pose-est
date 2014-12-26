
%% Prepares dataset
db = RealExemplarDB();
shapeContextsCalculator = [];

if exist(CONFIG.REAL_SC_CACHED, 'file')
	load(CONFIG.REAL_SC_CACHED);
	featCalculator = FeatureCalculator(db, ...
		'shapeContextsCalculator', shapeContextsCalculator);
else
	shapeContextsCalculator = ...
		FeatureCalculator.prepareSCCalculator(db);
	save(CONFIG.REAL_SC_CACHED, 'shapeContextsCalculator');
end

n = db.nImages;


%% Chooses feature types, optionally
mask = FeatureCalculator.makeFeatureMask();
indicator = mask.OM;
fprintf('# of selected dimensions: %d\n', sum(indicator));
featCalculator.setFeatureSelector(indicator);


%% Split the database into training and testing sets
% sets the seed of random number generator, for debugging purpose:
rndgen('default');
indicesTR = false(n, 1);
indicesTR(randsample(n, floor(n / 2))) = true;
indicesTE = ~indicesTR;
indicesTR = find(indicesTR);
indicesTE = find(indicesTE);

useSelector = ~all(indicator);
% training
featsTR = featCalculator.calculate('useSelector', useSelector, ...
	'indicesToCalc', indicesTR);
featCalculator.setFeatureRange(featsTR);
featsTR = featCalculator.normalizeLerp(featsTR);
posesTR = db.poses(indicesTR, :);
% testing
featsTE = featCalculator.calculate('useSelector', useSelector, ...
	'indicesToCalc', indicesTE);
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
