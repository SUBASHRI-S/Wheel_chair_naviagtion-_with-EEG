function models = train_models(X_train, Y_train, cfg)
%TRAIN_MODELS  Train 6 classifiers on EEG feature matrix.

n_classes = numel(unique(Y_train));
models    = struct();

%% MODEL 1 — Cubic SVM
fprintf('\n  [1/6] Training Cubic SVM...\n');
t0 = tic;
svm_template = templateSVM('KernelFunction', 'polynomial', ...
                            'PolynomialOrder', 3, ...
                            'KernelScale',     'auto', ...
                            'BoxConstraint',   1, ...
                            'Standardize',     true);
models.m1 = fitcecoc(X_train, Y_train, ...
    'Learners', svm_template, ...
    'Coding',   'onevsone');
fprintf('    Done in %.1fs\n', toc(t0));

%% MODEL 2 — Ensemble Bagging Tree
fprintf('  [2/6] Training Bagging Ensemble...\n');
t0 = tic;
tree_tmpl = templateTree('MaxNumSplits', 50, 'MinLeafSize', 5);
models.m2 = fitcensemble(X_train, Y_train, ...
    'Method',            'Bag', ...
    'NumLearningCycles', 100, ...
    'Learners',          tree_tmpl);
fprintf('    Done in %.1fs\n', toc(t0));

%% MODEL 3 — Feedforward Neural Network (patternnet)
fprintf('  [3/6] Training Feedforward Neural Network...\n');
t0 = tic;
net = patternnet([128, 64, 32]);
net.trainFcn               = 'trainscg';
net.trainParam.epochs      = 200;
net.trainParam.max_fail    = 20;
net.trainParam.showWindow  = false;
net.trainParam.show        = 25;
net.divideParam.trainRatio = 0.80;
net.divideParam.valRatio   = 0.10;
net.divideParam.testRatio  = 0.10;
net.performFcn             = 'crossentropy';
T = ind2vec(Y_train', n_classes);
[models.m3, ~] = train(net, full(X_train'), T);
fprintf('    Done in %.1fs\n', toc(t0));

%% MODEL 4 — CNN
fprintf('  [4/6] Training CNN...\n');
t0     = tic;
n_feat = size(X_train, 2);

% Reshape to [n_feat x 1 x 1 x N]
X_cnn = reshape(X_train', [n_feat, 1, 1, size(X_train, 1)]);
Y_cnn = categorical(Y_train);

% Manual validation split (80/20) — avoids 'ValidationSplit' option issue
n_train_cnn  = size(X_train, 1);
val_idx      = randperm(n_train_cnn, floor(0.1 * n_train_cnn));
train_idx    = setdiff(1:n_train_cnn, val_idx);

X_cnn_tr  = X_cnn(:,:,:, train_idx);
Y_cnn_tr  = Y_cnn(train_idx);
X_cnn_val = X_cnn(:,:,:, val_idx);
Y_cnn_val = Y_cnn(val_idx);

cnn_layers = [
    imageInputLayer([n_feat 1 1], 'Normalization', 'zscore', 'Name', 'input')
    convolution2dLayer([5 1], 32, 'Padding', 'same', 'Name', 'conv1')
    batchNormalizationLayer('Name', 'bn1')
    reluLayer('Name', 'relu1')
    convolution2dLayer([5 1], 64, 'Padding', 'same', 'Name', 'conv2')
    batchNormalizationLayer('Name', 'bn2')
    reluLayer('Name', 'relu2')
    averagePooling2dLayer([2 1], 'Stride', [2 1], 'Name', 'pool1')
    convolution2dLayer([3 1], 128, 'Padding', 'same', 'Name', 'conv3')
    batchNormalizationLayer('Name', 'bn3')
    reluLayer('Name', 'relu3')
    globalAveragePooling2dLayer('Name', 'gap')
    fullyConnectedLayer(64, 'Name', 'fc1')
    reluLayer('Name', 'relu_fc1')
    dropoutLayer(0.3, 'Name', 'drop1')
    fullyConnectedLayer(n_classes, 'Name', 'fc_out')
    softmaxLayer('Name', 'softmax')
    classificationLayer('Name', 'output')
];

cnn_opts = trainingOptions('adam', ...
    'MaxEpochs',           80, ...
    'MiniBatchSize',       64, ...
    'InitialLearnRate',    1e-3, ...
    'LearnRateSchedule',   'piecewise', ...
    'LearnRateDropPeriod', 30, ...
    'LearnRateDropFactor', 0.5, ...
    'ValidationData',      {X_cnn_val, Y_cnn_val}, ...
    'ValidationFrequency', 10, ...
    'Shuffle',             'every-epoch', ...
    'Verbose',             false, ...
    'Plots',               'none');

try
    models.m4 = trainNetwork(X_cnn_tr, Y_cnn_tr, cnn_layers, cnn_opts);
    fprintf('    Done in %.1fs\n', toc(t0));
catch ME
    warning('CNN training failed: %s\n  Using fallback decision tree.', ME.message);
    models.m4 = fitctree(X_train, Y_train);
end

%% MODEL 5 — Random Forest (TreeBagger, 150 trees)
fprintf('  [5/6] Training Random Forest (150 trees)...\n');
t0 = tic;
models.m5 = TreeBagger(150, X_train, Y_train, ...
    'Method',                'classification', ...
    'NumPredictorsToSample', 'all', ...
    'MinLeafSize',           3, ...
    'OOBPrediction',         'on');
fprintf('    OOB error: %.4f\n', oobError(models.m5, 'Mode', 'ensemble'));
fprintf('    Done in %.1fs\n', toc(t0));

%% MODEL 6 — Gradient Boosting (AdaBoostM2)
fprintf('  [6/6] Training Gradient Boosting (AdaBoostM2)...\n');
t0 = tic;
boost_tmpl = templateTree('MaxNumSplits', 20, 'MinLeafSize', 5);
models.m6 = fitcensemble(X_train, Y_train, ...
    'Method',            'AdaBoostM2', ...
    'NumLearningCycles', 200, ...
    'LearnRate',         0.1, ...
    'Learners',          boost_tmpl);
fprintf('    Done in %.1fs\n', toc(t0));

fprintf('\n  All 6 models trained successfully.\n');
end