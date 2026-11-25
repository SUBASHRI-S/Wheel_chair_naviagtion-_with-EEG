function [command, confidence] = predict_realtime(raw_window, model, cfg)
%PREDICT_REALTIME  Predict wheelchair command from a raw EEG window.
%
%  Can be called in two ways:
%    1. From main.m with a pre-loaded window (demo mode)
%    2. Standalone via run_live_prediction.m for real-time device streaming
%
%  Inputs:
%    raw_window : [win_len x 2] OR [2 x win_len]  raw EEG
%    model      : trained classifier
%    cfg        : configuration struct used during training
%
%  Outputs:
%    command    : 'LEFT' | 'RIGHT' | 'FORWARD' | 'STOP'
%    confidence : scalar [0..1]

class_names = {'LEFT','RIGHT','FORWARD','STOP'};

%% 1. Ensure [win_len x 2] orientation
if size(raw_window, 1) == 2 && size(raw_window, 2) ~= 2
    raw_window = raw_window';
end

%% 2. Preprocess
clean = preprocess_signal(double(raw_window), cfg);

%% 3. Reshape to [1 x 2 x win_len] for extract_features
seg = reshape(clean', [1, size(clean, 2), size(clean, 1)]);
seg = single(seg);

%% 4. Extract features
[x_feat, ~] = extract_features(seg, 1, cfg);

%% 5. Predict
lbl_idx    = 1;
confidence = 0;

try
    if isa(model, 'network')
        out = model(x_feat');
        [confidence, lbl_idx] = max(out);

    elseif isa(model, 'DAGNetwork') || isa(model, 'SeriesNetwork')
        n_feat = size(x_feat, 2);
        X_cnn  = reshape(x_feat', [n_feat, 1, 1, 1]);
        [Y_cat, scores] = classify(model, X_cnn);
        lbl_idx    = double(Y_cat);
        confidence = max(scores);

    elseif isa(model, 'TreeBagger')
        [Y_cell, scores] = predict(model, x_feat);
        lbl_idx    = str2double(Y_cell{1});
        confidence = max(scores);

    else
        [lbl_idx, scores] = predict(model, x_feat);
        lbl_idx    = double(lbl_idx);
        scores     = scores(:);
        scores_sm  = exp(scores - max(scores));
        scores_sm  = scores_sm / sum(scores_sm);
        confidence = max(scores_sm);
    end
catch ME
    warning('BCI:predError', '%s', ME.message);
    lbl_idx    = 1;
    confidence = 0;
end

%% 6. Map to command string
lbl_idx = round(double(lbl_idx));
if lbl_idx >= 1 && lbl_idx <= 4
    command = class_names{lbl_idx};
else
    command    = 'UNKNOWN';
    confidence = 0;
end
end