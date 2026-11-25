%% =========================================================
%  main.m  —  EEG Wheelchair BCI Full Pipeline
%  Project : Wheelchair Navigation using Brain-Controlled Interface
%  Device  : ChordsAlpha Dual-Channel EEG Kit
%  Classes : LEFT(1) | RIGHT(2) | FORWARD(3) | STOP(4)
%  Author  : Generated Pipeline
% ==========================================================

clc; clear; close all;

%% ── CONFIGURATION ─────────────────────────────────────────
cfg.Fs              = 500;        % Sampling rate (Hz)
cfg.n_channels      = 2;
cfg.window_sec      = 2;          % Window length in seconds
cfg.overlap_ratio   = 0.5;        % 50% overlap
cfg.bp_low          = 0.5;        % Bandpass low  (Hz)
cfg.bp_high         = 40;         % Bandpass high (Hz)
cfg.notch_freq      = 50;         % Notch frequency (Hz)
cfg.n_folds         = 5;          % Cross-validation folds
cfg.train_ratio     = 0.70;       % Train/test split
cfg.dataset_root    = 'dataset';  % Root folder

% Band definitions [low high] Hz
cfg.bands.delta  = [0.5  4 ];
cfg.bands.theta  = [4    8 ];
cfg.bands.alpha  = [8    13];
cfg.bands.beta   = [13   30];
cfg.bands.gamma  = [30   40];

class_names = {'LEFT','RIGHT','FORWARD','STOP'};

fprintf('========================================\n');
fprintf('   EEG Wheelchair BCI Pipeline\n');
fprintf('========================================\n\n');

%% ── STEP 1 : Load Dataset ─────────────────────────────────
fprintf('[STEP 1] Loading dataset...\n');
[raw_signals, labels] = load_dataset(cfg);
fprintf('  Loaded %d sessions, %d total samples\n\n', ...
    numel(unique(labels,'rows')), size(raw_signals,1));

%% ── STEP 2 & 3 : Segment + Preprocess ────────────────────
fprintf('[STEP 2-3] Segmenting and preprocessing...\n');
[segments, seg_labels] = segment_and_preprocess(raw_signals, labels, cfg);
fprintf('  Produced %d windows x %d channels x %d samples\n\n', ...
    size(segments,1), size(segments,2), size(segments,3));

%% ── STEP 4 : Feature Extraction ──────────────────────────
fprintf('[STEP 4] Extracting features...\n');
[X, Y] = extract_features(segments, seg_labels, cfg);
fprintf('  Feature matrix: %d windows x %d features\n\n', size(X,1), size(X,2));

%% ── STEP 5 : Train / Test Split ──────────────────────────
fprintf('[STEP 5] Splitting data 70/30...\n');
cv_partition = cvpartition(Y, 'HoldOut', 1 - cfg.train_ratio, 'Stratify', true);
X_train = X(training(cv_partition), :);
Y_train = Y(training(cv_partition));
X_test  = X(test(cv_partition), :);
Y_test  = Y(test(cv_partition));
fprintf('  Train: %d  |  Test: %d\n\n', numel(Y_train), numel(Y_test));

%% ── STEP 6 : Train Models ─────────────────────────────────
fprintf('[STEP 6] Training all 6 models...\n');
models = train_models(X_train, Y_train, cfg);

%% ── STEP 7 & 8 : Evaluate + Select Best ──────────────────
fprintf('[STEP 7-8] Evaluating models...\n');
results = evaluate_models(models, X_test, Y_test, class_names);

%% ── STEP 9 : Best model demo prediction ──────────────────
fprintf('\n[STEP 9] Real-time prediction demo...\n');
% Use one random test window as demo
demo_idx    = randi(size(X_test,1));
demo_window = segments(test(cv_partition),:,:);
demo_seg    = squeeze(demo_window(demo_idx,:,:));  % [channels x samples]
[cmd, prob] = predict_realtime(demo_seg, results.best_model, cfg);
fprintf('  Demo prediction → %s  (confidence %.1f%%)\n\n', cmd, prob*100);

%% ── STEP 10 : Save / Load ─────────────────────────────────
fprintf('[STEP 10] Saving model...\n');
best_model  = results.best_model;
feature_cfg = cfg;
save('eeg_model.mat', 'best_model', 'feature_cfg', 'class_names');
fprintf('  Saved: eeg_model.mat\n');

% Demonstrate loading
loaded = load('eeg_model.mat');
fprintf('  Loaded model: %s\n', class(loaded.best_model));

fprintf('\n========================================\n');
fprintf('   Pipeline complete!\n');
fprintf('========================================\n');
